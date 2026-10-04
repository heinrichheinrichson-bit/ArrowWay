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
	preview = Node2D.new()
	preview.set_script(load("res://motif_preview.gd"))
	preview.set("rounder", studio.game)
	preview.scale = Vector2.ONE * STEP / ArrowPuzzle.CELL
	preview.position = OFFSET - ArrowPuzzle.ORIGIN * STEP / ArrowPuzzle.CELL
	add_child(preview)

func refresh() -> void:
	preview.set("arrows", studio.paths)
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := cell_at(event.position)
		if event.pressed and valid(cell):
			first = cell
			previous = cell
			last = cell
			if studio.tool == 0:
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
			if studio.tool == 3:
				studio.split_cells(CustomMotif.line(first, last))
			studio.refresh()
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		var cell := cell_at(event.position)
		if valid(cell):
			last = cell
			if studio.tool != 3:
				studio.paint_cells(CustomMotif.line(previous, cell))
			previous = cell
		queue_redraw()
		accept_event()

func _draw() -> void:
	draw_style_box(studio.canvas_style, Rect2(Vector2.ZERO, size))
	var fit: Array = studio.motif.get("fit", [])
	if reference != null and fit.size() == 4 and studio.show_reference:
		draw_texture_rect(reference, Rect2(OFFSET + Vector2(fit[0], fit[1]) * STEP, Vector2(fit[2], fit[3]) * STEP), false, Color(1, 1, 1, 0.15))
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
