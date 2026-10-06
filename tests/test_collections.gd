extends SceneTree

var failures := 0
class LibraryHarness extends "res://main.gd":
	var freeze_catalog := false
	func discover_levels(include_user_exports: bool = true, directory: String = "") -> void:
		if not freeze_catalog: super.discover_levels(include_user_exports, directory)
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	require(catalog.levels.size() == 814, "All 814 authored motifs appear in the catalog")
	var titles := {}
	var masks := {}
	var scene := LibraryHarness.new()
	scene.storage_prefix = "user://test_full_catalog_"
	scene.resume_enabled = false
	scene.scan_user_exports = true
	root.add_child(scene)
	var groups := {}
	for entry in catalog.levels:
		groups[entry.collection.id] = int(groups.get(entry.collection.id, 0)) + 1
		var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(entry.path))
		var motif := CustomMotif.decode(document.motif)
		require(not titles.has(entry.title), "Motif titles are unique: " + entry.title)
		titles[entry.title] = true
		var cells: Array = motif.cells.keys()
		cells.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y if a.y != b.y else a.x < b.x)
		var parts := {}
		var canonical: Array = []
		for cell in cells:
			var part: int = motif.cells[cell]
			if not parts.has(part): parts[part] = parts.size()
			canonical.append([cell.x,cell.y,parts[part]])
		var signature := JSON.stringify(canonical).sha256_text()
		require(not masks.has(signature), "Motif geometry and region layout are unique: " + entry.title)
		masks[signature] = entry.title
		var paths := CustomMotif.decode_paths(document.paths, motif)
		require(not paths.is_empty(), "Complete, non-overlapping, valid and solvable motif: " + entry.title)
		require(CustomMotif.isolated(motif).is_empty(), "No isolated raster points: " + entry.title)
		require(paths.size() == document.design.paths, "Measured path count matches baked geometry")
		scene.level = scene.level_files.find(entry.path)
		require(scene.level >= 9 and scene.level_available(scene.level), "Collections are immediately playable")
		scene.reset()
		for index in ArrowPuzzle.solution(scene.arrows):
			require(not scene.is_blocked(index), "Runtime agrees with solution: " + entry.title)
			scene.click_at(scene.arrows[index].points[0])
			scene._process(2)
		require(scene.cleared == paths.size() and scene.mistakes == 0, "Real gameplay completes: " + entry.title)
		require(scene.completed.has(scene.level), "Completion is recorded independently")
		var next: int = scene.next_collection_level(scene.level)
		require(next < 0 or scene.level_collection(next).id == entry.collection.id, "Next puzzle stays within its collection")
		if titles.size() % 50 == 0: print("PLAYED ",titles.size(),"/814")
	var definition: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/journey.json"))
	var expected := {}
	for id in definition.groups:
		if id!="base": expected[id]=int(definition.groups[id].count)
	require(groups == expected and groups.size()==expected.size(), "All collections have the intended counts")
	require(scene.unlocked == 0, "Completing collections does not change campaign unlocks")
	scene.collection_filter = "all"
	scene.gallery_page = 0
	scene.open_gallery()
	var cards: GridContainer = scene.gallery.get_child(3).get_child(0)
	require(cards.get_child_count() == scene.GALLERY_PAGE_SIZE, "Only twelve previews are instantiated")
	scene.gallery.get_child(6).pressed.emit()
	cards = scene.gallery.get_child(3).get_child(0)
	require(scene.gallery_page == 1 and cards.get_child(0).number == 12, "Next page uses global level indices")
	var filters: OptionButton = scene.gallery.get_child(4)
	filters.item_selected.emit(2)
	cards = scene.gallery.get_child(3).get_child(0)
	require(scene.collection_filter == "world" and scene.gallery_page == 0 and cards.get_child_count() == groups.world, "Collection filter resets pagination and displays the complete landmark collection")
	var first_index: int = cards.get_child(0).number
	cards.get_child(0).pressed.emit()
	require(scene.level == first_index and not is_instance_valid(scene.gallery), "Filtered card launches its correct puzzle")
	var last_world: int = JourneyProgress.indices(scene,"world")[-1]
	scene.level = last_world
	scene.advance()
	require(is_instance_valid(scene.gallery) and scene.collection_filter == "world", "End of collection returns to its overview")
	scene.close_gallery()
	# A one-cell-wide vertical stem must be packed into arrows rather than dropped.
	var stem := {"cells":{},"palettes":{0:["#00ff88"]},"names":{0:"Stiel"},"title":"Stiel"}
	for y in range(8): stem.cells[Vector2i(12,y+5)] = 0
	var stem_paths := MotifBuilder.generate(6,92317,stem)
	var covered := 0
	for arrow in stem_paths: covered += arrow.points.size()
	require(covered == 8 and not stem_paths.is_empty(), "Thin vertical details retain all cells")
	# Exercise the actual gallery with a large in-memory index; geometry is reused
	# deliberately, so this checks paging/UI allocation rather than disk throughput.
	scene.freeze_catalog = true
	scene.level_files.clear()
	for index in range(1000): scene.level_files.append("res://collections/levels/world_01_eiffel.json")
	scene.completed.clear()
	scene.collection_filter = "all"
	scene.gallery_page = 0
	scene.open_gallery()
	cards = scene.gallery.get_child(3).get_child(0)
	require(cards.get_child_count() == 12, "A thousand-entry index still creates twelve previews")
	scene.close_gallery()
	scene.gallery_page = 83
	scene.open_gallery()
	cards = scene.gallery.get_child(3).get_child(0)
	require(cards.get_child_count() == 4 and cards.get_child(0).number == 996, "Last page of a thousand-entry index has the correct remaining entries")
	require(scene.gallery.get_child(6).disabled, "Next page is disabled at the end of a large index")
	for name in ["progress.cfg","settings.cfg"]: DirAccess.remove_absolute(scene.storage_prefix + name)
	print("PASS 814 motifs: unique geometry, complete coverage, all real gameplay solutions, gradients, pagination, filtering, next puzzle and progress" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
