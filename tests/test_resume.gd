extends SceneTree

var scene: Node2D
var failures := 0
const PREFIX = "user://test_resume_"

func require(value: bool, message: String) -> void:
	if not value: failures+=1; push_error(message)

func _initialize() -> void: call_deferred("run")

func launch() -> void:
	scene=load("res://main.tscn").instantiate()
	scene.storage_prefix=PREFIX; scene.resume_enabled=true; scene.journey_mode=true; scene.scan_user_exports=true
	scene.set_process(false)
	root.add_child(scene)
	scene.set_process(false)
	await process_frame
	scene.start_journey_puzzle(scene.level)
	scene.set_process(false)

func close() -> void:
	scene.queue_session(); scene.session_store.flush()
	scene.queue_free(); await process_frame

func run() -> void:
	for suffix in ["progress.cfg","sessions.json","sessions.json.bak","sessions.json.tmp","library.cfg","settings.cfg"]:
		DirAccess.remove_absolute(PREFIX+suffix)
	await launch()
	var first: int=scene.free_paths()[0]
	scene.click_at(scene.arrows[first].points[-1])
	scene._process(0.03)
	require(scene.arrows[first].escaping,"A real tap starts the escape")
	scene.board_navigation.zoom=2.5
	scene.board_navigation.center+=Vector2(18,24)
	scene.board_navigation.apply_view()
	var center: Vector2=scene.board_navigation.center
	await close(); await launch()
	require(scene.arrows[first].escaping and not scene.arrows[first].removed,"An interrupted animation resumes")
	require(is_equal_approx(scene.board_navigation.zoom,2.5) and scene.board_navigation.center.distance_to(center)<0.01,"Zoom and position survive restart")
	scene._process(3)
	require(scene.cleared==1,"Resumed animation counts exactly once")
	scene.mistakes=3
	scene.start_journey_puzzle(1); scene.set_process(false)
	var second: int=scene.free_paths()[0]
	scene.click_at(scene.arrows[second].points[-1]); scene._process(3)
	scene.start_journey_puzzle(0); scene.set_process(false)
	require(scene.cleared==1 and scene.mistakes==3,"Switching motifs preserves each unfinished puzzle")
	await close(); await launch()
	require(scene.cleared==1 and scene.mistakes==3,"Removed arrows and mistakes survive app restart")
	scene.queue_session(); scene.session_store.flush()
	await close()
	var file:=FileAccess.open(PREFIX+"sessions.json",FileAccess.WRITE)
	file.store_string("broken interrupted write"); file.close()
	await launch()
	require(scene.cleared==1,"A damaged primary file falls back to the previous checkpoint")
	scene.session_store.states[scene.level_path(0)].fingerprint="different motif"
	scene.reset(true); scene.set_process(false)
	require(scene.cleared==0,"Changed motif geometry cannot receive stale arrow state")
	var guard:=0
	while scene.cleared<scene.arrows.size() and guard<500:
		var available: Array[int]=scene.free_paths()
		require(not available.is_empty(),"Puzzle remains solvable after restore")
		if available.is_empty(): break
		scene.click_at(scene.arrows[available[0]].points[-1]); scene._process(3)
		guard+=1
	require(scene.completed.has(0),"Completion is saved normally")
	await close()
	DirAccess.remove_absolute(PREFIX+"progress.cfg")
	await launch()
	require(scene.completed.has(0),"Checkpoint recovers completed progress if the legacy progress file is missing")
	scene.reset(); scene.set_process(false)
	require(scene.cleared==0,"Explicit restart starts a fresh puzzle")
	await close()
	for suffix in ["progress.cfg","sessions.json","sessions.json.bak","sessions.json.tmp","library.cfg","settings.cfg"]:
		DirAccess.remove_absolute(PREFIX+suffix)
	if failures==0: print("PASS resume: animations, camera, multiple puzzles, recovery, geometry validation, completion and restart")
	quit(1 if failures else 0)
