extends RefCounted
# Private author service. Public paths are stable identities; list indices are never identities.
var root := "res://"
var error := ""
const FILES := ["collections/catalog.json", "collections/taxonomy.json", "collections/journey.json", "collections/discoveries.json", "collections/editor_overrides.json", "collections/workshop_manifest.json", "collections/workshop_trash.json"]
func read(path: String, fallback: Dictionary = {}) -> Dictionary:
	if not FileAccess.file_exists(root + path): return fallback.duplicate(true)
	var data = JSON.parse_string(FileAccess.get_file_as_string(root + path))
	return data if data is Dictionary else fallback.duplicate(true)
func fingerprints() -> Dictionary:
	var hashes := {}
	for path in FILES: hashes[path] = FileAccess.get_sha256(root + path) if FileAccess.file_exists(root + path) else ""
	return hashes
func load_state() -> Dictionary:
	var state := {"catalog": read(FILES[0]), "taxonomy": read(FILES[1]), "journey": read(FILES[2]), "discoveries": read(FILES[3]), "overrides": read(FILES[4], {"version": 1, "entries": {}}), "manifest": read(FILES[5], {"version": 1, "deleted": []}), "trash": read(FILES[6], {"version": 1, "entries": {}})}
	if not state.manifest.has("catalog_order"): state.manifest.catalog_order = state.catalog.get("levels", []).map(func(item): return item.path)
	return state
func recount(state: Dictionary) -> void:
	var counts := {}
	var category_counts := {}
	var intros: Array = []
	for item in state.taxonomy.assignments:
		counts[item.group] = int(counts.get(item.group, 0)) + 1
		category_counts[item.category_id] = int(category_counts.get(item.category_id, 0)) + 1
		if item.group == "base": intros.append(item.path)
	for id in state.journey.groups: state.journey.groups[id].count = counts.get(id, 0)
	for world in state.taxonomy.worlds:
		for category in world.categories:
			category.existing_count = category_counts.get(category.id, 0)
			category.status = "populated" if category.existing_count > 0 else "empty"
	state.manifest.intro_paths = intros
	state.manifest.total = state.taxonomy.assignments.size()
func state_updates(state: Dictionary) -> Dictionary:
	return {FILES[0]: state.catalog, FILES[1]: state.taxonomy, FILES[2]: state.journey, FILES[3]: state.discoveries, FILES[4]: state.overrides, FILES[5]: state.manifest, FILES[6]: state.trash}
func write_checked(file: FileAccess, text: String) -> bool:
	file.store_string(text); file.flush()
	var result := file.get_error() == OK
	file.close()
	return result
func commit(updates: Dictionary, expected: Dictionary = {}) -> bool:
	error = ""
	if not recover(): return false
	for path in expected:
		var current := FileAccess.get_sha256(root + path) if FileAccess.file_exists(root + path) else ""
		if current != expected[path]: error = "Zwischenzeitliche Änderungen erkannt. Bitte neu öffnen."; return false
	var originals := {}
	var backup_dir := root + "work/catalog-backups/" + str(Time.get_unix_time_from_system()).replace(".", "-") + "-" + str(Time.get_ticks_usec())
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(backup_dir)) != OK: error = "Sicherung kann nicht angelegt werden."; return false
	for path in updates:
		if path.contains("..") or path.begins_with("/") or path.contains(":"): error = "Ungültiger Katalogpfad."; return false
		originals[path] = FileAccess.get_file_as_string(root + path) if FileAccess.file_exists(root + path) else null
		var backup := FileAccess.open(backup_dir + "/" + path.replace("/", "__"), FileAccess.WRITE)
		if backup == null: error = "Sicherung fehlgeschlagen."; return false
		if not write_checked(backup, JSON.stringify({"path": path, "original": originals[path]})): error = "Sicherung konnte nicht vollständig geschrieben werden."; return false
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path((root + path).get_base_dir()))
		if updates[path] != null:
			var temporary := FileAccess.open(root + path + ".pending", FileAccess.WRITE)
			if temporary == null: error = "Datei kann nicht vorbereitet werden."; return false
			if not write_checked(temporary, JSON.stringify(updates[path], "\t")): error = "Datei konnte nicht vollständig vorbereitet werden."; return false
	var journal := FileAccess.open(root + "work/catalog-transaction.json", FileAccess.WRITE)
	if journal == null: error = "Transaktionssicherung fehlgeschlagen."; return false
	if not write_checked(journal, JSON.stringify({"originals": originals})):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(root + "work/catalog-transaction.json"))
		error = "Transaktionssicherung konnte nicht vollständig geschrieben werden."; return false
	for path in updates:
		var result := OK
		if updates[path] == null:
			if FileAccess.file_exists(root + path): result = DirAccess.remove_absolute(ProjectSettings.globalize_path(root + path))
		else: result = DirAccess.rename_absolute(ProjectSettings.globalize_path(root + path + ".pending"), ProjectSettings.globalize_path(root + path))
		if result != OK:
			error = "Speichern fehlgeschlagen. Die vorherigen Dateien werden wiederhergestellt."
			recover(); return false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(root + "work/catalog-transaction.json"))
	return true
