extends Window

var draft_key := ""
var save_button: Button
var draft_clock := 0.0
var saved_draft_state := ""
var catalog_root := "res://"
var catalog_baseline := ""
var catalog_path := ""
var catalog_document := {}
var catalog_hashes := {}
var completion_text: TextEdit
var completion_kind: LineEdit
var completion_source: LineEdit
var completion_url: LineEdit
var english := {}
var reviewed_german := {}
var language_status: Label
var text_editor: Window

var game: Node2D
var motif := {}
var paths: Array[Dictionary] = []
var history: Array[Dictionary] = []
var selected := 0
var tool := 0
var busy := false
var show_paths := true
var show_reference := true
var canvas: Control
var canvas_style: StyleBoxFlat
var regions: OptionButton
var name_field: LineEdit
var title_field: LineEdit
var detection_mode: OptionButton
var threshold: HSlider
var palette_picker: OptionButton
var tool_picker: OptionButton
var notice: Label
var swatches: Array[ColorPickerButton] = []
var actions: Array[BaseButton] = []
var arrow_actions: Array[BaseButton] = []
var source: Image
var player_export_worker: Thread
var worker: Thread
var filling := false
var preserving_fill := false
var seed_value := 8900
var selected_arrow := -1
var palette_label: Label
var arrow_label: Label
var color_placeholder: Label
var arrow_color: ColorPickerButton
var arrow_styles: Button
var drawn_cells: Array[Vector2i] = []
var mirror_axis := 14.0
var arrow_tools: Window
var color_session := false
var color_snapshot_taken := false
var view_mode := false
var pages: TabContainer
var recent_row: HBoxContainer
var suggested_row: HBoxContainer
var recent_colors: Array[Color] = []
var replace_dialog: ConfirmationDialog
var view_button: Button
var undo_button: Button
var color_dialogue: Window

func _ready() -> void:
	title = "arrow.joy · Motivwerkstatt · " + str(ProjectSettings.get_setting("application/config/version", ""))
	size = Vector2i(1040, 800)
	min_size = size
	unresizable = true
	close_requested.connect(close_studio)
	load_recent_colors()
	var root := Control.new()
	root.size = Vector2(size)
	root.theme = game.panel.theme
	add_child(root)
	var background := ColorRect.new()
	background.size = root.size
	background.color = Color("#080e19")
	root.add_child(background)
	add_button(root, "← Katalog & Entwürfe", Vector2(25, 18), Vector2(245, 34), choose_catalog)
	view_button = Button.new()
	view_button.text = "Gesamtansicht · Esc"
	view_button.toggle_mode = true
	view_button.position = Vector2(300, 18)
	view_button.size = Vector2(165, 34)
	view_button.pressed.connect(show_overview)
	root.add_child(view_button)
	actions.append(view_button)
	undo_button = Button.new()
	undo_button.text = "Rückgängig"
	undo_button.position = Vector2(475, 18)
	undo_button.size = Vector2(140, 34)
	undo_button.pressed.connect(undo)
	root.add_child(undo_button)
	actions.append(undo_button)
	add_button(root, "Auswählen", Vector2(25, 63), Vector2(110, 36), func(): activate_tool(0))
	add_button(root, "Zeichnen", Vector2(143, 63), Vector2(100, 36), func(): activate_tool(9))
	arrow_actions.append(add_button(root, "Löschen", Vector2(251, 63), Vector2(100, 36), delete_arrow))
	arrow_actions.append(add_button(root, "Spitze wählen", Vector2(359, 63), Vector2(130, 36), func(): activate_tool(11)))
	arrow_actions.append(add_button(root, "Spiegeln …", Vector2(497, 63), Vector2(118, 36), open_arrow_tools))
	canvas_style = StyleBoxFlat.new()
	canvas_style.bg_color = Color("#0b1421")
	canvas_style.set_corner_radius_all(12)
	canvas = Control.new()
	canvas.set_script(load("res://motif_canvas.gd"))
	canvas.set("studio", self)
	canvas.position = Vector2(25, 115)
	canvas.size = Vector2(590, 620)
	root.add_child(canvas)
	var sidebar := VBoxContainer.new()
	sidebar.position = Vector2(640, 18)
	sidebar.size = Vector2(375, 717)
	sidebar.add_theme_constant_override("separation", 8)
	root.add_child(sidebar)
	add_label(sidebar, "MOTIV")
	title_field = LineEdit.new()
	title_field.max_length = 80
	title_field.placeholder_text = "Name deines Motivs"
	title_field.text_changed.connect(func(text: String): motif.title = text)
	sidebar.add_child(title_field)
	arrow_label = Label.new()
	arrow_label.custom_minimum_size.y = 28
	arrow_label.add_theme_font_size_override("font_size", 15)
	sidebar.add_child(arrow_label)
	pages = TabContainer.new()
	pages.custom_minimum_size.y = 470
	pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(pages)
	var page_style := StyleBoxFlat.new()
	page_style.bg_color = Color("#0b1421")
	page_style.set_corner_radius_all(8)
	page_style.content_margin_left = 6
	page_style.content_margin_right = 6
	page_style.content_margin_top = 10
	pages.add_theme_stylebox_override("panel", page_style)
	for state in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var tab_style := StyleBoxFlat.new()
		tab_style.bg_color = Color("#23445c") if state == "tab_selected" else Color("#111e2e")
		tab_style.content_margin_left = 10
		tab_style.content_margin_right = 10
		tab_style.content_margin_top = 8
		tab_style.content_margin_bottom = 8
		tab_style.set_corner_radius_all(6)
		pages.get_tab_bar().add_theme_stylebox_override(state, tab_style)
	var arrows_page := make_page("Pfeile & Farben")
	add_label(arrows_page, "FARBE DES AUSGEWÄHLTEN PFEILS")
	arrow_color = ColorPickerButton.new()
	arrow_color.custom_minimum_size.y = 42
	arrow_color.edit_alpha = false
	arrow_color.color_changed.connect(change_arrow_color)
	arrow_color.get_popup().about_to_popup.connect(begin_color_edit)
	arrow_color.popup_closed.connect(func(): end_color_edit(arrow_color.color))
	arrows_page.add_child(arrow_color)
	color_placeholder = Label.new()
	color_placeholder.text = "Pfeil auswählen, um seine Farbe zu ändern."
	color_placeholder.custom_minimum_size.y = 42
	color_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	color_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	color_placeholder.add_theme_font_size_override("font_size", 14)
	color_placeholder.modulate = Color("#91b4cf")
	arrows_page.add_child(color_placeholder)
	add_label(arrows_page, "ZULETZT VERWENDET")
	recent_row = HBoxContainer.new()
	recent_row.custom_minimum_size.y = 32
	arrows_page.add_child(recent_row)
	add_label(arrows_page, "FARBEN AUS DIESEM MOTIV")
	suggested_row = HBoxContainer.new()
	suggested_row.custom_minimum_size.y = 32
	arrows_page.add_child(suggested_row)
	arrow_styles = Button.new()
	arrow_styles.text = "Verläufe & Farbvorschläge …"
	arrow_styles.custom_minimum_size.y = 34
	arrow_styles.pressed.connect(open_colors)
	arrows_page.add_child(arrow_styles)
	add_row_button(arrows_page, "Pipette · vorhandene Farbe übernehmen", func():
		if selected_arrow < 0:
			notice.text = "Wähle zuerst den Pfeil aus, den du färben möchtest."
			return
		activate_tool(6))
	add_row_button(arrows_page, "Farben für das gesamte Motiv …", func():
		open_colors(); color_dialogue.target.select(2); color_dialogue.refresh_target())
	var help := Label.new()
	help.text = "Pfeil anklicken → Farbe wählen.\nGesamtansicht beendet die Hervorhebung.\nZeichnen ergänzt Pfeile. Entf löscht, R dreht.\nEsc zeigt wieder das ganze Motiv."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.custom_minimum_size = Vector2(320, 80)
	help.add_theme_font_size_override("font_size", 14)
	help.modulate = Color("#91b4cf")
	arrows_page.add_child(help)
	var areas_page := make_page("Vorlage & Flächen")
	add_label(areas_page, "FLÄCHE UND NAME")
	regions = OptionButton.new()
	regions.fit_to_longest_item = false
	regions.item_selected.connect(func(index: int):
		selected = regions.get_item_id(index); selected_arrow = -1; refresh())
	areas_page.add_child(regions)
	actions.append(regions)
	name_field = LineEdit.new()
	name_field.max_length = 60
	name_field.placeholder_text = "Dach, Stamm, Fenster …"
	name_field.text_changed.connect(func(text: String): motif.names[selected] = text)
	name_field.focus_exited.connect(refresh)
	areas_page.add_child(name_field)
	tool_picker = OptionButton.new()
	for text in ["Auswählen", "Fläche malen", "Radieren", "Fläche mit Linie trennen", "Flächen zusammenführen", "Pfeil auswählen", "Pipette · Pfeil / Fläche", "Pipette · Bildvorlage", "Nur Fläche auswählen", "Pfeil zeichnen", "Spiegelachse setzen", "Pfeilspitze wählen"]:
		tool_picker.add_item(text)
	tool_picker.item_selected.connect(activate_tool)
	areas_page.add_child(tool_picker)
	actions.append(tool_picker)
	add_row_button(areas_page, "Neue Fläche", new_region)
	palette_label = Label.new()
	palette_label.add_theme_font_size_override("font_size", 12)
	palette_label.modulate = Color("#91b4cf")
	areas_page.add_child(palette_label)
	palette_picker = OptionButton.new()
	palette_picker.add_item("Individuelle Palette")
	for key in CustomMotif.PALETTES:
		palette_picker.add_item(key)
	palette_picker.item_selected.connect(func(index: int):
		if index > 0: set_palette(CustomMotif.PALETTES.values()[index - 1]))
	areas_page.add_child(palette_picker)
	actions.append(palette_picker)
	var colors := HBoxContainer.new()
	areas_page.add_child(colors)
	for index in range(3):
		var swatch := ColorPickerButton.new()
		swatch.custom_minimum_size = Vector2(100, 34)
		swatch.edit_alpha = false
		swatch.color_changed.connect(func(color: Color): change_color(index, color))
		swatch.get_popup().about_to_popup.connect(begin_color_edit)
		swatch.popup_closed.connect(func(): end_color_edit(swatch.color))
		colors.add_child(swatch)
		swatches.append(swatch)
		actions.append(swatch)
	add_row_button(areas_page, "Flächenfarben & Verläufe …", open_colors)
	add_row_button(areas_page, "Bildvorlage öffnen …", choose_image)
	detection_mode = OptionButton.new()
	detection_mode.fit_to_longest_item = false
	for text in ["Automatisch erkennen", "Geschlossene Umrisse", "Farben / Transparenz"]:
		detection_mode.add_item(text)
	areas_page.add_child(detection_mode)
	actions.append(detection_mode)
	add_row_button(areas_page, "Vorlage neu erkennen …", analyze_image)
	add_label(areas_page, "LINIENERKENNUNG · HELL / DUNKEL")
	threshold = HSlider.new()
	threshold.min_value = 0.15; threshold.max_value = 0.85
	threshold.step = 0.05; threshold.value = 0.5
	areas_page.add_child(threshold)
	var reference := CheckButton.new()
	reference.text = "Bildvorlage einblenden"
	reference.button_pressed = true
	reference.toggled.connect(func(value: bool): show_reference = value; canvas.refresh())
	areas_page.add_child(reference)
	add_row_button(areas_page, "Letzten lokalen Entwurf laden …", load_draft)
	add_row_button(areas_page, "Alle Pfeile neu erzeugen …", func():
		if busy: return
		confirm_replace(func(): fill(true), "Eine komplette Neufüllung ersetzt auch deine eigenen Pfeile. Deine letzte Füllung wird zusätzlich gesichert."))
	add_row_button(areas_page, "Letzte ersetzte Füllung wiederherstellen", restore_backup)
	var data_page := make_page("Bilddaten")
	language_status = Label.new()
	language_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	language_status.custom_minimum_size=Vector2(300,42)
	language_status.add_theme_font_size_override("font_size",14)
	data_page.add_child(language_status)
	add_row_button(data_page, "Deutsch & Englisch bearbeiten …", open_text_editor)
	add_label(data_page, "DEUTSCHER ABSCHLUSSTEXT")
	completion_text = TextEdit.new()
	completion_text.custom_minimum_size.y = 150
	completion_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	data_page.add_child(completion_text)
	completion_kind = LineEdit.new()
	completion_kind.placeholder_text = "Art: Ein kleiner Gedanke / Wissenswert …"
	data_page.add_child(completion_kind)
	completion_source = LineEdit.new()
	completion_source.placeholder_text = "Quelle (bei Fakten und Zitaten)"
	data_page.add_child(completion_source)
	completion_url = LineEdit.new()
	completion_url.placeholder_text = "https://… Quellenlink"
	data_page.add_child(completion_url)
	add_row_button(data_page, "Am bisherigen Katalogplatz speichern", save_catalog)
	add_row_button(data_page, "Katalogmotiv auswählen …", choose_catalog)
	add_row_button(data_page, "Als neues Katalogmotiv hinzufügen …", publish_catalog)
	add_label(data_page, "Speichern aktualisiert das Projekt. Für das Handy\nist anschließend eine neue APK nötig.")
	pages.tab_changed.connect(func(index: int):
		if index == 0: activate_tool(0)
		elif index == 1: activate_tool(8))
	add_row_button(sidebar, "Freie Flächen mit Pfeilen füllen", fill)
	add_row_button(sidebar, "Im Spiel testen", apply)
	var files := HBoxContainer.new()
	sidebar.add_child(files)
	save_button = add_row_button(files, "Speichern", func():
		if catalog_path.is_empty(): save_draft()
		else: save_catalog())
	var open_menu := MenuButton.new()
	open_menu.text = "Öffnen ▾"
	open_menu.flat = false
	open_menu.custom_minimum_size.y = 34
	open_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open_menu.get_popup().add_item("Katalogmotiv auswählen …", 3)
	open_menu.get_popup().add_item("Kopie speichern …", 4)
	open_menu.get_popup().add_item("Bild, Motiv oder Level-Datei …", 0)
	open_menu.get_popup().add_item("Letzten lokalen Entwurf laden", 1)
	open_menu.get_popup().add_item("Letzte ersetzte Füllung wiederherstellen", 2)
	open_menu.get_popup().id_pressed.connect(func(id: int):
		if id == 3: choose_catalog()
		elif id == 4: choose_save_document()
		elif id == 0: choose_open_document()
		elif id == 1: load_draft()
		else: restore_backup())
	files.add_child(open_menu)
	actions.append(open_menu)
	notice = Label.new()
	notice.position = Vector2(25, 747)
	notice.size = Vector2(985, 46)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 14)
	root.add_child(notice)
	refresh()
	load_motif_languages()
	update_notice()

