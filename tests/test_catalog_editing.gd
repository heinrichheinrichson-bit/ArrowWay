extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	var scene = load("res://main.tscn").instantiate()
	scene.storage_prefix = "user://test_catalog_edit_"
	root.add_child(scene)
	scene.enter_editor(); scene.open_studio()
	var studio: Window = scene.studio
	var checked := 0
	var edited_groups := {}
	for entry in catalog.levels:
		var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(entry.path))
		require(studio.open_document(entry.path,true), "Catalog motif opens in the actual editor: " + entry.title)
		var original := CustomMotif.encode_paths(studio.paths)
		var expected := CustomMotif.encode_paths(CustomMotif.decode_paths(document.paths,CustomMotif.decode(document.motif),false))
		require(original == expected and studio.motif.title == entry.title, "Opening preserves every original path and color: " + entry.title)
		if not edited_groups.has(entry.collection.id):
			studio.activate_tool(0)
			studio.select_arrow_at(studio.paths[0].points[0])
			studio.begin_color_edit()
			studio.arrow_color.color_changed.emit(Color("#44ee99"))
			studio.arrow_color.popup_closed.emit()
			require(studio.paths[0].color == Color("#44ee99") and CustomMotif.encode_paths([studio.paths[1]])[0] == original[1], "Fine color editing affects only the selected arrow")
			studio.undo()
			require(CustomMotif.encode_paths(studio.paths) == original, "Undo restores the original catalog artwork")
			edited_groups[entry.collection.id] = true
		checked += 1
		if checked % 100 == 0: print("OPENED ",checked,"/500")
	for name in ["editor_colors.json","editor_backup.json","motif_draft.json","progress.cfg"]: DirAccess.remove_absolute(scene.storage_prefix + name)
	require(checked == 500 and edited_groups.size() == 42, "All 500 motifs and all 42 collections were checked")
	print("PASS all 500 catalog motifs open unchanged in the actual editor; individual recoloring and undo work in all 42 collections" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
