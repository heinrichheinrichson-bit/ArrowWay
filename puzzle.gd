class_name ArrowPuzzle
extends RefCounted

const CELL := 14.0
const ORIGIN := Vector2(74, 183)
const COLS := 29
const ROWS := 33
const DIRECTIONS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const PALETTE := ["#65e5ff", "#ff6ab5", "#b299ff", "#ffd36e", "#69efb4", "#ff9870"]

static func pixel(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2(cell) * CELL

static func grid(pos: Vector2) -> Vector2i:
	return Vector2i(((pos - ORIGIN) / CELL).round())

static func mask(shape: int) -> Dictionary:
	var result := {}
	for y in range(ROWS):
		for x in range(COLS):
			var sx := x * 18.0 / 28.0
			var sy := y * 22.0 / 32.0
			var inside := false
			match shape:
				0: # House with a chimney, two windows and a door.
					inside = (sy >= 9 and sy <= 21 and sx >= 2 and sx <= 16) or (sy >= 2 and sy <= 9 and abs(sx - 9) <= sy)
					inside = inside or (sx >= 13 and sx <= 15 and sy >= 1 and sy <= 7)
				1: # Tree: three overlapping triangular layers and a trunk.
					for layer in range(3):
						var top := 1 + layer * 5
						if sy >= top and sy <= top + 8 and abs(sx - 9) <= (sy - top) * 0.9:
							inside = true
					inside = inside or (sy >= 18 and sy <= 22 and sx >= 8 and sx <= 10)
				2: # Heart.
					var v := Vector2((sx - 9.0) / 8.0, (12.0 - sy) / 8.0)
					var base := v.x * v.x + v.y * v.y - 1.0
					inside = base * base * base - v.x * v.x * v.y * v.y * v.y <= 0.0
				3: # Butterfly: two broad wings on each side of a narrow body.
					var dx := absf(sx - 9.0)
					inside = pow((dx - 4.2) / 4.0, 2) + pow((sy - 7.0) / 5.5, 2) <= 1.0
					inside = inside or pow((dx - 3.5) / 3.3, 2) + pow((sy - 15.0) / 5.0, 2) <= 1.0
					inside = inside or (dx <= 0.9 and sy >= 3 and sy <= 20)
				4: # Fish with a broad triangular tail.
					inside = pow((sx - 7.5) / 6.5, 2) + pow((sy - 11.0) / 6.0, 2) <= 1.0
					inside = inside or (sx >= 12 and sx <= 18 and absf(sy - 11.0) <= (sx - 11) * 0.85)
				5: # Flower with six overlapping petals, stem and leaves.
					for petal in range(6):
						var center := Vector2(9, 8) + Vector2.from_angle(petal * TAU / 6.0) * 3.7
						inside = inside or Vector2(sx, sy).distance_squared_to(center) <= 12.0
					inside = inside or (absf(sx - 9) <= 0.9 and sy >= 10 and sy <= 22)
					inside = inside or pow((sx - 6.7) / 3.1, 2) + pow((sy - 16.0) / 1.7, 2) <= 1.0
					inside = inside or pow((sx - 11.3) / 3.1, 2) + pow((sy - 18.0) / 1.7, 2) <= 1.0
			if inside:
				result[Vector2i(x, y)] = true
	return result

static func make_arrow(points: PackedVector2Array, color: Color) -> Dictionary:
	return {"points": points, "color": color, "travel": 0.0, "escape_time": 0.0, "escaping": false, "removed": false, "flash": 0.0, "hint": 0.0, "release": 0.0}

static func generate(shape: int, seed_value: int) -> Array[Dictionary]:
	return MotifBuilder.generate(shape, seed_value)

static func self_blocked(points: PackedVector2Array) -> bool:
	return points.size() > 2 and ray_hits(points, points.slice(0, points.size() - 1))

static func ray_hits(points: PackedVector2Array, other: PackedVector2Array) -> bool:
	if points.size() < 2:
		return true
	var head := points[-1]
	var end := head + (head - points[-2]).normalized() * 1800.0
	for i in range(other.size() - 1):
		var a := other[i]
		var b := other[i + 1]
		if Geometry2D.segment_intersects_segment(head, end, a, b) != null:
			return true
		# Endpoint distances also detect parallel paths and their round line caps.
		if a.distance_to(Geometry2D.get_closest_point_to_segment(a, head, end)) < CELL * 0.42 or b.distance_to(Geometry2D.get_closest_point_to_segment(b, head, end)) < CELL * 0.42:
			return true
		if head.distance_to(Geometry2D.get_closest_point_to_segment(head, a, b)) < CELL * 0.42:
			return true
	return false

static func solution(data: Array[Dictionary]) -> Array[int]:
	var blockers: Array[Dictionary] = []
	var order: Array[int] = []
	for i in range(data.size()):
		var dependencies := {}
		if self_blocked(data[i].points):
			dependencies[i] = true
		for j in range(data.size()):
			if i != j and ray_hits(data[i].points, data[j].points):
				dependencies[j] = true
		blockers.append(dependencies)
	for i in range(data.size()):
		if blockers[i].is_empty():
			order.append(i)
	var cursor := 0
	while cursor < order.size():
		var removed := order[cursor]
		cursor += 1
		for i in range(data.size()):
			if blockers[i].has(removed):
				blockers[i].erase(removed)
				if blockers[i].is_empty():
					order.append(i)
	return order
