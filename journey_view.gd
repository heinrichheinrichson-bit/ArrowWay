extends Control

var game: Node2D
var screen := "map"
var world := -1
var group := ""
var history := false
var page := 0
var scroller: ScrollContainer
var canvas: Control
var scroll_positions := {}
var visible_station_ids: Array[String] = []
var seen: Array[String] = []
var toast: Label
var rebuilding := false
var finger := -1
var finger_start := Vector2.ZERO
var previous_finger := Vector2.ZERO
var scroll_start := 0
var dragging := false
var velocity := 0.0
var previous_tick := 0
var canceling_gui := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	relayout()

func _process(delta: float) -> void:
	if not is_instance_valid(scroller) or dragging or absf(velocity)<6: return
	var old:=scroller.scroll_vertical
	scroller.scroll_vertical+=roundi(velocity*delta)
	velocity*=exp(-delta*7.5)
	if scroller.scroll_vertical==old: velocity=0.0

func cancel_button_press() -> void:
	# Cancel the GUI press before a swipe can become a station activation.
	canceling_gui=true
	var motion:=InputEventMouseMotion.new()
	motion.position=Vector2(-100,-100)
	motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	motion.device=InputEvent.DEVICE_ID_EMULATION
	get_viewport().push_input(motion,true)
	var release:=InputEventMouseButton.new()
	release.button_index=MOUSE_BUTTON_LEFT
	release.pressed=false
	release.position=Vector2(-100,-100)
	release.device=InputEvent.DEVICE_ID_EMULATION
	get_viewport().push_input(release,true)
	canceling_gui=false

func _input(event: InputEvent) -> void:
	if canceling_gui or not is_instance_valid(scroller): return
	if dragging and event is InputEventMouseMotion and event.device==InputEvent.DEVICE_ID_EMULATION:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			if finger>=0:
				get_viewport().set_input_as_handled()
				return
			if not Rect2(scroller.global_position,scroller.size).has_point(event.position): return
			finger=event.index; finger_start=event.position; previous_finger=event.position
			scroll_start=scroller.scroll_vertical; previous_tick=Time.get_ticks_msec()
			velocity=0.0; dragging=false
		elif event.index==finger:
			if dragging: get_viewport().set_input_as_handled()
			finger=-1; dragging=false
	elif event is InputEventScreenDrag and event.index==finger:
		if not dragging and absf(event.position.y-finger_start.y)>10:
			dragging=true
			cancel_button_press()
		if not dragging: return
		var tick:=Time.get_ticks_msec()
		var elapsed:=maxf((tick-previous_tick)/1000.0,0.016)
		velocity=clampf((previous_finger.y-event.position.y)/elapsed,-1800,1800)
		scroller.scroll_vertical=scroll_start-roundi(event.position.y-finger_start.y)
		previous_finger=event.position; previous_tick=tick
		get_viewport().set_input_as_handled()

func label(text: String, position: Vector2, width: float, font_size: int, color: Color = Color("#edf4fc")) -> Label:
	var item := Label.new()
	item.text = text
	item.position = position
	item.size = Vector2(width,font_size*1.5)
	item.add_theme_font_size_override("font_size",font_size)
	item.modulate = color
	item.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(item)
	return item

func action(text: String, position: Vector2, dimensions: Vector2, callback: Callable, primary := false) -> Button:
	var item := Button.new()
	item.text = text
	item.position = position
	item.size = dimensions
	item.add_theme_font_size_override("font_size",17)
	for state in ["normal","hover","pressed","focus"]:
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(18 if primary else 14)
		box.bg_color = Color("#8aefd5") if primary else Color("#132332")
		if state == "hover": box.bg_color = box.bg_color.lightened(0.06)
		if state == "pressed": box.bg_color = box.bg_color.darkened(0.08)
		box.set_border_width_all(1)
		box.border_color = Color("#a9ffe6") if primary else Color("#263c4c")
		if state == "focus": box.border_color = Color("#a9ffe6")
		item.add_theme_stylebox_override(state,box)
	if primary:
		for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: item.add_theme_color_override(state,Color("#0d302c"))
	item.pressed.connect(callback)
	add_child(item)
	return item

