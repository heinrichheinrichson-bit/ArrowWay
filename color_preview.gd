extends Control

var dialogue: Window
var preview: Node2D
var motif := {}
var has_paths := false

func _ready() -> void:
	clip_contents = true
	preview = Node2D.new()
	preview.set_script(load("res://motif_preview.gd"))
	preview.set("rounder", dialogue.studio.game)
	preview.scale = Vector2.ONE * 0.87
	preview.position = Vector2(222, 216) - Vector2(270, 407) * 0.87
	add_child(preview)

func refresh() -> void:
	var document: Dictionary = dialogue.preview_document()
	motif = document.motif
	var paths: Array[Dictionary] = document.paths
	has_paths = not paths.is_empty()
	preview.set("arrows", paths)
	queue_redraw()

func _draw() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b1421")
	style.set_corner_radius_all(12)
	draw_style_box(style, Rect2(Vector2.ZERO, size))
	if has_paths:
		return
	for cell in motif.get("cells", {}):
		var part: int = motif.cells[cell]
		var pos := ArrowPuzzle.pixel(cell)
		var color := Color(motif.palettes[part][0])
		if motif.get("styles", {}).has(part):
			color = MotifColors.color_at(motif.styles[part], pos)
		draw_rect(Rect2(Vector2(222, 216) + (pos - Vector2(270, 407)) * 0.87 - Vector2.ONE * 5.4, Vector2.ONE * 10.8), color)
