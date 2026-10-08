extends Window
var studio: Window
var store: RefCounted
var entries: Array = []
var filtered: Array = []
var selected_path := ""
var page := 0
var trash_mode := false
var drafts_mode := false
var drafts_button: Button
var query: LineEdit
var collection_filter: OptionButton
var grid: GridContainer
var status: Label
var selection: Label
var page_label: Label
var copy_button: Button
var open_button: Button
var move_button: Button
var delete_button: Button
var trash_button: Button
var expected := {}
var pending_filter: CheckButton
var pending_only := false
func _ready() -> void:
	title = "arrow.joy · Katalogwerkstatt"
	size = Vector2i(1060, 800); min_size = size
	store = load("res://catalog_workshop_store.gd").new(); store.root = studio.catalog_root
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 18)
	add_child(margin)
	var box := VBoxContainer.new(); box.add_theme_constant_override("separation", 12); margin.add_child(box)
	var header := HBoxContainer.new(); box.add_child(header)
	var heading := Label.new(); heading.text = "DEINE MOTIVWERKSTATT"; heading.add_theme_font_size_override("font_size", 24); heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(heading)
	button(header, "Neu zeichnen", func(): studio.new_workshop_motif(); queue_free())
	button(header, "Vorlage importieren", func(): studio.choose_open_document(); queue_free())
	trash_button = button(header, "Papierkorb", func(): trash_mode = not trash_mode; drafts_mode = false; selected_path = ""; page = 0; reload_entries())
	drafts_button = button(header, "Entwürfe", func(): drafts_mode = not drafts_mode; trash_mode = false; selected_path = ""; page = 0; reload_entries())
	var controls := HBoxContainer.new(); box.add_child(controls)
	query = LineEdit.new(); query.placeholder_text = "Motivname oder Sammlung suchen …"; query.size_flags_horizontal = Control.SIZE_EXPAND_FILL; controls.add_child(query)
	query.text_changed.connect(func(_text): page = 0; filter_entries())
	collection_filter = OptionButton.new(); collection_filter.custom_minimum_size.x = 250; controls.add_child(collection_filter)
	pending_filter=CheckButton.new(); pending_filter.text="Englisch offen"; controls.add_child(pending_filter)
	pending_filter.toggled.connect(func(value:bool): pending_only=value; page=0; filter_entries())
	collection_filter.item_selected.connect(func(_index): page = 0; filter_entries())
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation", 18); box.add_child(body)
	grid = GridContainer.new(); grid.columns = 3; grid.add_theme_constant_override("h_separation", 10); grid.add_theme_constant_override("v_separation", 10); body.add_child(grid)
	var actions := VBoxContainer.new(); actions.custom_minimum_size.x = 270; actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL; actions.add_theme_constant_override("separation", 10); body.add_child(actions)
	selection = Label.new(); selection.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; selection.custom_minimum_size.y = 110; actions.add_child(selection)
	open_button = button(actions, "Motiv bearbeiten", open_selected)
	copy_button = button(actions, "Als neues Motiv kopieren", duplicate_selected)
	move_button = button(actions, "Sammlung ändern …", move_selected)
	delete_button = button(actions, "In den Papierkorb …", delete_selected)
	var help := Label.new(); help.text = "Ein Motiv auswählen, dann bearbeiten.\n\nPfeile, Farben, Flächen und Abschlusstext bearbeitest du in der Werkstatt.\n\nSpeichern ersetzt das vorhandene Motiv. Eine Kopie erhält einen eigenen Platz.\n\nGelöschte Motive kannst du im Papierkorb wiederherstellen."; help.add_theme_font_size_override("font_size", 14); help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; help.modulate = Color("#91b4cf"); actions.add_child(help)
	var navigation := HBoxContainer.new(); box.add_child(navigation)
	button(navigation, "‹ Zurück", func(): page = maxi(0, page - 1); render())
	page_label = Label.new(); page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; navigation.add_child(page_label)
	button(navigation, "Spieler-APK bauen …", func(): studio.choose_player_export(); queue_free())
	button(navigation, "Weiter ›", func(): page = mini(maxi(0, ceili(filtered.size() / 9.0) - 1), page + 1); render())
	status = Label.new(); status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; status.custom_minimum_size.y = 38; box.add_child(status)
	close_requested.connect(queue_free)
	reload_entries()