func icon_button(path: String, position: Vector2, callback: Callable, tooltip: String) -> Button:
	var item := action("",position,Vector2(48,48),callback)
	var image := Image.new()
	image.load_svg_from_string("<svg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24'><g fill='none' stroke='#c1d4df' stroke-width='1.6' stroke-linecap='round' stroke-linejoin='round'>"+path+"</g></svg>")
	item.icon = ImageTexture.create_from_image(image)
	item.tooltip_text = tooltip
	return item

func relayout() -> void:
	if rebuilding: return
	rebuilding = true
	finger=-1; dragging=false; velocity=0.0
	var key := "%s:%d:%s:%s" % [screen,world,group,history]
	if is_instance_valid(scroller): scroll_positions[key] = scroller.get_meta("wanted_scroll",scroller.scroll_vertical)
	for child in get_children(): remove_child(child); child.queue_free()
	scroller = null
	size = get_viewport_rect().size
	seen.assign(game.journey_seen)
	visible_station_ids.clear()
	var color := Color("#68eed2") if world < 0 else Color(JourneyProgress.worlds()[world].color)
	var background := ColorRect.new()
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://journey_background.gdshader")
	material.set_shader_parameter("accent",color)
	background.material = material
	add_child(background)
	if screen == "home":
		build_home()
	elif screen == "settings":
		build_settings()
	else:
		icon_button("<path d='M15 5L8 12l7 7'/>",Vector2(24,24),go_back,"Zurück")
		if screen == "map": build_map()
		elif screen == "world": build_world()
		else: build_collection()
		if is_instance_valid(scroller):
			for lower in [false,true]:
				var edge:=ColorRect.new()
				edge.position=Vector2(0,scroller.position.y+(scroller.size.y-32 if lower else 0))
				edge.size=Vector2(size.x,32)
				edge.mouse_filter=Control.MOUSE_FILTER_IGNORE
				var fade:=ShaderMaterial.new()
				fade.shader=load("res://journey_edge_fade.gdshader")
				fade.set_shader_parameter("accent",color)
				fade.set_shader_parameter("lower",lower)
				edge.material=fade
				add_child(edge)
	game.remember_journey_stations(visible_station_ids)
	rebuilding = false

func navigate(next_screen: String, next_world := -1, next_group := "", past := false) -> void:
	if is_instance_valid(scroller): scroll_positions["%s:%d:%s:%s" % [screen,world,group,history]] = scroller.get_meta("wanted_scroll",scroller.scroll_vertical)
	scroller = null
	screen = next_screen; world = next_world; group = next_group; history = past; page = 0
	relayout()

func go_back() -> void:
	if screen == "map": game.close_journey(); game.open_home()
	elif screen == "world": navigate("map")
	elif screen == "collection":
		if history: navigate("collection",world,group)
		elif world > 0: navigate("world",world)
		else: navigate("map")
	elif screen == "settings": navigate("home")
	else: game.close_home()

func make_scroll(height: float, tint: Color) -> void:
	scroller = ScrollContainer.new()
	scroller.position = Vector2(0,142)
	scroller.size = Vector2(size.x,size.y-230)
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroller.follow_focus = true
	scroller.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scroller)
	canvas = Control.new()
	canvas.set_script(load("res://journey_canvas.gd"))
	canvas.custom_minimum_size = Vector2(size.x,maxf(height,scroller.size.y))
	canvas.size = canvas.custom_minimum_size
	canvas.accent = tint
	canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	scroller.add_child(canvas)

