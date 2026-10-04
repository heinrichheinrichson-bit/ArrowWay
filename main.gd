extends Node2D

const SPEED := 950.0
const TITLES := ["Erste Lichtung", "Herzenswege", "Das erste Haus", "Winterlabyrinth", "Herzklopfen", "Haus bei Nacht", "Flügeltanz", "Meerespause", "Neonblüte"]
const SHAPES := [1, 2, 0, 1, 2, 0, 3, 4, 5]
var level_files: Array[String] = []
var catalog_metadata := {}
var collection_filter := "all"
var gallery_page := 0
const GALLERY_PAGE_SIZE := 12
var catalog_directory := "res://levels"
var scan_user_exports := not OS.get_cmdline_user_args().has("--test")
var arrows: Array[Dictionary] = []
var editor_data: Array[Dictionary] = []
var draft := PackedVector2Array()
var status := ""
var detail := ""
var cleared := 0
var mistakes := 0
var level := 0
var shape_index := 0
var unlocked := 0
var selected := -1
var editor := false
var testing := false
var draw_tool := true
var controls: Array[Control] = []
var next_button: Button
var level_picker: OptionButton
var panel: Control
var board: Node2D
var generation_seed := 9121
var clock_time := 0.0
var storage_prefix := "user://test_" if OS.get_cmdline_user_args().has("--test") else "user://"
var authoring := OS.get_cmdline_user_args().has("--editor-tool")
var known_free := {}
var scan_clock := 0.0
var generating := false
var feedback: FeedbackAudio
var sound_button: Button
var win_time := -1.0
var display_progress := 0.0
var completed: Array[int] = []
var gallery: Control
var motif := {}
var studio: Window
var studio_draft := {}
const MOODS := ["Zum Ankommen", "Ruhig entdecken", "Verflochten", "Neue Wege", "Knifflig", "Für Tüftler", "Flügel entfalten", "Verschnaufpause", "Blüte für Tüftler"]

static func escape_distance(time: float) -> float:
	const RAMP := 0.12
	if time < RAMP:
		return SPEED * (time * 0.5 - RAMP * sin(PI * time / RAMP) / (2.0 * PI))
	return SPEED * (time - RAMP * 0.5)

func _ready() -> void:
	get_window().title = "ArrowWay · " + str(ProjectSettings.get_setting("application/config/version", "")) + (" · Level-Werkzeug" if authoring else "")
	feedback = FeedbackAudio.new()
	add_child(feedback)
	var preferences := ConfigFile.new()
	if preferences.load(storage_prefix + "settings.cfg") == OK:
		feedback.set_enabled(bool(preferences.get_value("audio", "enabled", true)))
	var clip := Control.new()
	clip.position = Vector2(20, 165)
	clip.size = Vector2(500, 510)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	board = Node2D.new()
	board.position = -clip.position
	board.set_script(load("res://board.gd"))
	board.set("game", self)
	clip.add_child(board)
	var theme := Theme.new()
	theme.default_font_size = 14
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#17253b") if state == "normal" else Color("#254461")
		if state == "disabled":
			box.bg_color = Color("#10192a")
		box.set_corner_radius_all(9)
		box.set_content_margin_all(6)
		theme.set_stylebox(state, "Button", box)
		theme.set_stylebox(state, "OptionButton", box)
	discover_levels()
	var config := ConfigFile.new()
	if config.load(storage_prefix + "progress.cfg") == OK:
		unlocked = clampi(int(config.get_value("game", "unlocked", 0)), 0, TITLES.size() - 1)
		level = clampi(int(config.get_value("game", "level", 0)), 0, unlocked)
		for index in config.get_value("game", "completed", range(unlocked)):
			if index is int and index >= 0 and index < TITLES.size() and not completed.has(index):
				completed.append(index)
		var custom_path: String = config.get_value("game", "custom_level", "")
		if level_files.has(custom_path): level = level_files.find(custom_path)
		for path in config.get_value("game", "completed_custom", []):
			var index := level_files.find(str(path))
			if index >= TITLES.size() and not completed.has(index): completed.append(index)
	var startup_args := OS.get_cmdline_user_args()
	var requested := startup_args.find("--play-level")
	if requested >= 0 and requested + 1 < startup_args.size():
		var requested_index := level_files.find(startup_args[requested + 1])
		if requested_index >= 0 and level_available(requested_index): level = requested_index
	var ui := CanvasLayer.new()
	add_child(ui)
	panel = Control.new()
	panel.theme = theme
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel)
	reset()
	if authoring:
		enter_editor()
		open_studio()