func button(parent: Node, text: String, action: Callable) -> Button:
	var result := Button.new(); result.text = text; result.custom_minimum_size.y = 38; result.pressed.connect(action); parent.add_child(result); return result
func reload_entries() -> void:
	if not store.recover(): status.text = store.error; return
	var state: Dictionary = store.load_state(); entries.clear()
	if drafts_mode:
		var directory: String = studio.drafts_directory()
		for filename in DirAccess.get_files_at(directory):
			if filename.get_extension() != "json": continue
			var document = JSON.parse_string(FileAccess.get_file_as_string(directory + filename))
			if not document is Dictionary or not document.get("cells") is Array: continue
			entries.append({"path": directory + filename, "title": document.get("title", "Entwurf"), "collection": {"id": "draft", "title": "Lokaler Entwurf"}, "document": {"shape": 6, "motif": document, "paths": document.get("paths", [])}, "draft": document})
	elif trash_mode:
		for path in state.trash.entries:
			var item: Dictionary = state.trash.entries[path]
			entries.append({"path": "res://" + path, "title": item.document.title, "collection": {"id": item.assignment.group, "title": item.assignment.get("old_collection_title", item.assignment.group)}, "document": item.document})
	else:
		entries = state.catalog.levels.duplicate(true)
		for assignment in state.taxonomy.assignments:
			if not entries.any(func(item): return item.path == assignment.path): entries.append({"path": assignment.path, "title": assignment.title, "collection": {"id": assignment.group, "title": state.journey.groups.get(assignment.group, {}).get("title", assignment.group)}})
	if not trash_mode and not drafts_mode:
		var helper:RefCounted=load("res://workshop_language_service.gd").new(); helper.root=studio.catalog_root
		for entry in entries:
			var german:Dictionary=helper.original_fields(str(entry.title),state.discoveries.entries.get(entry.path,{}))
			var languages:Dictionary=helper.load_record(entry.path,german)
			entry.language_issues=helper.issues(languages,german)
			entry.english_title=languages.en.title
	pending_filter.disabled=trash_mode or drafts_mode
	expected = store.fingerprints()
	collection_filter.clear(); collection_filter.add_item("Alle Sammlungen"); collection_filter.set_item_metadata(0, "")
	var groups := {}
	for item in entries: groups[item.collection.id] = item.collection.title
	for id in groups: collection_filter.add_item(groups[id]); collection_filter.set_item_metadata(collection_filter.item_count - 1, id)
	drafts_button.text = "Zurück zum Katalog" if drafts_mode else "Entwürfe"
	trash_button.text = "Zurück zum Katalog" if trash_mode else "Papierkorb · " + str(state.trash.entries.size())
	status.text = "Papierkorb: Wiederherstellen setzt das Motiv zurück in seine Sammlung." if trash_mode else "%d Motive · Änderungen bleiben im Projekt, bis du eine neue Spieler-APK baust." % entries.size()
	if drafts_mode: status.text = "Lokale Entwürfe · automatisch gesichert. Erst ›Als neues Katalogmotiv hinzufügen‹ übernimmt einen Entwurf ins Spiel."
	filter_entries()
func filter_entries() -> void:
	var group: String = collection_filter.get_item_metadata(collection_filter.selected)
	var text := query.text.strip_edges().to_lower()
	filtered = entries.filter(func(item): return (not pending_only or trash_mode or drafts_mode or not item.get("language_issues",[]).is_empty()) and (group.is_empty() or item.collection.id == group) and (text.is_empty() or (str(item.title) + " " + str(item.get("english_title","")) + " " + str(item.collection.title)).to_lower().contains(text)))
	render()