func make_page(page_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = page_name
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pages.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 10)
	scroll.add_child(box)
	return box

func add_label(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color("#91b4cf")
	parent.add_child(label)

func add_button(parent: Node, text: String, pos: Vector2, extent: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = extent
	button.pressed.connect(action)
	parent.add_child(button)
	actions.append(button)

	return button

func add_row_button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 34
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	actions.append(button)
	return button

func remember() -> void:
	history.append({"motif": motif.duplicate(true), "paths": game.clone_data(paths), "selected_arrow": selected_arrow, "workshop": workshop_state()})
	if history.size() > 40:
		history.pop_front()

func undo() -> void:
	if history.is_empty() or busy:
		return
	var state: Dictionary = history.pop_back()
	motif = state.motif
	paths = state.paths
	restore_workshop_state(state.get("workshop", {}))
	selected_arrow = state.get("selected_arrow", -1)
	view_mode = false
	tool = 0
	tool_picker.select(0)
	refresh()
	update_notice()

func refresh() -> void:
	if selected_arrow >= paths.size():
		selected_arrow = -1
	for index in range(paths.size()):
		paths[index]["editor_selected"] = index == selected_arrow
		paths[index]["editor_dimmed"] = selected_arrow >= 0 and index != selected_arrow
	arrow_label.text = "Pfeil %d · eigene Farbe" % (selected_arrow + 1) if selected_arrow >= 0 else ("Gesamtansicht · %d Pfeile" % paths.size() if view_mode else "Keine Auswahl · Pfeil anklicken")
	if pages.current_tab == 1 and selected_arrow < 0:
		arrow_label.text = "Flächen bearbeiten · Pfeile bleiben erhalten"
	undo_button.disabled = history.is_empty() or busy
	view_button.button_pressed = view_mode
	arrow_color.disabled = selected_arrow < 0 or busy
	arrow_color.visible = selected_arrow >= 0
	color_placeholder.visible = selected_arrow < 0
	arrow_styles.disabled = selected_arrow < 0 or busy
	for action in arrow_actions: action.disabled = selected_arrow < 0 or busy
	if selected_arrow >= 0:
		arrow_color.color = paths[selected_arrow].color
	regions.clear()
	for part in motif.palettes:
		regions.add_item(motif.names.get(part, "Fläche %d" % part), part)
	if not motif.palettes.has(selected) and not motif.palettes.is_empty():
		selected = motif.palettes.keys()[0]
	regions.select(regions.get_item_index(selected))
	name_field.text = motif.names.get(selected, "")
	title_field.text = motif.get("title", "Eigenes Motiv")
	palette_label.text = "FARBEN FÜR PFEIL %d" % (selected_arrow + 1) if selected_arrow >= 0 else "NEONPALETTE DER FLÄCHE"
	var palette: Array = motif.palettes.get(selected, ["#65e5ff"])
	if selected_arrow >= 0:
		var arrow: Dictionary = paths[selected_arrow]
		palette = arrow.color_style.colors if arrow.has("color_style") else [arrow.color.to_html(false)]
	palette_picker.select(0)
	for index in range(CustomMotif.PALETTES.size()):
		var preset: Array = CustomMotif.PALETTES.values()[index]
		var matches := palette.size() == preset.size()
		for color_index in range(mini(palette.size(), preset.size())):
			matches = matches and Color(palette[color_index]).is_equal_approx(Color(preset[color_index]))
		if matches:
			palette_picker.select(index + 1)
	for index in range(swatches.size()):
		swatches[index].color = Color(palette[index % palette.size()])
	refresh_color_chips()
	canvas.refresh()

func update_notice() -> void:
	var tips := ["Klicke einen Pfeil an und wähle oben seine Farbe. Für Flächen: Nur Fläche auswählen.", "Male neue Flächen auf freie Rasterpunkte. Vorhandene Pfeile bleiben unangetastet.", "Radieren entfernt ungefüllte Rasterpunkte. Einen bestehenden Pfeil löschst du über Auswählen → Löschen.", "Ziehe eine Linie durch die ausgewählte Fläche. Die Trennung erzeugt neue Bereiche ohne Lücke.", "Wähle zuerst die Zielfläche. Klicke dann die Fläche an, die dazugehören soll.", "Klicke einen Pfeil an. Farben & Verläufe bietet eigene Farben und Vorschläge.", "Klicke einen Pfeil oder eine Fläche, um ihre Farbe zu übernehmen.", "Klicke auf eine Farbe der eingeblendeten Bildvorlage.", "Klicke eine Fläche an, um ihren Namen und ihre Palette zu ändern.", "Ziehe einen Pfeil. Die Spitze sitzt am Ende; R dreht sie um. Entf löscht die Auswahl.", "Klicke die senkrechte Spiegelachse an. Pfeile bearbeiten bietet Spiegeln.", "Klicke auf das Ende des ausgewählten Pfeils, das seine Spitze bekommen soll."]
	if view_mode:
		notice.text = "Gesamtansicht: alle Pfeile ohne Hervorhebung. Auswählen oder Zeichnen startet die Bearbeitung."
		return
	var lonely := CustomMotif.isolated(motif)
	notice.text = "%d Rasterpunkte · %d Flächen. %s" % [motif.cells.size(), motif.palettes.size(), tips[tool]]
	if not lonely.is_empty():
		notice.text = "%d zu kleine Einzelpunkte sind rot markiert. Verbinde, verbreitere oder entferne sie vor dem Füllen." % lonely.size()

func select_cell(cell: Vector2i) -> void:
	selected_arrow = -1
	if motif.cells.has(cell):
		selected = motif.cells[cell]
		refresh()
		if is_instance_valid(color_dialogue):
			color_dialogue.target.select(0)
			color_dialogue.refresh_target()
	update_notice()

func paint_cells(cells: Array[Vector2i]) -> void:
	if busy: return
	var occupied := occupied_cells()
	for cell in cells:
		if cell.x < 0 or cell.x >= ArrowPuzzle.COLS or cell.y < 0 or cell.y >= ArrowPuzzle.ROWS:
			continue
		if occupied.has(cell): continue
		if tool == 2:
			motif.cells.erase(cell)
		else:
			motif.cells[cell] = selected
	canvas.refresh()
	update_notice()

func split_cells(barrier: Array[Vector2i]) -> void:
	if not area_edit_allowed(): return
	if CustomMotif.split(motif, selected, barrier):
		# A region boundary must never split the geometry of an existing arrow.
		for arrow in paths:
			var owner: int = motif.cells[ArrowPuzzle.grid(arrow.points[0])]
			for point in arrow.points: motif.cells[ArrowPuzzle.grid(point)] = owner
		refresh()
		update_notice()
	else:
		notice.text = "Die Linie hat die Fläche nicht geteilt. Ziehe vollständig von einer Seite zur anderen."

func merge_cell(cell: Vector2i) -> void:
	if not area_edit_allowed(): return
	var part := int(motif.cells.get(cell, -1))
	if part < 0 or part == selected:
		return
	remember()
	for point in motif.cells:
		if motif.cells[point] == part:
			motif.cells[point] = selected
	motif.palettes.erase(part)
	motif.names.erase(part)
	motif.get("styles", {}).erase(part)
	refresh()
	update_notice()

func new_region() -> void:
	if not area_edit_allowed(): return
	var part := CustomMotif.next_part(motif)
	if part < 0:
		return
	remember()
	motif.palettes[part] = CustomMotif.PALETTES["Wasser"].duplicate()
	motif.names[part] = "Neue Fläche %d" % (part + 1)
	selected = part
	selected_arrow = -1
	view_mode = false
	tool = 1
	tool_picker.select(1)
	refresh()
	update_notice()

func set_palette(colors: Array) -> void:
	if busy:
		return
	if selected_arrow >= 0:
		remember()
		var arrow: Dictionary = paths[selected_arrow]
		arrow.color_style = {"mode": 2, "colors": colors.duplicate(), "strength": 0.55, "bounds": MotifColors.bounds_of_path(arrow.points)}
		arrow.manual_color = true
		arrow.color = Color(colors[1])
		refresh()
		if is_instance_valid(color_dialogue):
			color_dialogue.target.select(1)
			color_dialogue.refresh_target()
		return
	remember()
	motif.palettes[selected] = colors.duplicate()
	motif.get("styles", {}).erase(selected)
	recolor()
	refresh()

func change_color(index: int, color: Color) -> void:
	if busy:
		return
	if selected_arrow >= 0:
		change_arrow_color(color)
		return
	remember_color_change()
	var palette: Array = motif.palettes[selected].duplicate()
	while palette.size() < 3:
		palette.append(palette[-1])
	palette[index] = color.to_html(false)
	motif.palettes[selected] = palette
	if motif.get("styles", {}).has(selected):
		motif.styles[selected].colors = palette.duplicate()
	recolor()
	palette_picker.select(0)
	canvas.refresh()

func recolor() -> void:
	MotifColors.apply(motif, paths)

func open_colors() -> void:
	if is_instance_valid(color_dialogue):
		color_dialogue.target.select(1 if selected_arrow >= 0 else 0)
		color_dialogue.refresh_target()
		color_dialogue.popup_centered(color_dialogue.size)
		return
	color_dialogue = Window.new()
	color_dialogue.set_script(load("res://color_studio.gd"))
	color_dialogue.set("studio", self)
	add_child(color_dialogue)
	color_dialogue.popup_centered(Vector2i(900, 665))

func change_arrow_color(color: Color) -> void:
	if busy or selected_arrow < 0 or selected_arrow >= paths.size():
		return
	remember_color_change()
	paths[selected_arrow].color = color
	paths[selected_arrow].manual_color = true
	paths[selected_arrow].erase("color_style")
	refresh()
	if is_instance_valid(color_dialogue):
		color_dialogue.target.select(1)
		color_dialogue.refresh_target()
	notice.text = "Eigene Farbe für Pfeil %d übernommen. Rückgängig stellt die vorige Farbe wieder her." % (selected_arrow + 1)

func arrow_at(pos: Vector2) -> int:
	var nearest := 8.0
	var found := -1
	for index in range(paths.size()):
		var points: PackedVector2Array = game.rounded_points(paths[index].points)
		for segment in range(points.size() - 1):
			var distance := pos.distance_to(Geometry2D.get_closest_point_to_segment(pos, points[segment], points[segment + 1]))
			if distance < nearest:
				nearest = distance
				found = index
	return found

func select_arrow_at(pos: Vector2) -> void:
	view_mode = false
	selected_arrow = arrow_at(pos)
	if selected_arrow >= 0:
		selected = motif.cells[ArrowPuzzle.grid(paths[selected_arrow].points[0])]
		refresh()
		if is_instance_valid(color_dialogue):
			color_dialogue.target.select(1)
			color_dialogue.refresh_target()
		notice.text = "Pfeil %d ausgewählt. Farben & Verläufe färbt nur diesen Pfeil." % (selected_arrow + 1)
	else:
		refresh()
		notice.text = "Klicke direkt auf einen vorhandenen Pfeil."

func sample_color(pos: Vector2, from_image: bool) -> void:
	var color := Color.TRANSPARENT
	if from_image:
		var fit: Array = motif.get("fit", [])
		if canvas.reference != null and fit.size() == 4:
			var cell := (pos - ArrowPuzzle.ORIGIN) / ArrowPuzzle.CELL
			var uv := (cell - Vector2(fit[0], fit[1])) / Vector2(fit[2], fit[3])
			var image: Image = canvas.reference.get_image()
			if uv.x >= 0 and uv.y >= 0 and uv.x < 1 and uv.y < 1:
				color = image.get_pixel(int(uv.x * image.get_width()), int(uv.y * image.get_height()))
	else:
		var index := arrow_at(pos) if show_paths else -1
		if index >= 0:
			color = MotifColors.color_at(paths[index].color_style, pos) if paths[index].has("color_style") else paths[index].color
		else:
			var part := int(motif.cells.get(ArrowPuzzle.grid(pos), -1))
			if part >= 0:
				color = MotifColors.color_at(motif.styles[part], pos) if motif.get("styles", {}).has(part) else Color(motif.palettes[part][0])
	if color.a < 0.15:
		notice.text = "An dieser Stelle ist keine Farbe vorhanden."
		return
	if not is_instance_valid(color_dialogue):
		open_colors()
	color_dialogue.accept_sample(color)

func clear_paths() -> void:
	paths.clear()
	selected_arrow = -1

func choose_image() -> void:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Bildvorlagen"])
	dialog.current_dir = ProjectSettings.globalize_path("res://examples")
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var loaded := Image.load_from_file(path)
		if loaded == null or loaded.is_empty():
			notice.text = "Das Bild konnte nicht geöffnet werden."
		else:
			source = loaded
			analyze_image()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(800, 600))

func set_busy(value: bool) -> void:
	busy = value
	for action in actions:
		action.disabled = value
	name_field.editable = not value
	title_field.editable = not value
	threshold.editable = not value
	arrow_color.disabled = value or selected_arrow < 0
	arrow_styles.disabled = value or selected_arrow < 0
	for action in arrow_actions: action.disabled = value or selected_arrow < 0
	refresh_color_chips()

func analyze_image(replace_confirmed: bool = false) -> void:
	if busy:
		return
	if source == null:
		notice.text = "Öffne zuerst eine Bildvorlage."
		return
	if not replace_confirmed and not paths.is_empty():
		confirm_replace(func(): analyze_image(true), "Neu erkennen ersetzt die Flächen und die bestehende Pfeilfüllung. Deine letzte Füllung wird zusätzlich gesichert.")
		return
	remember()
	set_busy(true)
	filling = false
	notice.text = "Die Flächen werden erkannt …"
	var image := source.duplicate() as Image
	var detection := detection_mode.selected
	var cutoff := threshold.value
	worker = Thread.new()
	worker.start(func(): return MotifImport.analyze(image, detection, cutoff))

func fill(replace_confirmed: bool = false) -> void:
	if busy: return
	var copy := motif.duplicate(true)
	var existing: Array[Dictionary] = []
	if not replace_confirmed: existing = game.clone_data(paths)
	if not existing.is_empty():
		for cell in occupied_cells(): copy.cells.erase(cell)
	if copy.cells.is_empty():
		notice.text = "Alle Flächen sind bereits gefüllt. Zeichnen ergänzt Details; Neue Fläche schafft zusätzlichen Platz."
		return
	if not CustomMotif.isolated(copy).is_empty():
		notice.text = "Die freien Flächen enthalten rote Einzelpunkte. Verbinde oder verbreitere sie vor dem Füllen. Vorhandene Pfeile bleiben erhalten."
		return
	remember()
	set_busy(true)
	filling = true
	preserving_fill = not existing.is_empty()
	seed_value += 173
	var seed_copy := seed_value
	notice.text = "Freie Flächen werden gefüllt und gemeinsam mit den bestehenden Pfeilen auf Lösbarkeit geprüft …"
	worker = Thread.new()
	worker.start(func():
		for attempt in range(16 if not existing.is_empty() else 1):
			var additions := LevelDesign.refine(6, seed_copy + attempt * 173, 10, 350, copy)
			if additions.is_empty(): continue
			MotifColors.apply(copy, additions)
			var combined: Array[Dictionary] = existing.duplicate(true)
			combined.append_array(additions)
			if ArrowPuzzle.solution(combined).size() == combined.size(): return combined
		return [])

func _process(_delta: float) -> void:
	if player_export_worker != null and not player_export_worker.is_alive():
		var report: Dictionary = player_export_worker.wait_to_finish()
		player_export_worker = null; set_busy(false)
		if report.code == 0: notice.text = "Spieler-APK erstellt: " + str(report.path)
		else: notice.text = "APK konnte nicht erstellt werden. Exportprotokoll: " + str(report.log)
	refresh_language_status()
	draft_clock += _delta
	if draft_clock >= 2.0 and completion_text != null:
		draft_clock = 0.0
		var state := catalog_state()
		if save_button != null: save_button.text = "Entwurf speichern" if catalog_path.is_empty() else ("Speichern •" if state != catalog_baseline else "Speichern")
		if visible and not busy and state != saved_draft_state:
			save_draft(false); saved_draft_state = state
	if worker == null or worker.is_alive():
		return
	var result = worker.wait_to_finish()
	worker = null
	set_busy(false)
	if filling:
		if result.is_empty():
			notice.text = "Noch keine lösbare Ergänzung gefunden. Vorhandene Pfeile bleiben erhalten. Verbreitere die freien Flächen oder ändere blockierende Richtungen."
		else:
			paths = result
			selected_arrow = -1
			view_mode = false
			tool = 0
			tool_picker.select(0)
			pages.set_block_signals(true)
			pages.current_tab = 0
			pages.set_block_signals(false)
			if not preserving_fill: recolor()
			refresh()
			var analysis := LevelDesign.metrics(paths)
			notice.text = "100 %% gefüllt · %d Pfade · %d freie Startzüge · %d Freispielstufen. Übernehmen startet den Spieltest." % [paths.size(), analysis.starts, analysis.depth]
	else:
		if result.is_empty() or result.cells.is_empty():
			notice.text = "Keine geschlossenen Flächen erkannt. Prüfe den Modus oder schließe offene Umrisse in deiner Vorlage."
		else:
			motif = result
			clear_paths()
			selected = motif.palettes.keys()[0]
			activate_tool(8)
			refresh()
			if english.is_empty(): load_motif_languages()
			update_notice()
	canvas.refresh()

func apply() -> void:
	if busy or paths.is_empty():
		notice.text = "Fülle das Motiv zuerst mit Pfeilen."
		return
	if occupied_cells().size() != motif.cells.size():
		notice.text = "Neue Flächen sind noch ungefüllt. Freie Flächen mit Pfeilen füllen ergänzt sie und erhält vorhandene Pfeile."
		return
	if ArrowPuzzle.solution(paths).size() != paths.size():
		notice.text = "Das Puzzle ist noch nicht lösbar. Drehe blockierende Pfeile um oder ändere ihre Form. Dein Entwurf kann trotzdem gespeichert werden."
		return
	game.motif = motif.duplicate(true)
	game.shape_index = 6
	game.arrows = game.clone_data(paths)
	game.draft.clear()
	game.test_editor()
	if catalog_path.is_empty(): close_studio()
	else: hide()

func save_draft(show_notice: bool = true) -> void:
	var file := FileAccess.open(game.storage_prefix + "motif_draft.json", FileAccess.WRITE)
	if file == null:
		notice.text = "Entwurf konnte nicht gespeichert werden."
		return
	var document := CustomMotif.encode(motif)
	document["paths"] = CustomMotif.encode_paths(paths)
	if draft_key.is_empty(): draft_key = "draft_" + str(Time.get_unix_time_from_system()).replace(".", "_") + "_" + str(Time.get_ticks_usec())
	document["workshop"] = workshop_state()
	var directory := drafts_directory()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK:
		var archived := FileAccess.open(directory + draft_key + ".json", FileAccess.WRITE)
		if archived != null: archived.store_string(JSON.stringify(document, "\t")); archived.close()
	file.store_string(JSON.stringify(document, "\t"))
	if show_notice: notice.text = "Entwurf einschließlich Name, Abschlusstext und Pfeilfüllung lokal gespeichert."

func load_draft(replace_confirmed: bool = false) -> void:
	var path: String = game.storage_prefix + "motif_draft.json"
	if not FileAccess.file_exists(path):
		notice.text = "Noch kein Motiv-Entwurf gespeichert."
		return
	var document = JSON.parse_string(FileAccess.get_file_as_string(path))
	var loaded := CustomMotif.decode(document)
	if loaded.is_empty():
		notice.text = "Die Entwurfsdatei ist ungültig."
		return
	var restored: Array[Dictionary] = []
	if document.get("paths") is Array and not document.paths.is_empty():
		restored = CustomMotif.decode_paths(document.paths, loaded, false)
		if restored.is_empty():
			notice.text = "Die gespeicherte Pfeilfüllung ist ungültig."
			return
	if not replace_confirmed and not paths.is_empty():
		confirm_replace(func(): load_draft(true), "Laden ersetzt den aktuellen Entwurf. Deine letzte Füllung wird zusätzlich gesichert.")
		return
	catalog_path = ""
	catalog_document = {}
	completion_text.text = ""; completion_kind.text = "Ein kleiner Gedanke"; completion_source.text = ""; completion_url.text = ""
	remember()
	motif = loaded
	paths = restored
	source = null
	show_overview()
	restore_workshop_state(document.get("workshop", {}))

func drafts_directory() -> String:
	return game.storage_prefix + "workshop_drafts/"

func workshop_state() -> Dictionary:
	return {"path": catalog_path, "document": catalog_document, "hashes": catalog_hashes, "baseline": catalog_baseline, "text": completion_text.text, "kind": completion_kind.text, "source": completion_source.text, "url": completion_url.text, "root": catalog_root, "draft_key": draft_key, "english": english, "reviewed_german": reviewed_german}

func restore_workshop_state(state: Dictionary) -> void:
	draft_key = state.get("draft_key", "")
	catalog_path = state.get("path", ""); catalog_document = state.get("document", {})
	catalog_hashes = state.get("hashes", {}); catalog_baseline = state.get("baseline", "")
	completion_text.text = state.get("text", ""); completion_kind.text = state.get("kind", "Ein kleiner Gedanke")
	completion_source.text = state.get("source", ""); completion_url.text = state.get("url", "")
	catalog_root = state.get("root", "res://")
	load_motif_languages()
	if state.get("english") is Dictionary: english=state.english.duplicate(true); reviewed_german=state.get("reviewed_german",{}).duplicate(true)
	refresh_language_status()

func close_studio() -> void:
	if busy:
		notice.text = "Die Berechnung läuft noch. Das Fenster kann danach geschlossen werden."
		return
	if not catalog_path.is_empty() and catalog_state() != catalog_baseline:
		var dialog := ConfirmationDialog.new()
		dialog.title = "Ungespeicherte Katalogänderungen"
		dialog.dialog_text = "Deine Änderungen sind noch nicht im Katalog gespeichert. Werkstatt schließen und als Entwurf behalten?"
		dialog.ok_button_text = "Als Entwurf behalten und schließen"
		add_child(dialog)
		dialog.confirmed.connect(finish_close_studio)
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered()
		return
	finish_close_studio()

func finish_close_studio() -> void:
	save_draft(false)
	game.studio_draft = {"motif": motif.duplicate(true), "paths": game.clone_data(paths), "workshop": workshop_state()}
	game.studio = null
	queue_free()

func _exit_tree() -> void:
	if player_export_worker != null and player_export_worker.is_started(): player_export_worker.wait_to_finish()
	if worker != null and worker.is_started():
		worker.wait_to_finish()

func open_arrow_tools() -> void:
	if is_instance_valid(arrow_tools):
		arrow_tools.queue_free()
	arrow_tools = Window.new()
	arrow_tools.title = "Pfeil spiegeln"
	arrow_tools.size = Vector2i(440, 235)
	arrow_tools.unresizable = true
	add_child(arrow_tools)
	arrow_tools.close_requested.connect(arrow_tools.hide)
	var box := VBoxContainer.new()
	box.position = Vector2(20, 15)
	box.size = Vector2(400, 200)
	box.add_theme_constant_override("separation", 10)
	box.theme = game.panel.theme
	arrow_tools.add_child(box)
	add_label(box, "SENKRECHTE SPIEGELACHSE · 14 = MOTIVMITTE")
	var axis := SpinBox.new()
	axis.min_value = 0; axis.max_value = ArrowPuzzle.COLS - 1
	axis.step = 0.5; axis.value = mirror_axis
	axis.value_changed.connect(func(value: float): mirror_axis = value; canvas.refresh())
	box.add_child(axis)
	add_row_button(box, "Achse im Motiv anklicken", func():
		activate_tool(10); arrow_tools.hide())
	add_row_button(box, "Spiegelkopie ergänzen", func():
		mirror_arrow(); arrow_tools.hide())
	add_row_button(box, "Abbrechen", arrow_tools.hide)
	arrow_tools.popup_centered()

func occupied_cells() -> Dictionary:
	var used := {}
	for arrow in paths:
		for point in arrow.points:
			used[ArrowPuzzle.grid(point)] = true
	return used

func drawing_valid(cells: Array[Vector2i]) -> bool:
	if cells.size() < 2:
		return false
	var used := occupied_cells()
	var visited := {}
	for index in range(cells.size()):
		var cell := cells[index]
		if not canvas.valid(cell) or used.has(cell) or visited.has(cell):
			return false
		if index > 0 and absi(cell.x - cells[index - 1].x) + absi(cell.y - cells[index - 1].y) != 1:
			return false
		visited[cell] = true
	return true

func extend_drawing(cell: Vector2i) -> void:
	if drawn_cells.is_empty():
		drawn_cells.append(cell)
	else:
		var current := drawn_cells[-1]
		while current != cell:
			var difference := cell - current
			if absi(difference.x) >= absi(difference.y):
				current.x += signi(difference.x)
			else:
				current.y += signi(difference.y)
			if drawn_cells.size() > 1 and current == drawn_cells[-2]:
				drawn_cells.pop_back()
			else:
				drawn_cells.append(current)
	canvas.refresh()

func add_drawn_arrow(cells: Array[Vector2i], appearance: Dictionary = {}) -> bool:
	if busy or not drawing_valid(cells):
		notice.text = "Der Pfeil überlappt einen vorhandenen Pfeil, sich selbst oder den Rand. Bitte an einer freien Stelle zeichnen."
		return false
	var part := CustomMotif.next_part(motif)
	if part < 0:
		notice.text = "Keine weitere Fläche verfügbar."
		return false
	remember()
	var color: Color = appearance.get("color", Color(motif.palettes.get(selected, ["#65e5ff"])[0]))
	var points := PackedVector2Array()
	for cell in cells:
		points.append(ArrowPuzzle.pixel(cell))
		motif.cells[cell] = part
	motif.palettes[part] = [color.to_html(false), color.to_html(false), color.to_html(false)]
	motif.names[part] = "Eigener Pfeil %d" % (paths.size() + 1)
	var arrow := ArrowPuzzle.make_arrow(points, color)
	MotifColors.copy_appearance(appearance, arrow)
	arrow.manual_color = true
	if arrow.has("color_style"):
		arrow.color_style.bounds = MotifColors.bounds_of_path(points)
	paths.append(arrow)
	selected_arrow = paths.size() - 1
	selected = part
	refresh()
	edit_status("Pfeil ergänzt. R dreht die Spitze um; seine Farbe kannst du rechts ändern.")
	return true

func finish_drawing() -> void:
	var cells := drawn_cells.duplicate()
	drawn_cells.clear()
	if add_drawn_arrow(cells):
		tool = 0
		tool_picker.select(tool)
	canvas.refresh()

func delete_arrow() -> void:
	if busy or selected_arrow < 0 or selected_arrow >= paths.size():
		notice.text = "Wähle zuerst den Pfeil aus, den du löschen möchtest."
		return
	remember()
	for point in paths[selected_arrow].points:
		motif.cells.erase(ArrowPuzzle.grid(point))
	paths.remove_at(selected_arrow)
	selected_arrow = -1
	refresh()
	edit_status("Pfeil gelöscht. Die freie Stelle kannst du neu zeichnen. Rückgängig stellt ihn wieder her.")

func reverse_arrow() -> void:
	if busy or selected_arrow < 0 or selected_arrow >= paths.size():
		notice.text = "Wähle zuerst einen Pfeil aus."
		return
	remember()
	var arrow: Dictionary = paths[selected_arrow]
	arrow.points.reverse()
	arrow.erase("draw_points")
	refresh()
	edit_status("Pfeilspitze sitzt jetzt am anderen Ende.")

func mirror_arrow() -> void:
	if busy or selected_arrow < 0 or selected_arrow >= paths.size():
		notice.text = "Wähle zuerst den Pfeil aus, den du spiegeln möchtest."
		return
	var source_arrow: Dictionary = paths[selected_arrow]
	var cells: Array[Vector2i] = []
	for point in source_arrow.points:
		var cell := ArrowPuzzle.grid(point)
		cells.append(Vector2i(roundi(2.0 * mirror_axis - cell.x), cell.y))
	if add_drawn_arrow(cells, source_arrow):
		edit_status("Spiegelbild mit gleicher Form und Farbe ergänzt.")

func edit_status(message: String) -> void:
	var solvable := ArrowPuzzle.solution(paths).size() == paths.size()
	notice.text = message + (" Puzzle lösbar." if solvable else " Achtung: noch nicht lösbar — Richtung oder Form anpassen.")

func choose_arrow_head(pos: Vector2) -> void:
	if selected_arrow < 0 or selected_arrow >= paths.size():
		notice.text = "Wähle zuerst einen Pfeil aus."
		return
	var points: PackedVector2Array = paths[selected_arrow].points
	if pos.distance_to(points[0]) <= 8.0:
		reverse_arrow()
	elif pos.distance_to(points[-1]) <= 8.0:
		edit_status("Pfeilspitze bleibt an diesem Ende.")
	else:
		notice.text = "Klicke direkt auf eines der beiden Enden des ausgewählten Pfeils."
		return
	tool = 0
	tool_picker.select(tool)
	canvas.refresh()

func activate_tool(index: int) -> void:
	if busy: return
	if index in [1, 2, 3, 4] and not area_edit_allowed():
		tool_picker.select(tool)
		return
	view_mode = false
	tool = index
	tool_picker.select(tool)
	show_paths = true
	if index in [1, 2, 3, 4, 8, 9]:
		selected_arrow = -1
	if index in [1, 2, 3, 4, 8] and pages.current_tab != 1:
		pages.set_block_signals(true)
		pages.current_tab = 1
		pages.set_block_signals(false)
	if index in [0, 5, 9, 10, 11] and pages.current_tab != 0:
		pages.set_block_signals(true)
		pages.current_tab = 0
		pages.set_block_signals(false)
	refresh()
	update_notice()

func show_overview() -> void:
	if busy: return
	view_mode = true
	selected_arrow = -1
	tool = 0
	tool_picker.select(0)
	drawn_cells.clear()
	canvas.dragging = false
	show_paths = true
	if is_instance_valid(color_dialogue): color_dialogue.hide()
	if is_instance_valid(arrow_tools): arrow_tools.hide()
	refresh()
	update_notice()

func area_edit_allowed() -> bool:
	return not busy

func confirm_replace(action: Callable, message: String) -> void:
	if is_instance_valid(replace_dialog):
		replace_dialog.grab_focus()
		return
	replace_dialog = ConfirmationDialog.new()
	replace_dialog.title = "Bestehende Füllung ersetzen?"
	replace_dialog.dialog_text = message + "\nAbbrechen erhält den aktuellen Entwurf."
	replace_dialog.ok_button_text = "Füllung ersetzen"
	replace_dialog.cancel_button_text = "Abbrechen"
	add_child(replace_dialog)
	var dialog := replace_dialog
	dialog.confirmed.connect(func():
		var saved := save_backup()
		replace_dialog = null
		dialog.queue_free()
		if saved: action.call()
		else: notice.text = "Sicherung konnte nicht gespeichert werden. Dein aktueller Entwurf bleibt unverändert.")
	dialog.canceled.connect(func(): replace_dialog = null; dialog.queue_free())
	dialog.popup_centered(Vector2i(560, 160))


func save_backup() -> bool:
	var document := CustomMotif.encode(motif)
	document["paths"] = CustomMotif.encode_paths(paths)
	document["workshop"] = workshop_state()
	var file := FileAccess.open(game.storage_prefix + "editor_backup.json", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(document))
	file.flush()
	return file.get_error() == OK

func restore_backup() -> void:
	if busy: return
	var document = JSON.parse_string(FileAccess.get_file_as_string(game.storage_prefix + "editor_backup.json")) if FileAccess.file_exists(game.storage_prefix + "editor_backup.json") else null
	var loaded := CustomMotif.decode(document)
	if loaded.is_empty():
		notice.text = "Noch keine gesicherte Füllung vorhanden."
		return
	var restored := CustomMotif.decode_paths(document.get("paths", []), loaded, false)
	if restored.is_empty():
		notice.text = "Die Sicherung enthält keine gültige Pfeilfüllung."
		return
	remember()
	motif = loaded
	paths = restored
	show_overview()
	restore_workshop_state(document.get("workshop", {}))
	notice.text = "Die letzte ersetzte Füllung ist wiederhergestellt. Rückgängig bringt dich zum vorigen Entwurf."

func load_recent_colors() -> void:
	var path: String = game.storage_prefix + "editor_colors.json"
	if not FileAccess.file_exists(path): return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Array: return
	for value in data:
		if value is String and Color.html_is_valid(value) and recent_colors.size() < 10:
			recent_colors.append(Color(value))

func remember_color(color: Color) -> void:
	color.a = 1.0
	for index in range(recent_colors.size() - 1, -1, -1):
		if recent_colors[index].is_equal_approx(color): recent_colors.remove_at(index)
	recent_colors.push_front(color)
	if recent_colors.size() > 10: recent_colors.resize(10)
	var data: Array[String] = []
	for value in recent_colors: data.append(value.to_html(false))
	var file := FileAccess.open(game.storage_prefix + "editor_colors.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(data))
	refresh_color_chips()

func refresh_color_chips() -> void:
	if recent_row == null: return
	build_color_chips(recent_row, recent_colors)
	var colors: Array[Color] = []
	for part in motif.palettes:
		for hex in motif.palettes[part]:
			var color := Color(hex)
			if not colors.has(color) and colors.size() < 10: colors.append(color)
	build_color_chips(suggested_row, colors)

func build_color_chips(row: HBoxContainer, colors: Array[Color]) -> void:
	for child in row.get_children():
		row.remove_child(child); child.queue_free()
	if colors.is_empty():
		add_label(row, "Noch keine Farben gewählt")
		return
	for color in colors:
		var button := Button.new()
		button.custom_minimum_size = Vector2(30, 30)
		button.tooltip_text = "#" + color.to_html(false)
		button.disabled = selected_arrow < 0 or busy
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(6)
		style.set_border_width_all(1)
		style.border_color = Color("#819bb2")
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(func():
			change_arrow_color(color); remember_color(color))
		row.add_child(button)

func begin_color_edit() -> void:
	color_session = true
	color_snapshot_taken = false

func remember_color_change() -> void:
	if not color_session or not color_snapshot_taken:
		remember()
		color_snapshot_taken = true

func end_color_edit(color: Color) -> void:
	color_session = false
	if color_snapshot_taken: remember_color(color)
	color_snapshot_taken = false

func choose_save_document() -> void:
	if busy: return
	var dialog := FileDialog.new()
	dialog.title = "Motiventwurf speichern"
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.filters = PackedStringArray(["*.json ; arrow.joy Motiventwurf"])
	dialog.current_dir = ProjectSettings.globalize_path("res://examples")
	dialog.current_file = str(motif.get("title", "Mein Motiv")).validate_filename() + ".json"
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var document := CustomMotif.encode(motif)
		document["paths"] = CustomMotif.encode_paths(paths)
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			notice.text = "Der Entwurf konnte nicht gespeichert werden."
		else:
			file.store_string(JSON.stringify(document, "\t"))
			save_draft()
			notice.text = "Motiv und alle Pfeile gespeichert: " + path.get_file()
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(850, 650))

func choose_open_document() -> void:
	if busy: return
	var dialog := FileDialog.new()
	dialog.title = "Vorhandenes Motiv, Level oder Bild öffnen"
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.filters = PackedStringArray(["*.json,*.png,*.jpg,*.jpeg,*.webp ; Motive, Levels und Bilder"])
	dialog.current_dir = ProjectSettings.globalize_path("res://examples")
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		if path.get_extension().to_lower() == "json":
			open_document(path)
		else:
			var image := Image.load_from_file(path)
			if image == null or image.is_empty():
				notice.text = "Das Bild konnte nicht geöffnet werden."
			else:
				var action := func():
					catalog_path = ""; catalog_document = {}; draft_key = ""; completion_text.text = ""; completion_kind.text = "Ein kleiner Gedanke"; completion_source.text = ""; completion_url.text = ""
					english.clear(); reviewed_german.clear()
					source = image; analyze_image(true)
				if paths.is_empty(): action.call()
				else: confirm_replace(action, "Ein anderes Bild ersetzt den aktuellen Entwurf. Deine letzte Füllung wird zusätzlich gesichert.")
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(850, 650))

