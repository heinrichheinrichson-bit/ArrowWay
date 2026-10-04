extends Button

var number := 0
var title := ""
var subtitle := ""
var paths: Array[Dictionary] = []
var selected := false
var complete := false

func _draw() -> void:
	var alpha := 0.35 if disabled else 1.0
	var font := ThemeDB.fallback_font
	for arrow in paths:
		var points: PackedVector2Array = arrow.points
		var scaled := PackedVector2Array()
		for point in points:
			scaled.append(Vector2(116, 66) + (point - Vector2(270, 407)) * 0.20)
		var color: Color = arrow.color
		color.a = alpha
		draw_polyline(scaled, Color(color, 0.09 * alpha), 4.0, true)
		if arrow.has("color_style"):
			var colors := PackedColorArray()
			for point in points:
				var tint := MotifColors.color_at(arrow.color_style, point)
				tint.a = alpha
				colors.append(tint)
			draw_polyline_colors(scaled, colors, 1.25, true)
			color = colors[-1]
		else:
			draw_polyline(scaled, color, 1.25, true)
		var direction := (scaled[-1] - scaled[-2]).normalized()
		var head := scaled[-1] + direction * 1.0
		draw_line(head, head - direction.rotated(0.55) * 3.0, color, 1.2, true)
		draw_line(head, head - direction.rotated(-0.55) * 3.0, color, 1.2, true)
	var ink := Color(0.90, 0.95, 1.0, alpha)
	draw_string(font, Vector2(14, 22), "%02d" % (number + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ink)
	var display_title := title
	while font.get_string_size(display_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x > size.x - 18 and display_title.length() > 2:
		display_title = display_title.trim_suffix("…").left(display_title.trim_suffix("…").length() - 1) + "…"
	draw_string(font, Vector2(0, 132), display_title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, ink)
	var state := "Gesperrt" if disabled else ("Geschafft" if complete else subtitle)
	draw_string(font, Vector2(0, 154), state, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color(0.50, 0.72, 0.83, alpha))
	if selected:
		draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color("#65e5ff"), false, 1.5)
