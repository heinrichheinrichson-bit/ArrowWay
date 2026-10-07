extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func put(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE); file.store_string(text); file.close()
func run() -> void:
	var store: RefCounted = load("res://catalog_workshop_store.gd").new()
	store.root = "user://workshop_management_" + str(Time.get_ticks_usec()) + "/"
	for name in store.FILES.slice(0, 4): put(store.root + name, FileAccess.get_file_as_string("res://" + name))
	var state: Dictionary = store.load_state()
	var original_order: Array = state.catalog.levels.map(func(item): return item.path)
	var path: String = str(original_order[0]).trim_prefix("res://")
	put(store.root + path, FileAccess.get_file_as_string("res://" + path))
	var original: Dictionary = store.read(path)
	var target := {"world": "animals", "world_title": "Tierwelt", "category": "Insekten", "category_id": "animals_03", "group": "insects"}
	check(store.change(path, "move", target, store.fingerprints()), "Move succeeds")
	state = store.load_state()
	check(state.catalog.levels[0].collection.id == "insects" and store.read(path).paths == original.paths, "Move retains puzzle identity and exact arrows")
	check(state.taxonomy.assignments.filter(func(item): return item.path == "res://" + path)[0].category_id == "animals_03", "Move updates canonical category")
	var total: int = state.taxonomy.assignments.size()
	var moved: Dictionary = store.read(path)
	check(not moved.get("compatible_color_checkpoints", []).is_empty(), "Moving preserves unfinished play session compatibility")
	check(store.change(path, "delete", {}, store.fingerprints()), "Delete succeeds")
	state = store.load_state()
	check(not FileAccess.file_exists(store.root + path) and state.taxonomy.assignments.size() == total - 1 and state.manifest.total == total - 1, "Deletion updates document, taxonomy and totals")
	check(state.trash.entries[path].document == moved and not state.discoveries.entries.has("res://" + path), "Trash retains editable document and removes public completion text")
	check(store.change(path, "restore", {}, store.fingerprints()), "Restore succeeds")
	state = store.load_state()
	check(store.read(path).paths == moved.paths and store.read(path).collection == moved.collection and state.catalog.levels.map(func(item): return item.path) == original_order and state.manifest.total == total, "Restore retains original catalog position and geometry")
	var discovery := {"kind": "Ein kleiner Gedanke", "text": "Ein neuer Weg beginnt mit einem freien Ende."}
	var published: String = store.publish(original.duplicate(true), discovery, target, store.fingerprints())
	check(not published.is_empty() and store.read(published).paths == original.paths, "New copy receives a distinct editable catalog identity")
	state = store.load_state()
	check(state.manifest.total == total + 1 and state.catalog.levels[-1].path == "res://" + published, "Publish updates counts and appends without shifting existing puzzles")
	var second_path: String = str(original_order[2]).trim_prefix("res://")
	put(store.root + second_path, FileAccess.get_file_as_string("res://" + second_path))
	var order_before_multiple: Array = state.catalog.levels.map(func(item): return item.path)
	check(store.change(path, "delete", {}, store.fingerprints()) and store.change(second_path, "delete", {}, store.fingerprints()), "Multiple motifs can be safely trashed")
	check(store.change(path, "restore", {}, store.fingerprints()) and store.change(second_path, "restore", {}, store.fingerprints()), "Multiple motifs can be restored independently")
	check(store.load_state().catalog.levels.map(func(item): return item.path) == order_before_multiple, "Restoring multiple deletions preserves their original relative positions")
	var before: String = FileAccess.get_file_as_string(store.root + path)
	var journal := {"originals": {path: before, "collections/accidental.json": null}}
	put(store.root + "work/catalog-transaction.json", JSON.stringify(journal))
	put(store.root + path, "partial write"); put(store.root + "collections/accidental.json", "partial write")
	check(store.recover() and FileAccess.get_file_as_string(store.root + path) == before and not FileAccess.file_exists(store.root + "collections/accidental.json"), "Interrupted transaction restores existing and removes newly created files")
	var stale: Dictionary = store.fingerprints()
	put(store.root + "collections/catalog.json", FileAccess.get_file_as_string(store.root + "collections/catalog.json") + "\n")
	check(not store.change(path, "delete", {}, stale) and FileAccess.file_exists(store.root + path), "Stale browser cannot delete after concurrent edits")
	# Base puzzles are managed too; restored introduction keeps its original order.
	var intro := "levels/01.json"; put(store.root + intro, FileAccess.get_file_as_string("res://" + intro))
	check(store.change(intro, "delete", {}, store.fingerprints()), "Intro motif can be deleted")
	check(store.load_state().manifest.intro_paths.size() == 8, "Public intro manifest excludes deleted slot")
	check(store.change(intro, "restore", {}, store.fingerprints()), "Intro motif can be restored")
	check(store.load_state().manifest.intro_paths[0] == "res://levels/01.json", "Restored intro returns to its original position")
	var scene = load("res://main.tscn").instantiate(); root.add_child(scene)
	scene.storage_prefix = "user://management_runtime_test_"
	scene.scan_user_exports = true; scene.discover_levels()
	var baseline_count: int = scene.level_count()
	var completed_path: String = scene.level_files[10]
	scene.completed.clear(); scene.completed.append_array([0, 9, 10])
	var deleted_path: String = scene.level_files[9]
	var intros: Array = []
	for index in range(1, 9): intros.append("res://levels/%02d.json" % (index + 1))
	var manifest_path: String = store.root + "runtime_manifest.json"
	put(manifest_path, JSON.stringify({"intro_paths": intros, "deleted": ["res://levels/01.json", deleted_path]}))
	scene.workshop_manifest_path = manifest_path; scene.discover_levels()
	check(scene.base_level_count == 8 and scene.level_count() == baseline_count - 2, "Player count drops after deleting intro and catalog motifs")
	check(scene.completed.size() == 1 and scene.level_path(scene.completed[0]) == completed_path, "Remaining completion stays bound to the same picture after index shifts")
	var all_intro: Array = ["res://levels/01.json"] + intros
	put(manifest_path, JSON.stringify({"intro_paths": [], "deleted": all_intro}))
	scene.discover_levels()
	check(scene.base_level_count == 0 and scene.level_count() == baseline_count - 9, "Player tolerates a redesigned introduction without fixed nine-slot assumptions")
	scene.queue_free(); await process_frame
	if failures == 0: print("PASS workshop move/delete/restore/publish, metadata totals, original slots, crash recovery and stale-write protection")
	quit(1 if failures else 0)