func open_document(path: String, replace_confirmed: bool = false) -> bool:
	if busy or not FileAccess.file_exists(path): return false
	var document = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not document is Dictionary:
		notice.text = "Die Datei enthält keinen gültigen Motiventwurf."
		return false
	if document.has("paths") and not document.paths is Array:
		notice.text = "Die Pfeildaten sind ungültig. Dein aktueller Entwurf bleibt erhalten."
		return false
	var loaded: Dictionary
	if document.has("cells"):
		loaded = CustomMotif.decode(document)
	elif document.get("shape") is int or document.get("shape") is float:
		var shape := int(document.shape)
		if float(document.shape) != shape or shape < 0 or shape > 6: return false
		loaded = CustomMotif.decode(document.get("motif")) if shape == 6 else CustomMotif.from_shape(shape)
	else:
		return false
	if loaded.is_empty():
		notice.text = "Die Datei enthält keine gültigen Flächen."
		return false
	var restored: Array[Dictionary] = []
	if document.get("paths") is Array and not document.paths.is_empty():
		restored = CustomMotif.decode_paths(document.paths, loaded, false)
		if restored.is_empty():
			notice.text = "Die gespeicherten Pfeile sind ungültig. Dein aktueller Entwurf bleibt erhalten."
			return false
	if not replace_confirmed and not paths.is_empty():
		confirm_replace(func(): open_document(path, true), "Öffnen ersetzt den aktuellen Entwurf. Deine letzte Füllung wird zusätzlich gesichert.")
		return true
	draft_key = ""
	catalog_path = ""
	catalog_document = {}
	completion_text.text = ""; completion_kind.text = "Ein kleiner Gedanke"; completion_source.text = ""; completion_url.text = ""
	remember()
	motif = loaded
	paths = restored
	source = null
	show_overview()
	load_motif_languages()
	notice.text = "Motiv geöffnet: " + path.get_file() + ". Auswählen bearbeitet Pfeile; Vorlage & Flächen ergänzt neue Flächen."
	return true

