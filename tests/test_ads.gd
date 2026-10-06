extends SceneTree

var failures := 0
func require(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var policy=load("res://ad_policy.gd").new()
	for second in range(360): policy.tick(1.0,true)
	for i in range(5):
		policy.record_completion("intro_%d" % i,0)
		require(not policy.eligible(true,0),"First five completions stay entirely ad-free")
	policy.record_completion("sixth",0)
	require(policy.eligible(true,0),"Sixth normal transition can show an ad after six active minutes")
	require(not policy.eligible(false,0),"Milestones, menus and first world opening are not ad transitions")
	policy.ad_shown()
	for i in range(3): policy.record_completion("later_%d" % i,0)
	for second in range(360): policy.tick(1.0,true)
	require(not policy.eligible(true,0),"Six minutes alone never trigger an ad")
	policy.record_completion("later_3",0)
	require(policy.eligible(true,0),"Four new completions AND six active minutes are required")
	policy.ad_shown()
	for i in range(4): policy.record_completion("fast_%d" % i,0)
	policy.tick(1.0,true)
	require(not policy.eligible(true,0),"Four fast completions alone never trigger an ad")
	var clock: float=policy.active_since_ad
	policy.tick(600.0,false)
	require(policy.active_since_ad==clock,"Inactive time never accrues")
	for second in range(359): policy.tick(1.0,true)
	policy.open_world(1)
	require(not policy.eligible(true,1),"A newly opened world stays protected until a new completion")
	policy.record_completion("first_new_world",1)
	require(policy.eligible(true,1),"A normal transition after the first new-world puzzle can qualify")
	policy.ad_free=true
	require(not policy.eligible(true,1),"Verified ad-free state blocks ads")
	policy.ad_free=false
	var restored=load("res://ad_policy.gd").new()
	restored.restore(policy.snapshot())
	require(restored.eligible(true,1),"Counts and active time survive restoration")
	var count: int=restored.rounds_since_ad
	restored.record_completion("first_new_world",1)
	require(restored.rounds_since_ad==count,"Restoring or replaying an existing achievement cannot count twice")
	for second in range(1800): restored.tick(1.0,true)
	restored.ad_shown()
	require(not restored.eligible(true,1),"Deferred ads never accumulate into a catch-up series")

	var prefix := "user://test_ad_policy_"
	for name in ["ads.json","ads.json.bak","ads.json.tmp","progress.cfg","library.cfg","settings.cfg"]: DirAccess.remove_absolute(prefix+name)
	var scene=load("res://main.tscn").instantiate()
	scene.storage_prefix=prefix; scene.journey_mode=true
	root.add_child(scene); await process_frame
	scene.ads.set_process(false); scene.set_process(false)
	scene.ads.focused=true; scene.session_in_progress=true; scene.win_time=-1
	var before: float=scene.ads.policy.active_since_ad
	scene.ads._process(1)
	require(scene.ads.policy.active_since_ad==before+1,"Controller counts actual foreground gameplay")
	scene.open_home(); scene.ads._process(1)
	require(scene.ads.policy.active_since_ad==before+1,"Home and settings are excluded from active play time")
	scene.close_home(); scene.ads.focused=false; scene.ads._process(1)
	require(scene.ads.policy.active_since_ad==before+1,"Background app time is excluded")
	scene.ads.focused=true; scene.win_time=2.6; scene.ads._process(1)
	require(scene.ads.policy.active_since_ad==before+1,"Celebration and completion reading are excluded")
	scene.ads.policy=policy
	if OS.get_cmdline_user_args().has("--capture"):
		scene.open_home(); scene.home_menu.navigate("settings")
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://previews/ad-test-settings.png")
		scene.close_home()
	scene.ads.set_test_mode(false)
	var reached := [0]
	scene.ads.transition(1,func(): reached[0]+=1)
	require(reached[0]==1 and not scene.ads.showing,"Missing provider continues immediately without an ad or wait")
	scene.ads.set_test_mode(true); scene.ads.set_simulated_ad_free(true)
	scene.ads.transition(1,func(): reached[0]+=1)
	require(reached[0]==2 and not scene.ads.showing,"Simulated premium bypasses the test provider")
	scene.ads.set_simulated_ad_free(false)
	scene.ads.transition(1,func(): reached[0]+=1)
	require(scene.ads.showing and reached[0]==2,"Eligible transition opens a clearly labeled offline test ad")
	if OS.get_cmdline_user_args().has("--capture"):
		await process_frame; await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://previews/ad-test-transition.png")
	var current_clock: float=scene.clock_time
	scene._process(1)
	require(scene.clock_time==current_clock,"Test ad pauses gameplay")
	require(scene.ads.policy.rounds_since_ad==0 and scene.ads.policy.active_since_ad==0,"Only actual display resets the interval")
	scene.ads.transition(1,func(): reached[0]+=10)
	scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST); scene.ads.dismiss()
	require(reached[0]==3 and not scene.ads.showing,"Duplicate taps and dismissals continue exactly once")
	scene.ads.policy.active_since_ad=360; scene.ads.policy.rounds_since_ad=4
	scene.completed.assign([0]); scene.level=0; scene.win_time=2.6
	scene.advance()
	require(scene.ads.showing and scene.level==0,"Real Next action waits at the completed puzzle while the test ad is open")
	scene.ads.dismiss()
	require(scene.level==1 and scene.win_time<0,"Closing the ad loads the intended next puzzle exactly once")
	for index in range(9):
		if not scene.completed.has(index): scene.completed.append(index)
	scene.ads.policy.active_since_ad=360; scene.ads.policy.rounds_since_ad=4
	scene.level=8; scene.win_time=2.6; scene.advance()
	require(is_instance_valid(scene.journey) and not scene.ads.showing,"A real collection and world milestone bypasses due ads")
	scene.ads.policy.seen_worlds.clear()
	scene.journey.navigate("collection",1,"animals")
	require(scene.ads.policy.protected_world==1 and not scene.ads.showing,"First entry into a new-world collection is protected")
	scene.ads.policy.active_since_ad=123; scene.ads.save()
	var controller=load("res://ad_controller.gd").new()
	controller.game=scene; scene.add_child(controller); controller.initialize(); controller.set_process(false)
	require(controller.policy.active_since_ad==123 and controller.test_mode,"Controller persists counters and test mode")
	# A corrupt primary file falls back to the last valid backup.
	scene.ads.policy.active_since_ad=234; scene.ads.save()
	var broken=FileAccess.open(prefix+"ads.json",FileAccess.WRITE); broken.store_string("incomplete"); broken.close()
	controller.initialize()
	require(controller.policy.active_since_ad==123,"Damaged state falls back to backup")
	scene.queue_free(); await process_frame
	for name in ["ads.json","ads.json.bak","ads.json.tmp","progress.cfg","library.cfg","settings.cfg"]: DirAccess.remove_absolute(prefix+name)
	print("PASS ads: intro grace, dual intervals, milestones, worlds, no catch-up, foreground time, premium, offline provider and persistence" if failures==0 else "%d FAILURES" % failures)
	quit(1 if failures else 0)
