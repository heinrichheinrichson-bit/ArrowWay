extends Button

var game: Node2D
var index := 0
var accent := Color("#68eed2")
var hero := false
var complete := false
var preview: Node2D
var display_mode := "puzzle"
var activate: Callable
var continuing := false

func _ready() -> void:
	for state in ["normal","hover","pressed","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	clip_contents = true
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.level_path(index)))
	var motif := CustomMotif.decode(document.motif) if int(document.shape) == 6 else CustomMotif.from_shape(int(document.shape))
	preview = Node2D.new()
	preview.set_script(load("res://motif_preview.gd"))
	preview.rounder = game
	preview.win_time = 2.2 if display_mode in ["album","display","home_art"] else -1.0
	preview.motif = motif
	preview.arrows = CustomMotif.decode_paths(document.paths,motif,false)
	add_child(preview)
	var bounds := Rect2()
	var first := true
	for arrow in preview.arrows:
		for point in arrow.points:
			if first: bounds = Rect2(point,Vector2.ZERO); first = false
			else: bounds = bounds.expand(point)
	bounds = bounds.grow(20)
	var area := Rect2(18,18,size.x-36,size.y-36) if display_mode=="display" else Rect2(18,18,size.x-36,size.y-(98 if hero else 82))
	var zoom := minf(area.size.x/maxf(bounds.size.x,1),area.size.y/maxf(bounds.size.y,1))
	preview.scale = Vector2.ONE*zoom
	preview.position = area.get_center()-bounds.get_center()*zoom
	preview.modulate.a = 1.0
	var title := Label.new()
	title.text = "" if display_mode=="display" else game.level_title(index)
	title.position = Vector2(18,size.y-(62 if hero else 58))
	title.size = Vector2(size.x-36,28)
	title.add_theme_font_size_override("font_size",22 if hero else 16)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)
	var caption := Label.new()
	caption.text = AppLanguage.text("Kunstwerk ansehen") if display_mode=="album" else (AppLanguage.text("Erneut spielen") if complete else (AppLanguage.text("Losspielen") if hero else AppLanguage.text("Spielen")))
	if display_mode=="home_art": caption.text=AppLanguage.text("Dein zuletzt entdecktes Kunstwerk")
	continuing = display_mode in ["puzzle","resume"] and index==game.level and game.session_in_progress and game.win_time<0
	if continuing: caption.text=AppLanguage.text("Fortsetzen")
	caption.position = Vector2(12,size.y-31)
	caption.size.x = size.x-24
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",12)
	caption.modulate = Color("#8298ae")
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)
	if display_mode=="display":
		caption.text=""; mouse_filter=Control.MOUSE_FILTER_IGNORE
	elif activate.is_valid(): pressed.connect(activate)
	else: pressed.connect(func(): game.start_journey_puzzle(index))

func _process(_delta: float) -> void:
	if display_mode=="home_art" and is_instance_valid(preview):
		preview.modulate=Color(1,1,1,0.88+sin(preview.clock_time*0.65)*0.10)

func _draw() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#10202e") if hero else Color("#0d1927")
	panel.set_corner_radius_all(24)
	panel.set_border_width_all(1)
	panel.border_color = Color(accent,0.65 if continuing else (0.42 if is_hovered() or has_focus() else (0.22 if hero else 0.10)))
	panel.shadow_color = Color(0,0,0,0.18)
	panel.shadow_size = 10
	panel.shadow_offset = Vector2(0,5)
	draw_style_box(panel,Rect2(Vector2.ONE,size-Vector2(2,2)))
	if complete:
		draw_circle(Vector2(size.x-24,24),9,Color(accent,0.15))
		draw_polyline(PackedVector2Array([Vector2(size.x-29,24),Vector2(size.x-25,28),Vector2(size.x-19,20)]),accent,1.5,true)