func choose_catalog() -> void:
	if busy:
		notice.text = "Die Berechnung läuft noch. Danach kannst du den Katalog öffnen."
		return
	var picker := Window.new()
	picker.set_script(load("res://catalog_workshop_browser.gd"))
	picker.studio = self
	picker.theme = game.panel.theme
	add_child(picker)
	picker.popup_centered()

func workshop_store() -> RefCounted:
	var store: RefCounted = load("res://catalog_workshop_store.gd").new()
	store.root = catalog_root
	return store

func catalog_changed() -> void:
	AppLanguage.reload_motifs()
	load("res://discoveries.gd").entries = {}
	JourneyProgress.definition = {}
	game.discover_levels()
	if not catalog_path.is_empty():
		if FileAccess.file_exists(catalog_root + catalog_path):
			catalog_document = JSON.parse_string(FileAccess.get_file_as_string(catalog_root + catalog_path))
			catalog_hashes = catalog_fingerprints()
		else: catalog_path = ""; catalog_document = {}; notice.text = "Dieses Motiv liegt jetzt im Papierkorb. Der Entwurf bleibt geöffnet."

func new_workshop_motif() -> void:
	confirm_replace(func():
		catalog_path = ""; catalog_document = {}; draft_key = ""; history.clear()
		motif = CustomMotif.from_shape(0); motif.cells.clear(); motif.title = "Neues Motiv"
		paths.clear(); source = null; completion_text.text = ""; completion_kind.text = "Ein kleiner Gedanke"; completion_source.text = ""; completion_url.text = ""
		show_overview(); load_motif_languages(); activate_tool(1); notice.text = "Zeichne deine Flächen oder öffne eine Bildvorlage. Danach freie Flächen mit Pfeilen füllen.", "Neues Motiv beginnen? Dein aktueller Entwurf wird vorher gesichert.")

