extends Control

var game: Node2D
var screen := "map"
var world := -1
var group := ""
var history := false
var world_centers: Array[Vector2] = []
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
var ui_accent := Color("#ffd17c")
var favorites_only := false
var selected_art := -1
var reward := {}
var reward_age := 0.0
var camera_tween: Tween
var atmosphere: Control
var backdrop: ShaderMaterial
var ambient_age := 0.0
var edge_materials: Array[ShaderMaterial] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	relayout()

func _process(delta: float) -> void:
	ambient_age+=delta
	if is_instance_valid(atmosphere):
		var offset := float(scroller.scroll_vertical) if is_instance_valid(scroller) else 0.0
		var ambient_color := ui_accent
		var ambient_icon := JourneyProgress.worlds()[JourneyProgress.frontier(game)].icon as String
		if screen=="map" and not world_centers.is_empty():
			var center_y := offset+scroller.size.y*0.55
			var nearest := 0
			for i in world_centers.size():
				if absf(world_centers[i].y-center_y)<absf(world_centers[nearest].y-center_y): nearest=i
			ambient_color=Color(JourneyProgress.worlds()[nearest].color)
			ambient_icon=JourneyProgress.worlds()[nearest].icon if JourneyProgress.world_open(game,nearest) else "spark"
		atmosphere.camera=offset
		atmosphere.tint=atmosphere.tint.lerp(ambient_color,1.0-exp(-delta*2.0))
		atmosphere.decor_icon=ambient_icon
		atmosphere.queue_redraw()
		backdrop.set_shader_parameter("accent",atmosphere.tint)
		backdrop.set_shader_parameter("drift",ambient_age*0.035+offset*0.0003)
		for edge in edge_materials:
			edge.set_shader_parameter("accent",atmosphere.tint)
			edge.set_shader_parameter("drift",ambient_age*0.035+offset*0.0003)
	if not reward.is_empty():
		reward_age+=delta
		if reward_age>3.5: reward.clear()
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
	if event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed:
		if is_instance_valid(camera_tween): camera_tween.kill()
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
		box.bg_color = ui_accent if primary else Color("#132332")
		if state == "hover": box.bg_color = box.bg_color.lightened(0.06)
		if state == "pressed": box.bg_color = box.bg_color.darkened(0.08)
		box.set_border_width_all(1)
		box.border_color = ui_accent.lightened(0.15) if primary else Color("#263c4c")
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
	if is_instance_valid(camera_tween): camera_tween.kill()
	finger=-1; dragging=false; velocity=0.0
	var key := "%s:%d:%s:%s" % [screen,world,group,history]
	if is_instance_valid(scroller): scroll_positions[key] = scroller.get_meta("wanted_scroll",scroller.scroll_vertical)
	for child in get_children(): remove_child(child); child.queue_free()
	scroller = null
	edge_materials.clear()
	size = get_viewport_rect().size
	seen.assign(game.journey_seen)
	visible_station_ids.clear()
	var color := Color("#a997ff") if world < 0 else Color(JourneyProgress.worlds()[world].color)
	ui_accent = Color(JourneyProgress.worlds()[JourneyProgress.frontier(game)].color) if world<0 else JourneyProgress.group_color(group)
	var background := ColorRect.new()
	background.size = size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = load("res://journey_background.gdshader")
	material.set_shader_parameter("accent",color)
	background.material = material
	backdrop=material
	add_child(background)
	atmosphere=Control.new()
	atmosphere.set_script(load("res://journey_atmosphere.gd"))
	atmosphere.size=size; atmosphere.tint=ui_accent; atmosphere.home=screen=="home"
	atmosphere.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)
	if screen == "home":
		build_home()
	elif screen == "settings":
		build_settings()
	else:
		icon_button("<path d='M15 5L8 12l7 7'/>",Vector2(24,24),go_back,"Zurück")
		if screen == "map": build_map()
		elif screen == "album": build_album()
		elif screen == "artwork": build_artwork()
		else: build_collection()
		if is_instance_valid(scroller):
			for lower in [false,true]:
				var edge := ColorRect.new()
				edge.position=Vector2(0,scroller.position.y+(scroller.size.y-32 if lower else 0))
				edge.size=Vector2(size.x,32); edge.mouse_filter=Control.MOUSE_FILTER_IGNORE
				var fade := ShaderMaterial.new()
				fade.shader=load("res://journey_edge_fade.gdshader")
				fade.set_shader_parameter("accent",ui_accent)
				fade.set_shader_parameter("lower",lower)
				edge.material=fade; edge_materials.append(fade); add_child(edge)
	game.remember_journey_stations(visible_station_ids)
	rebuilding = false

