extends SceneTree
var failures := 0
var scene: Node2D
func require(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_guide_"
	root.add_child(scene)
	await process_frame
	var prefs := ConfigFile.new()
	prefs.set_value("audio","enabled",false)
	prefs.save(scene.storage_prefix+"settings.cfg")
	scene.journey_mode=true
	scene.start_journey_puzzle(0)
	await process_frame
	require(is_instance_valid(scene.play_guide),"First puzzle opens guide")
	require(not scene.board_navigation.active(),"Guide blocks board gestures")
	var clock_before=scene.clock_time
	await process_frame
	require(scene.clock_time==clock_before,"Guide time does not count as play time")
	var guide=scene.play_guide
	var before=scene.cleared
	var event := InputEventMouseButton.new()
	event.pressed=true; event.button_index=MOUSE_BUTTON_LEFT
	guide.demo_input(event)
	require(guide.released and scene.cleared==before,"Demo leaves real puzzle unchanged")
	guide.show_step(1)
	event.position=Vector2(10,60); guide.demo_input(event)
	require(guide.flash>0 and not guide.blocker_removed,"Demo explains blocked move")
	event.position=Vector2(guide.demo.size.x,60); guide.demo_input(event)
	require(guide.blocker_removed,"Demo blocker can be cleared")
	for language in ["de","en"]:
		AppLanguage.choose(language,scene.storage_prefix)
		for dimensions in [Vector2i(540,850),Vector2i(540,1170)]:
			root.size=dimensions
			for page in 4:
				guide.show_step(page)
				await process_frame
				await process_frame
				require(guide.card.position.y+guide.card.size.y<root.get_visible_rect().size.y-20,"Guide fits portrait screen")
				if OS.get_cmdline_user_args().has("--capture"):
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png("res://previews/guide-%s-%d-%d.png" % [language,dimensions.y,page])
	guide.finish()
	await process_frame
	prefs.load(scene.storage_prefix+"settings.cfg")
	require(prefs.get_value("guide","seen",false),"Dismissal remembered")
	require(prefs.get_value("audio","enabled",true)==false,"Other preferences preserved")
	scene.maybe_show_play_guide()
	require(not is_instance_valid(scene.play_guide),"Guide does not repeat")
	scene.show_play_guide()
	await process_frame
	require(is_instance_valid(scene.play_guide),"Help can be reopened")
	scene.play_guide.finish()
	await process_frame
	scene.open_home()
	scene.home_menu.navigate("settings")
	require(scene.home_menu.find_children("*","Button",true,false).any(func(b): return b.text==AppLanguage.text("So spielst du")),"Settings offer help")
	print("PLAY GUIDE: ",failures," failures")
	quit(1 if failures else 0)
