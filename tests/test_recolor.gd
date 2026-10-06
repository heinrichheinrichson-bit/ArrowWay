extends SceneTree
var failures := 0
func require(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	var checked := 0
	var specimen := ""
	for entry in catalog.levels:
		if not entry.path.get_file().begins_with("expanded_"): continue
		var document: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(entry.path))
		var motif := CustomMotif.decode(document.motif)
		var arrows := CustomMotif.decode_paths(document.paths,motif)
		require(arrows.size()==document.paths.size(),"Colored paths keep complete valid coverage: "+entry.title)
		require(motif.palettes.size()>=2,"New motifs have separate editable color areas: "+entry.title)
		require(CustomMotif.isolated(motif).is_empty(),"Color regions contain no isolated editor cells")
		for arrow in arrows:
			require(arrow.has("color_style") and not MotifColors.valid_style(arrow.color_style).is_empty(),"Colors retain valid spatial gradients")
		checked+=1
		if document.color_design.recipe=="new_flower_pot": specimen=entry.path
	require(checked==314 and not specimen.is_empty(),"All 314 additions were colored")
	var game=load("res://main.tscn").instantiate()
	game.storage_prefix="user://test_recolor_"; game.journey_mode=true; game.resume_enabled=true; game.scan_user_exports=true
	root.add_child(game); game.set_process(false)
	var index: int=game.level_files.find(specimen)
	game.journey_access_groups.append(game.level_collection(index).id)
	game.start_journey_puzzle(index); game.set_process(false)
	var first: int=game.free_paths()[0]
	game.click_at(game.arrows[first].points[-1]); game._process(3)
	game.board_navigation.zoom=2.2; game.board_navigation.apply_view()
	game.queue_session(); game.session_store.capture()
	var document: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(specimen))
	game.session_store.states[specimen].fingerprint=document.compatible_color_checkpoints[0].fingerprint
	game.reset(true)
	require(game.arrows[first].removed and game.cleared==1 and is_equal_approx(game.board_navigation.zoom,2.2),"Previous monochrome checkpoint keeps removed arrows and zoom after coloring")
	game.session_store.states[specimen].fingerprint="unrelated file"
	game.reset(true)
	require(game.cleared==0,"Unrelated file fingerprints remain rejected")
	var predecessor: String=document.compatible_color_checkpoints[0].fingerprint
	game.session_store.states[specimen].fingerprint=predecessor
	game.arrows[0].points[0]+=Vector2(14,0)
	game.session_store.configure()
	require(not game.session_store.restore(),"Changed geometry cannot use the color-only compatibility grant")
	game.queue_free(); await process_frame
	for suffix in ["progress.cfg","sessions.json","sessions.json.bak","sessions.json.tmp","library.cfg","settings.cfg"]: DirAccess.remove_absolute("user://test_recolor_"+suffix)
	print("PASS recolor: 314 editable palettes, full coverage, gradients and safe monochrome checkpoint migration" if failures==0 else "%d FAILURES" % failures)
	quit(1 if failures else 0)
