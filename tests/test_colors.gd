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
	require(not studio.busy, "Color fixtures finish filling")

func click(studio: Window, point: Vector2) -> void:
	var position: Vector2 = studio.canvas.position + studio.canvas.OFFSET + (point - ArrowPuzzle.ORIGIN) / ArrowPuzzle.CELL * studio.canvas.STEP
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = position
		studio.push_input(event, true)

func run() -> void:
	var yellow := Color("#ffdf3a")
	var colors := MotifColors.shades(yellow, 0.8)
	var style := {"mode": 5, "colors": colors, "bounds": [0, 0, 100, 100], "strength": 0.8}
	var center := MotifColors.color_at(style, Vector2(50, 50))
	var edge := MotifColors.color_at(style, Vector2(50, 100))
	require(MotifImport.color_distance(center, edge) > 0.1 and center.v > edge.v, "A yellow sun gets a lighter center and warmer edges")
	var linear := style.duplicate(true)
	linear.mode = 3
	var last := MotifColors.color_at(linear, Vector2(50, 0))
	for y in range(1, 101):
		var current := MotifColors.color_at(linear, Vector2(50, y))
		require(MotifImport.color_distance(current, last) < 0.02, "Spatial gradients remain continuous")
		last = current
	require(MotifColors.shades(yellow, 0.8, 2) != colors, "Suggestions derive different colors from one base")
	var malformed := style.duplicate(true)
	malformed.colors = ["broken"]
	require(MotifColors.valid_style(malformed).is_empty(), "Invalid styles are rejected")
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.enter_editor()
	scene.open_studio()
	var studio: Window = scene.studio
	studio.source = preload("res://tests/image_fixtures.gd").sun()
	studio.analyze_image(true)
	await wait_worker(studio)
	require(studio.motif.palettes.size() == 1 and CustomMotif.isolated(studio.motif).is_empty(), "Sun imports as a usable area")
	studio.fill()
	await wait_worker(studio)
	require(not studio.paths.is_empty(), "Sun has a complete fill")
	var geometry: Array[Dictionary] = scene.clone_data(studio.paths)
	studio.open_colors()
	var dialogue: Window = studio.color_dialogue
	dialogue.base.color = yellow
	dialogue.mode_picker.select(4)
	dialogue.strength.value = 0.8
	dialogue.update_preview()
	require(not studio.motif.has("styles"), "Color preview does not alter the draft before applying")
	dialogue.apply_colors()
	require(studio.motif.styles[0].mode == 5 and studio.paths[0].has("color_style"), "Area gradients apply to the existing fill")
	for index in range(studio.paths.size()):
		require(studio.paths[index].points == geometry[index].points, "Color changes retain every path")
	await process_frame
	var renderer: Node2D = studio.canvas.preview.get_child(0)
	require(renderer.strokes[0].material.get_shader_parameter("gradient_enabled") == true, "Renderer enables continuous gradient lookup")
	var rounded: PackedVector2Array = scene.rounded_points(studio.paths[0].points)
	var lookup := MotifColors.color_lookup(rounded, studio.paths[0].color_style)
	require(MotifImport.color_distance(lookup.get_pixel(0, 0), MotifColors.color_at(studio.paths[0].color_style, rounded[0])) < 0.008, "Lookup starts with the original tail color")
	require(MotifImport.color_distance(lookup.get_pixel(127, 0), MotifColors.color_at(studio.paths[0].color_style, rounded[-1])) < 0.008, "Lookup ends with the original head color")
	studio.change_color(0, Color("#fff6bd"))
	dialogue.refresh_target()
	require(dialogue.pending_style(dialogue.base.color).colors[0] == "fff6bd", "Reopening color controls preserves edited gradient stops")
	studio.undo()
	dialogue.refresh_target()
	studio.paths[0].hint = 1
	await process_frame
	require(renderer.strokes[0].material.get_shader_parameter("gradient_enabled") == false, "Hints stay readable over gradients")
	studio.paths[0].hint = 0
	dialogue.hide()
	studio.tool = 0
	click(studio, studio.paths[0].points[0])
	require(studio.selected_arrow == 0, "Actual mouse input selects an individual arrow")
	var previous_color: Color = studio.paths[1].color
	studio.arrow_color.color_changed.emit(Color("#fc48a8"))
	require(studio.paths[0].color == Color("#fc48a8") and studio.paths[0].manual_color and studio.paths[1].color == previous_color, "Visible color picker changes only the clicked arrow")
	await process_frame
	require(renderer.strokes[1].material.get_shader_parameter("selection_opacity") < 0.3 and renderer.strokes[0].material.get_shader_parameter("selection_opacity") == 1.0, "Selected arrow stands out from dimmed neighbors")
	studio.undo()
	var region_palette: Array = studio.motif.palettes[studio.selected].duplicate()
	var neighbor: Dictionary = studio.paths[1].duplicate(true)
	studio.swatches[1].color_changed.emit(Color("#ff3a72"))
	require(studio.paths[0].color == Color("#ff3a72") and studio.paths[1].color == neighbor.color and studio.motif.palettes[studio.selected] == region_palette, "Sidebar swatch edits only the selected arrow, never its region")
	studio.set_palette(CustomMotif.PALETTES["Wasser"])
	require(studio.paths[0].manual_color and studio.paths[0].color_style.colors == CustomMotif.PALETTES["Wasser"] and studio.paths[1].color == neighbor.color and studio.motif.palettes[studio.selected] == region_palette, "Sidebar palette edits only the selected arrow")
	studio.undo()
	studio.undo()
	dialogue.refresh_target()
	dialogue.base.color = Color("#a875ff")
	dialogue.mode_picker.select(0)
	dialogue.update_preview()
	var other_style: Dictionary = studio.paths[1].color_style.duplicate(true)
	dialogue.apply_colors()
	var own_color: Color = studio.paths[0].color
	require(studio.paths[0].manual_color and studio.paths[0].color_style.mode == 1 and studio.paths[1].color_style == other_style, "Individual editing affects only the selected arrow")
	dialogue.target.select(0)
	dialogue.refresh_target()
	dialogue.base.color = Color("#ffb540")
	dialogue.mode_picker.select(2)
	dialogue.apply_colors()
	require(studio.paths[0].color == own_color and studio.paths[1].color_style.mode == 3, "Area changes preserve individual overrides")
	dialogue.reset_overrides()
	require(not studio.paths[0].get("manual_color", false), "Individual colors can be reset to their area")
	studio.undo()
	require(studio.paths[0].get("manual_color", false) and studio.paths[0].color == own_color, "Undo restores individual colors")
	dialogue.activate_pipette(6)
	click(studio, studio.paths[0].points[0])
	require(MotifImport.color_distance(dialogue.base.color, own_color) < 0.008, "Pipette samples an existing arrow without changing its target")
	dialogue.activate_pipette(7)
	click(studio, Vector2(270, 407))
	require(MotifImport.color_distance(dialogue.base.color, yellow) < 0.008, "Image pipette samples the original sun color")
	var serialized = JSON.parse_string(JSON.stringify(CustomMotif.encode(studio.motif)))
	var restored := CustomMotif.decode(serialized)
	require(restored.styles[0].mode == 3, "Region styles survive JSON")
	studio.save_draft()
	studio.load_draft(true)
	require(studio.paths[0].get("manual_color", false) and studio.paths[0].color == own_color and studio.paths[1].has("color_style"), "Drafts preserve gradients and individual overrides")
	dialogue.target.select(2)
	dialogue.refresh_target()
	require(dialogue.target.selected == 2, "Whole-motif scope remains selectable with an arrow selected")
	var saved_motif: Dictionary = studio.motif
	var saved_paths: Array[Dictionary] = studio.paths
	studio.motif = CustomMotif.from_shape(1)
	var no_paths: Array[Dictionary] = []
	studio.paths = no_paths
	var tree: Dictionary = dialogue.preview_document().motif
	var crown := Color(tree.styles[0].colors[1])
	var trunk := Color(tree.styles[1].colors[1])
	require(crown.g > crown.r and trunk.r > trunk.g and trunk.g > trunk.b, "Whole-motif shading retains green leaves and brown wood")
	studio.motif = saved_motif
	studio.paths = saved_paths
	dialogue.mode_picker.select(1)
	dialogue.apply_colors()
	require(studio.paths[0].color == own_color, "Whole-motif suggestions preserve overrides")
	studio.apply()
	require(scene.testing and scene.arrows[0].get("manual_color", false) and scene.arrows[1].has("color_style"), "Playing keeps the edited colors")
	scene.save_custom()
	require(scene.read_custom() and scene.arrows[0].color == own_color and scene.arrows[1].has("color_style"), "Exported levels restore their appearance")
	var order := ArrowPuzzle.solution(scene.arrows)
	for index in order:
		require(not scene.is_blocked(index), "Colored levels retain their solution")
		scene.click_at(scene.arrows[index].points[0])
		scene._process(2)
	require(scene.cleared == scene.arrows.size(), "Colored sun plays to completion")
	for filename in ["custom_puzzle.json", "motif_draft.json", "progress.cfg", "editor_colors.json", "editor_backup.json"]:
		DirAccess.remove_absolute(scene.storage_prefix + filename)
	print("PASS gradients, suggestions, real arrow selection, pipettes, overrides, persistence, gameplay" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