func request_scroll(value: int) -> void:
	velocity=0.0
	var node := scroller
	node.set_meta("wanted_scroll",value)
	node.set_deferred("scroll_vertical",value)
	await get_tree().process_frame
	if not is_instance_valid(node) or node != scroller: return
	node.scroll_vertical = value
	node.remove_meta("wanted_scroll")

func station(id: String, name_text: String, caption: String, icon: String, color: Color, center: Vector2, available: bool, achieved: bool, current: bool, callback: Callable, width := 216.0) -> Button:
	var node := Button.new()
	node.set_script(load("res://journey_station.gd"))
	node.title = name_text; node.subtitle = caption; node.icon_name = icon
	node.tint = color; node.locked = not available; node.achieved = achieved; node.current = current
	node.fresh = available and not seen.has(id)
	node.position = center-Vector2(width*0.5,64)
	node.size = Vector2(width,180)
	canvas.add_child(node)
	canvas.label_zones.append(Rect2(Vector2(center.x-width*0.5-14,center.y+57),Vector2(width+28,53)))
	if available:
		visible_station_ids.append(id)
		node.pressed.connect(callback)
	else: node.pressed.connect(func(): tell("Dieser Weg öffnet sich beim Weiterreisen."))
	return node

func build_map() -> void:
	label("DEINE NEONREISE",Vector2(88,29),size.x-110,12,Color("#83ada9"))
	label("Ein Licht nach dem anderen",Vector2(24,91),size.x-48,26)
	var worlds := JourneyProgress.worlds()
	var frontier := JourneyProgress.frontier(game)
	var height := worlds.size()*264.0+110
	make_scroll(height,Color("#68eed2"))
	var centers: Array[Vector2] = []
	for index in worlds.size():
		centers.append(Vector2(size.x*(0.43 if index%2==0 else 0.66),height-170-index*264))
	for index in worlds.size():
		var data: Dictionary = worlds[index]
		var open := index<=frontier
		var done := JourneyProgress.world_done(game,index)
		var caption := "Noch verborgen" if not open else ("Dein erstes Licht" if index==0 and done==0 else "%d Kunstwerke entdeckt" % done)
		if index==frontier and done>0: caption="Hier geht deine Reise weiter"
		station("world:"+data.id,data.title,caption,data.icon,Color(data.color),centers[index],open,done>=int(data.gate),index==frontier,func(): navigate("collection",0,"base") if index==0 else navigate("world",index))
		if index>0:
			canvas.routes.append({"start":centers[index-1],"finish":centers[index],"open":open,"color":Color(data.color),"fresh":open and not seen.has("world:"+data.id)})
	var key := "map:-1::false"
	var target:=maxf(0,centers[frontier].y-scroller.size.y*0.66)
	if seen.has("world:"+worlds[frontier].id): target=float(scroll_positions.get(key,target))
	request_scroll(int(target))
	action("Weiterreisen",Vector2(24,size.y-74),Vector2(size.x-48,54),func(): navigate("collection",0,"base") if frontier==0 else navigate("world",frontier),true)

