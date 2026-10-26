extends Node

var game: Node2D
var policy=preload("res://ad_policy.gd").new()
var test_mode := false
var simulate_ad_free := false
var focused := true
var showing := false
var dialog: AcceptDialog
var continuation: Callable
var save_clock := 0.0
var initialized := false
var provider: Object
var native_pending := false
var request_token := 0
var opened_token := -1
var prepare_clock := 0.0

func file_path() -> String: return game.storage_prefix+"ads.json"

func initialize() -> void:
	var state := {}
	for path in [file_path(),file_path()+".bak"]:
		if not FileAccess.file_exists(path): continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path))!=OK: continue
		var parsed=parser.data
		if parsed is Dictionary and int(parsed.get("version",0))==1 and parsed.get("completed_paths",[]) is Array and parsed.get("seen_worlds",[]) is Array: state=parsed; break
	policy.restore(state)
	# Existing achievements keep the introductory grace period honest on upgrade.
	for index in JourneyProgress.album_indices(game):
		var path: String=game.level_path(index)
		if not policy.completed_paths.has(path): policy.completed_paths.append(path)
	test_mode=bool(state.get("test_mode",false)) and OS.has_feature("debug")
	simulate_ad_free=bool(state.get("simulate_ad_free",false)) and OS.has_feature("debug")
	initialized=true
	if Engine.has_singleton("ArrowJoyAds") and not game.editor and not game.authoring:
		setup_native.call_deferred()

func setup_native() -> void:
	if provider != null or not FileAccess.file_exists("res://admob_runtime.json"): return
	var config = JSON.parse_string(FileAccess.get_file_as_string("res://admob_runtime.json"))
	if not config is Dictionary or str(config.get("interstitial_id", "")).is_empty(): return
	provider=Engine.get_singleton("ArrowJoyAds")
	provider.connect("ad_opened",native_opened)
	provider.connect("ad_finished",native_finished)
	provider.connect("privacy_changed",refresh_privacy_page)
	provider.call("setEnabled",not is_ad_free())
	if not is_ad_free(): provider.call("start",str(config.interstitial_id))

func privacy_required() -> bool:
	return provider != null and bool(provider.call("privacyRequired"))

func refresh_privacy_page() -> void:
	if is_instance_valid(game.home_menu) and game.home_menu.screen=="privacy":
		game.home_menu.relayout.call_deferred()

func show_privacy_options() -> void:
	if privacy_required(): provider.call("showPrivacy")

func native_opened(token: int) -> void:
	if not native_pending or token!=request_token or opened_token==token: return
	opened_token=token
	policy.ad_shown(); save()

func native_finished(token: int, _shown: bool) -> void:
	if not native_pending or token!=request_token: return
	native_pending=false
	dismiss()

func save() -> int:
	if not initialized: return OK
	var state: Dictionary=policy.snapshot()
	state.test_mode=test_mode; state.simulate_ad_free=simulate_ad_free
	var path := file_path()
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(state)); file.flush()
	var error := file.get_error()
	file.close()
	if error != OK: return error
	if FileAccess.file_exists(path):
		error = DirAccess.copy_absolute(path,path+".bak")
		if error != OK: return error
	error = DirAccess.rename_absolute(path+".tmp",path)
	if error != OK: push_warning(AppLanguage.text("Werbezähler konnten nicht gespeichert werden."))
	return error

func is_ad_free() -> bool: return policy.ad_free or simulate_ad_free

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT,NOTIFICATION_APPLICATION_PAUSED]: focused=false; save()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN,NOTIFICATION_APPLICATION_RESUMED]: focused=true
	elif what==NOTIFICATION_WM_CLOSE_REQUEST: save()

func _process(delta: float) -> void:
	if not initialized: return
	var modal := false
	for child in game.get_children():
		if child is Window and child.visible: modal=true; break
	var active: bool= focused and not is_instance_valid(game.play_guide) and not modal and not showing and game.session_in_progress and game.win_time<0 and not game.editor and not game.authoring and not is_instance_valid(game.home_menu) and not is_instance_valid(game.journey) and not is_instance_valid(game.gallery)
	policy.tick(delta,active)
	if provider != null and focused and not showing and not is_ad_free():
		prepare_clock+=delta
		if prepare_clock>=60:
			prepare_clock=0.0; provider.call("prepare")
	if active:
		save_clock+=clampf(delta,0.0,1.0)
		if save_clock>=15: save_clock=0.0; save()

func completed(path: String, world: int) -> void:
	policy.record_completion(path,world_key(world)); save()

func world_key(world: int) -> int:
	# Stable keys preserve existing ad protection when the map is reordered.
	if world<0 or world>=JourneyProgress.worlds().size(): return -1
	return int(JourneyProgress.worlds()[world].ad_id)

func opened_world(world: int) -> void:
	if world>=0 and JourneyProgress.worlds()[world].id=="first_light": return
	policy.open_world(world_key(world)); save()

func transition(world: int, callback: Callable) -> void:
	if showing: return
	if is_ad_free() or not policy.eligible(true,world_key(world)):
		callback.call(); return
	if provider != null:
		continuation=callback; showing=true; native_pending=true
		request_token+=1
		provider.call("show",request_token)
		return
	# Desktop/developer simulation remains offline; a missing SDK never blocks play.
	if not test_mode or not OS.has_feature("debug"):
		callback.call(); return
	continuation=callback
	dialog=AcceptDialog.new()
	dialog.title=AppLanguage.text("Testanzeige · keine echte Werbung")
	dialog.dialog_text=AppLanguage.text("Hier würde eine Werbeanzeige erscheinen.\n\nKeine Verbindung zu einem Werbedienst.\nMit Weiterreisen geht dein Spiel sofort weiter.")
	dialog.ok_button_text=AppLanguage.text("Weiterreisen")
	dialog.exclusive=true
	dialog.confirmed.connect(dismiss)
	dialog.canceled.connect(dismiss)
	game.add_child(dialog)
	showing=true
	dialog.popup_centered(Vector2i(mini(420,game.get_window().size.x-40),240))
	policy.ad_shown(); save()

func dismiss() -> void:
	# Native ads own their close button. Android Back must not resume behind them.
	if native_pending: return
	if not showing: return
	showing=false
	if is_instance_valid(dialog): dialog.hide(); dialog.queue_free()
	dialog=null
	var callback := continuation
	continuation=Callable()
	if callback.is_valid(): callback.call()

func set_test_mode(value: bool) -> void:
	test_mode=value and OS.has_feature("debug"); save()

func set_simulated_ad_free(value: bool) -> void:
	simulate_ad_free=value and OS.has_feature("debug"); save()

func set_verified_ad_free(value: bool) -> void:
	# Reserved for a future verified purchase/restore integration; no purchase UI yet.
	policy.ad_free=value; save()
	if provider != null: provider.call("setEnabled",not is_ad_free())
