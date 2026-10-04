extends RefCounted

static func sun() -> Image:
	var image := Image.create(320, 320, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	for y in range(320):
		for x in range(320):
			var point := Vector2(x - 160, y - 160)
			var inside := point.length() <= 75
			for ray in range(8):
				var direction := Vector2.from_angle(ray * TAU / 8.0)
				var projection := point.dot(direction)
				inside = inside or (projection >= 65 and projection <= 130 and absf(point.cross(direction)) <= 14)
			if inside:
				image.set_pixel(x, y, Color("#ffdf3a"))
	return image

static func outline_house() -> Image:
	var image := Image.create(320, 360, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var polygons: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(35, 145), Vector2(160, 30), Vector2(285, 145), Vector2(35, 145)]),
		PackedVector2Array([Vector2(45, 145), Vector2(275, 145), Vector2(275, 330), Vector2(45, 330), Vector2(45, 145)]),
		PackedVector2Array([Vector2(80, 190), Vector2(125, 190), Vector2(125, 245), Vector2(80, 245), Vector2(80, 190)]),
		PackedVector2Array([Vector2(195, 190), Vector2(240, 190), Vector2(240, 245), Vector2(195, 245), Vector2(195, 190)]),
		PackedVector2Array([Vector2(140, 270), Vector2(180, 270), Vector2(180, 330), Vector2(140, 330), Vector2(140, 270)])]
	for polygon in polygons:
		for index in range(polygon.size() - 1):
			var a := polygon[index]
			var b := polygon[index + 1]
			for step in range(int(a.distance_to(b) * 2) + 1):
				var point := Vector2i(a.lerp(b, float(step) / maxf(int(a.distance_to(b) * 2), 1)).round())
				image.fill_rect(Rect2i(point - Vector2i.ONE, Vector2i(3, 3)), Color.BLACK)
	return image

static func colored_palm() -> Image:
	var image := Image.create(320, 360, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	image.fill_rect(Rect2i(147, 110, 28, 220), Color("#986434"))
	var leaves: Array[PackedVector2Array] = [
		PackedVector2Array([Vector2(161, 130), Vector2(25, 150), Vector2(40, 90), Vector2(110, 65)]),
		PackedVector2Array([Vector2(161, 130), Vector2(295, 150), Vector2(280, 90), Vector2(210, 65)]),
		PackedVector2Array([Vector2(135, 110), Vector2(160, 25), Vector2(185, 110)])]
	for y in range(360):
		for x in range(320):
			for polygon in leaves:
				if Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
					image.set_pixel(x, y, Color("#28a85a"))
	return image
