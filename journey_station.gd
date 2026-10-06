extends Button

var title := ""
var subtitle := ""
var icon_name := "spark"
var tint := Color("#68eed2")
var locked := false
var achieved := false
var current := false
var fresh := false
var major := false
var celebrate := false
var age := 0.0
var clock := 0.0

func _ready() -> void:
	if fresh: modulate.a = 0.0
	pivot_offset = Vector2(size.x*0.5,64)
	for state in ["normal", "hover", "pressed", "focus"]: add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _process(delta: float) -> void:
	age += delta
	clock += delta
	if fresh:
		modulate.a = smoothstep(0.35, 1.05, age)
		scale = Vector2.ONE*lerpf(0.93,1.0,smoothstep(0.25,1.2,age))
	queue_redraw()

func line(points: Array, color: Color, width := 2.0) -> void:
	var p := PackedVector2Array()
	var center := Vector2(size.x * 0.5, 64)
	for point in points: p.append(center + point * 0.68)
	draw_polyline(p, Color(color, 0.045), width + 7, true)
	draw_polyline(p, Color(color, 0.10), width + 3, true)
	draw_polyline(p, color, width, true)
	for point in [p[0],p[-1]]: draw_circle(point, width * 0.5, color)

func ring(center: Vector2, radius: float, color: Color, width := 2.0) -> void:
	draw_arc(center, radius, 0, TAU, 64, Color(color, 0.08), width + 5, true)
	draw_arc(center, radius, 0, TAU, 64, color, width, true)

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 64)
	var color := tint if not locked else tint.darkened(0.30)
	var alpha := 1.0 if not locked else 0.32
	var radius := 57.0 if major else 43.0
	for outer in range(int(radius)+25,int(radius),-4):
		draw_circle(center,outer,Color(color,0.012*alpha))
	if major:
		var hexagon := PackedVector2Array()
		for index in 7: hexagon.append(center+Vector2.from_angle(index*TAU/6-PI/6)*radius)
		draw_colored_polygon(hexagon,Color("#1a203b") if not locked else Color("#101625"))
		draw_polyline(hexagon,Color(color,0.70*alpha),1.8,true)
		var inner := PackedVector2Array()
		for point in hexagon: inner.append(center+(point-center)*0.89)
		draw_polyline(inner,Color(color,0.13*alpha),1.0,true)
	else:
		draw_circle(center+Vector2(0,3),radius+2,Color("#040b14"))
		draw_circle(center,radius,Color("#141e30"))
		draw_arc(center,radius,PI*1.05,PI*1.82,48,Color(color,0.70*alpha),1.6,true)
		draw_arc(center,radius,PI*-0.18,PI*0.86,48,Color(color,0.28*alpha),1.2,true)
	if celebrate and age<3:
		var t := clampf(age/3.0,0,1)
		draw_arc(center,radius+8+t*35,0,TAU,80,Color(color,(1-t)*0.6),2.0,true)
		for index in 12:
			var direction := Vector2.from_angle(index*TAU/12+0.2)
			draw_circle(center+direction*(radius+12+t*54),2.5*(1-t),Color(color,(1-t)*0.8))
	if current:
		var pulse := 0.5 + 0.5 * sin(clock * 2.0)
		draw_arc(center, 57, 0, TAU, 80, Color(color, 0.16 + pulse * 0.10), 1.1, true)
		for index in 3:
			var angle := -PI * 0.5 + index * TAU / 3
			draw_circle(center + Vector2.from_angle(angle) * 57, 2.4, Color(color, 0.72))
	if is_hovered() or has_focus(): ring(center, 53, Color(color, 0.45), 1.0)
	if is_pressed(): draw_circle(center, 48, Color(color, 0.08))
	color.a = 0.34 if locked else 0.95
	match icon_name:
		"house":
			line([Vector2(-38,-3),Vector2(0,-35),Vector2(38,-3)],color)
			line([Vector2(-28,-9),Vector2(-28,32),Vector2(28,32),Vector2(28,-9)],color)
			line([Vector2(-6,32),Vector2(-6,8),Vector2(9,8),Vector2(9,32)],color,1.6)
			line([Vector2(-19,-3),Vector2(-9,-3),Vector2(-9,7),Vector2(-19,7),Vector2(-19,-3)],color,1.5)
		"tool":
			line([Vector2(-27,32),Vector2(9,-4),Vector2(3,-17),Vector2(8,-31),Vector2(22,-36),Vector2(16,-20),Vector2(27,-12),Vector2(38,-25),Vector2(36,-9),Vector2(25,2),Vector2(14,3),Vector2(-22,39),Vector2(-27,32)],color)
		"flask":
			line([Vector2(-12,-34),Vector2(12,-34)],color)
			line([Vector2(-7,-34),Vector2(-7,-13),Vector2(-30,25),Vector2(-26,34),Vector2(26,34),Vector2(30,25),Vector2(7,-13),Vector2(7,-34)],color)
			line([Vector2(-20,12),Vector2(20,12)],color,1.5)
			ring(center+Vector2(-5,22)*0.68,3,color,1.3)
		"train":
			line([Vector2(-23,-32),Vector2(23,-32),Vector2(27,25),Vector2(-27,25),Vector2(-23,-32)],color)
			line([Vector2(-19,-21),Vector2(19,-21),Vector2(19,0),Vector2(-19,0),Vector2(-19,-21)],color,1.5)
			for x in [-16,16]: ring(center+Vector2(x,14)*0.68,3,color,1.5)
			line([Vector2(-16,25),Vector2(-27,40)],color); line([Vector2(16,25),Vector2(27,40)],color)
		"ship":
			line([Vector2(-38,11),Vector2(36,11),Vector2(22,31),Vector2(-24,31),Vector2(-38,11)],color)
			line([Vector2(-4,8),Vector2(-4,-36),Vector2(25,3),Vector2(-4,3)],color)
			line([Vector2(-11,-26),Vector2(-29,3),Vector2(-11,3)],color,1.5)
			line([Vector2(-37,39),Vector2(-24,35),Vector2(-11,39),Vector2(3,35),Vector2(17,39),Vector2(31,35)],color,1.5)
		"plane":
			line([Vector2(0,-38),Vector2(6,-27),Vector2(6,-7),Vector2(34,13),Vector2(34,22),Vector2(6,9),Vector2(5,28),Vector2(16,34),Vector2(16,40),Vector2(0,35),Vector2(-16,40),Vector2(-16,34),Vector2(-5,28),Vector2(-6,9),Vector2(-34,22),Vector2(-34,13),Vector2(-6,-7),Vector2(-6,-27),Vector2(0,-38)],color)
		"tree":
			line([Vector2(0,-35),Vector2(-18,-12),Vector2(-9,-12),Vector2(-28,11),Vector2(-16,11),Vector2(-37,31),Vector2(37,31),Vector2(16,11),Vector2(28,11),Vector2(9,-12),Vector2(18,-12),Vector2(0,-35)],color)
			line([Vector2(-5,31),Vector2(-5,43),Vector2(5,43),Vector2(5,31)],color)
		"planet":
			ring(center, 21, color)
			line([Vector2(-38,17),Vector2(-32,25),Vector2(-13,23),Vector2(12,9),Vector2(34,-12),Vector2(38,-22),Vector2(30,-25)],color)
			line([Vector2(-30,2),Vector2(-37,12),Vector2(-38,17)],color)
			line([Vector2(28,-36),Vector2(28,-27)],Color(color,0.6),1.4)
		"city":
			line([Vector2(-36,31),Vector2(-36,-4),Vector2(-20,-4),Vector2(-20,31),Vector2(-20,-26),Vector2(-4,-26),Vector2(-4,-35),Vector2(2,-35),Vector2(2,31),Vector2(2,-12),Vector2(23,-12),Vector2(23,31),Vector2(23,0),Vector2(35,0),Vector2(35,31),Vector2(-36,31)],color)
			for x in [-29,-12,12]:
				for y in [4,16]: line([Vector2(x,y),Vector2(x+3,y)],Color(color,0.5),1.2)
		"moon":
			var p: Array = []
			for index in 31: p.append(Vector2.from_angle(lerpf(-1.9,1.9,index/30.0))*29)
			for index in 31: p.append(Vector2(17,0)+Vector2.from_angle(lerpf(2.0,4.28,index/30.0))*28)
			line(p,color)
			line([Vector2(26,-34),Vector2(26,-22)],color,1.5); line([Vector2(20,-28),Vector2(32,-28)],color,1.5)
		"cup":
			line([Vector2(-28,-6),Vector2(-22,25),Vector2(-13,33),Vector2(8,33),Vector2(18,25),Vector2(24,-6),Vector2(-28,-6)],color)
			line([Vector2(24,-1),Vector2(36,-1),Vector2(38,8),Vector2(31,19),Vector2(20,19)],color)
			line([Vector2(-35,40),Vector2(34,40)],Color(color,0.6),1.5)
			for x in [-14,2,16]: line([Vector2(x,-17),Vector2(x-4,-24),Vector2(x+2,-31),Vector2(x,-38)],Color(color,0.7),1.6)
		"palette":
			line([Vector2(26,29),Vector2(7,39),Vector2(-20,31),Vector2(-36,12),Vector2(-33,-16),Vector2(-13,-34),Vector2(16,-31),Vector2(34,-15),Vector2(33,3),Vector2(19,8),Vector2(12,15),Vector2(17,23),Vector2(26,29)],color)
			for pos in [Vector2(-15,-16),Vector2(8,-17),Vector2(-22,6)]: ring(center+pos*0.68,4,color,1.6)
		"snow":
			for index in 6:
				var dir := Vector2.from_angle(index*TAU/6)
				line([Vector2.ZERO,dir*36],color)
				line([dir*28+dir.orthogonal()*9,dir*18,dir*28-dir.orthogonal()*9],color,1.5)
		"flower":
			for index in 5: ring(center+Vector2.from_angle(index*TAU/5-PI/2)*15,11,color,1.6)
			ring(center,7,color,1.8)
			line([Vector2(0,18),Vector2(0,40),Vector2(16,29)],color)
		"mountain": line([Vector2(-40,30),Vector2(-10,-27),Vector2(9,7),Vector2(23,-11),Vector2(42,30),Vector2(-40,30)],color); line([Vector2(-20,-8),Vector2(-10,-2),Vector2(-2,-10)],color,1.4)
		"chip":
			line([Vector2(-23,-23),Vector2(23,-23),Vector2(23,23),Vector2(-23,23),Vector2(-23,-23)],color)
			line([Vector2(-10,-10),Vector2(10,-10),Vector2(10,10),Vector2(-10,10),Vector2(-10,-10)],Color(color,0.6),1.6)
			for x in [-13,0,13]:
				line([Vector2(x,-34),Vector2(x,-23)],color,1.5); line([Vector2(x,23),Vector2(x,34)],color,1.5)
				line([Vector2(-34,x),Vector2(-23,x)],color,1.5); line([Vector2(23,x),Vector2(34,x)],color,1.5)
		"phone": line([Vector2(-19,-36),Vector2(19,-36),Vector2(19,36),Vector2(-19,36),Vector2(-19,-36)],color); line([Vector2(-7,26),Vector2(7,26)],color,1.6)
		"fish": line([Vector2(-29,0),Vector2(-12,-20),Vector2(10,-17),Vector2(24,-4),Vector2(38,-17),Vector2(38,17),Vector2(24,4),Vector2(10,17),Vector2(-12,20),Vector2(-29,0)],color); draw_circle(center+Vector2(-12,-4)*0.68,2,color)
		"bird": line([Vector2(-36,18),Vector2(-12,-12),Vector2(5,-8),Vector2(15,-25),Vector2(30,-20),Vector2(39,-12),Vector2(28,-10),Vector2(17,16),Vector2(-2,26),Vector2(-36,18)],color); line([Vector2(-18,9),Vector2(1,4),Vector2(13,10)],color,1.5)
		"paw":
			for pos in [Vector2(-25,-10),Vector2(-9,-26),Vector2(10,-26),Vector2(27,-9)]: ring(center+pos*0.68,6,color,1.6)
			line([Vector2(-23,23),Vector2(-15,2),Vector2(0,-5),Vector2(15,2),Vector2(24,23),Vector2(15,31),Vector2(0,27),Vector2(-15,31),Vector2(-23,23)],color)
		"music": line([Vector2(-10,24),Vector2(-10,-25),Vector2(24,-34),Vector2(24,14)],color); ring(center+Vector2(-18,25)*0.68,8,color); ring(center+Vector2(16,15)*0.68,8,color)
		"ball": ring(center,27,color); line([Vector2(0,-15),Vector2(15,-4),Vector2(9,14),Vector2(-9,14),Vector2(-15,-4),Vector2(0,-15)],color,1.5)
		"car": line([Vector2(-38,16),Vector2(-38,-2),Vector2(-25,-8),Vector2(-12,-26),Vector2(15,-26),Vector2(30,-8),Vector2(38,-3),Vector2(38,16),Vector2(-38,16)],color); ring(center+Vector2(-23,20)*0.68,7,color); ring(center+Vector2(23,20)*0.68,7,color)
		_:
			line([Vector2(0,-40),Vector2(9,-10),Vector2(37,0),Vector2(9,10),Vector2(0,40),Vector2(-9,10),Vector2(-37,0),Vector2(-9,-10),Vector2(0,-40)],color)
			line([Vector2(31,-37),Vector2(31,-24)],Color(color,0.65),1.5); line([Vector2(24,-30),Vector2(38,-30)],Color(color,0.65),1.5)
	var ink := Color("#edf4fc") if not locked else Color(tint.lightened(0.20),0.42)
	var display := title
	var font := ThemeDB.fallback_font
	while font.get_string_size(display,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x > size.x+32 and display.length()>2: display=display.trim_suffix("…").left(display.trim_suffix("…").length()-1)+"…"
	draw_string(font,Vector2(-16,139),display,HORIZONTAL_ALIGNMENT_CENTER,size.x+32,19,ink)
	draw_string(font,Vector2(-24,162),subtitle,HORIZONTAL_ALIGNMENT_CENTER,size.x+48,12,Color("#7a8da4") if not locked else Color("#465268"))
	if achieved:
		draw_circle(center+Vector2(35,35),11,Color("#142f2b"))
		draw_polyline(PackedVector2Array([center+Vector2(30,35),center+Vector2(34,39),center+Vector2(41,31)]),tint,1.7,true)
