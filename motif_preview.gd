extends Node2D

var arrows: Array[Dictionary] = []
var editor := false
var draft := PackedVector2Array()
var selected := -1
var clock_time := 0.0
var shape_index := 6
var motif := {}
var rounder: Node2D

func _ready() -> void:
	var board := Node2D.new()
	board.set_script(load("res://board.gd"))
	board.set("game", self)
	add_child(board)

func _process(delta: float) -> void:
	clock_time += delta

func visible_points(arrow: Dictionary) -> PackedVector2Array:
	if not arrow.has("draw_points"):
		arrow.draw_points = rounder.rounded_points(arrow.points)
	return arrow.draw_points
