extends Window

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
var source: Image
var worker: Thread
var filling := false
var seed_value := 8900

func _ready() -> void:
	title = "ArrowWay · Motivwerkstatt"
	size = Vector2i(1040, 800)
	min_size = size
	unresizable = true
	close_requested.connect(close_studio)
	var root := Control.new()
	root.size = Vector2(size)
	root.theme = game.panel.theme
	add_child(root)
	var background := ColorRect.new()
	background.size = root.size
	background.color = Color("#080e19")
	root.add_child(background)
	var heading := Label.new()
	heading.text = "MOTIVWERKSTATT"
	heading.position = Vector2(25, 18)
	heading.add_theme_font_size_override("font_size", 24)
	root.add_child(heading)
	add_button(root, "Bild öffnen", Vector2(25, 63), Vector2(150, 36), choose_image)
	detection_mode = OptionButton.new()
	detection_mode.position = Vector2(190, 63)
	detection_mode.size = Vector2(190, 36)
	for text in ["Automatisch", "Geschlossene Umrisse", "Farben / Transparenz"]:
		detection_mode.add_item(text)
	root.add_child(detection_mode)
	actions.append(detection_mode)
	add_button(root, "Neu erkennen", Vector2(395, 63), Vector2(160, 36), analyze_image)
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
	sidebar.position = Vector2(640, 30)
	sidebar.size = Vector2(375, 710)
	sidebar.add_theme_constant_override("separation", 9)
	root.add_child(sidebar)
	add_label(sidebar, "MOTIVNAME")
	title_field = LineEdit.new()
	title_field.text = motif.get("title", "Eigenes Motiv")
	title_field.placeholder_text = "Zum Beispiel: Palme im Abendlicht"
	title_field.max_length = 80
	title_field.text_changed.connect(func(text: String): motif.title = text)
	sidebar.add_child(title_field)
	add_label(sidebar, "FLÄCHEN")
	regions = OptionButton.new()
	regions.fit_to_longest_item = false
	regions.item_selected.connect(func(index: int): selected = regions.get_item_id(index); refresh())
	sidebar.add_child(regions)
	actions.append(regions)
	name_field = LineEdit.new()
	name_field.max_length = 60
	name_field.placeholder_text = "Dach, Stamm, Fenster …"
	name_field.text_changed.connect(func(text: String): motif.names[selected] = text)
	name_field.focus_exited.connect(refresh)
	sidebar.add_child(name_field)
	var tools := OptionButton.new()
	tool_picker = tools
	for text in ["Fläche auswählen", "Fläche malen", "Radieren", "Fläche mit Linie trennen", "Angeklickte Fläche zusammenführen"]:
		tools.add_item(text)
	tools.item_selected.connect(func(index: int): tool = index; update_notice())
	sidebar.add_child(tools)
	actions.append(tools)
	var row := HBoxContainer.new()
	sidebar.add_child(row)
	add_row_button(row, "Neue Fläche", new_region)
	add_row_button(row, "Rückgängig", undo)
	add_label(sidebar, "NEONPALETTE DER FLÄCHE")
	var palette := OptionButton.new()
	palette_picker = palette
	palette.add_item("Individuelle Palette")
	for key in CustomMotif.PALETTES:
		palette.add_item(key)
	palette.item_selected.connect(func(index: int):
		if index > 0:
			set_palette(CustomMotif.PALETTES.values()[index - 1]))
	sidebar.add_child(palette)
	actions.append(palette)
	var colors := HBoxContainer.new()
	sidebar.add_child(colors)
	for index in range(3):
		var swatch := ColorPickerButton.new()
		swatch.custom_minimum_size = Vector2(110, 34)
		swatch.edit_alpha = false
		swatch.color_changed.connect(func(color: Color): change_color(index, color))
		colors.add_child(swatch)
		swatches.append(swatch)
		actions.append(swatch)
	add_label(sidebar, "LINIENERKENNUNG · HELL / DUNKEL")
	threshold = HSlider.new()
	threshold.min_value = 0.15
	threshold.max_value = 0.85
	threshold.step = 0.05
	threshold.value = 0.5
	sidebar.add_child(threshold)
	var reference := CheckButton.new()
	reference.text = "Vorlage einblenden"
	reference.button_pressed = true
	reference.toggled.connect(func(value: bool): show_reference = value; canvas.refresh())
	sidebar.add_child(reference)
	var preview := CheckButton.new()
	preview.text = "Pfeilvorschau einblenden"
	preview.button_pressed = true
	preview.toggled.connect(func(value: bool): show_paths = value; canvas.refresh())
	sidebar.add_child(preview)
	add_row_button(sidebar, "Automatisch mit Pfeilen füllen", fill)
	add_row_button(sidebar, "Übernehmen und testen", apply)
	add_row_button(sidebar, "Entwurf speichern", save_draft)
	add_row_button(sidebar, "Entwurf laden", load_draft)
	notice = Label.new()
	notice.position = Vector2(25, 747)
	notice.size = Vector2(985, 46)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 14)
	root.add_child(notice)
	refresh()
	update_notice()

