extends SceneTree

var failures := 0

func mouse_click(pos: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = pos
		event.global_position = pos
		root.push_input(event, true)

func require(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	for level in range(6):
		scene.level = level
		scene.testing = false
		scene.reset()
		var order := ArrowPuzzle.solution(scene.arrows)
		require(scene.arrows.size() >= 15, "Level needs enough paths")
		require(order.size() == scene.arrows.size(), "Generated level must be solvable")
		var used := {}
		var directions := {}
		var blocked := -1
		for i in range(scene.arrows.size()):
			var points: PackedVector2Array = scene.arrows[i].points
			directions[points[-1] - points[-2]] = true
			for point in points:
				require(not used.has(point), "Paths must not overlap")
				require(ArrowPuzzle.mask(level % 3).has(ArrowPuzzle.grid(point)), "Paths must fit silhouette")
				used[point] = true
			if scene.is_blocked(i):
				blocked = i
		require(directions.size() >= 3, "Level needs varied arrow directions")
		require(blocked >= 0, "Level must contain dependencies")
		if blocked >= 0:
			scene.click_at(scene.arrows[blocked].points[0])
			require(not scene.arrows[blocked].escaping and scene.arrows[blocked].flash > 0, "Blocked click must flash")
		scene.show_hint()
		var hints := 0
		for a in scene.arrows:
			if a.hint > 0:
				hints += 1
		require(hints == 1, "Hint must identify one free path")
		for i in order:
			require(not scene.is_blocked(i), "Solver and runtime must agree")
			scene.click_at(scene.arrows[i].points[0])
			require(scene.arrows[i].escaping, "Valid click starts animation")
			scene._process(2.0)
			require(scene.arrows[i].removed, "Animation exits in every direction")
		require(scene.cleared == scene.arrows.size(), "All paths must clear")
		require(scene.next_button.visible, "Win exposes next-level action")
		print("PASS level %d: %d paths, %d directions, coverage %d/%d" % [level + 1, scene.arrows.size(), directions.size(), used.size(), ArrowPuzzle.mask(level % 3).size()])
	# Two facing paths are mutually blocked.
	var deadlock: Array[Dictionary] = [
		ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(100, 200), Vector2(120, 200)]), Color.WHITE),
		ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(180, 200), Vector2(160, 200)]), Color.WHITE)]
	require(ArrowPuzzle.solution(deadlock).is_empty(), "Solver must reject a dependency cycle")
	# Parallel paths on the same line must block too.
	require(ArrowPuzzle.ray_hits(deadlock[0].points, deadlock[1].points), "Collinear segments must block")
	var self_loop := PackedVector2Array([Vector2(100, 160), Vector2(140, 160), Vector2(140, 200), Vector2(120, 200), Vector2(120, 180)])
	require(ArrowPuzzle.self_blocked(self_loop), "A head aimed at its own body must be rejected")
	scene.level = 0
	scene.testing = false
	scene.reset()
	scene.enter_editor()
	scene.arrows.clear()
	scene.add_draft(ArrowPuzzle.pixel(Vector2i(4, 10)))
	scene.add_draft(ArrowPuzzle.pixel(Vector2i(7, 10)))
	scene.add_draft(ArrowPuzzle.pixel(Vector2i(7, 12)))
	require(scene.draft.size() == 6, "Editor expands clicks into continuous orthogonal cells")
	scene.finish_draft()
	require(scene.arrows.size() == 1 and scene.draft.is_empty(), "Finish adds a real path")
	var original: PackedVector2Array = scene.arrows[0].points.duplicate()
	scene.reverse_selected()
	require(scene.arrows[0].points[0] == original[-1], "Reverse changes arrow direction")
	require(scene.check_editor(), "Custom puzzle must be solvable")
	scene.save_custom()
	scene.arrows.clear()
	require(scene.read_custom(), "Saved puzzle must load")
	require(scene.arrows[0].points[0] == original[-1], "Save/load preserves path direction")
	require(scene.arrows[0].color == Color(ArrowPuzzle.PALETTE[0]), "Save/load preserves color")
	scene.test_editor()
	require(scene.testing and not scene.editor, "Test enters play mode")
	scene.click_at(scene.arrows[0].points[0])
	scene._process(2)
	require(scene.cleared == 1, "Custom test puzzle is playable")
	scene.enter_editor()
	require(scene.editor and scene.arrows.size() == 1 and not scene.arrows[0].removed, "Return restores editable source")
	scene.draft = PackedVector2Array([Vector2(1, 1)])
	require(not scene.check_editor(), "Unfinished drafts must prevent testing and saving")
	scene.draft.clear()
	scene.selected = 0
	scene.undo_edit()
	require(scene.arrows.is_empty(), "Delete removes selected path")
	scene.shape_index = 1
	scene.fill_template()
	require(scene.arrows.size() > 15 and scene.check_editor(), "Template fill creates a solvable tree")
	# Malformed saves must not partially replace the current puzzle.
	var file := FileAccess.open(scene.storage_prefix + "custom_puzzle.json", FileAccess.WRITE)
	file.store_string('{"paths":[{"points":[[1,2],[1,2]]}]}')
	file.close()
	require(not scene.read_custom(), "Malformed paths must be rejected")
	for shape in range(3):
		for seed_value in range(10):
			var generated := ArrowPuzzle.generate(shape, seed_value * 731 + 8)
			require(ArrowPuzzle.solution(generated).size() == generated.size(), "Additional generator seeds must remain solvable")
	scene.leave_editor()
	await process_frame
	var free := ArrowPuzzle.solution(scene.arrows)[0]
	mouse_click(scene.arrows[free].points[0])
	require(scene.arrows[free].escaping, "Mouse events must reach the playfield through the UI")
	scene.reset()
	await process_frame
	mouse_click(Vector2(440, 120))
	require(scene.editor, "Editor button must receive real GUI input")
	scene.leave_editor()
	await process_frame
	free = ArrowPuzzle.solution(scene.arrows)[0]
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = scene.arrows[free].points[0]
	root.push_input(touch, true)
	require(scene.arrows[free].escaping, "Touch events must reach the playfield")
	for name in ["progress.cfg", "custom_puzzle.json"]:
		DirAccess.remove_absolute(scene.storage_prefix + name)
	print("PASS editor, hints, deadlocks, save/load, test/return, invalid data" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