func choose_workshop_target(action: Callable, initial_path: String = "") -> void:
	var state: Dictionary = workshop_store().load_state()
	var initial := {}
	var requested := initial_path if not initial_path.is_empty() else "res://" + catalog_path
	for assignment in state.taxonomy.assignments:
		if assignment.path == requested: initial = assignment
	var dialog := Window.new(); dialog.title = "Motiv einordnen"; dialog.size = Vector2i(640, 360); add_child(dialog)
	var box := VBoxContainer.new(); box.position = Vector2(20, 20); box.size = Vector2(600, 320); box.add_theme_constant_override("separation", 8); dialog.add_child(box)
	add_label(box, "THEMENWELT")
	var world_picker := OptionButton.new(); world_picker.fit_to_longest_item = false; world_picker.custom_minimum_size.y = 36; box.add_child(world_picker)
	add_label(box, "KATEGORIE")
	var category_picker := OptionButton.new(); category_picker.fit_to_longest_item = false; category_picker.custom_minimum_size.y = 36; box.add_child(category_picker)
	add_label(box, "SPIELBARE SAMMLUNG")
	var group_picker := OptionButton.new(); group_picker.fit_to_longest_item = false; group_picker.custom_minimum_size.y = 36; box.add_child(group_picker)
	var accept := Button.new(); accept.text = "Zuordnung übernehmen"; accept.custom_minimum_size.y = 38; box.add_child(accept)
	var populate_groups := func():
		group_picker.clear()
		if world_picker.selected < 0 or category_picker.selected < 0: accept.disabled = true; return
		var world: Dictionary = state.taxonomy.worlds[world_picker.selected]
		var category: Dictionary = world.categories[category_picker.selected]
		for group in category.get("playable_groups", []):
			if not state.journey.groups.has(group): continue
			group_picker.add_item(str(state.journey.groups[group].title))
			group_picker.set_item_metadata(group_picker.item_count - 1, {"world": world.id, "world_title": world.title, "category": category.title, "category_id": category.id, "group": group})
		accept.disabled = group_picker.item_count == 0
	var populate_categories := func():
		category_picker.clear()
		for category in state.taxonomy.worlds[world_picker.selected].categories:
			category_picker.add_item(str(category.title) + " · " + str(category.get("existing_count", 0)) + " Motive")
		populate_groups.call()
	for world in state.taxonomy.worlds: world_picker.add_item(world.title)
	world_picker.item_selected.connect(func(_index): populate_categories.call())
	category_picker.item_selected.connect(func(_index): populate_groups.call())
	populate_categories.call()
	if not initial.is_empty():
		for index in state.taxonomy.worlds.size():
			if state.taxonomy.worlds[index].id == initial.world: world_picker.select(index); populate_categories.call()
		for index in state.taxonomy.worlds[world_picker.selected].categories.size():
			if state.taxonomy.worlds[world_picker.selected].categories[index].id == initial.category_id: category_picker.select(index); populate_groups.call()
		for index in group_picker.item_count:
			if group_picker.get_item_metadata(index).group == initial.group: group_picker.select(index)
	accept.pressed.connect(func():
		if group_picker.selected >= 0: action.call(group_picker.get_item_metadata(group_picker.selected)); dialog.queue_free())
	dialog.close_requested.connect(dialog.queue_free); dialog.popup_centered()

