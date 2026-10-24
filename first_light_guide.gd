extends Control

const GROUP := "first_light"
var game: Node2D
var card: PanelContainer
var title_label: Label
var body: Label
var skip: Button
var active := false
var forced := false
var lesson := -1
var phase := 0
var source_arrow := -1
var target_arrow := -1
var highlight := -1
var last_mistakes := 0
var warning_time := 0.0
var pan_start := Vector2.ZERO
const LESSONS := {"first_light_01_fish.json":0,"first_light_02_tulip.json":1,"first_light_03_mushroom.json":2}

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	auto_translate_mode=Node.AUTO_TRANSLATE_MODE_DISABLED
	card=PanelContainer.new()
	card.name="FirstLightHint"
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("#101c30")
	style.border_color=Color("#294356")
	style.set_border_width_all(1); style.set_corner_radius_all(18)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel",style)
	add_child(card)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",7)
	card.add_child(stack)
	title_label=Label.new()
	title_label.add_theme_font_size_override("font_size",18)
	title_label.add_theme_color_override("font_color",Color("#a2f5d1"))
	title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(title_label)
	body=Label.new()
	body.add_theme_font_size_override("font_size",15)
	body.add_theme_color_override("font_color",Color("#c1d1e1"))
	body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	skip=Button.new()
	skip.custom_minimum_size.y=38
	skip.pressed.connect(continue_lesson)
	stack.add_child(skip)
	visible=false

func configure(force := false) -> void:
	clear_highlight()
	forced=force; phase=0; warning_time=0; source_arrow=-1; target_arrow=-1
	lesson=LESSONS.get(game.level_path(game.level).get_file(),-1)
	active=lesson>=0 and game.journey_mode and not game.authoring and not game.testing
	var preferences:=ConfigFile.new()
	preferences.load(game.storage_prefix+"settings.cfg")
	if not force and (game.completed.has(game.level) or game.level_path(game.level) in preferences.get_value("first_light","hidden",[])): active=false
	last_mistakes=game.mistakes
	if active and lesson==0: find_teaching_pair()
	visible=active
	update_copy()

func find_teaching_pair() -> void:
	var available: Array=game.free_paths()
	for index in game.arrows.size():
		if game.arrows[index].removed or game.arrows[index].escaping or not game.is_blocked(index): continue
		var blockers: Array[int]=[]
		for other in game.arrows.size():
			if other!=index and not game.arrows[other].removed and ArrowPuzzle.ray_hits(game.arrows[index].points,game.visible_points(game.arrows[other])): blockers.append(other)
		if blockers.size()==1 and available.has(blockers[0]):
			source_arrow=blockers[0]; target_arrow=index; return
	phase=3

func clear_highlight() -> void:
	if highlight>=0 and highlight<game.arrows.size(): game.arrows[highlight].hint=0.0
	highlight=-1

func dismiss() -> void:
	active=false; visible=false; clear_highlight()
	var preferences:=ConfigFile.new()
	preferences.load(game.storage_prefix+"settings.cfg")
	var hidden: Array=preferences.get_value("first_light","hidden",[])
	var path: String=game.level_path(game.level)
	if not hidden.has(path): hidden.append(path)
	preferences.set_value("first_light","hidden",hidden)
	preferences.save(game.storage_prefix+"settings.cfg")
	game.update_play_layout()

func continue_lesson() -> void:
	if lesson==1 and phase<2:
		phase+=1; pan_start=game.board_navigation.center
		update_copy()
	elif lesson==2 and phase==0:
		phase=1; update_copy()
	else: dismiss()

func hint_used() -> void:
	if active and lesson==2: phase=1; update_copy()

func prepare_layout(safe: Rect2) -> float:
	var height:=196.0 if safe.size.x<420 else 158.0
	card.position=Vector2(safe.position.x+24,safe.end.y-height-18)
	card.size=Vector2(safe.size.x-48,height)
	return card.position.y-16

func _process(delta: float) -> void:
	var playing: bool=active and game.win_time<0 and not is_instance_valid(game.home_menu) and not is_instance_valid(game.journey) and not is_instance_valid(game.gallery)
	visible=playing
	if not playing:
		clear_highlight(); return
	warning_time=maxf(0,warning_time-delta)
	if game.mistakes>last_mistakes:
		last_mistakes=game.mistakes; warning_time=2.2
	if lesson==0 and source_arrow>=0 and target_arrow>=0:
		if game.arrows[target_arrow].escaping or game.arrows[target_arrow].removed: phase=3
		elif game.arrows[source_arrow].removed and not game.is_blocked(target_arrow): phase=2
		elif game.arrows[source_arrow].escaping: phase=1
		var next_highlight:=source_arrow if phase==0 else (target_arrow if phase==2 else -1)
		if next_highlight!=highlight: clear_highlight(); highlight=next_highlight
	elif lesson==1:
		if phase==0 and game.board_navigation.zoom>1.12: phase=1; pan_start=game.board_navigation.center
		elif phase==1 and game.board_navigation.center.distance_to(pan_start)>8: phase=2
	if highlight>=0: game.arrows[highlight].hint=maxf(game.arrows[highlight].hint,0.15)
	update_copy()

func update_copy() -> void:
	if not is_instance_valid(title_label): return
	var title:=""
	var detail:=""
	if warning_time>0:
		title="Dieser Weg ist noch besetzt."; detail="Vor seiner Spitze steht noch ein Pfeil."
	elif lesson==0:
		match phase:
			0: title="Tippe auf den leuchtenden Pfeil."; detail="Seine Spitze zeigt in einen freien Weg."
			1: title="Freie Bahn."; detail="Der Schwanzpfeil fliegt hinaus."
			2: title="Jetzt ist dieser Weg frei."; detail="Tippe auf den leuchtenden Körperpfeil."
			_: title="Befreie die übrigen Pfeile."
	elif lesson==1:
		match phase:
			0:
				title="Schau etwas näher hin."
				detail="Ziehe zwei Finger auseinander, um zu vergrößern." if OS.has_feature("mobile") else "Drehe das Mausrad, um zu vergrößern."
			1:
				title="Verschiebe das vergrößerte Motiv."
				detail="Ziehe mit einem Finger über das Bild." if OS.has_feature("mobile") else "Ziehe das Bild mit gedrückter Maustaste."
			_: title="Entdecke die Tulpe in deinem Tempo."; detail="Befreie die übrigen Pfeile."
	elif lesson==2:
		if phase==0: title="Ein Lichtblick, wenn du ihn brauchst."; detail="Tippe auf die Glühbirne oben. Sie zeigt dir kurz einen freien Pfeil."
		else: title="Ein Hinweis, kein gelöster Zug."; detail="Du entscheidest selbst, welchen Pfeil du als Nächstes entfernst."
	title_label.text=AppLanguage.text(title)
	body.text=AppLanguage.text(detail); body.visible=not detail.is_empty()
	skip.text=AppLanguage.text("Überspringen" if ((lesson==1 and phase<2) or (lesson==2 and phase==0) or (lesson==0 and phase<3)) else "Verstanden")
