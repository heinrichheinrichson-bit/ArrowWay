extends SceneTree

var failures := 0
var scene: Node2D

func require(condition: bool, message: String) -> void:
	if not condition: failures+=1; push_error(message)

func _initialize() -> void: call_deferred("run")

func tap(point: Vector2) -> void:
	# Newly rebuilt controls need a layout frame before the first touch.
	await process_frame
	for down in [true,false]:
		var event:=InputEventScreenTouch.new()
		event.position=root.get_final_transform()*point; event.pressed=down
		Input.parse_input_event(event)
		await process_frame

func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"): return
	var view=scene.journey if is_instance_valid(scene.journey) else scene.home_menu
	if is_instance_valid(view.canvas):
		view.canvas.age=3.2
		for item in view.canvas.get_children():
			if item.get("age")!=null: item.age=3.2; item.modulate.a=1
	await process_frame; await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/player-"+name+".png")

func station(id: String) -> Button:
	for child in scene.journey.canvas.get_children():
		if child.get_meta("station_id","")==id: return child
	return null

func run() -> void:
	for file in ["progress.cfg","library.cfg","settings.cfg"]: DirAccess.remove_absolute("user://test_player_ui_"+file)
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_player_ui_"; scene.journey_mode=true; scene.scan_user_exports=true
	root.add_child(scene); await process_frame
	scene.open_home(); await process_frame
	var actions: Array[String]=[]
	for item in scene.home_menu.get_children():
		if item is Button and not item.text.is_empty(): actions.append(item.text)
	require(actions==["Weiter spielen","Deine Reise","Meine Kunstwerke"],"Home exposes only play, journey and solved artwork album")
	require(scene.home_menu.canvas.get_child(0).index==0,"Home previews the actual next available motif")
	await capture("home")
	scene.open_gallery(); await process_frame
	require(scene.journey.screen=="album" and not is_instance_valid(scene.gallery),"Old catalog entry point routes to the safe album")
	require(JourneyProgress.album_indices(scene).is_empty(),"Fresh album contains no puzzle previews")
	await capture("album-empty")
	var custom:=JourneyProgress.indices(scene,"custom")
	for index in custom:
		scene.completed.append(index)
		require(not scene.level_available(index),"Internal editor draft cannot be played through a player route")
	scene.completed.append(0); scene.completed.append(1)
	scene.favorite_paths.append(scene.level_path(2))
	scene.open_album(); await process_frame
	require(scene.journey.canvas.get_child_count()==2,"Album excludes unfinished puzzles and completed internal drafts")
	require(JourneyProgress.album_indices(scene,true).is_empty(),"Old favorite records cannot reveal unsolved pictures")
	var favorites_before: Array[String]=scene.favorite_paths.duplicate()
	scene.toggle_favorite(2)
	require(scene.favorite_paths==favorites_before,"Unsolved images cannot be marked as favorites")
	await capture("album")
	var first:Button=scene.journey.canvas.get_child(0)
	await tap(first.global_position+first.size*0.5)
	require(scene.journey.screen=="artwork" and scene.journey.selected_art==0,"Album card opens a large artwork, not a game")
	require(not scene.arrows.any(func(a): return a.escaping),"Viewing artwork does not launch puzzle arrows")
	await tap(Vector2(48,scene.get_viewport_rect().size.y-50))
	require(scene.favorite_paths.has(scene.level_path(0)),"Heart on the large artwork saves a favorite")
	var saved:=ConfigFile.new(); saved.load(scene.storage_prefix+"library.cfg")
	require(saved.get_value("library","favorites",[]).has(scene.level_path(0)),"Heart preference persists to disk")
	await capture("artwork")
	scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	require(scene.journey.screen=="album","Android back gesture returns the artwork to its album")
	scene.journey.favorites_only=true; scene.journey.relayout()
	require(scene.journey.canvas.get_child_count()==1 and scene.journey.canvas.get_child(0).index==0,"Favorite album contains only solved heart-marked art")
	await capture("favorites")
	scene.journey.open_artwork(2)
	require(scene.journey.screen=="album","Direct unsolved artwork requests reveal nothing")
	# Solving the final intro puzzle records exactly one real milestone.
	scene.close_journey(); scene.completed.clear()
	for index in range(8): scene.completed.append(index)
	scene.level=8; scene.reset()
	for arrow in ArrowPuzzle.solution(scene.arrows):
		scene.click_at(scene.arrows[arrow].points[0]); scene._process(2.0)
	require(scene.journey_reward.get("group","")=="base" and scene.journey_reward.get("next",-1)==1,"A full theme awards a group celebration and new-world light route")
	scene.open_album(); scene.journey.open_artwork(8)
	await tap(Vector2(scene.get_viewport_rect().size.x*0.6,scene.get_viewport_rect().size.y-50))
	require(not is_instance_valid(scene.journey) and scene.win_time<0 and scene.cleared==0,"Replay resets the already completed current puzzle")
	scene.open_journey(1); await process_frame
	require(station("world:nature").major and not station("group:animals").major,"Themes and subcategories have distinct visual shapes")
	var colors: Array[Color]=[]
	for group in JourneyProgress.worlds()[1].groups:
		var color:Color=station("group:"+group).tint
		require(not colors.has(color),"Nature branches each have their own color")
		colors.append(color)
	require(scene.journey.reward.get("group","")=="base" and scene.journey.canvas.routes.any(func(route): return route.get("reward",false)),"Map consumes the milestone and animates its connecting path")
	var camera_start: int=scene.journey.scroller.scroll_vertical
	await create_timer(2.65).timeout
	require(scene.journey.scroller.scroll_vertical<camera_start-100,"Milestone camera travels from the completed theme toward the newly unlocked theme")
	scene.journey.focus_world(1); await process_frame
	await capture("color-map")
	# All published completions are browsable in bounded album pages.
	for index in scene.level_count():
		if JourneyProgress.world_index(scene.level_collection(index).id)>=0 and not scene.completed.has(index): scene.completed.append(index)
	scene.open_album(); await process_frame
	require(scene.journey.canvas.get_child_count()==6,"Large solved albums render only six previews per page")
	scene.journey.page=84; scene.journey.relayout()
	for child in scene.journey.canvas.get_children():
		require(scene.completed.has(child.index) and scene.level_collection(child.index).id!="custom","Last album page contains only published solved images")
	root.size=Vector2i(540,1170); await process_frame
	scene.open_home(); await capture("home-tall")
	require(scene.home_menu.canvas.get_child(0).index==JourneyProgress.album_indices(scene).back(),"Home celebrates the latest completed public artwork")
	var featured: Button=scene.home_menu.canvas.get_child(0)
	var featured_index: int=featured.index
	await tap(featured.global_position+featured.size*0.5)
	require(is_instance_valid(scene.journey) and scene.journey.screen=="artwork" and scene.journey.selected_art==featured_index,"Home artwork opens its solved album picture")
	scene.close_journey(); scene.open_home()
	scene.home_menu.navigate("settings")
	scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	require(scene.home_menu.screen=="home","Android back returns settings to the home screen")
	require(scene.home_menu.size==scene.get_viewport_rect().size,"New menu fits a tall portrait screen")
	for file in ["progress.cfg","library.cfg","settings.cfg"]: DirAccess.remove_absolute(scene.storage_prefix+file)
	print("PASS player UI: private solved album, hearts, internal drafts, real touch, replay, colored mindmap and milestone rewards" if failures==0 else "%d FAILURES" % failures)
	quit(0 if failures==0 else 1)
