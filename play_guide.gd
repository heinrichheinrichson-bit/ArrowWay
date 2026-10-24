extends Control

var game: Node2D
var first_time := false
var step := 0
var age := 0.0
var released := false
var blocker_removed := false
var flash := 0.0
var card: PanelContainer
var demo: Control
var title_label: Label
var body: Label
var progress: Label
var caption: Label
var next_button: Button
var footer: Label
var skip: Button
var back_button: Button
const TITLES := ["Ein Bild aus Licht. Dein Weg dorthin.", "Erst den Weg freimachen", "Ganz nah heran", "Ein kleiner Lichtblick"]
const COPY := [
	"Tippe auf den Pfeil. Ist sein Weg frei, fliegt er in Richtung seiner Spitze hinaus.",
	"Der rosa Pfeil ist blockiert. Entferne zuerst den blauen Pfeil, der vor seiner Spitze liegt. Probiere es hier aus.",
	"Ziehe zwei Finger auseinander, um zu vergrößern. Im vergrößerten Bild kannst du mit einem Finger verschieben. Am Computer: Mausrad und Ziehen.",
	"Die Glühbirne hebt einen freien Pfeil hervor. Mit dem Kreispfeil startest du nur das aktuelle Rätsel neu. Entferne alle Pfeile, um das Kunstwerk aufleuchten zu lassen."
]

func _ready() -> void:
	name = "PlayGuide"
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	size = get_viewport_rect().size
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.015,0.025,0.06,0.96)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	card = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#101d32")
	style.border_color = Color("#385774")
	style.set_border_width_all(1)
	style.set_corner_radius_all(24)
	style.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel",style)
	add_child(card)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",14)
	card.add_child(stack)
	progress = add_label(stack,"",13,Color("#90cddd"))
	title_label = add_label(stack,"",25)
	demo = Control.new()
	demo.custom_minimum_size.y = 142
	demo.mouse_filter = Control.MOUSE_FILTER_STOP
	demo.draw.connect(draw_demo)
	demo.gui_input.connect(demo_input)
	stack.add_child(demo)
	caption = add_label(stack,"",14,Color("#9debe4"))
	body = add_label(stack,"",18)
	footer = add_label(stack,"",13,Color("#a0b2c7"))
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation",12)
	stack.add_child(buttons)
	back_button = Button.new()
	back_button.text = AppLanguage.text("Zurück")
	back_button.custom_minimum_size = Vector2(96,48)
	back_button.pressed.connect(func(): show_step(step-1))
	buttons.add_child(back_button)
	next_button = Button.new()
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.custom_minimum_size.y = 48
	next_button.pressed.connect(func():
		if step == 3: finish()
		else: show_step(step+1))
	buttons.add_child(next_button)
	skip = Button.new()
	skip.text = AppLanguage.text("Überspringen") if first_time else AppLanguage.text("Schließen")
	skip.custom_minimum_size.y = 44
	skip.pressed.connect(finish)
	stack.add_child(skip)
	get_viewport().size_changed.connect(layout)
	show_step(0)
	layout.call_deferred()

func add_label(parent: Node, text: String, font_size: int, color := Color("#edf4fc")) -> Label:
	var item := Label.new()
	item.text = text
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color)
	parent.add_child(item)
	return item

func layout() -> void:
	var viewport := get_viewport_rect().size
	size = viewport
	# The card stays away from the camera cutout and system gesture area.
	card.size.x = minf(460,viewport.x-40)
	card.position.x = (viewport.x-card.size.x)*0.5
	card.size.y = 0
	card.position.y = maxf(48,(viewport.y-card.get_combined_minimum_size().y)*0.5)

func show_step(value: int) -> void:
	step = clampi(value,0,3)
	age = 0; flash = 0; released = false; blocker_removed = false
	progress.text = AppLanguage.text("So spielst du") + "  ·  %d / 4" % (step+1)
	title_label.text = AppLanguage.text(TITLES[step])
	body.text = AppLanguage.text(COPY[step])
	caption.text = AppLanguage.text("Hier ausprobieren") if step < 2 else ""
	caption.visible = step < 2
	back_button.text = AppLanguage.text("Zurück")
	footer.text = AppLanguage.text("Jederzeit unter Einstellungen → So spielst du.")
	skip.text = AppLanguage.text("Überspringen") if first_time else AppLanguage.text("Schließen")
	back_button.disabled = step == 0
	next_button.text = AppLanguage.text("Losspielen" if first_time else "Schließen") if step == 3 else AppLanguage.text("Weiter")
	demo.queue_redraw()
	layout.call_deferred()

func _process(delta: float) -> void:
	age += delta
	flash = maxf(0,flash-delta)
	demo.queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		finish()
		get_viewport().set_input_as_handled()

func demo_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT: return
	if step == 0: released = true; age = 0; caption.text = AppLanguage.text("Freier Weg")
	elif step == 1:
		if event.position.x > demo.size.x*0.65 and not blocker_removed:
			blocker_removed = true
			caption.text = AppLanguage.text("Geschafft – der Weg ist frei!")
		elif blocker_removed: released = true; age = 0
		else: flash = 0.45; caption.text = AppLanguage.text("Blockiert")
	accept_event()

func arrow(points: PackedVector2Array, color: Color) -> void:
	demo.draw_polyline(points,Color(color,0.12),18,true)
	demo.draw_polyline(points,Color(color,0.25),10,true)
	demo.draw_polyline(points,color,4,true)
	for point in points:
		demo.draw_circle(point,9,Color(color,0.12))
		demo.draw_circle(point,5,Color(color,0.25))
		demo.draw_circle(point,2,color)
	var end := points[-1]
	var direction := (end-points[-2]).normalized()
	var side := direction.orthogonal()
	demo.draw_polyline(PackedVector2Array([end-direction*13+side*9,end,end-direction*13-side*9]),color,4,true)

func draw_demo() -> void:
	var w := demo.size.x
	var offset := minf(age*480,w+60) if released else 0.0
	var pink := Color("#ff77be")
	var blue := Color("#61d9ff")
	if step < 2:
		if not released or offset < w:
			var shake := sin(age*65)*4 if flash>0 else 0.0
			arrow(PackedVector2Array([Vector2(w*0.15+offset+shake,105),Vector2(w*0.15+offset+shake,65),Vector2(w*0.64+offset+shake,65)]),pink)
		if step == 1 and not blocker_removed:
			arrow(PackedVector2Array([Vector2(w*0.8,115),Vector2(w*0.8,25)]),blue)
	elif step == 2:
		var spread := (sin(age*1.8)+1)*18
		arrow(PackedVector2Array([Vector2(w*0.27,105),Vector2(w*0.27,40),Vector2(w*0.7,40)]),blue)
		for x in [w*0.4-spread,w*0.6+spread]:
			demo.draw_circle(Vector2(x,95),13,Color(1,1,1,0.12))
			demo.draw_arc(Vector2(x,95),13,0,TAU,40,Color("#d8e7fc"),2,true)
	else:
		var glow := Color("#ffffff").lerp(blue,(sin(age*3)+1)*0.3)
		arrow(PackedVector2Array([Vector2(w*0.2,100),Vector2(w*0.2,50),Vector2(w*0.78,50)]),glow)

func finish() -> void:
	if first_time:
		var preferences := ConfigFile.new()
		preferences.load(game.storage_prefix+"settings.cfg")
		preferences.set_value("guide","seen",true)
		if preferences.save(game.storage_prefix+"settings.cfg") != OK:
			push_warning("Could not save tutorial preference")
	game.board_navigation.cancel_gesture()
	game.play_guide = null
	queue_free()
