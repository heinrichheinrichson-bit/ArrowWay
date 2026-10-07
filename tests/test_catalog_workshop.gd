extends SceneTree
var failed := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failed += 1; push_error(message)
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.enter_editor(); scene.open_studio()
	var studio: Window = scene.studio
	studio.choose_catalog()
	var picker: Window = studio.get_child(studio.get_child_count() - 1)
	check(picker.entries.size() == 823, "Private browser includes all 814 catalog and nine intro puzzles")
	picker.queue_free()
	var base := "user://catalog_workshop_test/"
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	var path: String = str(catalog.levels[0].path).trim_prefix("res://")
	for name in [path, "collections/catalog.json", "collections/taxonomy.json", "collections/discoveries.json"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path((base + name).get_base_dir()))
		var file := FileAccess.open(base + name, FileAccess.WRITE)
		file.store_string(FileAccess.get_file_as_string("res://" + name)); file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(base + "collections/editor_overrides.json"))
	studio.catalog_root = base
	studio.bind_catalog(path)
	check(studio.catalog_path == path and not studio.paths.is_empty(), "Catalog opens with its existing arrows")
	var before: String = FileAccess.get_sha256(base + path)
	studio.paths.clear()
	studio.save_catalog()
	check(FileAccess.get_sha256(base + path) == before, "Incomplete fill cannot overwrite a catalog level")
	studio.bind_catalog(path)
	studio.title_field.text = "Werkstatt-Testmotiv"
	studio.motif.title = studio.title_field.text
	studio.completion_text.text = "Ein einzelner Weg verändert das ganze Bild."
	studio.completion_kind.text = "Ein kleiner Gedanke"
	studio.paths[0].color = Color("#ff22aa")
	studio.save_catalog()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + path))
	check(saved.title == "Werkstatt-Testmotiv", "Title saves in original level file")
	var updated: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "collections/catalog.json"))
	check(updated.levels.size() == catalog.levels.size() and updated.levels[0].path == "res://" + path and updated.levels[0].title == saved.title and updated.levels.slice(1) == catalog.levels.slice(1), "Save retains all catalog positions and other entries")
	check(not saved.get("compatible_color_checkpoints", []).is_empty(), "Cosmetic edits preserve session compatibility")
	var discoveries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + "collections/discoveries.json"))
	check(discoveries.entries["res://" + path].text == studio.completion_text.text, "Completion text saves under same ID")
	check(FileAccess.file_exists(base + "collections/editor_overrides.json"), "Manual edits are protected from regeneration")
	var current := FileAccess.get_file_as_string(base + path)
	var external := FileAccess.open(base + path, FileAccess.WRITE)
	external.store_string(current + "\n"); external.close()
	studio.title_field.text = "Conflict"
	studio.save_catalog()
	check(FileAccess.get_file_as_string(base + path) == current + "\n", "Second author window cannot silently overwrite newer edits")
	studio.bind_catalog(path)
	studio.completion_text.text = "Dieser Abschlusstext bleibt als Entwurf erhalten."
	studio.save_draft(false)
	check(FileAccess.file_exists(studio.drafts_directory() + studio.draft_key + ".json"), "Draft is saved in the central draft library")
	studio.completion_text.text = ""
	studio.load_draft(true)
	check(studio.completion_text.text == "Dieser Abschlusstext bleibt als Entwurf erhalten." and studio.catalog_path == path, "Draft recovery preserves completion text and catalog binding")
	studio.finish_close_studio(); await process_frame
	scene.open_studio(); studio = scene.studio
	check(studio.completion_text.text == "Dieser Abschlusstext bleibt als Entwurf erhalten." and studio.catalog_path == path, "Closing and reopening retains the complete editor context")
	studio.catalog_path = ""
	scene.queue_free()
	await process_frame
	if failed == 0: print("PASS catalog edits retain positions, save text/colors, protect generation, reject invalid fills and concurrent overwrites")
	quit(1 if failed else 0)