func build_world() -> void:
	var data: Dictionary = JourneyProgress.worlds()[world]
	var color := Color(data.color)
	label("DEIN WEG · "+data.title.to_upper(),Vector2(88,29),size.x-110,12,Color(color,0.75))
	label(data.subtitle,Vector2(24,91),size.x-48,25)
	var visible: Array[String] = []
	for item in data.groups:
		if JourneyProgress.group_visible(game,item): visible.append(item)
	var height := maxf(620,440+ceili((visible.size()-1)/2.0)*240)
	make_scroll(height,color)
	var centers: Array[Vector2] = []
	var fresh_centers: Array[Vector2] = []
	for index in visible.size():
		var point := Vector2(size.x*0.5,height-172) if index==0 else Vector2(size.x*(0.28 if index%2==1 else 0.72),height-405-floorf((index-1)/2.0)*240)
		centers.append(point)
		var item := visible[index]
		if not seen.has("group:"+item): fresh_centers.append(point)
		var count := JourneyProgress.group_done(game,item)
		station("group:"+item,JourneyProgress.group_title(game,item),"%d / %d Kunstwerke" % [count,JourneyProgress.indices(game,item).size()],JourneyProgress.group_icon(item),color,point,true,count==JourneyProgress.indices(game,item).size(),index==0 and count<3,func(): navigate("collection",world,item),190)
		if index>0:
			var parent := 0 if index<=2 else index-2
			canvas.routes.append({"start":centers[parent],"finish":point,"open":true,"color":color,"fresh":not seen.has("group:"+item)})
	if visible.size()==1:
		canvas.routes.append({"start":centers[0],"finish":centers[0]+Vector2(45,-190),"open":false,"color":color})
	var key := "world:%d::false" % world
	var target:float=scroll_positions.get(key,height-scroller.size.y)
	if not fresh_centers.is_empty() and visible.size()>1:
		var average:=0.0
		for point in fresh_centers: average+=point.y
		target=clampf(average/fresh_centers.size()-scroller.size.y*0.5,0,height-scroller.size.y)
	request_scroll(int(target))
	action("Nächstes Kunstwerk",Vector2(24,size.y-74),Vector2(size.x-48,54),func(): play_next(world),true)

func play_next(selected_world: int) -> void:
	if JourneyProgress.world_index(game.level_collection(game.level).id)==selected_world and game.level_available(game.level) and not game.completed.has(game.level):
		game.start_journey_puzzle(game.level)
		return
	for item in JourneyProgress.worlds()[selected_world].groups:
		for index in JourneyProgress.indices(game,item):
			if game.level_available(index) and not game.completed.has(index): game.start_journey_puzzle(index); return
	tell("Du hast hier schon alle Kunstwerke entdeckt.")

