extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func wait_worker(studio: Window) -> void:
	var deadline := Time.get_ticks_msec() + 60000
	while studio.busy and Time.get_ticks_msec() < deadline: await process_frame
	require(not studio.busy, "Worker finishes")
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
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.enter_editor(); scene.open_studio()
	var studio: Window = scene.studio
	require(not studio.paths.is_empty(), "Opening the workshop retains the current game motif and its exact arrows")
	studio.motif = CustomMotif.from_shape(3)
	studio.paths = ArrowPuzzle.generate(3, 9021)
	studio.refresh()
	var original := CustomMotif.encode_paths(studio.paths)
	studio.tool_picker.item_selected.emit(1)
	require(CustomMotif.encode_paths(studio.paths) == original, "Selecting area painting never removes existing arrows")
	studio.new_region()
	var part: int = studio.selected
	mouse(studio, Vector2i(1, 32), true)
	motion(studio, Vector2i(4, 32))
	mouse(studio, Vector2i(4, 32), false)
	require(studio.motif.cells.get(Vector2i(1,32), -1) == part and studio.motif.cells.get(Vector2i(4,32), -1) == part and CustomMotif.encode_paths(studio.paths) == original, "Real painting adds a new region to an already filled motif without replacing arrows")
	var first := ArrowPuzzle.grid(studio.paths[0].points[0])
	var previous_owner: int = studio.motif.cells[first]
	mouse(studio, first, true); mouse(studio, first, false)
	require(studio.motif.cells[first] == previous_owner and CustomMotif.encode_paths(studio.paths) == original, "Area brush never damages occupied arrow cells")
	studio.apply()
	require(not scene.testing and is_instance_valid(scene.studio), "Unfilled new regions remain editable instead of launching an incomplete puzzle")
	studio.save_draft(); studio.load_draft(true)
	require(studio.paths.size() == original.size() and studio.motif.cells.get(Vector2i(4,32), -1) == part, "Partially filled drafts preserve existing arrows and unfilled new regions")
	studio.fill()
	await wait_worker(studio)
	require(studio.paths.size() > original.size(), "Fill adds arrows only to the new free region")
	for i in range(original.size()):
		require(CustomMotif.encode_paths([studio.paths[i]])[0] == original[i], "Gap filling retains every original arrow's geometry and color")
	require(studio.occupied_cells().size() == studio.motif.cells.size(), "Added region is fully filled")
	studio.select_arrow_at(studio.paths[0].points[0])
	studio.begin_color_edit()
	studio.arrow_color.color_changed.emit(Color("#ffcc55"))
	studio.arrow_color.color_changed.emit(Color("#44ee99"))
	studio.arrow_color.popup_closed.emit()
	require(studio.recent_colors[0] == Color("#44ee99") and not studio.recent_colors.has(Color("#ffcc55")), "Recent colors remember the chosen color, not every slider intermediate")
	var history_size: int = studio.history.size()
	studio.undo()
	require(studio.history.size() == history_size - 1 and CustomMotif.encode_paths([studio.paths[0]])[0] == original[0], "One undo restores the color before a complete picker gesture")
	studio.select_arrow_at(studio.paths[0].points[0])
	studio.refresh_color_chips()
	studio.recent_row.get_child(0).pressed.emit()
	require(studio.paths[0].color == Color("#44ee99") and CustomMotif.encode_paths([studio.paths[1]])[0] == original[1], "One-click recent color edits only the selected arrow")
	studio.show_overview()
	require(studio.selected_arrow == -1 and studio.view_mode and studio.drawn_cells.is_empty(), "Overview clears highlighting and exits every edit tool")
	var before_overview := CustomMotif.encode_paths(studio.paths)
	mouse(studio, first, true); mouse(studio, first, false)
	require(CustomMotif.encode_paths(studio.paths) == before_overview and studio.selected_arrow == -1, "Overview ignores edits and accidental clicks")
	studio.activate_tool(0)
	mouse(studio, first, true); mouse(studio, first, false)
	require(studio.selected_arrow == 0 and not studio.view_mode, "Select explicitly returns to individual arrow editing")
	var key := InputEventKey.new()
	key.pressed = true; key.keycode = KEY_ESCAPE
	studio.push_input(key, true)
	require(studio.view_mode and studio.selected_arrow == -1, "Escape safely returns to the entire composition")
	studio.fill()
	require(not studio.busy and CustomMotif.encode_paths(studio.paths) == before_overview, "Filling an already filled motif never regenerates it accidentally")
	studio.source = preload("res://tests/image_fixtures.gd").sun()
	studio.analyze_image()
	require(is_instance_valid(studio.replace_dialog) and not studio.busy and CustomMotif.encode_paths(studio.paths) == before_overview, "Replacing a source requires explicit confirmation before any arrows change")
	studio.replace_dialog.canceled.emit()
	await process_frame
	require(CustomMotif.encode_paths(studio.paths) == before_overview, "Canceling replacement keeps the exact current work")
	studio.confirm_replace(func(): studio.paths.clear(); studio.refresh(), "Test replacement")
	studio.replace_dialog.confirmed.emit()
	await process_frame
	require(studio.paths.is_empty(), "Confirmed replacement executes")
	studio.restore_backup()
	require(CustomMotif.encode_paths(studio.paths) == before_overview, "Persistent backup restores replaced arrows and colors exactly")
	var other := Window.new()
	other.set_script(load("res://motif_studio.gd")); other.set("game", scene)
	other.load_recent_colors()
	require(other.recent_colors[0] == Color("#44ee99"), "Recent colors persist across editor sessions")
	other.free()
	studio.activate_tool(0); studio.apply()
	require(scene.testing, "Expanded butterfly is playable")
	scene.save_custom()
	require(scene.read_custom(), "Expanded motif exports and imports")
	var exported: Dictionary = scene.level_document()
	scene.enter_editor(); scene.open_studio()
	studio = scene.studio
	require(studio.paths.size() == exported.paths.size(), "Reopening a custom game keeps its complete edited artwork")
	for level in range(1, 10):
		require(studio.open_document("res://levels/%02d.json" % level, true) and not studio.paths.is_empty(), "Every existing built-in level opens for motif editing")
	studio.open_document(scene.storage_prefix + "custom_puzzle.json", true)
	require(CustomMotif.encode_paths(studio.paths) == exported.paths, "Existing exported custom levels open without changing their arrows")
	for filename in ["editor_colors.json", "editor_backup.json", "custom_puzzle.json", "motif_draft.json", "progress.cfg"]:
		DirAccess.remove_absolute(scene.storage_prefix + filename)
	print("PASS safe area painting, existing-image extensions, gap fill, overview, recent colors, grouped undo, confirmations, backups and export" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
