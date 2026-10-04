extends SceneTree

var failures := 0

func require(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.storage_prefix = "user://test_completion_"
	root.add_child(scene)
	await process_frame
	var original = scene.clone_data(scene.arrows)
	for index in ArrowPuzzle.solution(scene.arrows):
		scene.click_at(scene.arrows[index].points[0])
		scene._process(2.0)
	require(scene.win_time == 0.0, "Celebration starts only after the last arrow leaves")
	require(scene.next_button.visible and scene.next_button.disabled, "Next action waits for the artwork reveal")
	for time in [0.0, 0.65, 1.3, 2.2]:
		scene.win_time = time
		scene._process(0.0)
		scene.board._process(0.0)
		for index in scene.arrows.size():
			var stroke: ColorRect = scene.board.strokes[index]
			require(stroke.visible, "Removed arrows participate in the completion artwork")
			require(stroke.get_meta("source") == scene.rounded_points(original[index].points), "Completion uses original geometry")
			require(is_equal_approx(float(stroke.material.get_shader_parameter("completion_time")), time), "All strokes share the reveal clock")
			require(scene.arrows[index].removed, "Celebration does not restore playable arrows")
		if OS.get_cmdline_user_args().has("--capture"):
			scene.set_process(false)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://previews/completion-%02d.png" % int(time * 10))
	scene._process(0.0)
	require(not scene.next_button.disabled, "Next action is available after the reveal")
	scene.reset()
	scene.board._process(0.0)
	require(scene.win_time < 0 and scene.cleared == 0 and not scene.next_button.visible, "Restart resets completion state")
	for stroke in scene.board.strokes:
		require(stroke.material.get_shader_parameter("completion_time") == -1.0, "Restart clears the shader reveal")
	# Exercise a custom motif with authored color gradients, as used by the catalog/editor.
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	require(scene.read_custom(catalog.levels[0].path), "Custom motif loads for completion")
	for arrow in scene.arrows:
		arrow.removed = true
	scene.cleared = scene.arrows.size()
	scene.win_time = 1.3
	scene.board._process(0.0)
	for index in scene.arrows.size():
		var arrow: Dictionary = scene.arrows[index]
		var material: ShaderMaterial = scene.board.strokes[index].material
		require(material.get_shader_parameter("neon_color") == arrow.color, "Completion preserves individual arrow colors")
		var style: Dictionary = arrow.get("color_style", {})
		if not style.is_empty() and int(style.mode) > 1:
			require(material.get_shader_parameter("gradient_enabled"), "Completion preserves authored gradients")
	for name in ["progress.cfg", "settings.cfg", "library.cfg"]:
		DirAccess.remove_absolute(scene.storage_prefix + name)
	print("PASS completion: original artwork, synchronized reveal, removed state, next action and restart" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