func button(label: String, x: float, y: float, width: float, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.position = Vector2(x, y)
	b.size = Vector2(width, 38)
	b.pressed.connect(action)
	panel.add_child(b)
	controls.append(b)
	return b

func level_count() -> int:
	return level_files.size() if not level_files.is_empty() else TITLES.size()

func level_path(index: int) -> String:
	return level_files[index] if index < level_files.size() else "res://levels/%02d.json" % (index + 1)

func level_shape(index: int) -> int:
	return SHAPES[index] if index < SHAPES.size() else 1

func level_available(index: int) -> bool:
	return index >= TITLES.size() or index <= unlocked

func discover_levels(include_user_exports: bool = true, directory: String = "") -> void:
	if directory.is_empty(): directory = catalog_directory
	var current_path := level_path(level) if not level_files.is_empty() else ""
	var completed_paths: Array[String] = []
	for index in completed:
		if index >= TITLES.size() and index < level_files.size(): completed_paths.append(level_files[index])
	level_files.clear()
	catalog_metadata.clear()
	for index in range(TITLES.size()): level_files.append(directory.path_join("%02d.json" % (index + 1)))
	if include_user_exports and scan_user_exports and directory == "res://levels":
		var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json")) if FileAccess.file_exists("res://collections/catalog.json") else null
		if catalog is Dictionary and catalog.get("levels") is Array:
			for entry in catalog.levels:
				if not entry is Dictionary or not entry.get("path") is String or not entry.path.begins_with("res://collections/levels/") or not entry.get("collection") is Dictionary or not FileAccess.file_exists(entry.path): continue
				if level_files.has(entry.path): continue
				level_files.append(entry.path)
				catalog_metadata[entry.path] = entry
	if include_user_exports and scan_user_exports:
		var files := Array(DirAccess.get_files_at(directory))
		files.sort_custom(func(a: String, b: String): return a.naturalnocasecmp_to(b) < 0)
		for filename in files:
			var path := directory.path_join(filename)
			if filename.get_extension().to_lower() != "json" or level_files.has(path): continue
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if not data is Dictionary or (data.get("version") != 1 and data.get("version") != 2) or not (data.get("shape") is int or data.get("shape") is float): continue
			var shape := int(data.shape)
			if float(data.shape) != shape or shape < 0 or shape > 6: continue
			var imported := CustomMotif.decode(data.get("motif")) if shape == 6 else CustomMotif.from_shape(shape)
			if imported.is_empty() or CustomMotif.decode_paths(data.get("paths"), imported).is_empty(): continue
			level_files.append(path)
			catalog_metadata[path] = {"title":data.get("title", filename.get_basename()),"collection":data.get("collection", {})}
	level = level_files.find(current_path) if level_files.has(current_path) else mini(level, TITLES.size() - 1)
	var retained: Array[int] = []
	for index in completed:
		if index < TITLES.size(): retained.append(index)
	for path in completed_paths:
		if level_files.has(path): retained.append(level_files.find(path))
	completed = retained

func level_title(index: int) -> String:
	if catalog_metadata.has(level_path(index)): return str(catalog_metadata[level_path(index)].get("title", "Eigenes Motiv")).left(80)
	var fallback: String = TITLES[index] if index < TITLES.size() else level_path(index).get_file().get_basename()
	var data = JSON.parse_string(FileAccess.get_file_as_string(level_path(index)))
	return str(data.get("title", fallback)).left(80) if data is Dictionary else fallback

func build_controls() -> void:
	for c in controls:
		panel.remove_child(c)
		c.queue_free()
	controls.clear()
	next_button = null
	sound_button = button("Ton: An" if feedback.enabled else "Ton: Aus", 402, 30, 108, toggle_sound)
	if editor:
		var studio_button := button("Bild & Flächen", 285, 73, 225, open_studio)
		studio_button.size.y = 24
		var shapes := OptionButton.new()
		shapes.position = Vector2(30, 101)
		shapes.size = Vector2(240, 38)
		for name in ["Haus", "Weihnachtsbaum", "Herz", "Schmetterling", "Fisch", "Blume"]:
			shapes.add_item(name)
		if shape_index == 6:
			shapes.add_item("Eigenes Bildmotiv")
		shapes.select(shape_index)
		shapes.tooltip_text = "Neue Schablone auswählen; ersetzt die aktuellen Pfade."
		shapes.item_selected.connect(func(index: int):
			if index == 6:
				open_studio()
				return
			shape_index = index
			motif.clear()
			arrows.clear()
			draft.clear()
			selected = -1
			status = "Neue Schablone. Zeichne Pfade oder drücke Füllen.")
		panel.add_child(shapes)
		controls.append(shapes)
		button("Füllen", 290, 101, 105, fill_template)
		button("Spiel", 415, 101, 95, leave_editor)
		button("Zeichnen", 30, 741, 91, func(): draw_tool = true; selected = -1; status = "Rasterpunkte anklicken, dann Fertig drücken.")
		button("Auswahl", 128, 741, 85, func(): draw_tool = false; draft.clear(); status = "Pfad anklicken, dann drehen oder löschen.")
		button("Fertig", 220, 741, 65, finish_draft)
		button("Drehen", 292, 741, 67, reverse_selected)
		button("Zurück", 366, 741, 65, undo_edit)
		button("Leer", 438, 741, 72, func(): arrows.clear(); draft.clear(); selected = -1; status = "Leere Schablone – zeichne deinen ersten Pfad.")
		button("Prüfen", 30, 791, 90, check_editor)
		button("Testen", 127, 791, 90, test_editor)
		button("Speichern", 224, 791, 96, save_custom)
		button("Laden", 327, 791, 82, load_custom)
		button("Export", 416, 791, 94, export_level)
	else:
		var picker := OptionButton.new()
		level_picker = picker
		picker.position = Vector2(30, 101)
		picker.size = Vector2(330, 37)
		for i in range(level_count()):
			picker.add_item("%02d / %s" % [i + 1, level_title(i)])
			picker.set_item_disabled(i, not level_available(i))
		picker.select(level)
		if testing and shape_index == 6:
			picker.set_item_text(level, "Test / " + str(motif.get("title", "Eigenes Motiv")))
		picker.item_selected.connect(func(index: int): level = index; testing = false; reset())
		panel.add_child(picker)
		controls.append(picker)
		picker.size.x = 352
		var gallery_button := button("Alle Levels", 394, 101, 116, open_gallery)
		gallery_button.visible = not authoring
		gallery_button.disabled = testing
		button("Neustart", 90, 751, 165, reset)
		button("Hinweis", 285, 751, 165, show_hint)
		if authoring:
			button("Zum Level-Werkzeug", 140, 101, 260, enter_editor)
			picker.visible = false
		next_button = button("Zurück zum Editor" if testing else "Nächstes Puzzle", 130, 805, 280, enter_editor if testing else advance)
		next_button.visible = false

func close_gallery() -> void:
	if is_instance_valid(gallery):
		panel.remove_child(gallery)
		gallery.queue_free()
	gallery = null

func select_gallery_level(index: int) -> void:
	if index < 0 or index >= level_count() or not level_available(index):
		return
	close_gallery()
	if index != level:
		level = index
		testing = false
		reset()
		save_progress()

func open_gallery() -> void:
	discover_levels()
	if editor or testing or is_instance_valid(gallery):
		return
	gallery = Control.new()
	gallery.size = Vector2(540, 850)
	feedback.stop_all()
	panel.add_child(gallery)
	var background := ColorRect.new()
	background.color = Color("#080e19")
	background.size = gallery.size
	gallery.add_child(background)
	var heading := Label.new()
	heading.text = "DEINE NEONREISE"
	heading.position = Vector2(30, 28)
	heading.add_theme_font_size_override("font_size", 24)
	gallery.add_child(heading)
	var progress := Label.new()
	progress.text = "%d / %d Puzzles geschafft · Dein Tempo zählt" % [completed.size(), level_count()]
	progress.position = Vector2(30, 73)
	progress.add_theme_font_size_override("font_size", 14)
	gallery.add_child(progress)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 154)
	scroll.size = Vector2(480, 555)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gallery.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	var matching: Array[int] = []
	var collections := {"all":"Alle Motive", "base":"Erste Neonreise"}
	for index in range(level_count()):
		var group := level_collection(index)
		collections[group.id] = group.title
		if collection_filter == "all" or collection_filter == group.id: matching.append(index)
	if not collections.has(collection_filter):
		collection_filter = "all"
		for index in range(level_count()): matching.append(index)
	var page_count := maxi(1, ceili(float(matching.size()) / GALLERY_PAGE_SIZE))
	gallery_page = clampi(gallery_page, 0, page_count - 1)
	for page_index in range(gallery_page * GALLERY_PAGE_SIZE, mini((gallery_page + 1) * GALLERY_PAGE_SIZE, matching.size())):
		var index := matching[page_index]
		var card := Button.new()
		card.set_script(load("res://level_card.gd"))
		card.custom_minimum_size = Vector2(228, 170)
		card.set("number", index)
		card.set("title", level_title(index))
		card.set("subtitle", MOODS[index] if index < MOODS.size() else level_collection(index).title)
		card.set("selected", index == level)
		card.set("complete", completed.has(index))
		card.disabled = not level_available(index)
		var document = JSON.parse_string(FileAccess.get_file_as_string(level_path(index)))
		var thumbnail: Array[Dictionary] = []
		if document is Dictionary:
			for path in document.paths:
				var points := PackedVector2Array()
				for xy in path.points:
					points.append(Vector2(xy[0], xy[1]))
				var arrow := {"points": rounded_points(points), "color": Color(path.color)}
				CustomMotif.read_appearance(path, arrow)
				thumbnail.append(arrow)
		card.set("paths", thumbnail)
		card.pressed.connect(select_gallery_level.bind(index))
		grid.add_child(card)
	var filters := OptionButton.new()
	filters.position = Vector2(30, 106)
	filters.size = Vector2(480, 36)
	filters.fit_to_longest_item = false
	var filter_ids := collections.keys()
	for id in filter_ids:
		var total := 0
		var done := 0
		for index in range(level_count()):
			if id == "all" or level_collection(index).id == id:
				total += 1
				if completed.has(index): done += 1
		filters.add_item("%s · %d/%d" % [collections[id],done,total])
	filters.select(filter_ids.find(collection_filter))
	filters.item_selected.connect(func(index: int):
		collection_filter = filter_ids[index]; gallery_page = 0; close_gallery(); open_gallery())
	gallery.add_child(filters)
	for offset in [-1,1]:
		var navigation := Button.new()
		navigation.text = "← Zurück" if offset < 0 else "Weiter →"
		navigation.position = Vector2(30 if offset < 0 else 350, 723)
		navigation.size = Vector2(160, 36)
		navigation.disabled = gallery_page + offset < 0 or gallery_page + offset >= page_count
		navigation.pressed.connect(func(): gallery_page += offset; close_gallery(); open_gallery())
		gallery.add_child(navigation)
	var page_label := Label.new()
	page_label.text = "%d / %d" % [gallery_page+1,page_count]
	page_label.position = Vector2(210,731)
	page_label.size.x = 120
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gallery.add_child(page_label)
	var back := Button.new()
	back.text = "Weiter spielen"
	back.position = Vector2(150, 787)
	back.size = Vector2(240, 40)
	back.pressed.connect(close_gallery)
	gallery.add_child(back)
	back.grab_focus()