func publish_catalog() -> void:
	if busy: return
	var document := {"version": 2, "title": title_field.text.strip_edges(), "shape": 6, "motif": CustomMotif.encode(motif), "paths": CustomMotif.encode_paths(paths)}
	var discovery := {"kind": completion_kind.text.strip_edges(), "text": completion_text.text.strip_edges()}
	if str(discovery.kind).is_empty(): discovery.kind = "Ein kleiner Gedanke"
	if discovery.kind != "Ein kleiner Gedanke" and (completion_source.text.strip_edges().is_empty() or not completion_url.text.begins_with("https://")):
		notice.text = "Für Fakten und Zitate bitte Quelle und https://-Link angeben."; return
	if not completion_source.text.is_empty(): discovery.source = completion_source.text.strip_edges()
	if not completion_url.text.is_empty(): discovery.url = completion_url.text.strip_edges()
	var store := workshop_store()
	var expected: Dictionary = store.fingerprints()
	choose_workshop_target(func(target: Dictionary):
		var path: String = store.publish(document, discovery, target, expected, language_record())
		if path.is_empty(): notice.text = store.error
		else: catalog_changed(); bind_catalog(path); notice.text = "Neues Motiv im Katalog hinzugefügt: " + title_field.text)

func bind_catalog(path: String) -> void:
	path = path.trim_prefix("res://")
	var store := workshop_store()
	if not store.recover(): notice.text = store.error; return
	if not open_document(catalog_root + path, true): return
	catalog_path = path
	draft_key = "catalog_" + path.sha256_text().left(24)
	history.clear()
	catalog_document = JSON.parse_string(FileAccess.get_file_as_string(catalog_root + path))
	var discovery: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(catalog_root + "collections/discoveries.json")).entries.get("res://" + path, {})
	completion_text.text = discovery.get("text", "")
	completion_kind.text = discovery.get("kind", "Ein kleiner Gedanke")
	completion_source.text = discovery.get("source", "")
	completion_url.text = discovery.get("url", "")
	load_motif_languages()
	catalog_hashes = catalog_fingerprints()
	catalog_baseline = catalog_state()
	notice.text = "Katalogmotiv geöffnet. Speichern aktualisiert dieses Rätsel an seinem bisherigen Platz."