func navigate(next_screen: String, next_world := -1, next_group := "", past := false) -> void:
	if is_instance_valid(scroller): scroll_positions["%s:%d:%s:%s" % [screen,world,group,history]] = scroller.get_meta("wanted_scroll",scroller.scroll_vertical)
	scroller = null
	if screen=="map" and next_screen!="map": reward.clear()
	screen = next_screen; world = next_world; group = next_group; history = past; page = 0
	relayout()

func go_back() -> void:
	if screen == "map" or screen == "album": game.close_journey(); game.open_home()
	elif screen == "collection": navigate("map",world)
	elif screen == "artwork":
		screen="album"; scroller=null; relayout()
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
	if is_instance_valid(camera_tween): camera_tween.kill()
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
	node.major = id.begins_with("world:")
	node.celebrate = reward.get("group","")==id.trim_prefix("group:") or (id.begins_with("world:") and reward.get("world",-1)>=0 and JourneyProgress.world_complete(game,int(reward.world)) and id=="world:"+JourneyProgress.worlds()[int(reward.world)].id)
	node.tint = color; node.locked = not available; node.achieved = achieved; node.current = current
	node.fresh = available and not seen.has(id)
	node.position = center-Vector2(width*0.5,64)
	node.size = Vector2(width,180)
	node.set_meta("station_id",id)
	canvas.add_child(node)
	canvas.label_zones.append(Rect2(Vector2(center.x-width*0.5-14,center.y+57),Vector2(width+28,53)))
	if available:
		visible_station_ids.append(id)
		node.pressed.connect(callback)
	else: node.pressed.connect(func(): tell("Löse alle Rätsel der vorherigen Themenwelt."))
	return node

func focus_world(index: int) -> void:
	if index < 0 or index >= world_centers.size(): return
	var center := world_centers[index]
	request_scroll(maxi(0,int(center.y-scroller.size.y*0.72)))

func build_map() -> void:
	label("DEINE NEONREISE",Vector2(88,29),size.x-110,12,Color("#83ada9"))
	label("Dein Weg durch die Themen",Vector2(24,91),size.x-48,25)
	if reward.is_empty() and not game.journey_reward.is_empty():
		reward=game.journey_reward.duplicate(); reward_age=0.0; game.journey_reward.clear()
	var worlds := JourneyProgress.worlds()
	var frontier := JourneyProgress.frontier(game)
	# Every reached theme and its subcategories live on this ONE canvas.
	# Future themes have no child nodes or hidden child routes yet.
	var blocks: Array[Dictionary] = []
	var offset := 170.0
	for index in worlds.size():
		var rows := ceili(JourneyProgress.visible_groups(game,index).size()/2.0)
		blocks.append({"offset":offset,"rows":rows})
		offset += 270.0+rows*230.0
	var height := offset+30
	make_scroll(height,Color("#c5afff"))
	world_centers.clear()
	for block in blocks: world_centers.append(Vector2(size.x*0.5,height-block.offset))
	for index in worlds.size():
		var data: Dictionary = worlds[index]
		var available := JourneyProgress.world_open(game,index)
		var center := world_centers[index]
		var color := Color(data.color)
		var recommended := JourneyProgress.next_group(game,index) if available else ""
		var caption := "%d / %d Rätsel gelöst" % [JourneyProgress.world_done(game,index),JourneyProgress.world_total(game,index)] if available else "Noch gesperrt"
		station("world:"+data.id,data.title,caption,data.icon,color,center,available,JourneyProgress.world_complete(game,index),index==frontier,func(): focus_world(index),minf(300,size.x-48))
		if index>0:
			canvas.routes.append({"start":world_centers[index-1],"finish":center,"open":available and JourneyProgress.world_open(game,index-1),"color":color,"fresh":available and not seen.has("world:"+data.id),"opacity":0.65,"reward":reward.get("next",-1)==index,"guide":index==frontier})
		if not available: continue
		var visible := JourneyProgress.visible_groups(game,index)
		for position in visible.size():
			var item: String = visible[position]
			var branch_color := JourneyProgress.group_color(item)
			var row: int = position/2
			var single: bool = visible.size()==1 or (position==visible.size()-1 and visible.size()%2==1)
			var point := Vector2(size.x*(0.5 if single else (0.265 if position%2==0 else 0.735)),center.y-230*(row+1))
			var junction := Vector2(size.x*0.5,point.y+95)
			if position%2==0:
				var previous := center if row==0 else Vector2(size.x*0.5,center.y-230*row+95)
				canvas.routes.append({"start":previous,"finish":junction,"open":true,"color":color,"opacity":0.8,"guide":item==recommended})
			canvas.routes.append({"start":junction,"finish":point,"open":true,"color":branch_color,"fresh":not seen.has("group:"+item),"guide":item==recommended})
			station("group:"+item,JourneyProgress.group_title(game,item),"%d / %d Rätsel gelöst" % [JourneyProgress.group_done(game,item),JourneyProgress.indices(game,item).size()],JourneyProgress.group_icon(item),branch_color,point,true,JourneyProgress.group_complete(game,item),item==recommended,func(): navigate("collection",index,item),minf(216,size.x*0.44))
	var selected := world if JourneyProgress.world_open(game,world) else frontier
	var target := maxi(0,int(world_centers[selected].y-scroller.size.y*0.72))
	var key := "map:%d::false" % world
	if world<0 and seen.has("world:"+worlds[frontier].id): target=int(scroll_positions.get(key,target))
	if int(reward.get("next",-1))>int(reward.get("world",-1)) and int(reward.get("world",-1))>=0:
		animate_unlock(world_centers[int(reward.world)],target)
	else: request_scroll(target)
	if not reward.is_empty():
		var message: String = "Themenwelt geschafft · Ein neuer Weg leuchtet!" if int(reward.get("next",-1))>=0 else "Sammlung geschafft · Alle Kunstwerke leuchten!"
		tell(message)
	action("Nächstes Rätsel",Vector2(24,size.y-74),Vector2(size.x-48,54),func(): play_next(frontier),true)

