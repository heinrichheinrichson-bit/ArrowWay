extends Button

var colors: Array = []
var label := ""

func _draw() -> void:
	if colors.is_empty():
		return
	var style := {"mode": 4, "colors": colors, "bounds": [0, 0, size.x, 24], "strength": 0.5}
	for step in range(40):
		var x := 5 + (size.x - 10) * step / 40.0
		draw_rect(Rect2(x, 6, (size.x - 10) / 40.0 + 0.5, 22), MotifColors.color_at(style, Vector2(x, 10)))
	draw_string(ThemeDB.fallback_font, Vector2(0, 48), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color("#e0e8f5"))
