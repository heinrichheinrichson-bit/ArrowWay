extends Window

var studio: Window
var base: ColorPickerButton
var mode_picker: OptionButton
var target: OptionButton
var strength: HSlider
var keep_manual: CheckButton
var preview: Control
var notice: Label
var variant := 0
var initializing := false
var suggestions: Array[Button] = []
var current_colors: Array = []
var inherited_style := {}

func _ready() -> void:
	title = "ArrowWay · Farben & Verläufe"
	size = Vector2i(900, 665)
	min_size = size
	unresizable = true
	close_requested.connect(func(): studio.color_dialogue = null; queue_free())
	var root := Control.new()
	root.size = Vector2(size)
	root.theme = studio.game.panel.theme
	add_child(root)
	var background := ColorRect.new()
	background.color = Color("#080e19")
	background.size = root.size
	root.add_child(background)
	var heading := Label.new()
	heading.text = "FARBEN & VERLÄUFE"
	heading.position = Vector2(25, 18)
	heading.add_theme_font_size_override("font_size", 24)
	root.add_child(heading)
	var panel := VBoxContainer.new()
	panel.position = Vector2(25, 66)
	panel.size = Vector2(365, 540)
	panel.add_theme_constant_override("separation", 11)
	root.add_child(panel)
	studio.add_label(panel, "WAS SOLL GEFÄRBT WERDEN?")
	target = OptionButton.new()
	target.fit_to_longest_item = false
	for label in ["Ausgewählte Fläche", "Ausgewählter Pfeil", "Ganzes Motiv · Grundfarben behalten"]:
		target.add_item(label)
	target.item_selected.connect(func(index: int):
		studio.tool = 5 if index == 1 else 8
		studio.tool_picker.select(studio.tool)
		refresh_target())
	panel.add_child(target)
	studio.add_label(panel, "GRUNDFARBE")
	base = ColorPickerButton.new()
	base.custom_minimum_size.y = 42
	base.edit_alpha = false
	base.color_changed.connect(func(_color: Color): variant = 0; update_preview())
	panel.add_child(base)
	studio.add_label(panel, "FARBWIRKUNG")
	mode_picker = OptionButton.new()
	for label in MotifColors.MODES:
		mode_picker.add_item(label)
	mode_picker.item_selected.connect(func(_index: int): update_preview())
	panel.add_child(mode_picker)
	studio.add_label(panel, "STÄRKE DER SCHATTIERUNG")
	strength = HSlider.new()
	strength.min_value = 0
	strength.max_value = 1
	strength.step = 0.05
	strength.value = 0.55
	strength.value_changed.connect(func(_value: float): update_preview())
	panel.add_child(strength)
	keep_manual = CheckButton.new()
	keep_manual.text = "Eigene Pfeilfarben erhalten"
	keep_manual.button_pressed = true
	keep_manual.toggled.connect(func(_value: bool): update_preview())
	panel.add_child(keep_manual)
	add_action(panel, "Pipette · vorhandene Pfeilfarbe", func(): activate_pipette(6))
	add_action(panel, "Pipette · Farbe aus der Bildvorlage", func(): activate_pipette(7))
	add_action(panel, "Farben übernehmen", apply_colors)
	add_action(panel, "Eigene Pfeilfarben zurücksetzen", reset_overrides)
	preview = Control.new()
	preview.set_script(load("res://color_preview.gd"))
	preview.set("dialogue", self)
	preview.position = Vector2(415, 65)
	preview.size = Vector2(460, 455)
	root.add_child(preview)
	var label := Label.new()
	label.text = "FARBVORSCHLÄGE AUS DEINER GRUNDFARBE"
	label.position = Vector2(415, 535)
	label.add_theme_font_size_override("font_size", 12)
	root.add_child(label)
	for index in range(4):
		var button := Button.new()
		button.set_script(load("res://color_suggestion.gd"))
		button.position = Vector2(415 + index * 117, 557)
		button.size = Vector2(109, 58)
		button.set("label", MotifColors.SUGGESTIONS[index])
		button.pressed.connect(func(): variant = index; inherited_style.clear(); update_preview())
		root.add_child(button)
		suggestions.append(button)
	notice = Label.new()
	notice.position = Vector2(25, 622)
	notice.size = Vector2(850, 36)
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.add_theme_font_size_override("font_size", 13)
	root.add_child(notice)
	if studio.selected_arrow >= 0:
		target.select(1)
	refresh_target()

