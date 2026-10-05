extends Node

const MAX_ZOOM := 4.0
const DRAG_THRESHOLD := 10.0
var game: Node2D
var zoom := 1.0
var fit_scale := 1.0
var bounds := Rect2()
var center := Vector2.ZERO
var fingers := {}
var start := Vector2.ZERO
var dragged := false
var multi_touch := false
var mouse_down := false
var previous_mouse := Vector2.ZERO

func active() -> bool:
	for child in game.get_children():
		if child is Window and child.visible: return false
	return game.compact_play() and not game.generating and not is_instance_valid(game.home_menu) and not is_instance_valid(game.gallery) and not is_instance_valid(game.journey)

func cancel_gesture() -> void:
	fingers.clear()
	multi_touch = false
	dragged = false
	mouse_down = false

func configure(motif_bounds: Rect2, scale_to_fit: float) -> void:
	cancel_gesture()
	if bounds != motif_bounds: center = motif_bounds.get_center(); zoom = 1.0
	bounds = motif_bounds
	fit_scale = scale_to_fit
	apply_view()

func reset_view() -> void:
	cancel_gesture()
	zoom = 1.0
	center = bounds.get_center()
	if fit_scale > 0: apply_view()

func apply_view() -> void:
	var scale_value := fit_scale * zoom
	var half: Vector2 = game.board_clip.size / (2.0 * scale_value)
	for axis in 2:
		if half[axis]*2 >= bounds.size[axis]: center[axis] = bounds.get_center()[axis]
		else: center[axis] = clampf(center[axis],bounds.position[axis]+half[axis],bounds.end[axis]-half[axis])
	game.board.scale = Vector2.ONE * scale_value
	game.board.position = game.board_clip.size*0.5-center*scale_value

func inside(position: Vector2) -> bool:
	return Rect2(game.board_clip.global_position,game.board_clip.size).has_point(position)

func zoom_at(previous_focus: Vector2, focus: Vector2, factor: float) -> void:
	var anchor: Vector2 = game.board.get_global_transform().affine_inverse()*previous_focus
	zoom = clampf(zoom*factor,1.0,MAX_ZOOM)
	center = anchor-(focus-game.board_clip.global_position-game.board_clip.size*0.5)/(fit_scale*zoom)
	apply_view()

func _process(_delta: float) -> void:
	if not active() and (not fingers.is_empty() or mouse_down): cancel_gesture()

func _input(event: InputEvent) -> void:
	if not active(): return
	if event is InputEventScreenTouch:
		if event.pressed:
			if not inside(event.position): return
			fingers[event.index] = event.position
			if fingers.size()==1: start=event.position; dragged=false; multi_touch=false
			else: multi_touch=true; dragged=true
		elif fingers.has(event.index):
			var tap: bool = fingers.size()==1 and not dragged and not multi_touch and inside(event.position) and event.position.distance_to(start)<DRAG_THRESHOLD
			fingers.erase(event.index)
			if tap and game.win_time<0: game.click_at(game.board.get_global_transform().affine_inverse()*event.position)
			if fingers.is_empty():
				cancel_gesture(); game.queue_session()
		else: return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and fingers.has(event.index):
		var previous: Vector2 = fingers[event.index]
		if fingers.size()>=2:
			var keys := fingers.keys()
			var first: Vector2 = fingers[keys[0]]
			var second: Vector2 = fingers[keys[1]]
			var old_mid := (first+second)*0.5
			var old_distance := first.distance_to(second)
			fingers[event.index] = event.position
			first=fingers[keys[0]]; second=fingers[keys[1]]
			if old_distance>4: zoom_at(old_mid,(first+second)*0.5,first.distance_to(second)/old_distance)
		else:
			fingers[event.index] = event.position
			if event.position.distance_to(start)>=DRAG_THRESHOLD: dragged=true
			if dragged and not multi_touch and zoom>1:
				center -= (event.position-previous)/(fit_scale*zoom)
				apply_view()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		if event.device==InputEvent.DEVICE_ID_EMULATION: return
		if event.pressed and inside(event.position) and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(event.position,event.position,1.2 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1.0/1.2)
			game.queue_session()
			get_viewport().set_input_as_handled()
		elif event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed and inside(event.position):
				mouse_down=true; previous_mouse=event.position; start=event.position; dragged=false
			elif not event.pressed and mouse_down:
				mouse_down=false
				if not dragged and inside(event.position) and game.win_time<0: game.click_at(game.board.get_global_transform().affine_inverse()*event.position)
			else: return
			if not mouse_down: game.queue_session()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and mouse_down and event.device!=InputEvent.DEVICE_ID_EMULATION:
		if event.position.distance_to(start)>=DRAG_THRESHOLD: dragged=true
		if dragged and zoom>1:
			center-=(event.position-previous_mouse)/(fit_scale*zoom)
			apply_view()
		previous_mouse=event.position
		get_viewport().set_input_as_handled()