func clone_data(data: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for a in data:
		var copy := ArrowPuzzle.make_arrow(a.points.duplicate(), a.color)
		MotifColors.copy_appearance(a, copy)
		result.append(copy)
	return result

func reset() -> void:
	feedback.stop_all()
	win_time = -1.0
	display_progress = 0.0
	if not testing:
		shape_index = level_shape(level)
	if testing:
		arrows = clone_data(editor_data)
	elif not read_custom(level_path(level)):
		arrows = ArrowPuzzle.generate(level_shape(level), 4817 + level * 173)
	cleared = 0
	mistakes = 0
	clock_time = 0.0
	selected = -1
	status = "Welche Spitze hat freie Bahn?"
	detail = "Tippe auf einen Pfad. Er folgt seiner Linie nach draußen."
	build_controls()
	known_free.clear()
	for i in free_paths():
		known_free[i] = true
	scan_clock = 0.0
	queue_redraw()
	if board != null:
		board.queue_redraw()

func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("game", "unlocked", unlocked)
	config.set_value("game", "level", level)
	config.set_value("game", "completed", completed)
	config.set_value("game", "custom_level", level_path(level) if level >= TITLES.size() else "")
	var custom_completed: Array[String] = []
	for index in completed:
		if index >= TITLES.size() and index < level_files.size(): custom_completed.append(level_path(index))
	config.set_value("game", "completed_custom", custom_completed)
	config.save(storage_prefix + "progress.cfg")

func toggle_sound() -> void:
	feedback.set_enabled(not feedback.enabled)
	sound_button.text = "Ton: An" if feedback.enabled else "Ton: Aus"
	var preferences := ConfigFile.new()
	preferences.set_value("audio", "enabled", feedback.enabled)
	preferences.save(storage_prefix + "settings.cfg")

func next_collection_level(index: int) -> int:
	if index < TITLES.size():
		return index + 1 if index < TITLES.size() - 1 else -1
	var group: String = level_collection(index).id
	for candidate in range(index + 1, level_count()):
		if level_collection(candidate).id == group: return candidate
	return -1

func advance() -> void:
	var next := next_collection_level(level)
	if next < 0:
		collection_filter = level_collection(level).id
		gallery_page = 0
		open_gallery()
		return
	level = next
	if level < TITLES.size(): unlocked = maxi(unlocked, level)
	save_progress()
	reset()

func _process(delta: float) -> void:
	if is_instance_valid(gallery):
		return
	clock_time += delta
	if win_time >= 0.0:
		win_time += delta
	display_progress = lerpf(display_progress, float(cleared) / maxf(arrows.size(), 1.0), 1.0 - exp(-delta * 12.0))
	for a in arrows:
		a.flash = maxf(0.0, a.flash - delta)
		a.hint = maxf(0.0, a.hint - delta)
		a.release = maxf(0.0, a.release - delta)
		if a.escaping and not a.removed:
			a.escape_time += delta
			a.travel = escape_distance(a.escape_time)
			var p := visible_points(a)
			if a.travel > path_length(a.draw_points) and not Rect2(12, 157, 516, 526).has_point(p[0]):
				a.removed = true
				cleared += 1
				if cleared == arrows.size():
					win_time = 0.0
					feedback.play("win")
					status = "Geschafft! Alle Wege sind frei."
					detail = "%d Pfade befreit · %d blockierte Versuche" % [cleared, mistakes]
					next_button.visible = true
					if not testing:
						if next_collection_level(level) < 0:
							next_button.text = "Zur Levelübersicht"
						if not completed.has(level):
							completed.append(level)
						if level < TITLES.size(): unlocked = maxi(unlocked, mini(level + 1, TITLES.size() - 1))
						level_picker.set_item_disabled(unlocked, false)
						save_progress()
	if not editor and cleared < arrows.size():
		scan_clock -= delta
		if scan_clock <= 0:
			scan_clock = 0.14
			mark_releases()
	queue_redraw()
	board.queue_redraw()

func free_paths() -> Array[int]:
	var result: Array[int] = []
	for i in range(arrows.size()):
		if not arrows[i].removed and not arrows[i].escaping and not is_blocked(i):
			result.append(i)
	return result

func mark_releases() -> void:
	var free := free_paths()
	var opened := 0
	for i in free:
		if not known_free.has(i):
			arrows[i].release = 0.8
			opened += 1
	known_free.clear()
	for i in free:
		known_free[i] = true
	if opened > 0 and not status.begins_with("Der weiß"):
		feedback.play("release")
		status = "Ein neuer Weg ist jetzt frei." if opened == 1 else "%d neue Wege sind jetzt frei." % opened
		detail = "Deine Auswahl öffnet weitere Möglichkeiten."

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(gallery) and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_gallery()
		get_viewport().set_input_as_handled()
		return
	if generating:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		click_at(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		click_at(event.position)
	elif editor and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			finish_draft()
		elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
			undo_edit()
		elif event.keycode == KEY_ESCAPE:
			draft.clear()

func pick(pos: Vector2) -> int:
	var chosen := -1
	var nearest := 9.0
	for index in range(arrows.size()):
		var a := arrows[index]
		if a.removed or a.escaping:
			continue
		var p: PackedVector2Array = a.points
		for i in range(p.size() - 1):
			var distance := pos.distance_to(Geometry2D.get_closest_point_to_segment(pos, p[i], p[i + 1]))
			if distance < nearest:
				nearest = distance
				chosen = index
	return chosen

func click_at(pos: Vector2) -> void:
	if is_instance_valid(gallery):
		return
	if editor:
		if draw_tool:
			add_draft(pos)
		else:
			selected = pick(pos)
			status = "Pfad gewählt – Drehen oder Zurück zum Löschen." if selected >= 0 else "Kein Pfad getroffen."
		return
	var chosen := pick(pos)
	if chosen < 0:
		return
	if is_blocked(chosen):
		arrows[chosen].flash = 0.35
		feedback.play("blocked")
		mistakes += 1
		status = "Noch blockiert. Schau in Richtung der Spitze."
		detail = "Ein anderer Pfad versperrt diesen Weg."
	else:
		arrows[chosen].escaping = true
		feedback.play("escape")
		status = "Freie Bahn!"
		detail = "Du kannst während der Animation weiterspielen."

func is_blocked(index: int) -> bool:
	if ArrowPuzzle.self_blocked(arrows[index].points):
		return true
	for other in range(arrows.size()):
		if other != index and not arrows[other].removed and ArrowPuzzle.ray_hits(arrows[index].points, visible_points(arrows[other])):
			return true
	return false

func show_hint() -> void:
	for i in range(arrows.size()):
		if not arrows[i].removed and not arrows[i].escaping and not is_blocked(i):
			arrows[i].hint = 2.5
			feedback.play("hint")
			status = "Der weiß leuchtende Pfad hat freie Bahn."
			return
	status = "Warte kurz, bis die laufenden Pfade draußen sind."

func enter_editor() -> void:
	if not testing:
		editor_data = clone_data(arrows)
	arrows = clone_data(editor_data)
	editor = true
	testing = false
	selected = -1
	draft.clear()
	draw_tool = true
	status = "Zeichne auf der Schablone oder wähle einen Pfad."
	detail = "Rasterpunkte → Fertig. Enter / Rücktaste funktionieren auch."
	build_controls()

func open_studio() -> void:
	if is_instance_valid(studio):
		studio.grab_focus()
		return
	get_viewport().gui_embed_subwindows = DisplayServer.get_name() == "headless"
	studio = Window.new()
	studio.set_script(load("res://motif_studio.gd"))
	studio.set("game", self)
	var initial := motif.duplicate(true) if shape_index == 6 else CustomMotif.from_shape(shape_index)
	if not studio_draft.is_empty():
		initial = studio_draft.motif.duplicate(true)
		studio.set("paths", clone_data(studio_draft.paths))
	else:
		studio.set("paths", clone_data(arrows))
	studio.set("motif", initial)
	add_child(studio)
	studio.popup_centered(Vector2i(1040, 800))

func fill_template() -> void:
	if generating:
		return
	generating = true
	status = "Die Pfade werden gefüllt und miteinander verflochten …"
	for control in controls:
		if control is BaseButton:
			control.disabled = true
	await get_tree().process_frame
	generation_seed += 173
	var filled := LevelDesign.refine(shape_index, generation_seed, 10, 600, motif)
	if not filled.is_empty():
		arrows = filled
		if shape_index == 6:
			MotifColors.apply(motif, arrows)
	generating = false
	for control in controls:
		if control is BaseButton:
			control.disabled = false
	draft.clear()
	selected = -1
	status = "Keine vollständige Füllung gefunden. Korrigiere enge Stellen in Bild & Flächen." if filled.is_empty() else "Neue Füllung: %d verflochtene Pfade, lösbar." % arrows.size()
	detail = "Du kannst einzelne Pfade auswählen, umdrehen und neu prüfen."

func leave_editor() -> void:
	editor = false
	testing = false
	draft.clear()
	reset()

func add_draft(pos: Vector2) -> void:
	var cell := ArrowPuzzle.grid(pos)
	var allowed := ArrowPuzzle.mask(shape_index, motif)
	if not allowed.has(cell):
		status = "Bitte innerhalb der gepunkteten Form zeichnen."
		return
	var addition := PackedVector2Array()
	if draft.is_empty():
		addition.append(ArrowPuzzle.pixel(cell))
	else:
		var current := ArrowPuzzle.grid(draft[-1])
		while current.x != cell.x:
			current.x += 1 if cell.x > current.x else -1
			addition.append(ArrowPuzzle.pixel(current))
		while current.y != cell.y:
			current.y += 1 if cell.y > current.y else -1
			addition.append(ArrowPuzzle.pixel(current))
	for point in addition:
		if shape_index == 6 and not draft.is_empty() and MotifBuilder.region(6, ArrowPuzzle.grid(point), motif) != MotifBuilder.region(6, ArrowPuzzle.grid(draft[0]), motif):
			status = "Ein Pfeil bleibt innerhalb seiner Fläche."
			return
		if not allowed.has(ArrowPuzzle.grid(point)) or draft.has(point):
			status = "Bleibe in der Form; der Pfad darf sich nicht kreuzen."
			return
		for a in arrows:
			if a.points.has(point):
				status = "Dieser Rasterpunkt gehört bereits zu einem Pfad."
				return
	draft.append_array(addition)
	status = "%d Rasterpunkte · Fertig schließt den Pfad ab." % draft.size()

func finish_draft() -> void:
	if draft.size() < 2:
		status = "Ein Pfad braucht mindestens zwei Rasterpunkte."
		return
	arrows.append(ArrowPuzzle.make_arrow(draft.duplicate(), MotifBuilder.color_for(shape_index, MotifBuilder.region(shape_index, ArrowPuzzle.grid(draft[0]), motif), arrows.size(), motif)))
	if shape_index == 6:
		MotifColors.apply(motif, arrows)
	selected = arrows.size() - 1
	draft.clear()
	status = "Pfad hinzugefügt. Zeichne weiter oder prüfe die Lösung."

func reverse_selected() -> void:
	if selected >= 0 and selected < arrows.size():
		var p: PackedVector2Array = arrows[selected].points
		p.reverse()
		arrows[selected].points = p
		status = "Pfeilrichtung umgedreht. Prüfen testet die Lösung."
	else:
		status = "Erst Auswahl drücken und einen Pfad anklicken."

func undo_edit() -> void:
	if not draft.is_empty():
		draft.remove_at(draft.size() - 1)
	elif selected >= 0 and selected < arrows.size():
		arrows.remove_at(selected)
		selected = -1
	elif not arrows.is_empty():
		arrows.pop_back()
	status = "Letzten Punkt oder Pfad entfernt."

func check_editor() -> bool:
	if shape_index == 6:
		var used := {}
		for arrow in arrows:
			for point in arrow.points:
				used[ArrowPuzzle.grid(point)] = true
		if used.size() != motif.get("cells", {}).size():
			status = "Das Bildmotiv ist noch nicht vollständig gefüllt. Nutze Bild & Flächen → Füllen."
			return false
	if arrows.is_empty() or not draft.is_empty():
		status = "Zeichne einen Pfad und schließe ihn mit Fertig ab."
		return false
	var order := ArrowPuzzle.solution(arrows)
	if order.size() == arrows.size():
		status = "Lösbar! Alle %d Pfade lassen sich entfernen." % arrows.size()
		var analysis := LevelDesign.metrics(arrows)
		detail = "%d freie Startzüge · %d Freispielstufen · Testen startet das Puzzle." % [analysis.starts, analysis.depth]
		return true
	status = "Blockade: %d von %d Pfaden lassen sich entfernen." % [order.size(), arrows.size()]
	detail = "Drehe oder entferne einen der rot markierten Pfade."
	for i in range(arrows.size()):
		if not order.has(i):
			arrows[i].flash = 1.5
	return false

func test_editor() -> void:
	if check_editor():
		editor_data = clone_data(arrows)
		editor = false
		testing = true
		reset()

func level_document() -> Dictionary:
	var paths: Array = []
	for a in arrows:
		var points: Array = []
		for p in a.points:
			points.append([p.x, p.y])
		var item := {"points": points, "color": a.color.to_html()}
		MotifColors.copy_appearance(a, item)
		paths.append(item)
	var document := {"version": 1, "shape": shape_index, "title": level_title(level), "paths": paths}
	if shape_index == 6:
		document.version = 2
		document.title = motif.get("title", "Eigenes Motiv")
		document["motif"] = CustomMotif.encode(motif)
	return document

func save_custom() -> void:
	if not check_editor():
		return
	var file := FileAccess.open(storage_prefix + "custom_puzzle.json", FileAccess.WRITE)
	if file == null:
		status = "Speichern fehlgeschlagen."
		return
	file.store_string(JSON.stringify(level_document(), "\t"))
	status = "Dein Puzzle ist lokal gespeichert."
	detail = "Laden öffnet den Entwurf; Export schreibt eine Leveldatei."

func export_level() -> void:
	if not check_editor():
		return
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; ArrowWay Level"])
	dialog.current_dir = ProjectSettings.globalize_path("res://levels")
	dialog.current_file = str(motif.get("title", "Eigenes Motiv")).validate_filename() + ".json" if shape_index == 6 else "%02d.json" % (level + 1)
	dialog.title = "Level für das Spiel exportieren"
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(level_document(), "\t"))
			status = "Exportiert: " + path.get_file()
			detail = "Im Spiel: Alle Levels → Eigenes Motiv. Die Übersicht liest neue Exporte automatisch ein." if path.get_base_dir() == ProjectSettings.globalize_path("res://levels").trim_suffix("/") else "Für das Spiel die JSON-Datei im Projektordner levels speichern."
		else:
			status = "Export fehlgeschlagen."
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(500, 650))

