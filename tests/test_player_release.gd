extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func run():
	var scene = load("res://main.tscn").instantiate()
	scene.storage_prefix = "user://test_release_catalog_"
	scene.workshop_manifest_path = "res://collections/no-private-manifest.json"
	scene.journey_mode = true
	scene.scan_user_exports = true
	root.add_child(scene)
	await process_frame
	var expected: Array = []
	for index in scene.TITLES.size():
		var path = "res://levels/%02d.json" % (index+1)
		if FileAccess.file_exists(path): expected.append(path)
	if scene.base_level_count != expected.size(): failures += 1; push_error("Release introduction must contain only existing puzzle files")
	for index in range(scene.base_level_count):
		if scene.level_path(index) != expected[index]: failures += 1; push_error("Release introduction retains the actual file order")
	for index in scene.level_count():
		if not FileAccess.file_exists(scene.level_path(index)): failures += 1; push_error("Release catalog cannot contain deleted puzzle files")
	scene.open_home()
	scene.home_menu.navigate("settings")
	scene.home_menu.show_privacy()
	await process_frame
	if scene.home_menu.screen != "privacy" or scene.home_menu.get_node("PrivacyScroll/PrivacyText").text.is_empty(): failures += 1; push_error("Privacy opens as a readable offline page")
	scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	if not is_instance_valid(scene.home_menu) or scene.home_menu.screen != "settings": failures += 1; push_error("Android Back returns privacy to settings")
	scene.home_menu.show_privacy()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	scene._unhandled_input(escape)
	await process_frame
	if not is_instance_valid(scene.home_menu) or scene.home_menu.screen != "settings": failures += 1; push_error("Desktop Escape returns privacy to settings")
	scene.feedback.stop_all()
	scene.queue_free()
	await process_frame
	for file in ["settings.cfg","progress.cfg","library.cfg","sessions.json","sessions.json.bak","ads.json","ads.json.bak"]: DirAccess.remove_absolute("user://test_release_catalog_"+file)
	if failures == 0: print("PASS player release: private manifest absent, existing intro files only, no missing catalog paths, offline privacy page and Android Back")
	quit(1 if failures else 0)