func catalog_state() -> String:
	return JSON.stringify([CustomMotif.encode(motif), CustomMotif.encode_paths(paths), title_field.text, completion_text.text, completion_kind.text, completion_source.text, completion_url.text, english, reviewed_german])

func catalog_fingerprints() -> Dictionary:
	var result := {}
	for path in [catalog_path, "collections/catalog.json", "collections/taxonomy.json", "collections/discoveries.json", "collections/editor_overrides.json", "collections/workshop_manifest.json", "collections/workshop_trash.json", "collections/journey.json", "localization/motifs.json", "localization/en.json"]:
		result[path] = FileAccess.get_sha256(catalog_root + path) if FileAccess.file_exists(catalog_root + path) else ""
	return result

func save_catalog() -> void:
	if catalog_path.is_empty():
		notice.text = "Öffne zuerst ein Motiv über Katalogmotiv auswählen."
		return
	if catalog_hashes != catalog_fingerprints():
		notice.text = "Die Katalogdateien wurden inzwischen geändert. Bitte das Motiv neu öffnen; nichts wurde überschrieben."
		return
	var encoded := CustomMotif.encode_paths(paths)
	var checked := CustomMotif.decode_paths(encoded, motif)
	if checked.is_empty() or not LevelDesign.metrics(checked).get("solvable", false):
		notice.text = "Nicht gespeichert: Alle Flächen müssen gültig mit lösbaren Pfeilen gefüllt sein."
		return
	var new_title := title_field.text.strip_edges()
	var text := completion_text.text.strip_edges()
	if new_title.is_empty() or text.is_empty() or text.length() > 600 or str(english.get("text","")).length()>600:
		notice.text = "Name und deutscher Abschlusstext sind erforderlich. Beide Abschlusstexte dürfen höchstens 600 Zeichen haben."
		return
	var kind := completion_kind.text.strip_edges()
	if kind.is_empty(): kind = "Ein kleiner Gedanke"
	if kind != "Ein kleiner Gedanke" and (completion_source.text.strip_edges().is_empty() or not completion_url.text.begins_with("https://")):
		notice.text = "Für Fakten und Zitate bitte Quelle und einen https://-Link angeben."
		return
	var document := catalog_document.duplicate(true)
	document.title = new_title
	document.shape = 6
	document.motif = CustomMotif.encode(motif)
	document.paths = encoded
	document.design = LevelDesign.metrics(checked)
	if JSON.stringify(catalog_document.get("paths", []).map(func(a): return a.points)) != JSON.stringify(encoded.map(func(a): return a.points)):
		document.erase("compatible_color_checkpoints")
	else:
		var geometry_paths: Array[String] = []
		for arrow in encoded:
			var points: Array[String] = []
			for point in arrow.points: points.append("%d,%d" % [point[0], point[1]])
			geometry_paths.append(";".join(points))
		var predecessor := {"fingerprint": catalog_hashes[catalog_path], "geometry": "|".join(geometry_paths).sha256_text()}
		if not document.has("compatible_color_checkpoints"): document.compatible_color_checkpoints = []
		if not document.compatible_color_checkpoints.has(predecessor): document.compatible_color_checkpoints.append(predecessor)
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(catalog_root + "collections/catalog.json"))
	for entry in catalog.levels:
		if str(entry.path).trim_prefix("res://") == catalog_path:
			entry.title = new_title
			entry.design = document.design
	var taxonomy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(catalog_root + "collections/taxonomy.json"))
	for entry in taxonomy.assignments:
		if str(entry.path).trim_prefix("res://") == catalog_path: entry.title = new_title
	var discoveries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(catalog_root + "collections/discoveries.json"))
	var discovery := {"kind": kind, "text": text}
	if not completion_source.text.is_empty(): discovery.source = completion_source.text.strip_edges()
	if not completion_url.text.is_empty(): discovery.url = completion_url.text.strip_edges()
	discoveries.entries["res://" + catalog_path] = discovery
	var overrides := {"version": 1, "entries": {}}
	if FileAccess.file_exists(catalog_root + "collections/editor_overrides.json"):
		overrides = JSON.parse_string(FileAccess.get_file_as_string(catalog_root + "collections/editor_overrides.json"))
	var protection: Dictionary = overrides.entries.get(catalog_path, {})
	protection.merge({"protected": true, "title": new_title, "discovery": discovery}, true)
	overrides.entries[catalog_path] = protection
	var updates := {catalog_path: document, "collections/catalog.json": catalog, "collections/taxonomy.json": taxonomy, "collections/discoveries.json": discoveries, "collections/editor_overrides.json": overrides}
	var language_helper:RefCounted=load("res://workshop_language_service.gd").new(); language_helper.root=catalog_root
	updates[language_helper.FILE]=language_helper.with_record(catalog_path,language_record())
	var store := workshop_store()
	if not store.commit(updates, catalog_hashes):
		notice.text = store.error
		return
	catalog_document = document
	catalog_hashes = catalog_fingerprints()
	catalog_baseline = catalog_state()
	AppLanguage.reload_motifs()
	load("res://discoveries.gd").entries = {}
	game.discover_levels()
	notice.text = "Im Katalog gespeichert: " + new_title + ". Deutsch und Englisch bleiben am selben Motivplatz."
	if not language_issues().is_empty(): notice.text += " Englisch bitte vor dem APK-Bau vervollständigen oder prüfen."