func add_label(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.modulate = Color("#91b4cf")
	parent.add_child(label)

func add_button(parent: Node, text: String, pos: Vector2, extent: Vector2, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = extent
	button.pressed.connect(action)
	parent.add_child(button)
	actions.append(button)

func add_row_button(parent: Node, text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 34
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(action)
	parent.add_child(button)
	actions.append(button)

func remember() -> void:
	history.append({"motif": motif.duplicate(true), "paths": game.clone_data(paths)})
	if history.size() > 40:
		history.pop_front()

func undo() -> void:
	if history.is_empty() or busy:
		return
	var state: Dictionary = history.pop_back()
	motif = state.motif
	paths = state.paths
	refresh()
	update_notice()

func refresh() -> void:
	regions.clear()
	for part in motif.palettes:
		regions.add_item(motif.names.get(part, "Fläche %d" % part), part)
	if not motif.palettes.has(selected) and not motif.palettes.is_empty():
		selected = motif.palettes.keys()[0]
	regions.select(regions.get_item_index(selected))
	name_field.text = motif.names.get(selected, "")
	title_field.text = motif.get("title", "Eigenes Motiv")
	var palette: Array = motif.palettes.get(selected, ["#65e5ff"])
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
	canvas.refresh()

func update_notice() -> void:
	var tips := ["Klicke eine Fläche an, um ihren Namen und ihre Palette zu ändern.", "Ziehe mit gedrückter Maustaste: Punkte gehören zur ausgewählten Fläche.", "Ziehe über Punkte, die nicht zum Motiv gehören sollen.", "Ziehe eine Linie durch die ausgewählte Fläche. Die Trennung erzeugt neue Bereiche ohne Lücke.", "Wähle zuerst die Zielfläche. Klicke dann die Fläche an, die dazugehören soll."]
	var lonely := CustomMotif.isolated(motif)
	notice.text = "%d Rasterpunkte · %d Flächen. %s" % [motif.cells.size(), motif.palettes.size(), tips[tool]]
	if not lonely.is_empty():
		notice.text = "%d zu kleine Einzelpunkte sind rot markiert. Verbinde, verbreitere oder entferne sie vor dem Füllen." % lonely.size()

func select_cell(cell: Vector2i) -> void:
	if motif.cells.has(cell):
		selected = motif.cells[cell]
		refresh()
	update_notice()

func paint_cells(cells: Array[Vector2i]) -> void:
	for cell in cells:
		if cell.x < 0 or cell.x >= ArrowPuzzle.COLS or cell.y < 0 or cell.y >= ArrowPuzzle.ROWS:
			continue
		if tool == 2:
			motif.cells.erase(cell)
		else:
			motif.cells[cell] = selected
	paths.clear()
	canvas.refresh()
	update_notice()

func split_cells(barrier: Array[Vector2i]) -> void:
	if CustomMotif.split(motif, selected, barrier):
		paths.clear()
		refresh()
		update_notice()
	else:
		notice.text = "Die Linie hat die Fläche nicht geteilt. Ziehe vollständig von einer Seite zur anderen."

func merge_cell(cell: Vector2i) -> void:
	var part := int(motif.cells.get(cell, -1))
	if part < 0 or part == selected:
		return
	remember()
	for point in motif.cells:
		if motif.cells[point] == part:
			motif.cells[point] = selected
	motif.palettes.erase(part)
	motif.names.erase(part)
	paths.clear()
	refresh()
	update_notice()

func new_region() -> void:
	var part := CustomMotif.next_part(motif)
	if part < 0:
		return
	remember()
	motif.palettes[part] = CustomMotif.PALETTES["Wasser"].duplicate()
	motif.names[part] = "Neue Fläche %d" % (part + 1)
	selected = part
	tool = 1
	tool_picker.select(1)
	refresh()
	update_notice()

func set_palette(colors: Array) -> void:
	remember()
	motif.palettes[selected] = colors.duplicate()
	recolor()
	refresh()

func change_color(index: int, color: Color) -> void:
	remember()
	var palette: Array = motif.palettes[selected].duplicate()
	while palette.size() < 3:
		palette.append(palette[-1])
	palette[index] = color.to_html(false)
	motif.palettes[selected] = palette
	recolor()
	palette_picker.select(0)
	canvas.refresh()

func recolor() -> void:
	for index in range(paths.size()):
		var part := MotifBuilder.region(6, ArrowPuzzle.grid(paths[index].points[0]), motif)
		paths[index].color = MotifBuilder.color_for(6, part, index, motif)

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

func analyze_image() -> void:
	if busy:
		return
	if source == null:
		notice.text = "Öffne zuerst eine Bildvorlage."
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

func fill() -> void:
	if busy:
		return
	if motif.cells.is_empty() or not CustomMotif.isolated(motif).is_empty():
		notice.text = "Die Fläche ist leer oder enthält rote Einzelpunkte. Bitte zuerst korrigieren."
		return
	remember()
	set_busy(true)
	filling = true
	seed_value += 173
	var copy := motif.duplicate(true)
	var seed_copy := seed_value
	notice.text = "Pfeile werden verteilt und auf Lösbarkeit geprüft …"
	worker = Thread.new()
	worker.start(func(): return LevelDesign.refine(6, seed_copy, 10, 350, copy))

func _process(_delta: float) -> void:
	if worker == null or worker.is_alive():
		return
	var result = worker.wait_to_finish()
	worker = null
	set_busy(false)
	if filling:
		if result.is_empty():
			notice.text = "Noch keine vollständige lösbare Füllung gefunden. Versuche eine neue Variante oder verbreitere enge Stellen."
		else:
			paths = result
			var analysis := LevelDesign.metrics(paths)
			notice.text = "100 %% gefüllt · %d Pfade · %d freie Startzüge · %d Freispielstufen. Übernehmen startet den Spieltest." % [paths.size(), analysis.starts, analysis.depth]
	else:
		if result.is_empty() or result.cells.is_empty():
			notice.text = "Keine geschlossenen Flächen erkannt. Prüfe den Modus oder schließe offene Umrisse in deiner Vorlage."
		else:
			motif = result
			paths.clear()
			selected = motif.palettes.keys()[0]
			refresh()
			update_notice()
	canvas.refresh()

func apply() -> void:
	if busy or paths.is_empty():
		notice.text = "Fülle das Motiv zuerst mit Pfeilen."
		return
	game.motif = motif.duplicate(true)
	game.shape_index = 6
	game.arrows = game.clone_data(paths)
	game.draft.clear()
	game.test_editor()
	close_studio()

func save_draft() -> void:
	var file := FileAccess.open(game.storage_prefix + "motif_draft.json", FileAccess.WRITE)
	if file == null:
		notice.text = "Entwurf konnte nicht gespeichert werden."
		return
	var document := CustomMotif.encode(motif)
	document["paths"] = CustomMotif.encode_paths(paths)
	file.store_string(JSON.stringify(document, "\t"))
	notice.text = "Flächen, Namen, Paletten, Bildvorlage und aktuelle Pfeilfüllung sind lokal gespeichert."

func load_draft() -> void:
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
		restored = CustomMotif.decode_paths(document.paths, loaded)
		if restored.is_empty():
			notice.text = "Die gespeicherte Pfeilfüllung ist ungültig."
			return
	remember()
	motif = loaded
	paths = restored
	source = null
	refresh()
	update_notice()

func close_studio() -> void:
	if busy:
		notice.text = "Die Berechnung läuft noch. Das Fenster kann danach geschlossen werden."
		return
	game.studio_draft = {"motif": motif.duplicate(true), "paths": game.clone_data(paths)}
	game.studio = null
	queue_free()

func _exit_tree() -> void:
	if worker != null and worker.is_started():
		worker.wait_to_finish()
