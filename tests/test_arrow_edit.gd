extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func require(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func mouse(studio: Window, cell: Vector2i, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = studio.canvas.position + studio.canvas.OFFSET + Vector2(cell) * studio.canvas.STEP
	studio.push_input(event, true)
func motion(studio: Window, cell: Vector2i) -> void:
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = studio.canvas.position + studio.canvas.OFFSET + Vector2(cell) * studio.canvas.STEP
	studio.push_input(event, true)
func key(studio: Window, code: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = code
	studio.push_input(event, true)
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.enter_editor()
	scene.open_studio()
	var studio: Window = scene.studio
	studio.motif = CustomMotif.from_shape(3)
	studio.paths = ArrowPuzzle.generate(3, 9021)
	studio.refresh()
	var original_count: int = studio.paths.size()
	var original_cells: int = studio.motif.cells.size()
	require(original_count > 0, "Butterfly starts fully filled")
	studio.open_arrow_tools()
	require(studio.arrow_tools.visible, "Arrow tools are accessible from the studio")
	studio.arrow_tools.hide()
	studio.tool = 9
	mouse(studio, Vector2i(8, 0), true)
	motion(studio, Vector2i(8, 1))
	motion(studio, Vector2i(9, 1))
	mouse(studio, Vector2i(9, 1), false)
	require(studio.paths.size() == original_count + 1 and studio.motif.cells.size() == original_cells + 3, "Real drag adds an antenna outside the filled butterfly without replacing its arrows")
	var antenna: Dictionary = studio.paths[-1].duplicate(true)
	require(antenna.points[-1] == ArrowPuzzle.pixel(Vector2i(9, 1)) and studio.selected_arrow == original_count and studio.tool == 0, "Drawn arrow selects itself and places its head at the drag end")
	studio.change_color(0, Color("#ffa050"))
	studio.mirror_axis = 14.0
	studio.mirror_arrow()
	require(studio.paths.size() == original_count + 2, "Mirroring adds the second antenna")
	var mirrored: Dictionary = studio.paths[-1]
	for i in range(antenna.points.size()):
		var left := ArrowPuzzle.grid(antenna.points[i])
		var right := ArrowPuzzle.grid(mirrored.points[i])
		require(left.x + right.x == 28 and left.y == right.y, "Antennae have exactly mirrored shapes")
	require(mirrored.color == Color("#ffa050") and mirrored.manual_color, "Mirror retains individual color")
	studio.apply()
	require(not scene.testing and is_instance_valid(scene.studio), "An unfinished blocked puzzle stays editable instead of launching a broken game")
	studio.save_draft()
	studio.load_draft(true)
	require(studio.paths.size() == original_count + 2 and studio.paths[-1].color == Color("#ffa050"), "Unsolvable drafts still preserve hand-drawn arrows and colors")
	studio.activate_tool(0)
	studio.selected_arrow = studio.paths.size() - 1
	studio.refresh()
	var old_head: Vector2 = studio.paths[-1].points[-1]
	studio.canvas.grab_focus()
	key(studio, KEY_R)
	require(studio.paths[-1].points[0] == old_head, "R moves the head to the opposite end through real keyboard input")
	require(ArrowPuzzle.solution(studio.paths).size() == studio.paths.size(), "Changing the mirrored antenna direction makes the butterfly solvable")
	studio.tool = 11
	var chosen_end := ArrowPuzzle.grid(studio.paths[-1].points[0])
	mouse(studio, chosen_end, true)
	mouse(studio, chosen_end, false)
	require(studio.paths[-1].points[-1] == ArrowPuzzle.pixel(chosen_end), "Clicking an endpoint explicitly chooses where the head goes")
	key(studio, KEY_R)
	var count_before: int = studio.paths.size()
	var used: Dictionary = studio.occupied_cells()
	var overlapping: Array[Vector2i] = [Vector2i(8, 0), Vector2i(8, 1)]
	require(not studio.add_drawn_arrow(overlapping) and studio.paths.size() == count_before and studio.occupied_cells() == used, "Overlap rejection leaves the motif untouched")
	studio.mirror_axis = 0.0
	studio.mirror_arrow()
	require(studio.paths.size() == count_before, "An out-of-bounds mirror is rejected atomically")
	var loop: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(0, 0)]
	require(not studio.add_drawn_arrow(loop), "Self-intersecting arrows are rejected")
	studio.canvas.grab_focus()
	key(studio, KEY_DELETE)
	require(studio.paths.size() == count_before - 1 and not studio.motif.cells.has(Vector2i(20, 0)), "Delete removes only the selected arrow and frees its cells")
	studio.undo()
	require(studio.paths.size() == count_before and studio.motif.cells.has(Vector2i(20, 0)), "Undo restores deleted geometry and motif cells together")
	studio.activate_tool(9)
	mouse(studio, Vector2i(0, 0), true)
	motion(studio, Vector2i(3, 3))
	for i in range(1, studio.drawn_cells.size()):
		var delta: Vector2i = studio.drawn_cells[i] - studio.drawn_cells[i - 1]
		require(absi(delta.x) + absi(delta.y) == 1, "Diagonal hand movements become legal orthogonal raster steps")
	key(studio, KEY_ESCAPE)
	mouse(studio, Vector2i(3, 3), false)
	require(studio.drawn_cells.is_empty() and studio.paths.size() == count_before, "Escape cancels a drawing without changing the motif")
	studio.activate_tool(0)
	studio.apply()
	require(scene.testing and scene.arrows.size() == count_before, "Completed custom butterfly can be played")
	scene.save_custom()
	require(scene.read_custom() and scene.arrows.size() == count_before, "Export/import preserves hand-drawn antennae")
	var order := ArrowPuzzle.solution(scene.arrows)
	for index in order:
		require(not scene.is_blocked(index), "Edited butterfly retains its verified solution")
		scene.click_at(scene.arrows[index].points[0])
		scene._process(2)
	require(scene.cleared == scene.arrows.size(), "Butterfly with both antennae plays to completion")
	for filename in ["custom_puzzle.json", "motif_draft.json", "progress.cfg", "editor_colors.json", "editor_backup.json"]:
		DirAccess.remove_absolute(scene.storage_prefix + filename)
	print("PASS real drawing, mirrored antennae, delete, reverse, overlap checks, undo, draft, export and full play" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