func choose_player_export() -> void:
	if busy: return
	if not catalog_path.is_empty() and catalog_state()!=catalog_baseline:
		notice.text="Bitte das geöffnete Motiv zuerst speichern. Der APK-Bau übernimmt die gespeicherten Fassungen."; pages.current_tab=2; return
	if not check_export_languages(): return
	if catalog_root != "res://": notice.text = "APK-Export ist nur für das tatsächliche Projekt verfügbar."; return
	var python := OS.get_environment("USERPROFILE").path_join(".cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe")
	if not FileAccess.file_exists(python): notice.text = "Die Python-Laufzeit für den APK-Export wurde nicht gefunden."; return
	var dialog := FileDialog.new(); dialog.title = "Spieler-APK erstellen"; dialog.access = FileDialog.ACCESS_FILESYSTEM; dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE; dialog.filters = PackedStringArray(["*.apk ; Android-Spieler"])
	dialog.current_dir = ProjectSettings.globalize_path("res://.."); dialog.current_file = "arrow.joy-S22.apk"; add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var helper := ProjectSettings.globalize_path("res://tools/build_player.py")
		var godot := OS.get_executable_path()
		var log_path := ProjectSettings.globalize_path("res://work/player-export.log")
		DirAccess.make_dir_recursive_absolute(log_path.get_base_dir())
		set_busy(true); notice.text = "Spieler-APK wird gebaut. Gespeicherte Katalogänderungen werden übernommen; Entwürfe bleiben privat."
		player_export_worker = Thread.new()
		player_export_worker.start(func():
			var output: Array = []
			var result := OS.execute(python, [helper, "--godot", godot, "--output", path], output, true, false)
			var log_file := FileAccess.open(log_path, FileAccess.WRITE)
			if log_file != null: log_file.store_string("\n".join(output)); log_file.close()
			return {"code": result, "path": path, "log": log_path})
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free); dialog.popup_centered(Vector2i(850, 650))

func german_control(field: String) -> Control:
	return {"title":title_field,"text":completion_text,"kind":completion_kind,"source":completion_source}[field]

func german_fields() -> Dictionary:
	var kind:=completion_kind.text.strip_edges()
	return {"title":title_field.text.strip_edges(),"text":completion_text.text.strip_edges(),"kind":kind if not kind.is_empty() else "Ein kleiner Gedanke","source":completion_source.text.strip_edges()}

func language_record() -> Dictionary:
	var translated:=english.duplicate(true)
	for field in translated: translated[field]=str(translated[field]).strip_edges()
	return {"de":german_fields(),"en":translated,"reviewed_de":reviewed_german.duplicate(true)}

func language_issues() -> Array:
	var helper:RefCounted=load("res://workshop_language_service.gd").new()
	return helper.issues(language_record(),german_fields())

func load_motif_languages() -> void:
	var helper:RefCounted=load("res://workshop_language_service.gd").new(); helper.root=catalog_root
	var record:Dictionary=helper.load_record(catalog_path,german_fields())
	english=record.en; reviewed_german=record.reviewed_de
	refresh_language_status()

func mark_english_reviewed() -> void:
	var german:=german_fields()
	for field in english:
		if not str(english[field]).strip_edges().is_empty(): reviewed_german[field]=german[field]
	refresh_language_status()

func refresh_language_status() -> void:
	if language_status==null: return
	var problems:=language_issues()
	language_status.text="Deutsch & Englisch bereit" if problems.is_empty() else " · ".join(problems.map(func(item):return item.message))
	language_status.modulate=Color("#8ff0c3") if problems.is_empty() else Color("#ffd17c")

func open_text_editor() -> void:
	if busy: return
	if is_instance_valid(text_editor): text_editor.popup_centered(); return
	text_editor=Window.new(); text_editor.set_script(load("res://workshop_text_editor.gd"))
	text_editor.studio=self; add_child(text_editor); text_editor.popup_centered()

func check_export_languages() -> bool:
	var helper:RefCounted=load("res://workshop_language_service.gd").new(); helper.root=catalog_root
	var problems:Array=helper.catalog_issues()
	if problems.is_empty(): return true
	var dialog:=AcceptDialog.new(); dialog.title="Englische Texte noch offen"
	dialog.dialog_text="Bei %d Motiven fehlt Englisch oder eine Änderung muss geprüft werden. Öffne diese Motive und nutze ›Deutsch & Englisch bearbeiten‹.

" % problems.size()
	for item in problems.slice(0,8): dialog.dialog_text+=item.title+": "+" · ".join(item.issues.map(func(issue):return issue.message))+"
"
	dialog.ok_button_text="Später prüfen"; add_child(dialog)
	dialog.add_button("Offene Motive öffnen", false, "open_pending")
	dialog.custom_action.connect(func(action:String):
		if action != "open_pending": return
		dialog.hide(); dialog.queue_free()
		choose_catalog()
		var browser:Window=get_child(get_child_count()-1)
		browser.pending_filter.button_pressed=true)
	dialog.confirmed.connect(dialog.queue_free); dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(750,440))
	notice.text="APK noch nicht gebaut: %d Motive benötigen englische Texte oder eine Prüfung." % problems.size()
	return false
