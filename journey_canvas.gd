extends Control

var routes: Array[Dictionary] = []
var accent := Color("#68eed2")
var age := 0.0
var star_count := 65
var label_zones: Array[Rect2] = []

func covered(point: Vector2) -> bool:
	for zone in label_zones:
		if zone.has_point(point): return true
	return false

func _process(delta: float) -> void:
	age += delta
	if age < 3: queue_redraw()
	else:
		for route in routes:
			if route.get("guide",false): queue_redraw(); break

func _draw() -> void:
	# Quiet, deterministic starlight; decoration never receives input.
	var random := RandomNumberGenerator.new()
	random.seed = 48317
	for index in star_count:
		var point := Vector2(random.randf_range(24,size.x-24),random.randf_range(20,size.y-20))
		draw_circle(point,random.randf_range(0.6,1.6),Color(accent,random.randf_range(0.04,0.14)))
	for route in routes:
		var curve: Curve2D = route.get("curve",Curve2D.new())
		var start: Vector2 = route.start
		var finish: Vector2 = route.finish
		var bend := absf(start.y-finish.y)*0.45
		if curve.get_point_count()==0:
			curve.add_point(start,Vector2.ZERO,Vector2(0,-bend))
			curve.add_point(finish,Vector2(0,bend),Vector2.ZERO)
			route["curve"]=curve
		var points := curve.get_baked_points()
		var open: bool = route.open
		var color: Color = route.color if open else Color(route.color).darkened(0.65)
		var opacity: float = route.get("opacity",1.0)
		if open and route.get("fresh",false):
			var revealed := PackedVector2Array()
			var length := curve.get_baked_length()*smoothstep(0.15,1.35,age)
			for distance in range(0,int(length)+1,3): revealed.append(curve.sample_baked(distance))
			if revealed.size()>1: points = revealed
		if points.size() < 2: continue
		var chunks: Array[PackedVector2Array] = []
		var part := PackedVector2Array()
		for point in points:
			if covered(point):
				if part.size()>1: chunks.append(part)
				part=PackedVector2Array()
			else: part.append(point)
		if part.size()>1: chunks.append(part)
		for chunk in chunks:
			if open:
				draw_polyline(chunk,Color(color,0.018*opacity),18,true)
				draw_polyline(chunk,Color(color,0.05*opacity),9,true)
				draw_polyline(chunk,Color(color,0.12*opacity),4,true)
			draw_polyline(chunk,Color(color,(0.58 if open else 0.38)*opacity),1.6,true)
		for distance in range(35,int(curve.get_baked_length())-30,42):
			var point := curve.sample_baked(distance)
			if covered(point): continue
			draw_circle(point,2.0 if open else 1.3,Color(color,(0.55 if open else 0.5)*opacity))

		if open and (route.get("guide",false) or route.get("reward",false) and age<3):
			var fraction := clampf(age/2.5,0,1) if route.get("reward",false) and age<3 else fmod(age*0.22,1.0)
			var light := curve.sample_baked(curve.get_baked_length()*fraction)
			if not covered(light):
				for radius in range(14,2,-3): draw_circle(light,radius,Color(color,0.06))
				draw_circle(light,2.8,Color(color.lightened(0.35),0.95))