func read_custom(path: String = "") -> bool:
	if path.is_empty():
		path = storage_prefix + "custom_puzzle.json"
	if not FileAccess.file_exists(path):
		status = "Noch kein eigenes Puzzle gespeichert."
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	status = "Die Puzzle-Datei ist ungültig."
	if not data is Dictionary or (data.get("version") != 1 and data.get("version") != 2) or not data.get("shape") is float and not data.get("shape") is int:
		return false
	if not data.get("paths") is Array or data.paths.size() > 500 or int(data.shape) < 0 or int(data.shape) > 6 or float(data.shape) != int(data.shape):
		return false
	var loaded: Array[Dictionary] = []
	var occupied := {}
	var shape := int(data.shape)
	var imported := {}
	if shape == 6:
		if data.version != 2:
			return false
		imported = CustomMotif.decode(data.get("motif"))
		if imported.is_empty() or imported.cells.is_empty():
			return false
	var allowed := ArrowPuzzle.mask(shape, imported)
	for a in data.paths:
		if not a is Dictionary or not a.get("points") is Array or a.points.size() < 2 or a.points.size() > 500:
			return false
		if not a.get("color") is String or not Color.html_is_valid(a.color):
			return false
		var p := PackedVector2Array()
		for xy in a.points:
			if not xy is Array or xy.size() != 2 or not (xy[0] is float or xy[0] is int) or not (xy[1] is float or xy[1] is int):
				return false
			var point := Vector2(float(xy[0]), float(xy[1]))
			if not point.is_finite() or point != ArrowPuzzle.pixel(ArrowPuzzle.grid(point)) or occupied.has(point) or not allowed.has(ArrowPuzzle.grid(point)):
				return false
			if not p.is_empty() and point.distance_to(p[-1]) != ArrowPuzzle.CELL:
				return false
			if shape == 6 and not p.is_empty() and imported.cells[ArrowPuzzle.grid(point)] != imported.cells[ArrowPuzzle.grid(p[0])]:
				return false
			occupied[point] = true
			p.append(point)
		var arrow := ArrowPuzzle.make_arrow(p, Color(str(a.get("color", "65e5ff"))))
		if not CustomMotif.read_appearance(a, arrow):
			return false
		loaded.append(arrow)
	if (shape == 6 and occupied.size() != allowed.size()) or loaded.is_empty() or ArrowPuzzle.solution(loaded).size() != loaded.size():
		status = "Die gespeicherte Datei enthält kein lösbares Puzzle."
		return false
	shape_index = shape
	motif = imported
	arrows = loaded
	status = "Gespeichertes Puzzle geladen."
	return true

