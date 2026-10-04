extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func require(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func wait_worker(studio: Window) -> void:
	var deadline := Time.get_ticks_msec() + 60000
	while studio.busy and Time.get_ticks_msec() < deadline:
		await process_frame
	require(not studio.busy, "Background calculation must finish")

func mouse(window: Window, pos: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = pos
	event.global_position = pos
	window.push_input(event, true)

func run() -> void:
	var house := preload("res://tests/image_fixtures.gd").outline_house()
	var palm := preload("res://tests/image_fixtures.gd").colored_palm()
	var outline := MotifImport.analyze(house)
	var color := MotifImport.analyze(palm)
	require(not outline.is_empty() and outline.palettes.size() == 5, "Closed house contours detect roof, facade, two windows and door")
	require(not color.is_empty() and color.palettes.size() == 2, "Transparent palm detects green crown and brown trunk")
	var empty := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	empty.fill(Color.WHITE)
	require(MotifImport.analyze(empty).is_empty(), "Blank images are rejected")
	var silhouette := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	silhouette.fill(Color.TRANSPARENT)
	silhouette.fill_rect(Rect2i(10, 10, 44, 44), Color.BLACK)
	require(MotifImport.analyze(silhouette).palettes.size() == 1, "Opaque black silhouettes on transparency remain usable")
	for motif in [outline, color]:
		require(CustomMotif.isolated(motif).is_empty(), "Fixtures have enough room for arrows")
		var decoded := CustomMotif.decode(JSON.parse_string(JSON.stringify(CustomMotif.encode(motif))))
		require(decoded.cells == motif.cells and decoded.palettes == motif.palettes, "Mask and palettes survive JSON roundtrip")
		var generated := LevelDesign.refine(6, 4817, 10, 120, motif)
		require(not generated.is_empty(), "Imported shapes can be filled")
		var covered := {}
		for arrow in generated:
			var part: int = motif.cells[ArrowPuzzle.grid(arrow.points[0])]
			for point in arrow.points:
				var cell := ArrowPuzzle.grid(point)
				require(not covered.has(cell) and motif.cells.get(cell, -1) == part, "Paths respect imported regions without overlaps")
				covered[cell] = true
		require(covered.size() == motif.cells.size(), "Imported fills cover every accepted cell")
		require(ArrowPuzzle.solution(generated).size() == generated.size(), "Imported fills have a full solution")
		print("PASS imported motif: %d regions, %d cells, %d paths" % [motif.palettes.size(), motif.cells.size(), generated.size()])
	var rectangle := {"cells": {}, "palettes": {0: ["#20f58a"]}, "names": {0: "Blatt"}}
	for y in range(5, 13):
		for x in range(4, 16):
			rectangle.cells[Vector2i(x, y)] = 0
	var coverage: int = rectangle.cells.size()
	require(CustomMotif.split(rectangle, 0, CustomMotif.line(Vector2i(10, 4), Vector2i(10, 14))), "A separator splits a selected area")
	require(rectangle.palettes.size() == 2 and rectangle.cells.size() == coverage, "Splitting keeps all cells and duplicates palette")
	var malformed := CustomMotif.encode(rectangle)
	malformed.cells.append(malformed.cells[0])
	require(CustomMotif.decode(malformed).is_empty(), "Duplicate mask cells are rejected")
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.enter_editor()
	scene.open_studio()
	var studio: Window = scene.studio
	await process_frame
	studio.source = house
	studio.analyze_image()
	require(studio.busy and studio.actions[0].disabled, "Detection disables editing while running")
	await wait_worker(studio)
	require(studio.motif.palettes.size() == 5, "Studio applies detected regions")
	studio.selected = 1
	studio.tool = 3
	var first: Vector2 = studio.canvas.position + studio.canvas.OFFSET + Vector2(1, 25) * studio.canvas.STEP
	var last: Vector2 = studio.canvas.position + studio.canvas.OFFSET + Vector2(27, 25) * studio.canvas.STEP
	var before: int = studio.motif.cells.size()
	mouse(studio, first, true)
	var motion := InputEventMouseMotion.new()
	motion.position = last
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	studio.push_input(motion, true)
	mouse(studio, last, false)
	require(studio.motif.palettes.size() > 5 and studio.motif.cells.size() == before, "Real separator gesture creates regions without holes")
	studio.undo()
	require(studio.motif.palettes.size() == 5, "Undo restores a split")
	studio.new_region()
	studio.tool = 1
	var pos: Vector2 = studio.canvas.position + studio.canvas.OFFSET + Vector2(1, 1) * studio.canvas.STEP
	mouse(studio, pos, true)
	mouse(studio, pos, false)
	require(studio.motif.cells.get(Vector2i(1, 1), -1) == studio.selected, "Real canvas input paints a selected region")
	studio.fill()
	require(not studio.busy and studio.notice.text.contains("Einzelpunkte"), "Single-cell regions cannot silently lose coverage")
	studio.undo()
	require(not studio.motif.cells.has(Vector2i(1, 1)), "Undo restores the mask")
	studio.undo()
	studio.fill()
	await wait_worker(studio)
	require(not studio.paths.is_empty(), "Studio fills asynchronously")
	var geometry: PackedVector2Array = studio.paths[0].points.duplicate()
	studio.selected = studio.motif.cells[ArrowPuzzle.grid(geometry[0])]
	studio.set_palette(CustomMotif.PALETTES["Gold"])
	require(studio.paths[0].points == geometry and studio.paths[0].color == Color(CustomMotif.PALETTES["Gold"][0]), "Palette editing recolors paths without changing geometry")
	studio.save_draft()
	studio.load_draft()
	require(not studio.paths.is_empty() and studio.paths[0].points == geometry and studio.motif.palettes.size() == 5 and studio.motif.has("reference_png"), "Drafts retain editable areas, reference and the exact fill")
	studio.fill()
	await wait_worker(studio)
	studio.apply()
	require(scene.testing and scene.shape_index == 6, "Imported motif enters actual play mode")
	scene.save_custom()
	var document: Dictionary = scene.level_document()
	require(document.version == 2, "Custom levels carry their own mask")
	var order := ArrowPuzzle.solution(scene.arrows)
	for index in order:
		require(not scene.is_blocked(index), "Imported solver and game agree")
		scene.click_at(scene.arrows[index].points[0])
		scene._process(2)
	require(scene.cleared == scene.arrows.size(), "Imported motif plays to completion")
	require(scene.read_custom(), "Version 2 level reloads")
	require(scene.motif.cells.size() == outline.cells.size(), "Reload restores custom silhouette")
	scene.enter_editor()
	var mask_size: int = scene.motif.cells.size()
	for control in scene.controls:
		if control is OptionButton and control.item_count == 7:
			control.item_selected.emit(6)
	require(is_instance_valid(scene.studio) and scene.motif.cells.size() == mask_size, "Selecting the imported template reopens editing without clearing it")
	scene.open_studio()
	studio = scene.studio
	await process_frame
	require(studio.motif.cells.size() == outline.cells.size(), "Reopening the studio preserves edits")
	studio.close_studio()
	scene.leave_editor()
	require(scene.motif.is_empty() and scene.shape_index < 6, "Normal levels remain independent of custom masks")
	for filename in ["custom_puzzle.json", "motif_draft.json", "progress.cfg"]:
		DirAccess.remove_absolute(scene.storage_prefix + filename)
	print("PASS detection, free masks, separator, palettes, threaded studio, real input, draft, export, play" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