func recover() -> bool:
	var journal_path := root + "work/catalog-transaction.json"
	if not FileAccess.file_exists(journal_path): return true
	var journal := read("work/catalog-transaction.json")
	if not journal.get("originals") is Dictionary: error = "Transaktionssicherung ungültig. Bitte nicht weiter speichern."; return false
	for path in journal.originals:
		if str(path).contains("..") or str(path).contains(":"): error = "Ungültige Transaktionssicherung."; return false
		if journal.originals[path] == null:
			if FileAccess.file_exists(root + path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(root + path)) != OK: error = "Wiederherstellung fehlgeschlagen."; return false
		else:
			var file := FileAccess.open(root + path, FileAccess.WRITE)
			if file == null: error = "Wiederherstellung fehlgeschlagen."; return false
			if not write_checked(file, journal.originals[path]): error = "Wiederherstellung konnte nicht vollständig geschrieben werden."; return false
		if FileAccess.file_exists(root + path + ".pending"): DirAccess.remove_absolute(ProjectSettings.globalize_path(root + path + ".pending"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(journal_path))
	return true
func preserve_checkpoint(document: Dictionary, fingerprint: String) -> void:
	if fingerprint.length() != 64: return
	var geometry_paths: Array[String] = []
	for arrow in document.get("paths", []):
		var points: Array[String] = []
		for point in arrow.points: points.append("%d,%d" % [point[0], point[1]])
		geometry_paths.append(";".join(points))
	var predecessor := {"fingerprint": fingerprint, "geometry": "|".join(geometry_paths).sha256_text()}
	if not document.has("compatible_color_checkpoints"): document.compatible_color_checkpoints = []
	if not document.compatible_color_checkpoints.has(predecessor): document.compatible_color_checkpoints.append(predecessor)
func change(path: String, operation: String, target: Dictionary = {}, expected: Dictionary = {}) -> bool:
	path = path.trim_prefix("res://")
	if not recover(): return false
	var state := load_state()
	var public_path := "res://" + path
	var assignment := {}
	var entry := {}
	var position := -1
	for item in state.taxonomy.assignments:
		if item.path == public_path: assignment = item.duplicate(true)
	for index in state.catalog.levels.size():
		if state.catalog.levels[index].path == public_path: entry = state.catalog.levels[index].duplicate(true); position = index
	var updates := {}
	if operation == "delete":
		if assignment.is_empty(): error = "Motiv ist nicht im Katalog."; return false
		if state.taxonomy.assignments.size() <= 1: error = "Mindestens ein Motiv muss im Spiel bleiben."; return false
		var document := read(path)
		state.trash.entries[path] = {"document": document, "fingerprint": FileAccess.get_sha256(root + path), "assignment": assignment, "assignment_position": state.taxonomy.assignments.find(assignment), "entry": entry, "position": position, "discovery": state.discoveries.entries.get(public_path, {}), "override": state.overrides.entries.get(path, {}), "deleted_at": Time.get_datetime_string_from_system()}
		state.catalog.levels = state.catalog.levels.filter(func(item): return item.path != public_path)
		state.taxonomy.assignments = state.taxonomy.assignments.filter(func(item): return item.path != public_path)
		state.discoveries.entries.erase(public_path)
		if not state.manifest.deleted.has(public_path): state.manifest.deleted.append(public_path)
		state.overrides.entries[path] = {"protected": true, "deleted": true}
		updates[path] = null
	elif operation == "restore":
		if not state.trash.entries.has(path): error = "Motiv ist nicht im Papierkorb."; return false
		if not assignment.is_empty() or FileAccess.file_exists(root + path): error = "Dieser Motivplatz wird inzwischen verwendet."; return false
		var trashed: Dictionary = state.trash.entries[path]
		updates[path] = trashed.document
		preserve_checkpoint(updates[path], trashed.get("fingerprint", ""))
		state.taxonomy.assignments.insert(clampi(int(trashed.get("assignment_position", state.taxonomy.assignments.size())), 0, state.taxonomy.assignments.size()), trashed.assignment)
		if not trashed.entry.is_empty():
			state.catalog.levels.append(trashed.entry)
			state.catalog.levels.sort_custom(func(a, b): return state.manifest.catalog_order.find(a.path) < state.manifest.catalog_order.find(b.path))
		state.discoveries.entries[public_path] = trashed.discovery
		state.overrides.entries[path] = {"protected": true, "title": trashed.document.title, "discovery": trashed.discovery, "assignment": trashed.assignment}
		state.manifest.deleted.erase(public_path)
		state.trash.entries.erase(path)
	elif operation == "move":
		if assignment.is_empty() or not state.journey.groups.has(target.get("group", "")): error = "Bitte eine gültige Sammlung wählen."; return false
		if assignment.group == "base" or target.group == "base": error = "Einstiegsmotive bleiben in der Einführung; erstelle dafür eine Kopie."; return false
		for key in ["world", "world_title", "category", "category_id", "group"]: assignment[key] = target[key]
		var collection := {"id": target.group, "title": state.journey.groups[target.group].title, "order": state.catalog.levels.size() + 1}
		for item in state.taxonomy.assignments:
			if item.path == public_path: item.merge(assignment, true)
		for item in state.catalog.levels:
			if item.path == public_path: item.collection = collection; item.taxonomy = {"world": target.world, "category": target.category}
		var document := read(path); document.collection = collection
		preserve_checkpoint(document, FileAccess.get_sha256(root + path))
		updates[path] = document
		state.overrides.entries[path] = {"protected": true, "title": document.title, "discovery": state.discoveries.entries[public_path], "assignment": assignment, "collection": collection}
	else: error = "Unbekannte Katalogaktion."; return false
	recount(state)
	updates.merge(state_updates(state))
	return commit(updates, expected)
func publish(document: Dictionary, discovery: Dictionary, target: Dictionary, expected: Dictionary = {}) -> String:
	if not recover(): return ""
	var state := load_state()
	if not state.journey.groups.has(target.get("group", "")): error = "Bitte eine Sammlung wählen."; return ""
	var motif := CustomMotif.decode(document.get("motif", {}))
	var paths := CustomMotif.decode_paths(document.get("paths", []), motif)
	if paths.is_empty() or not LevelDesign.metrics(paths).get("solvable", false) or str(document.get("title", "")).strip_edges().is_empty() or str(discovery.get("text", "")).strip_edges().is_empty(): error = "Name, Abschlusstext und ein vollständig gefülltes lösbares Motiv sind erforderlich."; return ""
	if str(document.title).length() > 80 or str(discovery.text).length() > 600:
		error = "Der Name darf höchstens 80, der Abschlusstext höchstens 600 Zeichen haben."; return ""
	if discovery.get("kind", "Ein kleiner Gedanke") != "Ein kleiner Gedanke" and (str(discovery.get("source", "")).strip_edges().is_empty() or not str(discovery.get("url", "")).begins_with("https://")):
		error = "Für Fakten und Zitate sind Quelle und https://-Link erforderlich."; return ""
	var path := "collections/levels/workshop_" + str(Time.get_unix_time_from_system()).replace(".", "_") + "_" + str(Time.get_ticks_usec()) + ".json"
	var public_path := "res://" + path
	var collection := {"id": target.group, "title": state.journey.groups[target.group].title, "order": state.catalog.levels.size() + 1}
	document.erase("compatible_color_checkpoints")
	document.collection = collection; document.design = LevelDesign.metrics(paths)
	var entry := {"path": public_path, "title": document.title, "collection": collection, "design": document.design, "tags": [target.category], "taxonomy": {"world": target.world, "category": target.category}}
	var assignment := target.duplicate(true); assignment.path = public_path; assignment.title = document.title; assignment.old_collection = target.group; assignment.old_collection_title = collection.title; assignment.existing_tags = [target.category]
	state.catalog.levels.append(entry); state.manifest.catalog_order.append(public_path); state.taxonomy.assignments.append(assignment)
	state.discoveries.entries[public_path] = discovery
	state.overrides.entries[path] = {"protected": true, "title": document.title, "discovery": discovery, "assignment": assignment, "collection": collection}
	recount(state)
	var updates := state_updates(state); updates[path] = document
	return path if commit(updates, expected) else ""
