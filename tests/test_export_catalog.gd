extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func write_document(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
func game(directory: String) -> Node2D:
	var scene = load("res://main.tscn").instantiate()
	scene.catalog_directory = directory
	scene.scan_user_exports = true
	root.add_child(scene)
	return scene
func run() -> void:
	var directory := "user://test_catalog"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	for index in range(1,10):
		write_document(directory + "/%02d.json" % index, JSON.parse_string(FileAccess.get_file_as_string("res://levels/%02d.json" % index)))
	var exported: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://levels/07.json"))
	exported.title = "Test-Schmetterling A"
	write_document(directory + "/10.json", exported)
	exported.title = "Test-Schmetterling B"
	write_document(directory + "/11.json", exported)
	write_document(directory + "/broken.json", {"version":2,"shape":6,"paths":[]})
	var scene := game(directory)
	require(scene.level_count() == 11, "Additional exports appear automatically; malformed files are skipped")
	require(scene.level_title(10) == "Test-Schmetterling B" and not scene.level_picker.is_item_disabled(10), "Exported artwork is immediately selectable without campaign completion")
	scene.open_gallery()
	var cards: GridContainer = scene.gallery.get_child(3).get_child(0)
	require(cards.get_child_count() == 11 and not cards.get_child(10).disabled, "The actual gallery includes unlocked exported motifs")
	scene.select_gallery_level(10)
	require(scene.level == 10 and scene.arrows.size() == exported.paths.size() and scene.unlocked == 0, "Gallery launches the selected export without unlocking the campaign")
	for index in ArrowPuzzle.solution(scene.arrows):
		require(not scene.is_blocked(index), "Exported puzzle retains its solution in the real game")
		scene.click_at(scene.arrows[index].points[0]); scene._process(2)
	require(scene.cleared == scene.arrows.size() and scene.unlocked == 0 and scene.completed.has(10), "Completing an export records it independently of campaign progress")
	exported.title = "Später hinzugefügt"
	write_document(directory + "/00_eigen.json", exported)
	scene.open_gallery()
	require(scene.level_count() == 12 and scene.level_path(scene.level).ends_with("11.json") and scene.completed.has(scene.level), "Catalog refresh retains the selected export and completion when another file changes ordering")
	scene.close_gallery(); scene.save_progress()
	var reopened := game(directory)
	require(reopened.level_path(reopened.level).ends_with("11.json") and reopened.completed.has(reopened.level) and reopened.unlocked == 0, "Restart restores exported motif progress by filename")
	for filename in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(directory.path_join(filename)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(directory))
	DirAccess.remove_absolute(scene.storage_prefix + "progress.cfg")
	var actual := game("res://levels")
	for filename in ["10.json","11.json"]:
		if not FileAccess.file_exists("res://levels/" + filename): continue
		var index: int = actual.level_files.find("res://levels/" + filename)
		require(index >= 9 and actual.read_custom(actual.level_path(index)), "The user's actual exported butterfly loads as a playable extra motif")
	print("PASS export discovery, real gallery selection, complete play, campaign isolation, catalog refresh, progress persistence and actual user exports" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