func render() -> void:
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	page = mini(page, maxi(0, ceili(filtered.size() / 9.0) - 1))
	for entry in filtered.slice(page * 9, page * 9 + 9):
		var card := Button.new(); card.set_script(load("res://level_card.gd")); card.custom_minimum_size = Vector2(230, 178)
		card.number = page * 9 + grid.get_child_count(); card.tooltip_text = str(entry.title) + "\n" + str(entry.collection.title); card.title = entry.title; card.subtitle = entry.collection.title + (" · EN offen" if not entry.get("language_issues",[]).is_empty() else ""); card.selected = entry.path == selected_path
		var document: Dictionary = entry.get("document", store.read(str(entry.path).trim_prefix("res://")))
		var motif := CustomMotif.decode(document.get("motif", {})) if int(document.get("shape", 6)) == 6 else CustomMotif.from_shape(int(document.get("shape", 0)))
		card.paths = CustomMotif.decode_paths(document.get("paths", []), motif, false)
		card.pressed.connect(func(): selected_path = entry.path; render())
		grid.add_child(card)
	page_label.text = "Seite %d / %d · %d Motive" % [page + 1, maxi(1, ceili(filtered.size() / 9.0)), filtered.size()]
	var chosen := {}
	for entry in entries:
		if entry.path == selected_path: chosen = entry
	selection.text = "Wähle ein Motiv aus." if chosen.is_empty() else str(chosen.title) + "\n" + str(chosen.collection.title)
	if not chosen.get("language_issues",[]).is_empty(): selection.text+="\n\n"+"\n".join(chosen.language_issues.map(func(item):return item.message))
	open_button.text = "Motiv wiederherstellen" if trash_mode else "Motiv bearbeiten"
	copy_button.disabled = trash_mode or chosen.is_empty(); open_button.disabled = chosen.is_empty(); move_button.disabled = trash_mode or drafts_mode or chosen.is_empty(); delete_button.disabled = trash_mode or drafts_mode or chosen.is_empty()
func open_selected() -> void:
	if selected_path.is_empty(): return
	if drafts_mode:
		var action := func():
			var document = JSON.parse_string(FileAccess.get_file_as_string(selected_path))
			if studio.open_document(selected_path, true): studio.restore_workshop_state(document.get("workshop", {})); queue_free()
		studio.confirm_replace(action, "Entwurf öffnen? Dein aktueller Entwurf wird vorher gesichert.")
	elif trash_mode:
		if store.change(selected_path, "restore", {}, expected): studio.catalog_changed(); selected_path = ""; reload_entries(); status.text = "Motiv wiederhergestellt."
		else: status.text = store.error
	else:
		var action := func(): studio.bind_catalog(selected_path); queue_free()
		if studio.catalog_path.is_empty() or studio.catalog_state() != studio.catalog_baseline: studio.confirm_replace(action, "Motiv öffnen? Der aktuelle Entwurf wird vorher gesichert.")
		else: action.call()
func duplicate_selected() -> void:
	if selected_path.is_empty() or trash_mode: return
	studio.confirm_replace(func():
		if drafts_mode:
			var document = JSON.parse_string(FileAccess.get_file_as_string(selected_path))
			if not studio.open_document(selected_path, true): return
			studio.restore_workshop_state(document.get("workshop", {}))
		else: studio.bind_catalog(selected_path)
		studio.catalog_path = ""; studio.catalog_document = {}; studio.draft_key = ""
		studio.motif.title = studio.title_field.text + " · Kopie"; studio.refresh(); studio.notice.text = "Kopie erstellt. Mit ›Als neues Katalogmotiv hinzufügen‹ einer Sammlung zuordnen."; queue_free(), "Kopie öffnen? Dein aktueller Entwurf wird vorher gesichert.")
func move_selected() -> void:
	if selected_path.is_empty(): return
	studio.choose_workshop_target(func(target: Dictionary):
		if store.change(selected_path, "move", target, expected): studio.catalog_changed(); reload_entries(); status.text = "Motiv in die gewählte Sammlung verschoben."
		else: status.text = store.error, selected_path)
func delete_selected() -> void:
	if selected_path.is_empty(): return
	var dialog := ConfirmationDialog.new(); dialog.title = "Motiv in den Papierkorb"; dialog.dialog_text = "Dieses Motiv wird aus dem Spiel entfernt. Anzahl und Zuordnungen werden angepasst. Im Papierkorb bleiben Bild, Pfeile und Text wiederherstellbar."; dialog.ok_button_text = "In den Papierkorb"; add_child(dialog)
	dialog.confirmed.connect(func():
		if store.change(selected_path, "delete", {}, expected): studio.catalog_changed(); selected_path = ""; reload_entries(); status.text = "Motiv in den Papierkorb verschoben."
		else: status.text = store.error
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free); dialog.popup_centered(Vector2i(560, 200))
