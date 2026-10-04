extends SceneTree

var failures := 0
var scene: Node2D

func require(condition: bool, message: String) -> void:
	if not condition: failures += 1; push_error(message)

func _initialize() -> void: call_deferred("run")

func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	var view = scene.journey if is_instance_valid(scene.journey) else scene.home_menu
	if is_instance_valid(view) and is_instance_valid(view.canvas):
		view.canvas.age = 2.0
		for node in view.canvas.get_children():
			if node.get("age") != null: node.age = 2.0; node.modulate.a = 1.0
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/journey-"+name+".png")

func solve(index: int) -> void:
	scene.start_journey_puzzle(index)
	for arrow in ArrowPuzzle.solution(scene.arrows):
		scene.click_at(scene.arrows[arrow].points[0])
		scene._process(2.0)
	require(scene.completed.has(index),"Journey puzzle completes through actual gameplay")
	scene._process(2.0)

func tap(position: Vector2) -> void:
	for down in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.pressed=down
		event.position=root.get_final_transform()*position
		Input.parse_input_event(event)
		await process_frame

func swipe_map(over_station := false) -> void:
	var view=scene.journey
	var old:int=view.scroller.scroll_vertical
	var start:=Vector2(35,280)
	if over_station:
		var station:Button=view.canvas.get_child(0)
		start=station.global_position+Vector2(station.size.x*0.5,64)
	var touch:=InputEventScreenTouch.new()
	touch.pressed=true; touch.position=root.get_final_transform()*start
	Input.parse_input_event(touch)
	await process_frame
	var previous:=start
	for position in [start+Vector2(0,50),start+Vector2(0,100),start+Vector2(0,150)]:
		var drag:=InputEventScreenDrag.new()
		drag.position=root.get_final_transform()*position
		drag.relative=root.get_final_transform().basis_xform(position-previous)
		drag.screen_relative=drag.relative
		Input.parse_input_event(drag)
		previous=position
		await process_frame
	touch=touch.duplicate(); touch.pressed=false; touch.position=root.get_final_transform()*previous
	Input.parse_input_event(touch)
	await process_frame
	require(view.scroller.scroll_vertical<old,"Native finger drag scrolls the journey without opening a station")
	require(scene.journey==view and view.screen=="map","Swiping over a station cancels its tap")
	view.request_scroll(old)
	await process_frame

