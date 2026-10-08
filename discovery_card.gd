extends Panel

var game: Node2D
var data: Dictionary
var body: RichTextLabel
var source: Button
var heading: Label

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("#101b2d")
	style.border_color=Color("#2b465e")
	style.set_border_width_all(1); style.set_corner_radius_all(18)
	style.content_margin_left=20; style.content_margin_right=20
	style.content_margin_top=13; style.content_margin_bottom=13
	add_theme_stylebox_override("panel",style)
	heading=Label.new()
	heading.text=data.get("kind",AppLanguage.text("Ein kleiner Gedanke"))
	heading.add_theme_font_size_override("font_size",13)
	heading.modulate=Color("#7fdfe4"); add_child(heading)
	body=RichTextLabel.new(); body.text=data.text
	body.scroll_active=false
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("normal_font_size",18)
	body.add_theme_color_override("default_color",Color("#e4edf6"))
	body.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(body)
	if not str(data.get("url","")).is_empty():
		source=Button.new(); source.text=AppLanguage.text("Quelle · ")+str(data.get("source",AppLanguage.text("Mehr erfahren")))
		source.flat=true; source.alignment=HORIZONTAL_ALIGNMENT_LEFT
		source.custom_minimum_size.y=44
		source.add_theme_font_size_override("font_size",13)
		source.pressed.connect(show_source); add_child(source)
	visible=false
	resized.connect(layout)
	layout()

func layout() -> void:
	if body==null: return
	heading.position=Vector2(20,13); heading.size=Vector2(size.x-40,20)
	body.position=Vector2(20,39)
	body.size=Vector2(maxf(1,size.x-40),maxf(1,size.y-52-(44 if source!=null else 0)))
	if source!=null:
		source.position=Vector2(16,size.y-57); source.size=Vector2(size.x-32,44)

func show_source() -> void:
	var dialog:=ConfirmationDialog.new()
	dialog.title=AppLanguage.text("Quelle öffnen?")
	dialog.dialog_text=str(data.source)+AppLanguage.text("\nIm Browser weiterlesen.")
	dialog.ok_button_text=AppLanguage.text("Quelle öffnen"); dialog.cancel_button_text=AppLanguage.text("Zurück")
	dialog.confirmed.connect(func(): OS.shell_open(data.url); dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	game.add_child(dialog); dialog.popup_centered(Vector2i(360,170))

func _process(_delta: float) -> void:
	visible=game.win_time>=1.95 and not is_instance_valid(game.home_menu) and not is_instance_valid(game.journey)
	if visible: modulate.a=smoothstep(1.95,2.5,game.win_time)
