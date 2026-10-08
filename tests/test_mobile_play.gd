extends SceneTree

var failures := 0

func require(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.storage_prefix = "user://test_mobile_"
	root.add_child(scene)
	await process_frame
	for size in [Vector2i(540, 850), Vector2i(540, 1170), Vector2i(720, 960), Vector2i(960, 720), Vector2i(1024, 768)]:
		root.size = size
		await process_frame
		scene.update_play_layout()
		require(not scene.level_picker.visible and not scene.sound_button.visible, "Settings and level picker stay out of play")
		require(not scene.next_button.visible, "No bottom action during play")
		require(scene.compact_buttons.size() == 3, "Only three compact play actions")
		for button in scene.compact_buttons:
			require(button.size.x >= 48 and button.size.y >= 48, "Small symbols keep generous touch targets")
		for arrow in scene.arrows:
			for point in arrow.points:
				var screen: Vector2 = scene.board.get_global_transform() * point
				require(Rect2(scene.board_clip.position, scene.board_clip.size).has_point(screen), "Whole motif fits without clipping")
		var index: int = ArrowPuzzle.solution(scene.arrows)[0]
		var touch := InputEventScreenTouch.new()
		touch.pressed = true
		touch.position = scene.board.get_global_transform() * scene.arrows[index].points[0]
		root.push_input(touch, true)
		require(not scene.arrows[index].escaping, "Touch-down waits for a tap so a second finger can begin zooming")
		touch=touch.duplicate(); touch.pressed=false
		root.push_input(touch,true)
		require(scene.arrows[index].escaping, "Transformed touch reaches the correct enlarged arrow")
		scene.reset()
		if OS.get_cmdline_user_args().has("--capture"):
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://previews/mobile-%dx%d.png" % [size.x, size.y])
	var original = scene.arrows
	var hint_touch := InputEventScreenTouch.new()
	hint_touch.pressed = true
	hint_touch.position = root.get_final_transform() * (scene.compact_buttons[2].global_position + Vector2(24, 24))
	Input.parse_input_event(hint_touch)
	await process_frame
	hint_touch = hint_touch.duplicate()
	hint_touch.pressed = false
	Input.parse_input_event(hint_touch)
	await process_frame
	require(scene.arrows.any(func(arrow): return arrow.hint > 0), "Compact hint button accepts real touch events")
	var targets: Array[Dictionary] = [ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(100, 200), Vector2(200, 200)]), Color.GREEN), ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(100, 240), Vector2(200, 240)]), Color.BLUE)]
	scene.arrows = targets
	require(scene.pick(Vector2(150, 200 + 16 / scene.board.scale.x)) == 0, "Near miss inside the expanded target selects the nearest arrow")
	require(scene.pick(Vector2(150, 239)) == 1, "Closer neighbor wins")
	scene.arrows[1].removed = true
	require(scene.pick(Vector2(150, 239)) == -1, "Removed arrows cannot be tapped")
	var adjacent: Array[Dictionary] = [ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(170, 350), Vector2(270, 350)]), Color.GREEN), ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(170, 360), Vector2(270, 360)]), Color.BLUE)]
	scene.arrows = adjacent
	var arrow_touch := InputEventScreenTouch.new()
	arrow_touch.pressed = true
	arrow_touch.position = root.get_final_transform() * (scene.board.get_global_transform() * Vector2(200, 350))
	Input.parse_input_event(arrow_touch)
	await process_frame
	arrow_touch = arrow_touch.duplicate()
	arrow_touch.pressed = false
	Input.parse_input_event(arrow_touch)
	await process_frame
	require(scene.arrows[0].escaping and not scene.arrows[1].escaping, "One native touch plus its emulated mouse event launches exactly one arrow")
	scene.arrows = original
	scene.open_gallery()
	root.size = Vector2i(540, 1170)
	await process_frame
	scene.update_play_layout()
	require(scene.gallery.get_child(0).size == scene.get_viewport_rect().size, "Library background covers a tall display")
	require(scene.gallery.get_child(3).size.y > 427, "Library uses extra display height")
	scene.close_gallery()
	scene.open_home()
	var clock: float = scene.clock_time
	scene._process(1.0)
	require(scene.clock_time == clock, "Main menu pauses the puzzle")
	root.size = Vector2i(720, 960)
	await process_frame
	scene.update_play_layout()
	require(scene.home_menu.get_child(0).size == scene.get_viewport_rect().size, "Main menu adapts after resizing")
	if OS.get_cmdline_user_args().has("--capture"):
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://previews/mobile-home.png")
	scene.open_settings()
	var dialog: AcceptDialog = scene.get_child(scene.get_child_count() - 1)
	require(dialog.visible, "Settings open from the main menu")
	dialog.queue_free()
	scene.close_home()
	require(not is_instance_valid(scene.home_menu), "Continue closes the main menu")
	for name in ["progress.cfg", "settings.cfg", "library.cfg"]:
		DirAccess.remove_absolute(scene.storage_prefix + name)
	print("PASS mobile play: responsive motif, compact actions, large targets, transformed touch, nearest selection and menu pause" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
