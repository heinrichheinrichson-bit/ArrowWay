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

func station_named(id: String) -> Button:
	for node in scene.journey.canvas.get_children():
		if node.get_meta("station_id", "") == id: return node
	return null

func run() -> void:
	for name in ["progress.cfg","settings.cfg","library.cfg"]: DirAccess.remove_absolute("user://test_journey_"+name)
	scene = load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_journey_"; scene.journey_mode=true; scene.scan_user_exports=true
	root.add_child(scene)
	await process_frame
	var mapped: Array[String] = []
	for world in JourneyProgress.worlds():
		for group in world.groups:
			require(not mapped.has(group),"A collection belongs to exactly one theme")
			mapped.append(group)
	require(mapped.size()==43,"All 42 collections plus introduction have a theme")
	for index in scene.level_count():
		var group: String = scene.level_collection(index).id
		require(group=="custom" or mapped.has(group),"Every catalog entry has a map category")
	require(JourneyProgress.frontier(scene)==0,"Fresh journey starts at the first light")
	for index in range(9): require(scene.level_available(index),"All introduction puzzles are immediately in the collection")
	var garden := JourneyProgress.indices(scene,"animals")
	require(not scene.level_available(garden[0]),"Future-world puzzles cannot be selected")
	scene.open_home(); await capture("home"); scene.close_home()
	scene.open_journey(); await process_frame
	require(scene.journey.canvas.get_child_count()==15,"Fourteen major themes plus reached subcategory share a single canvas")
	require(scene.journey.visible_station_ids==["world:beginning","group:base"],"Future themes have no subcategory nodes")
	await capture("map-new")
	await swipe_map(); await swipe_map(true)
	station_named("world:beginning").pressed.emit()
	require(scene.journey.screen=="map","Clicking a major theme stays on the mindmap")
	await process_frame
	var first := station_named("group:base")
	await tap(first.global_position+Vector2(first.size.x*0.5,64))
	require(scene.journey.screen=="collection" and scene.journey.group=="base","Subcategory opens its puzzles directly")
	require(scene.journey.canvas.get_child_count()==9,"All nine introduction cards appear without a history expander")
	await capture("motifs")
	for index in range(3): solve(index)
	require(JourneyProgress.frontier(scene)==0 and not JourneyProgress.world_complete(scene,0),"Three introductory completions do not unlock Nature or award a theme checkmark")
	for index in range(3,8): solve(index)
	require(JourneyProgress.frontier(scene)==0,"One missing introduction puzzle keeps Nature locked")
	solve(8); scene.advance()
	require(scene.journey.screen=="map" and JourneyProgress.frontier(scene)==1,"All nine completions open Nature on the SAME map")
	require(station_named("world:beginning").achieved and not station_named("world:nature").achieved,"Only fully completed themes get checkmarks")
	require(scene.journey.canvas.get_child_count()==18,"Tierwelt's three child nodes join the original map")
	require(JourneyProgress.group_visible(scene,"animals") and JourneyProgress.group_visible(scene,"birds") and not JourneyProgress.group_visible(scene,"flowers"),"Only reached themes display their subcategory branches")
	for group in ["animals","birds","ocean"]:
		require(station_named("group:"+group)!=null,"Each Nature collection is connected on the same canvas")
	await capture("map-progress")
	scene.open_journey(1); await process_frame
	await capture("nature-new")
	station_named("group:animals").pressed.emit()
	require(scene.journey.canvas.get_child_count()==garden.size(),"Collection displays solved and unsolved cards together")
	await capture("nature-motifs")
	var card:Button=scene.journey.canvas.get_child(0)
	await tap(card.global_position+card.size*0.5)
	require(not is_instance_valid(scene.journey) and scene.level==garden[0],"Real motif card starts its own puzzle")
	require(not scene.arrows.any(func(arrow): return arrow.escaping),"Card tap never shoots an arrow behind the interface")
	var live:int=ArrowPuzzle.solution(scene.arrows)[0]
	scene.click_at(scene.arrows[live].points[0]); scene.open_current_journey()
	require(scene.journey.group=="animals","Play back-button returns to its subcategory")
	scene.start_journey_puzzle(garden[0])
	require(scene.arrows[live].escaping,"Returning preserves the current move")
	scene.reset(); solve(garden[0])
	scene.open_current_journey()
	require(scene.journey.canvas.get_child_count()==garden.size() and scene.journey.canvas.get_child(0).complete,"Solved card stays in its original place with a checkmark")
	scene.journey.go_back(); await process_frame
	require(scene.journey.screen=="map" and station_named("group:animals")!=null,"Collection back returns to the shared mindmap, never a separate theme screen")
	await capture("nature-branches")
	for index in garden:
		if not scene.completed.has(index): scene.completed.append(index)
	scene.open_journey(1)
	require(station_named("group:animals").achieved and not station_named("world:nature").achieved,"Completed subcategory never prematurely checks its parent theme")
	require(JourneyProgress.frontier(scene)==1,"Completing one Nature category keeps next theme locked")
	await capture("nature-expanded")
	var last := -1
	for group in JourneyProgress.worlds()[1].groups:
		for index in JourneyProgress.indices(scene,group):
			if not scene.completed.has(index): scene.completed.append(index)
			last=index
	scene.completed.erase(last)
	require(JourneyProgress.frontier(scene)==1 and not JourneyProgress.world_complete(scene,1),"One missing puzzle across ALL subcategories keeps next theme locked")
	scene.completed.append(last)
	require(JourneyProgress.frontier(scene)==2 and JourneyProgress.world_complete(scene,1),"Next major theme unlocks only after every Nature puzzle")
	# Old distant achievements remain replayable but do not bypass strict ordering.
	var distant := JourneyProgress.indices(scene,"fantasy")[10]
	scene.completed.append(distant)
	require(scene.level_available(distant) and JourneyProgress.frontier(scene)==2 and not JourneyProgress.group_visible(scene,"fantasy"),"Old distant completion does not unlock unfinished ancestors")
	scene.open_journey(2); root.size=Vector2i(540,1170); await process_frame
	require(scene.journey.size==scene.get_viewport_rect().size,"Shared map adapts to a tall phone display")
	await capture("map-tall")
	scene.save_progress()
	var expected: Array[int]=scene.completed.duplicate()
	scene.close_journey(); scene.queue_free(); await process_frame
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_journey_"; scene.journey_mode=true; scene.scan_user_exports=true
	root.add_child(scene); await process_frame
	require(scene.completed==expected and JourneyProgress.frontier(scene)==2,"Strict progression and old achievements survive restart")
	# Migrate an old unfinished puzzle without awarding themes or bypassing gates.
	var legacy_path:String=scene.level_path(JourneyProgress.indices(scene,"technology")[7])
	var legacy:=ConfigFile.new()
	legacy.set_value("game","completed",[0,1]); legacy.set_value("game","custom_level",legacy_path); legacy.set_value("game","unlocked",2)
	legacy.save(scene.storage_prefix+"progress.cfg")
	scene.queue_free(); await process_frame
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_journey_"; scene.journey_mode=true; scene.scan_user_exports=true
	root.add_child(scene); await process_frame
	require(scene.journey_legacy_paths.has(legacy_path) and not scene.level_available(scene.level_files.find(legacy_path)),"Migration retains the legacy record without exposing an unfinished future puzzle")
	require(JourneyProgress.frontier(scene)==0 and not JourneyProgress.group_visible(scene,"technology"),"Migration never bypasses theme completion")
	scene.completed.clear(); scene.journey_legacy_paths.clear()
	var additions:=0
	for step in scene.level_count():
		var candidate:=-1
		for index in scene.level_count():
			if not scene.completed.has(index) and scene.level_available(index): candidate=index; break
		if candidate<0: break
		scene.completed.append(candidate); additions+=1
	require(additions==scene.level_count()-JourneyProgress.indices(scene,"custom").size(),"All published catalog puzzles remain reachable; internal editor drafts are excluded")
	scene.open_journey()
	for wi in JourneyProgress.worlds().size():
		require(station_named("world:"+JourneyProgress.worlds()[wi].id).achieved,"Each fully solved major theme receives its checkmark")
	scene.open_home()
	var clock:float=scene.clock_time; scene._process(1)
	require(scene.clock_time==clock,"Home pauses gameplay")
	for name in ["progress.cfg","settings.cfg","library.cfg"]: DirAccess.remove_absolute(scene.storage_prefix+name)
	print("PASS journey: single mindmap, all collection cards, strict completion gates, accurate checkmarks, touch, persistence and entire catalog" if failures==0 else "%d FAILURES" % failures)
	quit(0 if failures==0 else 1)
