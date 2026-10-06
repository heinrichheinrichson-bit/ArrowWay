extends SceneTree

const PREFIX := "user://test_taxonomy_"
var failures := 0
var scene: Node2D
func require(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func cleanup() -> void:
	for suffix in ["progress.cfg","sessions.json","sessions.json.bak","sessions.json.tmp","ads.json","ads.json.bak","ads.json.tmp","library.cfg","settings.cfg"]: DirAccess.remove_absolute(PREFIX+suffix)
func launch() -> void:
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix=PREFIX; scene.journey_mode=true; scene.resume_enabled=true; scene.scan_user_exports=true
	root.add_child(scene); scene.set_process(false); scene.ads.set_process(false)
	await process_frame
func close() -> void:
	scene.queue_free(); await process_frame
func run() -> void:
	cleanup()
	var taxonomy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/taxonomy.json"))
	var categories := {}; var paths := {}; var empty := 0
	for world in taxonomy.worlds:
		for category in world.categories:
			require(not categories.has(category.id),"Category IDs are unique")
			categories[category.id]=category
			if category.existing_count==0:
				empty+=1; require(category.playable_groups.is_empty(),"Empty categories have no playable node")
	for item in taxonomy.assignments:
		require(not paths.has(item.path) and FileAccess.file_exists(item.path),"Every existing motif has one valid assignment")
		paths[item.path]=item
		require(categories.has(item.category_id) and JourneyProgress.world_index(item.group)>=0,"Every motif has a canonical category and published group")
	require(paths.size()==823 and categories.size()==123 and empty==0,"Complete taxonomy includes 823 motifs and all 123 populated categories")
	await launch()
	for index in scene.level_count():
		var path: String=scene.level_path(index)
		if paths.has(path): require(scene.level_collection(index).id==paths[path].group,"Live catalog matches canonical assignment")
	var ad_keys := {}
	for world in JourneyProgress.worlds():
		require(not ad_keys.has(world.ad_id),"Ad protection uses unique stable keys")
		ad_keys[world.ad_id]=true
		for group in world.groups: require(not JourneyProgress.indices(scene,group).is_empty(),"Every public collection contains motifs")
	require(scene.ads.world_key(4)==2 and scene.ads.world_key(8)==3 and scene.ads.world_key(JourneyProgress.world_index("world"))==4,"Original ad keys survive world reordering")
	await close()
	# Simulate a real old journey: intro solved, Nature reached, one animal solved.
	var config := ConfigFile.new()
	config.set_value("game","journey_migrated",true)
	config.set_value("game","journey_seen",["world:beginning","world:nature","group:animals"])
	config.set_value("game","completed",range(9))
	var old_animal := "res://collections/levels/animals_01_animals_01.json"
	var available_path := ""
	for item in taxonomy.assignments:
		if item.old_collection=="animals": old_animal=item.path; break
	for item in taxonomy.assignments:
		if item.old_collection=="garden" and item.world=="nature": available_path=item.path; break
	config.set_value("game","completed_custom",[old_animal])
	config.set_value("game","custom_level",available_path)
	config.save(PREFIX+"progress.cfg")
	await launch()
	require(scene.completed.has(scene.level_files.find(old_animal)),"Old completed motif remains completed after migration")
	for item in taxonomy.assignments:
		if item.old_collection in ["base","garden","animals","birds","flowers","ocean","landscapes"]:
			require(scene.level_available(scene.level_files.find(item.path)),"Every previously reached motif stays playable")
	require(JourneyProgress.group_visible(scene,"flowers") and not JourneyProgress.group_visible(scene,"workshop"),"Moved old categories retain access without unlocking unrelated future worlds")
	require(JourneyProgress.group_visible(scene,"toys") and not JourneyProgress.group_visible(scene,"sports"),"One redistributed category does not reveal sibling categories")
	require(not JourneyProgress.world_complete(scene,1) and not JourneyProgress.world_complete(scene,12),"Migration does not award false theme checkmarks")
	scene.open_journey(JourneyProgress.world_index("toys"))
	require(scene.journey.visible_station_ids.has("group:toys") and not scene.journey.visible_station_ids.has("group:sports"),"Mindmap only creates earned branches in partially migrated worlds")
	scene.close_journey()
	# Resume an arrow animation and zoom in a redistributed motif.
	scene.start_journey_puzzle(scene.level_files.find(available_path)); scene.set_process(false)
	var first: int=scene.free_paths()[0]
	scene.click_at(scene.arrows[first].points[-1]); scene._process(0.03)
	scene.board_navigation.zoom=2.1; scene.board_navigation.apply_view()
	scene.queue_session(); scene.session_store.flush(); scene.save_progress()
	var grants: Array[String]=scene.journey_access_groups.duplicate()
	await close(); await launch()
	require(scene.journey_access_groups==grants,"Migration grants persist with stable collection IDs")
	scene.start_journey_puzzle(scene.level_files.find(available_path)); scene.set_process(false)
	require(scene.arrows[first].escaping and is_equal_approx(scene.board_navigation.zoom,2.1),"Redistributed motif preserves arrow animation and camera checkpoint")
	await close(); cleanup()
	# Partial intro must never be mistaken for a previously reached Nature world.
	config=ConfigFile.new(); config.set_value("game","journey_migrated",true); config.set_value("game","completed",[0,1,2]); config.save(PREFIX+"progress.cfg")
	await launch()
	require(not JourneyProgress.group_visible(scene,"animals") and JourneyProgress.frontier(scene)==0,"Old partial introduction retains strict gates")
	await close(); cleanup()
	print("PASS taxonomy: complete assignments, prepared categories, stable ad keys, old access migration, accurate checkmarks, hidden siblings and resumed arrow/camera" if failures==0 else "%d FAILURES" % failures)
	quit(1 if failures else 0)
