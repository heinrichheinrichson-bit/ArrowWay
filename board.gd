extends Node2D

const NEON := preload("res://neon.gdshader")
var game: Node2D
var strokes: Array[ColorRect] = []

func _process(_delta: float) -> void:
	var count: int = game.arrows.size() + (1 if game.editor and game.draft.size() > 1 else 0)
	while strokes.size() < count:
		var stroke := ColorRect.new()
		stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = NEON
		stroke.material = material
		add_child(stroke)
		strokes.append(stroke)
	for i in range(strokes.size()):
		strokes[i].visible = i < count
	for i in range(game.arrows.size()):
		var a: Dictionary = game.arrows[i]
		if a.removed:
			strokes[i].visible = false
			continue
		var color: Color = a.color
		var highlighted: bool = a.hint > 0 or (game.editor and i == game.selected)
		if a.flash > 0:
			color = Color("#ff536b")
		elif highlighted:
			color = Color.WHITE
		update_stroke(strokes[i], game.visible_points(a), color, highlighted)
	if count > game.arrows.size():
		update_stroke(strokes[count - 1], game.rounded_points(game.draft), Color.WHITE, true)
	queue_redraw()

func update_stroke(stroke: ColorRect, points: PackedVector2Array, color: Color, highlighted: bool) -> void:
	if points.size() < 2:
		stroke.visible = false
		return
	var material: ShaderMaterial = stroke.material
	material.set_shader_parameter("neon_color", color)
	material.set_shader_parameter("emphasis", 0.5 + sin(game.clock_time * 6.0) * 0.5 if highlighted else 0.0)
	if stroke.get_meta("source", PackedVector2Array()) == points:
		return
	stroke.set_meta("source", points.duplicate())
	var direction := (points[-1] - points[-2]).normalized()
	var side := direction.orthogonal()
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	bounds = bounds.grow(19.0)
	stroke.position = bounds.position
	stroke.size = bounds.size
	var body := points.duplicate()
	var trim := 3.4
	while body.size() > 2 and body[-1].distance_to(body[-2]) < trim:
		trim -= body[-1].distance_to(body[-2])
		body.remove_at(body.size() - 1)
	body[-1] -= (body[-1] - body[-2]).normalized() * trim
	var packed := PackedFloat32Array()
	for point in body:
		var local := point - bounds.position
		packed.append(local.x)
		packed.append(local.y)
	var texture := ImageTexture.create_from_image(Image.create_from_data(body.size(), 1, false, Image.FORMAT_RGF, packed.to_byte_array()))
	material.set_shader_parameter("path_points", texture)
	material.set_shader_parameter("point_count", body.size())
	material.set_shader_parameter("tip", points[-1] + direction * 4.8 - bounds.position)
	material.set_shader_parameter("wing_a", points[-1] - direction * 4.0 + side * 4.4 - bounds.position)
	material.set_shader_parameter("wing_b", points[-1] - direction * 4.0 - side * 4.4 - bounds.position)

func _draw() -> void:
	if game.editor:
		for cell: Vector2i in ArrowPuzzle.mask(game.shape_index):
			draw_circle(ArrowPuzzle.pixel(cell), 1.7, Color("#334d68"))
		if game.draft.size() == 1:
			draw_circle(game.draft[0], 2.1, Color.WHITE)
