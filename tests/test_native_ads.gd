extends SceneTree

class FakeAds extends RefCounted:
	signal ad_opened(token: int)
	signal ad_finished(token: int, shown: bool)
	var token := -1
	var available := false
	var enabled := true
	func show(value: int) -> void:
		token=value
		if not available: ad_finished.emit(value,false)
	func setEnabled(value: bool) -> void: enabled=value
	func prepare() -> void: pass
	func privacyRequired() -> bool: return false

var failures := 0
func check(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_native_ads_"
	root.add_child(scene); await process_frame
	var controller=scene.ads
	controller.set_process(false)
	controller.policy.completed_paths.assign(["a","b","c","d","e","f"])
	controller.policy.active_since_ad=360
	controller.policy.rounds_since_ad=4
	controller.policy.protected_world=-1
	var fake=FakeAds.new()
	controller.provider=fake
	fake.ad_opened.connect(controller.native_opened)
	fake.ad_finished.connect(controller.native_finished)
	var count=[0]
	controller.transition(1,func(): count[0]+=1)
	check(count[0]==1 and not controller.showing,"Unavailable ad never waits or resets counters")
	check(controller.policy.active_since_ad==360,"Failed/no-fill ads do not reset active time")
	fake.available=true
	controller.transition(1,func(): count[0]+=1)
	check(controller.showing and count[0]==1,"Native show holds the intended continuation")
	controller.dismiss()
	check(controller.showing and count[0]==1,"Back cannot continue behind a native ad")
	fake.ad_opened.emit(fake.token-1)
	check(controller.policy.rounds_since_ad==4,"Old callbacks cannot count an impression")
	fake.ad_opened.emit(fake.token)
	check(controller.policy.active_since_ad==0 and controller.policy.rounds_since_ad==0,"Only actual opening resets both intervals")
	controller.policy.active_since_ad=3
	fake.ad_opened.emit(fake.token)
	check(controller.policy.active_since_ad==3,"Repeated opening callback counts once")
	controller.transition(1,func(): count[0]+=100)
	fake.ad_finished.emit(fake.token,true)
	fake.ad_finished.emit(fake.token,true)
	check(count[0]==2 and not controller.showing,"Duplicate close/taps continue once")
	controller.policy.active_since_ad=360; controller.policy.rounds_since_ad=4
	controller.transition(1,func(): count[0]+=1)
	fake.ad_finished.emit(fake.token,false)
	check(count[0]==3 and controller.policy.active_since_ad==360,"Show errors continue without charging the interval")
	controller.set_verified_ad_free(true)
	check(not fake.enabled,"Ad-free state disables native loading")
	controller.transition(1,func(): count[0]+=1)
	check(count[0]==4 and not controller.showing,"Ad-free state bypasses native display")
	scene.queue_free(); await process_frame
	for filename in ["ads.json","ads.json.bak","ads.json.tmp","progress.cfg","library.cfg","settings.cfg","sessions.json"]:
		DirAccess.remove_absolute("user://test_native_ads_"+filename)
	print("NATIVE ADS BRIDGE: %d failures" % failures)
	quit(1 if failures else 0)
