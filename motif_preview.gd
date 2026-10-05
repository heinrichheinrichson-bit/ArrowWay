extends Node2D

var arrows: Array[Dictionary] = []
var editor := false
var draft := PackedVector2Array()
var selected := -1
var clock_time := 0.0
var win_time := -1.0
var shape_index := 6
var motif := {}
var rounder: Node2D
var rounded_cache := {}

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

func rounded_points(points: PackedVector2Array) -> PackedVector2Array:
	var key := hash(points)
	var cached: Dictionary = rounded_cache.get(key,{})
	if cached.get("points") == points: return cached.rounded
	var rounded: PackedVector2Array = rounder.rounded_points(points)
	rounded_cache[key] = {"points":points,"rounded":rounded}
	return rounded
