extends Node2D

var game: Node2D

func _draw() -> void:
	game.draw_paths(self)
