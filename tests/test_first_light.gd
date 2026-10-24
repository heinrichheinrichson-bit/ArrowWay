extends SceneTree
var failures:=0
var game: Node2D
func check(ok: bool, text: String) -> void:
	if not ok: failures+=1; push_error(text)
func _initialize() -> void: call_deferred("run")
func create_game(prefix: String) -> Node2D:
	var instance=load("res://main.tscn").instantiate()
	instance.storage_prefix=prefix
	instance.journey_mode=true; instance.scan_user_exports=true; instance.resume_enabled=false
	root.add_child(instance)
	return instance
func solve() -> void:
	for index in ArrowPuzzle.solution(game.arrows):
		game.click_at(game.arrows[index].points[0]); game._process(3.0)
func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/first-light-"+name+".png")
func run() -> void:
	var prefix:="user://test_first_light_"+str(Time.get_ticks_usec())+"_"
	game=create_game(prefix)
	await process_frame
	game.set_language("de")
	root.size=Vector2i(540,960)
	await process_frame
	check(JourneyProgress.worlds()[0].id=="first_light","First world is the introduction")
	var lessons:=JourneyProgress.indices(game,"first_light")
	check(lessons.size()==3,"Exactly three introduction puzzles")
	check(game.level==lessons[0],"Fresh game starts with fish, not old catalogue")
	check(game.level_available(lessons[0]) and not game.level_available(lessons[1]),"Lessons unlock sequentially")
	check(not JourneyProgress.world_open(game,1),"Normal journey starts after the introduction")
	game.open_journey()
	var stations=game.journey.canvas.get_children().filter(func(n): return n.has_meta("station_id"))
	check(stations.filter(func(n): return n.get_meta("station_id")=="group:first_light").size()==1,"Introduction is exactly one visible station")
	check(not stations.any(func(n): return n.get_meta("station_id")=="world:first_light"),"No duplicate parent intro station")
	var intro_node=stations.filter(func(n): return n.get_meta("station_id")=="group:first_light")[0]
	check(intro_node.title=="Spielend entdecken","Single intro station uses requested name")
	intro_node.pressed.emit()
	check(game.journey.screen=="collection" and game.journey.group=="first_light","Single station opens puzzles directly")
	game.open_journey()
	await capture("reise")
	game.start_journey_puzzle(lessons[0])
	await process_frame
	var guide=game.first_light_guide
	check(guide.active and guide.lesson==0 and guide.source_arrow>=0,"Fish guide uses real blockers")
	await capture("fisch")
	game.click_at(game.arrows[guide.target_arrow].points[0]); guide._process(0)
	check(game.mistakes==1 and guide.warning_time>0,"Blocked move is explained")
	game.click_at(game.arrows[guide.source_arrow].points[0]); game._process(3.0); guide._process(3.0)
	check(guide.phase==2 and not game.is_blocked(guide.target_arrow),"Flight opens the guided second arrow")
	game.click_at(game.arrows[guide.target_arrow].points[0]); game._process(3.0); guide._process(0)
	check(guide.phase==3,"Fish ends with independent play")
	solve()
	check(game.completed.has(lessons[0]) and game.level_available(lessons[1]),"Fish completion unlocks tulip")
	game.advance(); await process_frame
	check(game.level==lessons[1] and guide.lesson==1,"Normal Next advances to tulip")
	await capture("tulpe")
	var focus: Vector2=game.board_clip.global_position+game.board_clip.size*0.5
	game.board_navigation.zoom_at(focus,focus,1.5); guide._process(0)
	check(guide.phase==1,"Tulip detects actual zoom")
	game.board_navigation.center+=Vector2(15,0); guide._process(0)
	check(guide.phase==2,"Tulip detects actual pan")
	game.set_language("en"); guide.update_copy()
	check(guide.title_label.text=="Explore the tulip at your own pace.","Guide translates live")
	game.set_language("de")
	solve(); game.advance(); await process_frame
	check(game.level==lessons[2] and guide.lesson==2,"Tulip advances to mushroom")
	await capture("pilz")
	var cleared: int=game.cleared
	game.show_hint(); guide._process(0)
	check(guide.phase==1 and game.cleared==cleared,"Mushroom explains real hint without solving")
	solve()
	check(JourneyProgress.world_complete(game,0) and JourneyProgress.world_open(game,1),"Three completions unlock original journey")
	game.open_journey(0,"first_light")
	check(game.journey.find_children("*","Button",true,false).any(func(b): return b.text=="Einführung erneut spielen"),"Replay is offered in the station")
	game.start_journey_puzzle(lessons[0],true); await process_frame
	check(guide.active and game.cleared==0,"Replay shows hints on a completed puzzle")
	solve(); game.advance(); await process_frame
	check(game.level==lessons[1] and guide.active,"Replay advances through completed lessons")
	var old_base:=JourneyProgress.indices(game,"base")
	var legacy_prefix:="user://test_first_light_legacy_"+str(Time.get_ticks_usec())+"_"
	var config:=ConfigFile.new()
	config.set_value("game","journey_version",3)
	config.set_value("game","journey_migrated",true)
	config.set_value("game","completed_paths",[game.level_path(old_base[0])])
	config.set_value("game","custom_level",game.level_path(old_base[1]))
	config.save(legacy_prefix+"progress.cfg")
	game.queue_free(); await process_frame
	game=create_game(legacy_prefix); await process_frame
	check(game.first_light_optional,"Existing saves get optional intro")
	check(game.completed.has(game.level_files.find(game.level_path(old_base[0]))),"Existing completed path is retained")
	check(JourneyProgress.world_open(game,1),"Existing players keep original first world accessible")
	check(JourneyProgress.group_done(game,"first_light")==0,"Migration does not falsely solve lessons")
	game.save_progress()
	var migrated:=ConfigFile.new(); migrated.load(legacy_prefix+"progress.cfg")
	check(migrated.get_value("game","journey_version",0)==4,"Migration is persisted")
	game.queue_free(); await process_frame
	var resume_prefix:="user://test_first_light_resume_"+str(Time.get_ticks_usec())+"_"
	var resumed=load("res://main.tscn").instantiate()
	resumed.storage_prefix=resume_prefix
	resumed.journey_mode=true; resumed.scan_user_exports=true; resumed.resume_enabled=true
	root.add_child(resumed); await process_frame
	var fish:=JourneyProgress.indices(resumed,"first_light")[0]
	resumed.start_journey_puzzle(fish)
	var chosen: int=resumed.free_paths()[0]
	resumed.click_at(resumed.arrows[chosen].points[0]); resumed._process(3.0)
	resumed.open_current_journey(); resumed.session_store.flush()
	resumed.queue_free(); await process_frame
	resumed=load("res://main.tscn").instantiate()
	resumed.storage_prefix=resume_prefix
	resumed.journey_mode=true; resumed.scan_user_exports=true; resumed.resume_enabled=true
	root.add_child(resumed); await process_frame
	check(resumed.level==JourneyProgress.indices(resumed,"first_light")[0] and resumed.cleared==1,"Interrupted introduction resumes real arrow state")
	check(not resumed.first_light_optional,"Saving a new introduction does not turn it into legacy progress")
	resumed.queue_free(); await process_frame
	print("FIRST LIGHT INTEGRATION: ",failures," failures")
	quit(1 if failures else 0)
