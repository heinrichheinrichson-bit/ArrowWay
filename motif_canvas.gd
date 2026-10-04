extends Control

const STEP := 18.0
const OFFSET := Vector2(35, 12)
var studio: Window
var dragging := false
var first := Vector2i.ZERO
var previous := Vector2i.ZERO
var last := Vector2i.ZERO
var reference: ImageTexture
var reference_key := ""
var preview: Node2D

func _ready() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_ALL
	preview = Node2D.new()
	preview.set_script(load("res://motif_preview.gd"))
	preview.set("rounder", studio.game)
	preview.scale = Vector2.ONE * STEP / ArrowPuzzle.CELL
	preview.position = OFFSET - ArrowPuzzle.ORIGIN * STEP / ArrowPuzzle.CELL
	add_child(preview)

func refresh() -> void:
	var arrows: Array[Dictionary] = studio.paths.duplicate()
	if studio.drawn_cells.size() > 1:
		var points := PackedVector2Array()
		for cell in studio.drawn_cells:
			points.append(ArrowPuzzle.pixel(cell))
		arrows.append(ArrowPuzzle.make_arrow(points, Color("#65e5ff") if studio.drawing_valid(studio.drawn_cells) else Color("#ff536b")))
	preview.set("arrows", arrows)
	preview.visible = studio.show_paths
	var key: String = studio.motif.get("reference_png", "")
	if key != reference_key:
		reference_key = key
		reference = null
		if not key.is_empty():
			var image := Image.new()
			if image.load_png_from_buffer(Marshalls.base64_to_raw(key)) == OK:
				reference = ImageTexture.create_from_image(image)
	queue_redraw()
	if is_instance_valid(studio.color_dialogue) and studio.color_dialogue.preview != null:
		studio.color_dialogue.update_preview()

func cell_at(pos: Vector2) -> Vector2i:
	return Vector2i(((pos - OFFSET) / STEP).round())

func valid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < ArrowPuzzle.COLS and cell.y >= 0 and cell.y < ArrowPuzzle.ROWS

func _gui_input(event: InputEvent) -> void:
	if studio.busy:
		return
	if studio.view_mode: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_DELETE:
			studio.delete_arrow(); accept_event()
		elif event.keycode == KEY_R:
			studio.reverse_arrow(); accept_event()
		elif event.keycode == KEY_ESCAPE:
			dragging = false; studio.show_overview(); accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := cell_at(event.position)
		if event.pressed and valid(cell):
			if studio.tool in [1, 2, 3, 4] and not studio.area_edit_allowed():
				accept_event(); return
			grab_focus()
			first = cell
			previous = cell
			last = cell
			if studio.tool == 9:
				dragging = true
				studio.drawn_cells.clear()
				studio.extend_drawing(cell)
			elif studio.tool == 10:
				studio.mirror_axis = float(cell.x)
				refresh()
				studio.notice.text = "Spiegelachse gesetzt. Wähle einen Pfeil und öffne Pfeile bearbeiten → Spiegeln."
			elif studio.tool == 11:
				studio.choose_arrow_head(ArrowPuzzle.ORIGIN + (event.position - OFFSET) / STEP * ArrowPuzzle.CELL)
			elif studio.tool == 0:
				var pos: Vector2 = ArrowPuzzle.ORIGIN + (event.position - OFFSET) / STEP * ArrowPuzzle.CELL
				if studio.show_paths and studio.arrow_at(pos) >= 0:
					studio.select_arrow_at(pos)
				else:
					if not studio.paths.is_empty(): studio.show_overview()
					else: studio.select_cell(cell)
			elif studio.tool == 8:
				studio.select_cell(cell)
			elif studio.tool == 4:
				studio.merge_cell(cell)
			elif studio.tool == 5:
				studio.select_arrow_at(ArrowPuzzle.ORIGIN + (event.position - OFFSET) / STEP * ArrowPuzzle.CELL)
			elif studio.tool == 6 or studio.tool == 7:
				studio.sample_color(ArrowPuzzle.ORIGIN + (event.position - OFFSET) / STEP * ArrowPuzzle.CELL, studio.tool == 7)
			else:
				dragging = true
				studio.remember()
				if studio.tool != 3:
					var cells: Array[Vector2i] = [cell]
					studio.paint_cells(cells)
		elif not event.pressed and dragging:
			dragging = false
			if studio.tool == 9:
				studio.finish_drawing()
			elif studio.tool == 3:
				studio.split_cells(CustomMotif.line(first, last))
			studio.refresh()
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		var cell := cell_at(event.position)
		if valid(cell):
			last = cell
			if studio.tool == 9:
				studio.extend_drawing(cell)
			elif studio.tool != 3:
				studio.paint_cells(CustomMotif.line(previous, cell))
			previous = cell
		queue_redraw()
		accept_event()

func _draw() -> void:
	draw_style_box(studio.canvas_style, Rect2(Vector2.ZERO, size))
	var fit: Array = studio.motif.get("fit", [])
	if reference != null and fit.size() == 4 and studio.show_reference and not studio.view_mode:
		draw_texture_rect(reference, Rect2(OFFSET + Vector2(fit[0], fit[1]) * STEP, Vector2(fit[2], fit[3]) * STEP), false, Color(1, 1, 1, 0.15))
	if studio.view_mode or (not studio.paths.is_empty() and studio.tool not in [9, 10] and studio.pages.current_tab == 0): return
	var lonely := CustomMotif.isolated(studio.motif)
	for y in range(ArrowPuzzle.ROWS):
		for x in range(ArrowPuzzle.COLS):
			var cell := Vector2i(x, y)
			var pos := OFFSET + Vector2(cell) * STEP
			draw_circle(pos, 1.0, Color("#23364a"))
			if not studio.motif.cells.has(cell):
				continue
			var part: int = studio.motif.cells[cell]
			var color := Color(studio.motif.palettes[part][0])
			if studio.motif.get("styles", {}).has(part):
				color = MotifColors.color_at(studio.motif.styles[part], ArrowPuzzle.pixel(cell))
			var alpha := 0.045 if studio.show_paths and not studio.paths.is_empty() else 0.24
			draw_rect(Rect2(pos - Vector2.ONE * 8, Vector2.ONE * 16), Color(color, alpha))
			if part == studio.selected and studio.paths.is_empty():
				draw_circle(pos, 2.3, color)
			if lonely.has(cell):
				draw_rect(Rect2(pos - Vector2.ONE * 7, Vector2.ONE * 14), Color("#ff536b"), false, 1.6)
	if dragging and studio.tool == 3:
		draw_line(OFFSET + Vector2(first) * STEP, OFFSET + Vector2(last) * STEP, Color.WHITE, 2.0, true)

	if studio.tool == 9 or studio.tool == 10:
		var x: float = OFFSET.x + studio.mirror_axis * STEP
		draw_dashed_line(Vector2(x, OFFSET.y), Vector2(x, OFFSET.y + (ArrowPuzzle.ROWS - 1) * STEP), Color("#65e5ff", 0.5), 1.0, 5.0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		studio.show_overview()
		get_viewport().set_input_as_handled()