func play_next(selected_world: int) -> void:
	if JourneyProgress.world_index(game.level_collection(game.level).id)==selected_world and game.level_available(game.level) and not game.completed.has(game.level):
		game.start_journey_puzzle(game.level)
		return
	for item in JourneyProgress.worlds()[selected_world].groups:
		for index in JourneyProgress.indices(game,item):
			if game.level_available(index) and not game.completed.has(index): game.start_journey_puzzle(index); return
	tell("Du hast hier schon alle Kunstwerke entdeckt.")

func build_collection() -> void:
	if world>=0: game.ads.opened_world(world)
	var color := JourneyProgress.group_color(group)
	var parent_title: String = "EIGENE MOTIVE" if world<0 else JourneyProgress.worlds()[world].title.to_upper()
	label(parent_title,Vector2(88,29),size.x-110,12,Color(color,0.75))
	label(JourneyProgress.group_title(game,group),Vector2(24,91),size.x-48,27)
	# Keep a stable order; solved and unsolved puzzles are always together.
	var displayed := JourneyProgress.indices(game,group)
	var height := ceilf(displayed.size()/2.0)*238+24
	make_scroll(maxf(height,360),color)
	for position in displayed.size():
		var card := Button.new()
		card.set_script(load("res://journey_puzzle_card.gd"))
		card.game = game; card.index = displayed[position]; card.accent = color
		card.complete = game.completed.has(card.index)
		var width := (size.x-60)*0.5
		card.position=Vector2(24+(position%2)*(width+12),8+floorf(position/2.0)*238)
		card.size=Vector2(width,224)
		canvas.add_child(card)
	if displayed.is_empty():
		var message := Label.new()
		message.text="Hier warten bald deine eigenen Kunstwerke."
		message.position=Vector2(24,120); message.size=Vector2(size.x-48,70)
		message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		message.modulate=Color("#a6bdca")
		canvas.add_child(message)
	label("%d / %d Rätsel gelöst" % [JourneyProgress.group_done(game,group),displayed.size()],Vector2(24,size.y-62),size.x-48,15,Color("#9db9c7")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var key := "collection:%d:%s:false" % [world,group]
	request_scroll(int(scroll_positions.get(key,0)))

func animate_unlock(previous_world: Vector2, target: int) -> void:
	var scroll := scroller
	request_scroll(maxi(0,int(previous_world.y-scroll.size.y*0.72)))
	await get_tree().process_frame
	if not is_instance_valid(scroll) or scroll!=scroller: return
	camera_tween=create_tween()
	camera_tween.tween_interval(0.65)
	camera_tween.tween_property(scroll,"scroll_vertical",target,1.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func art_card(index: int, position: Vector2, dimensions: Vector2, mode := "puzzle", callback := Callable()) -> Button:
	var card := Button.new()
	card.set_script(load("res://journey_puzzle_card.gd"))
	card.game=game; card.index=index; card.display_mode=mode; card.activate=callback
	card.accent=JourneyProgress.group_color(game.level_collection(index).id)
	card.complete=game.completed.has(index); card.hero=mode=="resume"
	card.position=position; card.size=dimensions
	canvas.add_child(card)
	return card

func build_home() -> void:
	var resume := JourneyProgress.resume_index(game)
	var featured := -1
	var public_art := JourneyProgress.album_indices(game)
	for index in game.completed:
		if public_art.has(index): featured=index
	label("ARROW WAY",Vector2(24,size.y*0.10),size.x-48,36).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label("Kunstwerke aus Licht",Vector2(24,size.y*0.10+53),size.x-48,15,Color("#a7a3c5")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	canvas=Control.new()
	canvas.set_script(load("res://journey_canvas.gd"))
	canvas.star_count=22
	canvas.size=size; canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	var top := size.y*0.24
	var height := minf(330,size.y*0.32)
	if featured>=0:
		art_card(featured,Vector2(32,top),Vector2(size.x-64,height),"home_art",func(): game.open_album(); game.journey.open_artwork(featured))
	else:
		art_card(resume,Vector2(32,top),Vector2(size.x-64,height),"resume",func(): game.start_journey_puzzle(resume))
	var next_y := top+height+24
	action("Erneut spielen" if game.completed.has(resume) else "Weiter spielen",Vector2(32,next_y),Vector2(size.x-64,58),func(): game.start_journey_puzzle(resume),true)
	action("Deine Reise",Vector2(32,next_y+74),Vector2(size.x-64,54),func(): game.close_home(); game.open_journey())
	action("Meine Kunstwerke",Vector2(32,next_y+142),Vector2(size.x-64,54),game.open_album)
	icon_button("<circle cx='12' cy='12' r='4'/><path d='M12 2v3m0 14v3M2 12h3m14 0h3M5 5l2 2m10 10l2 2M5 19l2-2M17 7l2-2'/>",Vector2(size.x-72,24),func(): navigate("settings"),"Einstellungen")

func build_album() -> void:
	var all_art := JourneyProgress.album_indices(game)
	label("DEIN ALBUM",Vector2(88,29),size.x-110,12,Color("#cca7e8"))
	label("Meine Kunstwerke",Vector2(24,91),size.x-48,27)
	var half := (size.x-60)*0.5
	var all_button := action("Alle Kunstwerke",Vector2(24,145),Vector2(half,44),func(): favorites_only=false; page=0; scroller=null; relayout(),not favorites_only)
	var hearts := action("Lieblingsbilder",Vector2(36+half,145),Vector2(half,44),func(): favorites_only=true; page=0; scroller=null; relayout(),favorites_only)
	all_button.add_theme_font_size_override("font_size",14); hearts.add_theme_font_size_override("font_size",14)
	var art := JourneyProgress.album_indices(game,favorites_only)
	var page_count := maxi(1,ceili(art.size()/6.0))
	page=clampi(page,0,page_count-1)
	var displayed := art.slice(page*6,page*6+6)
	make_scroll(maxf(360,ceilf(displayed.size()/2.0)*238+24),Color("#c3a0ff"))
	scroller.position.y=205; scroller.size.y=size.y-293
	for position in displayed.size():
		var index: int=displayed[position]
		art_card(index,Vector2(24+(position%2)*(half+12),8+floorf(position/2.0)*238),Vector2(half,224),"album",func(): open_artwork(index))
	if displayed.is_empty():
		var text := "Dein erstes Kunstwerk wartet auf dich.
Löse ein Rätsel und bring es zum Leuchten." if all_art.is_empty() else "Deine Lieblingsbilder bekommen ein Herz.
Öffne ein fertiges Kunstwerk und markiere es."
		var empty:=Label.new(); empty.text=text
		empty.position=Vector2(32,100); empty.size=Vector2(size.x-64,130)
		empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_font_size_override("font_size",18); empty.modulate=Color("#c4b7d7")
		canvas.add_child(empty)
	if page_count>1:
		var back:=action("Zurück",Vector2(24,size.y-74),Vector2(108,48),func(): page-=1; scroller=null; relayout())
		var next:=action("Weiter",Vector2(size.x-132,size.y-74),Vector2(108,48),func(): page+=1; scroller=null; relayout())
		back.disabled=page==0; next.disabled=page==page_count-1
		label("%d / %d" % [page+1,page_count],Vector2(142,size.y-61),size.x-284,15).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	else:
		label("%d Kunstwerke zum Leuchten gebracht" % all_art.size(),Vector2(24,size.y-62),size.x-48,14,Color("#a79bbb")).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func open_artwork(index: int) -> void:
	if not JourneyProgress.album_indices(game).has(index): return
	selected_art=index; screen="artwork"; scroller=null; relayout()

func build_artwork() -> void:
	if not JourneyProgress.album_indices(game).has(selected_art):
		screen="album"; build_album(); return
	ui_accent=JourneyProgress.group_color(game.level_collection(selected_art).id)
	label("DEIN KUNSTWERK",Vector2(88,29),size.x-110,12,ui_accent)
	label(game.level_title(selected_art),Vector2(24,91),size.x-48,27)
	canvas=Control.new(); canvas.set_script(load("res://journey_canvas.gd")); canvas.star_count=22; canvas.size=size; canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(canvas)
	art_card(selected_art,Vector2(24,153),Vector2(size.x-48,size.y-255),"display")
	var favorite: bool=game.favorite_paths.has(game.level_path(selected_art))
	var heart_path := "<path d='M12 21S3 15 3 8a5 5 0 0 1 9-3 5 5 0 0 1 9 3c0 7-9 13-9 13z'"+(" fill='#ff8bbf'" if favorite else "")+"/>"
	icon_button(heart_path,Vector2(24,size.y-74),func(): game.toggle_favorite(selected_art); relayout(),"Herz entfernen" if favorite else "Als Lieblingsbild merken")
	action("Erneut spielen",Vector2(88,size.y-74),Vector2(size.x-112,48),func(): game.start_journey_puzzle(selected_art),true)

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
	if OS.has_feature("debug"):
		label("ENTWICKLERTEST · KEINE ECHTE WERBUNG",Vector2(24,319),size.x-48,12,Color("#8fa8b7"))
		var ad_toggle := CheckButton.new()
		ad_toggle.text="Testanzeigen aktivieren"
		ad_toggle.position=Vector2(24,351); ad_toggle.size=Vector2(size.x-48,54)
		ad_toggle.button_pressed=game.ads.test_mode
		ad_toggle.toggled.connect(game.ads.set_test_mode)
		add_child(ad_toggle)
		var premium_toggle := CheckButton.new()
		premium_toggle.text="Werbefrei simulieren"
		premium_toggle.position=Vector2(24,415); premium_toggle.size=Vector2(size.x-48,54)
		premium_toggle.button_pressed=game.ads.simulate_ad_free
		premium_toggle.toggled.connect(game.ads.set_simulated_ad_free)
		add_child(premium_toggle)
		label("5 Rätsel frei · dann 4 Rätsel + 6 Spielminuten",Vector2(24,490),size.x-48,13,Color("#8fa8b7"))

	action("Bildquellen & Lizenzen",Vector2(24,545),Vector2(size.x-48,48),show_art_credits)

func show_art_credits() -> void:
	var dialog := AcceptDialog.new()
	dialog.title="Bildquellen & Lizenzen"
	dialog.dialog_text=""
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(280,350)
	dialog.add_child(scroll)
	var credits := RichTextLabel.new()
	credits.custom_minimum_size=Vector2(260,350)
	credits.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	credits.fit_content=true
	credits.bbcode_enabled=true
	credits.meta_clicked.connect(func(url): OS.shell_open(str(url)))
	var published: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/art_credits.json"))
	credits.text=str(published.notice)+"\n[url=https://creativecommons.org/licenses/by/3.0/]CC BY 3.0 – Lizenz ansehen[/url]\n\n"
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	for entry in catalog.levels:
		if not entry.has("attribution"): continue
		var credit: Dictionary=entry.attribution
		credits.text+=entry.title+"\n"+str(credit.author)+" · "+str(credit.license)+"\n"+"[url="+str(credit.source)+"]Originalquelle ansehen[/url]\n\n"
	scroll.add_child(credits)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(int(size.x)-48,mini(int(size.y)-100,650)))

func tell(message: String) -> void:
	if is_instance_valid(toast): toast.queue_free()
	toast=label(message,Vector2(24,size.y-127),size.x-48,13,Color("#bdd9df"))
	toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var item := toast
	get_tree().create_timer(2.5).timeout.connect(func(): if is_instance_valid(item): item.queue_free())
