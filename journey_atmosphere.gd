extends Control

# One lightweight decorative layer. It never intercepts taps or opens content.
var tint := Color("#ffd17c")
var camera := 0.0
var home := false
var decor_icon := "spark"

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed=71062
	for i in range(48):
		var p := Vector2(rng.randf_range(12,size.x-12),fposmod(rng.randf()*size.y-camera*0.12,size.y))
		var radius := rng.randf_range(0.6,1.5)
		draw_circle(p,radius,Color(tint, rng.randf_range(0.12,0.32)))
		if i%12==0:
			draw_line(p-Vector2(4,0),p+Vector2(4,0),Color(tint,0.16),1,true)
			draw_line(p-Vector2(0,4),p+Vector2(0,4),Color(tint,0.16),1,true)
	# Outlines stay near the sides, leaving the central reading area quiet.
	for i in range(5):
		var p := Vector2(size.x*(0.03 if i%2==0 else 0.96),fposmod(110+i*size.y/4.3-camera*0.22,size.y+150)-45)
		var color := Color(tint,0.15 if home else 0.12)
		if decor_icon=="tree":
			var curve := PackedVector2Array()
			for step in range(25):
				var angle := TAU*step/24.0
				curve.append(p+Vector2(sin(angle)*28,cos(angle)*64))
			draw_polyline(curve,color,1.3,true)
			draw_line(p-Vector2(0,61),p+Vector2(0,75),color,1,true)
			for y in [-30,0,30]:
				draw_line(p+Vector2(0,y+16),p+Vector2(22,y-6),color,1,true)
		elif decor_icon=="planet":
			draw_arc(p,38,0,TAU,48,color,1.2,true)
			var orbit := PackedVector2Array()
			for step in range(49):
				var angle := TAU*step/48.0
				orbit.append(p+Vector2(cos(angle)*65,sin(angle)*17).rotated(-0.4))
			draw_polyline(orbit,color,1,true)
		elif decor_icon=="city":
			draw_polyline(PackedVector2Array([p+Vector2(-50,35),p+Vector2(-50,-15),p+Vector2(-20,-15),p+Vector2(-20,-48),p+Vector2(10,-48),p+Vector2(10,0),p+Vector2(40,0),p+Vector2(40,35)]),color,1.2,true)
		elif decor_icon=="moon":
			draw_arc(p,43,-1.25,1.25,40,color,1.4,true)
			draw_arc(p-Vector2(18,0),35,-1.0,1.0,40,color,1.2,true)
		else:
			var star := PackedVector2Array()
			for point in range(9):
				var angle := PI*point/4.0
				star.append(p+Vector2(sin(angle),cos(angle))*(42 if point%2==0 else 12))
			draw_polyline(star,color,1.2,true)
