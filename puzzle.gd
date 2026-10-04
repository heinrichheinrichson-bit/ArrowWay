class_name ArrowPuzzle
extends RefCounted

const CELL := 20.0
const ORIGIN := Vector2(90, 190)
const COLS := 19
const ROWS := 23
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
			var inside := false
			match shape:
				0: # House with a chimney, two windows and a door.
					inside = (y >= 9 and y <= 21 and x >= 2 and x <= 16) or (y >= 2 and y <= 9 and abs(x - 9) <= y)
					inside = inside or (x >= 13 and x <= 15 and y >= 1 and y <= 7)
					if (y >= 12 and y <= 14 and ((x >= 5 and x <= 6) or (x >= 12 and x <= 13))) or (y >= 18 and x >= 9 and x <= 10):
						inside = false
				1: # Tree: three overlapping triangular layers and a trunk.
					for layer in range(3):
						var top := 1 + layer * 5
						if y >= top and y <= top + 8 and abs(x - 9) <= (y - top) * 0.9:
							inside = true
					inside = inside or (y >= 18 and y <= 22 and x >= 8 and x <= 10)
				2: # Heart.
					var v := Vector2((x - 9.0) / 8.0, (12.0 - y) / 8.0)
					var base := v.x * v.x + v.y * v.y - 1.0
					inside = base * base * base - v.x * v.x * v.y * v.y * v.y <= 0.0
			if inside:
				result[Vector2i(x, y)] = true
	return result

static func make_arrow(points: PackedVector2Array, color: Color) -> Dictionary:
	return {"points": points, "color": color, "travel": 0.0, "escaping": false, "removed": false, "flash": 0.0, "hint": 0.0}

static func generate(shape: int, seed_value: int) -> Array[Dictionary]:
	var cells := mask(shape)
	var used := {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var result: Array[Dictionary] = []
	# Build in reverse solution order. Each added head has a clear ray past all older paths.
	for iteration in range(100):
		var candidates: Array = []
		for head: Vector2i in cells:
			if used.has(head):
				continue
			for direction: Vector2i in DIRECTIONS:
				var behind := head - direction
				if not cells.has(behind) or used.has(behind):
					continue
				var ray := head + direction
				var free := true
				while ray.x >= 0 and ray.x < COLS and ray.y >= 0 and ray.y < ROWS:
					if used.has(ray):
						free = false
						break
					ray += direction
				if free:
					candidates.append([head, direction])
		if candidates.is_empty():
			break
		var candidate: Array = candidates[rng.randi_range(0, candidates.size() - 1)]
		var head: Vector2i = candidate[0]
		var direction: Vector2i = candidate[1]
		var chain: Array[Vector2i] = [head, head - direction]
		var local := {head: true, head - direction: true}
		var target := rng.randi_range(5, 12)
		while chain.size() < target:
			var options: Array[Vector2i] = []
			for step: Vector2i in DIRECTIONS:
				var next := chain[-1] + step
				if not cells.has(next) or used.has(next) or local.has(next):
					continue
				# Keep the path's own body out of its forward escape ray.
				var relative := next - head
				if Vector2(relative).dot(Vector2(direction)) > 0 and Vector2(relative).cross(Vector2(direction)) == 0:
					continue
				options.append(next)
			if options.is_empty():
				break
			var next := options[rng.randi_range(0, options.size() - 1)]
			chain.append(next)
			local[next] = true
		var points := PackedVector2Array()
		chain.reverse()
		for cell in chain:
			used[cell] = true
			points.append(pixel(cell))
		result.append(make_arrow(points, Color(PALETTE[result.size() % PALETTE.size()])))
	# Fill reachable gaps by extending tails, keeping a valid solution after every edit.
	for sweep in range(12):
		var changed := false
		for arrow in result:
			var points: PackedVector2Array = arrow.points
			var tail := grid(points[0])
			for step: Vector2i in DIRECTIONS:
				var next := tail + step
				if not cells.has(next) or used.has(next):
					continue
				var extended := PackedVector2Array([pixel(next)])
				extended.append_array(points)
				arrow.points = extended
				if not self_blocked(extended) and solution(result).size() == result.size():
					used[next] = true
					changed = true
					break
				arrow.points = points
		if not changed:
			break
	return result

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
		if a.distance_to(Geometry2D.get_closest_point_to_segment(a, head, end)) < 10.0 or b.distance_to(Geometry2D.get_closest_point_to_segment(b, head, end)) < 10.0:
			return true
		if head.distance_to(Geometry2D.get_closest_point_to_segment(head, a, b)) < 10.0:
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