func add_action(parent: Node, label: String, action: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 34
	button.pressed.connect(action)
	parent.add_child(button)

func refresh_target() -> void:
	initializing = true
	var style: Dictionary = studio.motif.get("styles", {}).get(studio.selected, {})
	var palette: Array = studio.motif.palettes[studio.selected]
	base.color = Color(palette[mini(1, palette.size() - 1)])
	if target.selected == 1 and studio.selected_arrow >= 0:
		var arrow: Dictionary = studio.paths[studio.selected_arrow]
		style = arrow.get("color_style", {})
		base.color = arrow.color
	if not style.is_empty():
		base.color = Color(style.colors[1])
		mode_picker.select(int(style.mode) - 1)
		strength.value = style.get("strength", 0.55)
	else:
		mode_picker.select(1)
		strength.value = 0.55
	base.disabled = target.selected == 2
	inherited_style = style.duplicate(true)
	variant = 0
	initializing = false
	update_preview()

func pending_style(color: Color) -> Dictionary:
	var colors := MotifColors.shades(color, strength.value, variant)
	if variant == 0 and not inherited_style.is_empty() and color.is_equal_approx(Color(inherited_style.colors[1])) and is_equal_approx(strength.value, float(inherited_style.strength)):
		colors = inherited_style.colors.duplicate()
	return {"mode": mode_picker.selected + 1, "colors": colors, "strength": strength.value, "bounds": MotifColors.bounds_for(studio.motif, studio.selected)}

func preview_document() -> Dictionary:
	var motif: Dictionary = studio.motif.duplicate(true)
	var paths: Array[Dictionary] = studio.game.clone_data(studio.paths)
	decorate(motif, paths)
	return {"motif": motif, "paths": paths}

func decorate(motif: Dictionary, paths: Array[Dictionary]) -> void:
	if target.selected == 1:
		if studio.selected_arrow >= 0 and studio.selected_arrow < paths.size():
			var arrow: Dictionary = paths[studio.selected_arrow]
			arrow.color_style = pending_style(base.color)
			arrow.color_style.bounds = MotifColors.bounds_of_path(arrow.points)
			arrow.manual_color = true
			arrow.color = MotifColors.color_at(arrow.color_style, arrow.points[arrow.points.size() / 2])
			arrow["editor_selected"] = true
		return
	if not motif.has("styles"):
		motif["styles"] = {}
	if target.selected == 2:
		for part in motif.palettes:
			var palette: Array = motif.palettes[part]
			var style := pending_style(Color(palette[mini(1, palette.size() - 1)]))
			style.bounds = MotifColors.bounds_for(motif, part)
			motif.styles[part] = style
			motif.palettes[part] = style.colors.duplicate()
		MotifColors.apply(motif, paths, -1, keep_manual.button_pressed)
	else:
		var style := pending_style(base.color)
		motif.styles[studio.selected] = style
		motif.palettes[studio.selected] = style.colors.duplicate()
		MotifColors.apply(motif, paths, studio.selected, keep_manual.button_pressed)

func update_preview() -> void:
	if initializing or preview == null:
		return
	current_colors = MotifColors.shades(base.color, strength.value, variant)
	for index in range(suggestions.size()):
		suggestions[index].set("colors", MotifColors.shades(base.color, strength.value, index))
		suggestions[index].queue_redraw()
	preview.refresh()
	notice.text = "Vorschau · %s · Übernehmen erhält alle Pfade und die Lösbarkeit." % MotifColors.SUGGESTIONS[variant]
	if target.selected == 1 and studio.selected_arrow < 0:
		notice.text = "Klicke in der Werkstatt auf einen Pfeil. Danach kannst du ihn hier individuell färben."

func apply_colors() -> void:
	if studio.busy or (target.selected == 1 and studio.selected_arrow < 0):
		return
	studio.remember()
	decorate(studio.motif, studio.paths)
	studio.refresh()
	notice.text = "Farben übernommen. Die Pfeilgeometrie bleibt erhalten; Rückgängig ist in der Werkstatt verfügbar."

func reset_overrides() -> void:
	if studio.busy:
		return
	studio.remember()
	MotifColors.apply(studio.motif, studio.paths, -1 if target.selected == 2 else studio.selected, false)
	studio.refresh()
	update_preview()
	notice.text = "Eigene Pfeilfarben wurden durch die Flächenfarben ersetzt."

func activate_pipette(tool: int) -> void:
	if target.selected == 2:
		target.select(0)
		base.disabled = false
	studio.tool = tool
	studio.tool_picker.select(tool)
	studio.notice.text = "Pipette: Klicke auf die gewünschte Farbe. Dein bisheriges Ziel bleibt ausgewählt."
	hide()

func accept_sample(color: Color) -> void:
	base.color = Color(color.r, color.g, color.b, 1)
	variant = 0
	update_preview()
	popup_centered(size)
	notice.text = "Farbe übernommen. Einfarbig übernimmt sie genau; Schattierungen erzeugen daraus Abstufungen."