func run() -> void:
	for name in ["progress.cfg","settings.cfg","library.cfg"]: DirAccess.remove_absolute("user://test_journey_"+name)
	scene = load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_journey_"
	scene.journey_mode=true
	scene.scan_user_exports=true
	root.add_child(scene)
	await process_frame
	var mapped: Array[String] = []
	for world in JourneyProgress.worlds():
		for group in world.groups:
			require(not mapped.has(group),"A collection belongs to exactly one theme")
			mapped.append(group)
	require(mapped.size()==30,"All 29 collections plus the introduction have a theme")
	for index in scene.level_count():
		var group: String = scene.level_collection(index).id
		require(group=="custom" or mapped.has(group),"Every catalog entry is represented in the journey")
	require(JourneyProgress.frontier(scene)==0,"Fresh journey starts at the first light")
	require(scene.level_available(0) and scene.level_available(1) and scene.level_available(2) and not scene.level_available(3),"Three introductory puzzles are initially available")
	var garden := JourneyProgress.indices(scene,"garden")
	require(not scene.level_available(garden[0]),"Future-world puzzles cannot be selected")
	scene.open_home()
	await capture("home")
	scene.close_home()
	scene.open_journey()
	await process_frame
	require(scene.journey.canvas.get_child_count()==7,"Overview contains only the seven major stations")
	require(scene.journey.visible_station_ids==["world:beginning"],"Only reached stations reveal their content")
	await capture("map-new")
	await swipe_map()
	await swipe_map(true)
	scene.journey.canvas.get_child(1).pressed.emit()
	require(scene.journey.screen=="map","Locked station cannot reveal its branches")
	var first:Button=scene.journey.canvas.get_child(0)
	await tap(first.global_position+Vector2(first.size.x*0.5,64))
	require(scene.journey.screen=="collection" and scene.journey.group=="base","Station activation navigates to its own content")
	require(scene.journey.canvas.get_child_count()==3,"Only three playable art previews are created")
	await capture("motifs")
	for index in range(3): solve(index)
	require(JourneyProgress.frontier(scene)==1,"Three actual introductory completions open Nature")
	scene.advance()
	require(is_instance_valid(scene.journey) and scene.journey.screen=="map","An introductory milestone returns to the growing path")
	require(scene.journey.canvas.get_child(1).fresh,"New world receives its reveal animation")
	await capture("map-progress")
	scene.journey.canvas.get_child(1).pressed.emit()
	require(scene.journey.screen=="world" and scene.journey.world==1,"Reached world opens its own branches")
	require(scene.journey.canvas.get_child_count()==1 and not JourneyProgress.group_visible(scene,"animals"),"Unreached subcategories remain completely hidden")
	await capture("nature-new")
	scene.journey.canvas.get_child(0).pressed.emit()
	require(scene.journey.canvas.get_child_count()==3,"Reached collection offers three initial puzzles")
	await capture("nature-motifs")
	for index in garden.slice(0,3): solve(index)
	require(JourneyProgress.group_visible(scene,"animals") and JourneyProgress.group_visible(scene,"birds") and not JourneyProgress.group_visible(scene,"flowers"),"Completing a small station reveals two branches, not the whole tree")
	scene.advance()
	require(scene.journey.screen=="world" and scene.journey.canvas.get_child_count()==3,"Milestone reveals the actual new branch controls")
	await capture("nature-branches")
	var animals := JourneyProgress.indices(scene,"animals")
	scene.start_journey_puzzle(JourneyProgress.indices(scene,"flowers")[0])
	require(is_instance_valid(scene.journey),"Direct attempts cannot bypass hidden-branch gating")
	scene.journey.canvas.get_child(1).pressed.emit()
	require(scene.journey.group=="animals","Each branch callback retains its own destination")
	var card:Button=scene.journey.canvas.get_child(0)
	await tap(card.global_position+card.size*0.5)
	require(not is_instance_valid(scene.journey) and scene.level==animals[0],"Real motif card starts its matching puzzle")
	require(not scene.arrows.any(func(arrow): return arrow.escaping),"Selecting a card never shoots an arrow behind the interface")
	var live:int=ArrowPuzzle.solution(scene.arrows)[0]
	scene.click_at(scene.arrows[live].points[0])
	scene.open_current_journey()
	require(scene.journey.group=="animals","Play back-button returns to the current collection")
	require(scene.journey.canvas.get_child(0).index==animals[0],"Current unfinished artwork stays at the front")
	scene.start_journey_puzzle(animals[0])
	require(scene.arrows[live].escaping,"Returning from the journey preserves the current move")
	scene.reset()
	solve(animals[0]); solve(animals[1])
	require(JourneyProgress.frontier(scene)==2 and JourneyProgress.group_visible(scene,"flowers"),"Five discoveries open the next major station and remaining Nature branches")
	scene.open_journey(1)
	await capture("nature-expanded")
	scene.open_journey()
	root.size=Vector2i(540,1170)
	await process_frame
	require(scene.journey.size==scene.get_viewport_rect().size,"Journey adapts to a tall phone display")
	await capture("map-tall")
	var distant := JourneyProgress.indices(scene,"fantasy")[10]
	scene.completed.append(distant)
	require(scene.level_available(distant) and JourneyProgress.frontier(scene)==6 and JourneyProgress.group_visible(scene,"fantasy"),"Historical completions remain playable and reveal their ancestors")
	scene.save_progress()
	var expected: Array[int] = scene.completed.duplicate()
	scene.close_journey()
	scene.queue_free()
	await process_frame
	scene = load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_journey_"; scene.journey_mode=true; scene.scan_user_exports=true
	root.add_child(scene)
	await process_frame
	require(scene.completed==expected and JourneyProgress.frontier(scene)==6,"Journey progress survives restart using existing path-based saves")
	require(scene.journey_seen.has("group:animals"),"Station reveal history persists")
	# An unfinished puzzle from the old freely accessible catalog remains available.
	var legacy_path:String=scene.level_path(JourneyProgress.indices(scene,"technology")[7])
	var legacy:=ConfigFile.new()
	legacy.set_value("game","completed",[0,1])
	legacy.set_value("game","custom_level",legacy_path)
	legacy.set_value("game","unlocked",2)
	legacy.save(scene.storage_prefix+"progress.cfg")
	scene.queue_free()
	await process_frame
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_journey_"; scene.journey_mode=true; scene.scan_user_exports=true
	root.add_child(scene)
	await process_frame
	require(scene.level_path(scene.level)==legacy_path and scene.level_available(scene.level),"Migration preserves the unfinished legacy puzzle")
	require(JourneyProgress.group_visible(scene,"technology") and JourneyProgress.frontier(scene)>=3,"Migration reveals the ancestors of an unfinished legacy puzzle")
	var before: Array[int]=scene.completed.duplicate()
	var legacy_paths: Array[String]=scene.journey_legacy_paths.duplicate()
	scene.completed.clear(); scene.journey_legacy_paths.clear()
	var additions:=0
	for step in scene.level_count():
		var candidate:=-1
		for index in scene.level_count():
			if not scene.completed.has(index) and scene.level_available(index): candidate=index; break
		if candidate<0: break
		scene.completed.append(candidate); additions+=1
	require(additions==scene.level_count(),"Entire catalog is reachable without payment, advertisements or a progression dead end")
	scene.completed.assign(before); scene.journey_legacy_paths.assign(legacy_paths)
	scene.open_home()
	var clock: float = scene.clock_time
	scene._process(1)
	require(scene.clock_time==clock,"New home screen pauses play")
	scene.close_home()
	for name in ["progress.cfg","settings.cfg","library.cfg"]: DirAccess.remove_absolute(scene.storage_prefix+name)
	print("PASS journey: all motifs mapped, gates, hidden branches, real play, cards, milestones, migration, responsive map and persistence" if failures==0 else "%d FAILURES" % failures)
	quit(0 if failures==0 else 1)
