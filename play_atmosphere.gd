extends ColorRect

var game: Node2D

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	material=ShaderMaterial.new()
	material.shader=load("res://play_atmosphere.gdshader")

func configure() -> void:
	# The palette belongs to the complete artwork, including removed arrows.
	# It is cached on level load so gameplay never changes the background color.
	var colors: Array[Color]=[]
	var weights: Array[float]=[]
	for arrow in game.arrows:
		var color: Color=arrow.color
		var index := colors.find(color)
		if index<0:
			index=colors.size(); colors.append(color); weights.append(0.0)
		weights[index]+=game.path_length(arrow.points)
	var first := -1
	var second := -1
	for index in colors.size():
		if first<0 or weights[index]>weights[first]: second=first; first=index
		elif second<0 or weights[index]>weights[second]: second=index
	var primary := colors[first] if first>=0 else Color("#68eed2")
	var other := colors[second] if second>=0 else primary
	material.set_shader_parameter("accent",primary)
	material.set_shader_parameter("secondary",other)
	material.set_shader_parameter("completion",-1.0)

func _process(_delta: float) -> void:
	size=game.get_viewport_rect().size
	visible=game.compact_play() and not is_instance_valid(game.home_menu) and not is_instance_valid(game.journey) and not is_instance_valid(game.gallery)
	if visible: material.set_shader_parameter("completion",game.win_time)