func build_collection() -> void:
	var color := Color("#68eed2") if world<0 else Color(JourneyProgress.worlds()[world].color)
	label("DEINE KUNSTWERKE" if history else "EIN NEUES LICHT",Vector2(88,29),size.x-110,12,Color(color,0.75))
	label(JourneyProgress.group_title(game,group),Vector2(24,91),size.x-48,27)
	var pending: Array[int] = []
	var finished: Array[int] = []
	for index in JourneyProgress.indices(game,group):
		if game.completed.has(index): finished.append(index)
		elif game.level_available(index): pending.append(index)
	if pending.has(game.level):
		pending.erase(game.level)
		pending.push_front(game.level)
	var displayed: Array[int] = []
	if history: displayed.assign(finished.slice(page*6,page*6+6))
	else: displayed.assign(pending.slice(0,3))
	var hero := not history and not displayed.is_empty()
	var height := (330+ceilf(maxf(0,displayed.size()-1)/2.0)*238) if hero else ceilf(displayed.size()/2.0)*238
	make_scroll(maxf(height,360),color)
	for position in displayed.size():
		var card := Button.new()
		card.set_script(load("res://journey_puzzle_card.gd"))
		card.game = game; card.index = displayed[position]; card.accent = color; card.hero = hero and position==0; card.complete = history
		if hero and position==0:
			card.position=Vector2(24,8); card.size=Vector2(size.x-48,310)
		else:
			var offset := position-1 if hero else position
			var width := (size.x-60)*0.5
			card.position=Vector2(24+(offset%2)*(width+12),(330 if hero else 8)+floorf(offset/2.0)*238)
			card.size=Vector2(width,224)
		canvas.add_child(card)
	if displayed.is_empty():
		var message := Label.new()
		message.text="Alle Lichter dieser Sammlung leuchten." if not finished.is_empty() else "Hier warten bald deine eigenen Kunstwerke."
		message.position=Vector2(24,120); message.size=Vector2(size.x-48,70)
		message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		message.modulate=Color("#a6bdca")
		canvas.add_child(message)
	if history and (page+1)*6<finished.size():
		action("Weitere Kunstwerke",Vector2(24,size.y-74),Vector2(size.x-48,54),func(): page+=1; scroller=null; relayout())
	elif not history and not finished.is_empty():
		action("Schon entdeckt · %d" % finished.size(),Vector2(24,size.y-74),Vector2(size.x-48,54),func(): navigate("collection",world,group,true))
	else:
		label("Dein Weg wächst mit jedem Kunstwerk.",Vector2(24,size.y-62),size.x-48,14,Color("#8298ab")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func build_home() -> void:
	var frontier := JourneyProgress.frontier(game)
	var data: Dictionary = JourneyProgress.worlds()[frontier]
	var logo := label("ARROW WAY",Vector2(24,size.y*0.13),size.x-48,40)
	logo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label("Kunstwerke aus Licht",Vector2(24,size.y*0.13+65),size.x-48,15,Color("#8fa8b7")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	canvas=Control.new()
	canvas.set_script(load("res://journey_canvas.gd"))
	canvas.position=Vector2(0,size.y*0.24)
	canvas.size=Vector2(size.x,250)
	canvas.star_count=22
	canvas.accent=Color(data.color)
	canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var center:=Vector2(size.x*0.5,size.y*0.05+86)
	canvas.routes.assign([{"start":Vector2(size.x*0.27,245),"finish":center,"open":true,"color":Color(data.color),"opacity":0.28},{"start":center,"finish":Vector2(size.x*0.73,12),"open":false,"color":Color(data.color),"opacity":0.45}])
	add_child(canvas)
	var illustration := Button.new()
	illustration.set_script(load("res://journey_station.gd"))
	illustration.position=Vector2(size.x*0.5-110,size.y*0.29+22)
	illustration.size=Vector2(220,180)
	illustration.scale=Vector2.ONE*1.35
	illustration.icon_name=data.icon; illustration.tint=Color(data.color); illustration.current=true
	illustration.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(illustration)
	action("Deine Reise",Vector2(36,size.y*0.59),Vector2(size.x-72,60),func(): game.close_home(); game.open_journey(),true)
	action("Weiter spielen",Vector2(36,size.y*0.59+76),Vector2(size.x-72,54),game.close_home)
	var search := action("Suchen & Favoriten",Vector2(36,size.y*0.59+145),Vector2(size.x-72,48),func(): game.close_home(); game.open_gallery())
	search.add_theme_font_size_override("font_size",14)
	if not JourneyProgress.indices(game,"custom").is_empty():
		action("Eigene Motive",Vector2(36,size.y-80),Vector2(size.x-72,48),func(): game.close_home(); game.open_journey(-1,"custom"))
	icon_button("<circle cx='12' cy='12' r='4'/><path d='M12 2v3m0 14v3M2 12h3m14 0h3M5 5l2 2m10 10l2 2M5 19l2-2M17 7l2-2'/>",Vector2(size.x-72,24),func(): navigate("settings"),"Einstellungen")

func build_settings() -> void:
	icon_button("<path d='M15 5L8 12l7 7'/>",Vector2(24,24),go_back,"Zurück")
	label("Ganz in deinem Tempo",Vector2(24,104),size.x-48,28)
	label("Einstellungen",Vector2(24,151),size.x-48,15,Color("#8fa8b7"))
	var toggle := CheckButton.new()
	toggle.text="Soundeffekte"
	toggle.position=Vector2(24,220); toggle.size=Vector2(size.x-48,64)
	toggle.button_pressed=game.feedback.enabled
	toggle.add_theme_font_size_override("font_size",20)
	toggle.toggled.connect(func(_enabled): game.toggle_sound())
	add_child(toggle)

func tell(message: String) -> void:
	if is_instance_valid(toast): toast.queue_free()
	toast=label(message,Vector2(24,size.y-127),size.x-48,13,Color("#bdd9df"))
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var item := toast
	get_tree().create_timer(2.5).timeout.connect(func(): if is_instance_valid(item): item.queue_free())
