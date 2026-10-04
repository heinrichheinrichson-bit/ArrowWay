extends Node2D

const SPEED := 950.0
const TITLES := ["Erste Lichtung", "Herzenswege", "Das erste Haus", "Winterlabyrinth", "Herzklopfen", "Haus bei Nacht"]
const SHAPES := [1, 2, 0, 1, 2, 0]
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

func _ready() -> void:
	DisplayServer.window_set_title("ArrowWay · Level-Werkzeug" if authoring else "ArrowWay · Neon Trails")
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
	var config := ConfigFile.new()
	if config.load(storage_prefix + "progress.cfg") == OK:
		unlocked = clampi(int(config.get_value("game", "unlocked", 0)), 0, TITLES.size() - 1)
		level = clampi(int(config.get_value("game", "level", 0)), 0, unlocked)
	var ui := CanvasLayer.new()
	add_child(ui)
	panel = Control.new()
	panel.theme = theme
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel)
	reset()
	if authoring:
		enter_editor()

func button(label: String, x: float, y: float, width: float, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.position = Vector2(x, y)
	b.size = Vector2(width, 38)
	b.pressed.connect(action)
	panel.add_child(b)
	controls.append(b)
	return b

func build_controls() -> void:
	for c in controls:
		panel.remove_child(c)
		c.queue_free()
	controls.clear()
	next_button = null
	if editor:
		var shapes := OptionButton.new()
		shapes.position = Vector2(30, 101)
		shapes.size = Vector2(240, 38)
		for name in ["Haus", "Weihnachtsbaum", "Herz"]:
			shapes.add_item(name)
		shapes.select(shape_index)
		shapes.tooltip_text = "Neue Schablone auswählen; ersetzt die aktuellen Pfade."
		shapes.item_selected.connect(func(index: int): shape_index = index; arrows.clear(); draft.clear(); selected = -1; status = "Neue Schablone. Zeichne Pfade oder drücke Füllen.")
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
		for i in range(TITLES.size()):
			picker.add_item("%02d / %s" % [i + 1, TITLES[i]])
			picker.set_item_disabled(i, i > unlocked)
		picker.select(level)
		picker.item_selected.connect(func(index: int): level = index; testing = false; reset())
		panel.add_child(picker)
		controls.append(picker)
		picker.size.x = 480
		button("Neustart", 90, 751, 165, reset)
		button("Hinweis", 285, 751, 165, show_hint)
		if authoring:
			button("Zum Level-Werkzeug", 140, 101, 260, enter_editor)
			picker.visible = false
		next_button = button("Zurück zum Editor" if testing else "Nächstes Puzzle", 130, 805, 280, enter_editor if testing else advance)
		next_button.visible = false

func clone_data(data: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for a in data:
		result.append(ArrowPuzzle.make_arrow(a.points.duplicate(), a.color))
	return result

func reset() -> void:
	if not testing:
		shape_index = SHAPES[level]
	if testing:
		arrows = clone_data(editor_data)
	elif not read_custom("res://levels/%02d.json" % (level + 1)):
		arrows = ArrowPuzzle.generate(SHAPES[level], 4817 + level * 173)
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
	config.save(storage_prefix + "progress.cfg")

func advance() -> void:
	level = level + 1 if level < TITLES.size() - 1 else 0
	unlocked = maxi(unlocked, level)
	save_progress()
	reset()

func _process(delta: float) -> void:
	clock_time += delta
	for a in arrows:
		a.flash = maxf(0.0, a.flash - delta)
		a.hint = maxf(0.0, a.hint - delta)
		a.release = maxf(0.0, a.release - delta)
		if a.escaping and not a.removed:
			a.travel += SPEED * delta
			var p := visible_points(a)
			if a.travel > path_length(a.draw_points) and not Rect2(12, 157, 516, 526).has_point(p[0]):
				a.removed = true
				cleared += 1
				if cleared == arrows.size():
					status = "Geschafft! Alle Wege sind frei."
					detail = "%d Pfade befreit · %d blockierte Versuche" % [cleared, mistakes]
					next_button.visible = true
					if not testing:
						unlocked = maxi(unlocked, mini(level + 1, TITLES.size() - 1))
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
		status = "Ein neuer Weg ist jetzt frei." if opened == 1 else "%d neue Wege sind jetzt frei." % opened
		detail = "Deine Auswahl öffnet weitere Möglichkeiten."

func _unhandled_input(event: InputEvent) -> void:
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
		mistakes += 1
		status = "Noch blockiert. Schau in Richtung der Spitze."
		detail = "Ein anderer Pfad versperrt diesen Weg."
	else:
		arrows[chosen].escaping = true
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
	arrows = LevelDesign.refine(shape_index, generation_seed, 10, 600)
	generating = false
	for control in controls:
		if control is BaseButton:
			control.disabled = false
	draft.clear()
	selected = -1
	status = "Neue Füllung: %d verflochtene Pfade, lösbar." % arrows.size()
	detail = "Du kannst einzelne Pfade auswählen, umdrehen und neu prüfen."

func leave_editor() -> void:
	editor = false
	testing = false
	draft.clear()
	reset()

func add_draft(pos: Vector2) -> void:
	var cell := ArrowPuzzle.grid(pos)
	var allowed := ArrowPuzzle.mask(shape_index)
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
	arrows.append(ArrowPuzzle.make_arrow(draft.duplicate(), MotifBuilder.color_for(shape_index, MotifBuilder.region(shape_index, ArrowPuzzle.grid(draft[0])), arrows.size())))
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
		paths.append({"points": points, "color": a.color.to_html()})
	return {"version": 1, "shape": shape_index, "title": TITLES[level], "paths": paths}

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
	dialog.current_file = "%02d.json" % (level + 1)
	dialog.title = "Level für das Spiel exportieren"
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(level_document(), "\t"))
			status = "Level exportiert. Das Spiel lädt es beim nächsten Start."
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
	if not data is Dictionary or data.get("version") != 1 or not data.get("shape") is float and not data.get("shape") is int:
		return false
	if not data.get("paths") is Array or data.paths.size() > 200 or int(data.shape) < 0 or int(data.shape) > 2:
		return false
	var loaded: Array[Dictionary] = []
	var occupied := {}
	var shape := clampi(int(data.get("shape", 0)), 0, 2)
	var allowed := ArrowPuzzle.mask(shape)
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
			occupied[point] = true
			p.append(point)
		loaded.append(ArrowPuzzle.make_arrow(p, Color(str(a.get("color", "65e5ff")))))
	if loaded.is_empty() or ArrowPuzzle.solution(loaded).size() != loaded.size():
		status = "Die gespeicherte Datei enthält kein lösbares Puzzle."
		return false
	shape_index = shape
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
		var ratio := float(cleared) / maxf(1, arrows.size())
		draw_line(Vector2(125, 653), Vector2(492, 653), Color("#24394e"), 4, true)
		if ratio > 0:
			draw_line(Vector2(125, 653), Vector2(125 + ratio * 367, 653), Color("#65e5ff"), 4, true)
	text_at(status, Vector2(20, 701), 17, Color("#e0e8f5"), 500)
	text_at(detail, Vector2(20, 724), 12, Color("#8296b0"), 500)
	if not editor and cleared == arrows.size() and cleared > 0:
		text_at("FREI", Vector2(160, 427), 62, Color("#69efb4"), 220)