func load_custom() -> void:
	if read_custom():
		draft.clear()
		selected = -1
		status = "Gespeichertes Puzzle geladen."

func play_custom() -> void:
	if read_custom():
		editor_data = clone_data(arrows)
		testing = true
		reset()

func path_length(p: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(p.size() - 1):
		total += p[i].distance_to(p[i + 1])
	return total

func point_along(p: PackedVector2Array, distance: float) -> Vector2:
	for i in range(p.size() - 1):
		var length := p[i].distance_to(p[i + 1])
		if distance <= length:
			return p[i].lerp(p[i + 1], distance / length)
		distance -= length
	return p[-1] + (p[-1] - p[-2]).normalized() * distance

func visible_points(a: Dictionary) -> PackedVector2Array:
	if not a.has("draw_points") or a.get("draw_source") != a.points:
		a.draw_source = a.points.duplicate()
		a.draw_points = rounded_points(a.points)
	var p: PackedVector2Array = a.draw_points
	var travel: float = a.travel
	if travel == 0.0:
		return p
	var result := PackedVector2Array([point_along(p, travel)])
	var walked := 0.0
	for i in range(1, p.size()):
		walked += p[i - 1].distance_to(p[i])
		if walked > travel:
			result.append(p[i])
	result.append(point_along(p, path_length(p) + travel))
	return result

func rounded_points(source: PackedVector2Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(source.size()):
		if i > 0 and i < source.size() - 1 and (source[i] - source[i - 1]).normalized().is_equal_approx((source[i + 1] - source[i]).normalized()):
			continue
		p.append(source[i])
	if p.size() < 3:
		return p
	var smooth := PackedVector2Array([p[0]])
	for i in range(1, p.size() - 1):
		var incoming := (p[i] - p[i - 1]).normalized()
		var outgoing := (p[i + 1] - p[i]).normalized()
		var radius := minf(4.8, minf(p[i].distance_to(p[i - 1]), p[i].distance_to(p[i + 1])) * 0.44)
		var center := p[i] - incoming * radius + outgoing * radius
		var start := p[i] - incoming * radius
		var finish := p[i] + outgoing * radius
		var angle := (start - center).angle()
		var turn := wrapf((finish - center).angle() - angle, -PI, PI)
		for step in range(9):
			smooth.append(center + Vector2.from_angle(angle + turn * step / 8.0) * radius)
	smooth.append(p[-1])
	return smooth

func text_at(text: String, pos: Vector2, size: int, color: Color, width: float = -1) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT if width < 0 else HORIZONTAL_ALIGNMENT_CENTER, width, size, color)

func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#080d18")
	box.set_corner_radius_all(22)
	draw_style_box(box, Rect2(20, 165, 500, 510))
	text_at("ARROW / WAY", Vector2(30, 55), 30, Color("#eef5ff"))
	text_at("LEVEL-WERKZEUG" if editor else "NEON TRAILS", Vector2(31, 79), 12, Color("#839ab8"))
	if not editor:
		text_at("%d / %d" % [cleared, arrows.size()], Vector2(36, 658), 14, Color("#839ab8"))
		var ratio := display_progress
		draw_line(Vector2(125, 653), Vector2(492, 653), Color("#24394e"), 4, true)
		if ratio > 0:
			draw_line(Vector2(125, 653), Vector2(125 + ratio * 367, 653), Color("#65e5ff"), 4, true)
	text_at(status, Vector2(20, 701), 17, Color("#e0e8f5"), 500)
	text_at(detail, Vector2(20, 724), 12, Color("#8296b0"), 500)
	if not editor and cleared == arrows.size() and cleared > 0:
		var fade := smoothstep(0.0, 0.32, maxf(win_time, 0.0))
		var size := lerpf(0.94, 1.0, fade)
		if win_time < 0.7:
			var ripple := clampf(win_time / 0.7, 0.0, 1.0)
			draw_arc(Vector2(270, 407), 48.0 + ripple * 46.0, 0, TAU, 96, Color(0.41, 0.94, 0.70, (1.0 - ripple) * 0.12), 1.5, true)
		draw_set_transform(Vector2(270, 407), 0.0, Vector2.ONE * size)
		text_at("FREI", Vector2(-110, 20), 62, Color(0.41, 0.94, 0.70, fade), 220)
		draw_set_transform(Vector2.ZERO)

func level_collection(index: int) -> Dictionary:
	if index < TITLES.size(): return {"id":"base","title":"Erste Neonreise"}
	var data: Dictionary = catalog_metadata.get(level_path(index), {})
	var group: Dictionary = data.get("collection", {}) if data.get("collection", {}) is Dictionary else {}
	if not group.get("id") is String or not group.get("title") is String:
		return {"id":"custom","title":"Eigene Motive"}
	return group
