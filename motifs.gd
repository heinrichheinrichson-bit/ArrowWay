class_name MotifBuilder
extends RefCounted

static func region(shape: int, cell: Vector2i) -> int:
	var x := cell.x * 18.0 / 28.0
	var y := cell.y * 22.0 / 32.0
	if shape == 3:
		return 1 if absf(x - 9) <= 0.9 else 0
	if shape == 4:
		return 1 if x >= 13 else 0
	if shape == 5:
		if y > 13:
			return 1
		return 2 if Vector2(x, y).distance_squared_to(Vector2(9, 8)) <= 6.5 else 0
	if shape == 1:
		return 1 if y > 18 and x >= 8 and x <= 10 else 0
	if shape == 0:
		if y < 7 and x >= 13 and x <= 15:
			return 2
		if y < 9:
			return 1
		if y >= 12 and y <= 15 and ((x >= 4.5 and x <= 7) or (x >= 11 and x <= 13.5)):
			return 4
		if y >= 17 and x >= 8 and x <= 10:
			return 5
		return 3
	return 0

static func color_for(shape: int, part: int, index: int) -> Color:
	var colors: Array
	match shape:
		3:
			colors = ["#ffe18a", "#ffc260"] if part == 1 else ["#a875ff", "#c06bff", "#ff72ca", "#867dff"]
		4:
			colors = ["#ffae55", "#ffd26f"] if part == 1 else ["#36dcff", "#51bfff", "#61f0e9", "#69a8ff"]
		5:
			colors = ["#45ef81", "#89f35d"] if part == 1 else (["#ffe064", "#ffc54b"] if part == 2 else ["#ff65ad", "#ff87d0", "#e671ff"])
		1:
			colors = ["#b97836", "#dc914b", "#eeac61"] if part == 1 else ["#20f58a", "#4cff6f", "#85ef44", "#16dfad", "#a4ff69"]
		0:
			match part:
				1: colors = ["#ff456a", "#ff6356", "#ff855f"]
				2: colors = ["#ed985d", "#ffb36d"]
				4: colors = ["#ffe977", "#ffcf54", "#fff5b2"]
				5: colors = ["#c77aff", "#eb87ff"]
				_: colors = ["#51ddff", "#4abaff", "#68f0f8", "#7dd5ff"]
		_:
			colors = ["#ff347b", "#ff548e", "#ff72bb", "#f537a8", "#ff91c9"]
	return Color(colors[index % colors.size()])

static func generate(shape: int, seed_value: int) -> Array[Dictionary]:
	var expected := ArrowPuzzle.mask(shape).size()
	# Reject incomplete packings instead of shipping empty boundary cells.
	for attempt in range(64):
		var candidate := build(shape, seed_value + attempt * 83)
		var covered := {}
		for arrow in candidate:
			for point in arrow.points:
				covered[ArrowPuzzle.grid(point)] = true
		if covered.size() == expected and ArrowPuzzle.solution(candidate).size() == candidate.size():
			return candidate
	push_error("No complete solvable motif packing found")
	return []

static func build(shape: int, seed_value: int) -> Array[Dictionary]:
	var cells := ArrowPuzzle.mask(shape)
	var chains: Array = []
	# Uniform lane spacing, with short bands interlocking into longer serpentine paths.
	var band_width := 7 + int(seed_value % 3)
	for y in range(ArrowPuzzle.ROWS):
		var x := 0
		while x < ArrowPuzzle.COLS:
			var cell := Vector2i(x, y)
			if not cells.has(cell):
				x += 1
				continue
			var part := region(shape, cell)
			var bucket := x / band_width
			var run: Array[Vector2i] = []
			while x < ArrowPuzzle.COLS and cells.has(Vector2i(x, y)) and region(shape, Vector2i(x, y)) == part and x / band_width == bucket:
				run.append(Vector2i(x, y))
				x += 1
			var merged := false
			for chain in chains:
				if chain.part != part or chain.bucket != bucket or chain.rows >= 3 + int((seed_value / 11 + bucket) % 3) or chain.row != y - 1:
					continue
				var p: Array = chain.cells
				if p[-1] + Vector2i.DOWN == run[0]:
					p.append_array(run)
					merged = true
				elif p[-1] + Vector2i.DOWN == run[-1]:
					run.reverse()
					p.append_array(run)
					merged = true
				if merged:
					chain.row = y
					chain.rows += 1
					break
			if not merged:
				chains.append({"cells": run, "part": part, "bucket": bucket, "rows": 1, "row": y})
	# Attach one-cell boundary slivers to neighboring endpoints, preserving complete coverage.
	for chain in chains:
		if chain.cells.size() != 1:
			continue
		var cell: Vector2i = chain.cells[0]
		for other in chains:
			if other == chain or other.cells.size() < 2 or other.part != chain.part:
				continue
			if (cell - other.cells[0]).length_squared() == 1:
				other.cells.push_front(cell)
				chain.cells.clear()
				break
			if (cell - other.cells[-1]).length_squared() == 1:
				other.cells.append(cell)
				chain.cells.clear()
				break
	var result: Array[Dictionary] = []
	for chain in chains:
		if chain.cells.size() < 2:
			continue
		# Alternate some rectangular bands into vertical meanders for a calmer, varied flow.
		if chains.find(chain) % 3 == 1:
			var minimum: Vector2i = chain.cells[0]
			var maximum := minimum
			for cell: Vector2i in chain.cells:
				minimum = Vector2i(mini(minimum.x, cell.x), mini(minimum.y, cell.y))
				maximum = Vector2i(maxi(maximum.x, cell.x), maxi(maximum.y, cell.y))
			if maximum.y - minimum.y >= 2 and (maximum.x - minimum.x + 1) * (maximum.y - minimum.y + 1) == chain.cells.size():
				var vertical: Array[Vector2i] = []
				for column in range(minimum.x, maximum.x + 1):
					for row in range(minimum.y, maximum.y + 1):
						vertical.append(Vector2i(column, row if (column - minimum.x) % 2 == 0 else maximum.y - row + minimum.y))
				chain.cells = vertical
		var points := PackedVector2Array()
		for cell in chain.cells:
			points.append(ArrowPuzzle.pixel(cell))
		# Aim outwards. Subsequent orientation pass resolves any boundary dependencies.
		var center := float(chain.cells[0].x + chain.cells[-1].x) * 0.5
		var direction := points[-1] - points[-2]
		if (center < 14 and direction.x > 0) or (center >= 14 and direction.x < 0):
			points.reverse()
		result.append(ArrowPuzzle.make_arrow(points, color_for(shape, chain.part, result.size())))
	# Choose a free endpoint at every step; this gives a constructive solution certificate.
	var remaining: Array[int] = []
	for i in range(result.size()):
		remaining.append(i)
	while not remaining.is_empty():
		var found := -1
		for i in remaining:
			var original: PackedVector2Array = result[i].points
			for flip in range(2):
				var candidate := original.duplicate()
				if flip == 1:
					candidate.reverse()
				if ArrowPuzzle.self_blocked(candidate):
					continue
				var blocked := false
				for j in remaining:
					if i != j and ArrowPuzzle.ray_hits(candidate, result[j].points):
						blocked = true
						break
				if not blocked:
					result[i].points = candidate
					found = i
					break
			if found >= 0:
				break
		if found < 0:
			# Split a stranded winding path without dropping or duplicating any cells.
			var index := -1
			for i in remaining:
				if result[i].points.size() >= 4:
					index = i
					break
			if index < 0:
				break
			var stuck: PackedVector2Array = result[index].points
			var split := stuck.size() / 2
			result[index].points = stuck.slice(0, split)
			remaining.append(result.size())
			result.append(ArrowPuzzle.make_arrow(stuck.slice(split), result[index].color))
			continue
		remaining.erase(found)
	return close_gaps(result, cells, shape)

static func close_gaps(data: Array[Dictionary], cells: Dictionary, shape: int) -> Array[Dictionary]:
	var used := {}
	for a in data:
		for point in a.points:
			used[ArrowPuzzle.grid(point)] = true
	for cell: Vector2i in cells:
		if used.has(cell):
			continue
		var point := ArrowPuzzle.pixel(cell)
		var accepted := false
		for i in range(data.size()):
			var p: PackedVector2Array = data[i].points
			if region(shape, ArrowPuzzle.grid(p[0])) != region(shape, cell):
				continue
			for k in range(p.size()):
				if point.distance_to(p[k]) != ArrowPuzzle.CELL:
					continue
				var pieces: Array[PackedVector2Array] = []
				if k == 0:
					var extended := PackedVector2Array([point])
					extended.append_array(p)
					pieces.append(extended)
				elif k == p.size() - 1:
					var extended := p.duplicate()
					extended.append(point)
					pieces.append(extended)
				elif k < p.size() - 2:
					var first := p.slice(0, k + 1)
					first.append(point)
					pieces = [first, p.slice(k + 1)]
				elif k >= 2:
					var second := PackedVector2Array([point])
					second.append_array(p.slice(k))
					pieces = [p.slice(0, k), second]
				else:
					continue
				for flips in range(1 << pieces.size()):
					var candidate: Array[Dictionary] = data.duplicate()
					for j in range(pieces.size()):
						var segment := pieces[j].duplicate()
						if flips & (1 << j):
							segment.reverse()
						var arrow := ArrowPuzzle.make_arrow(segment, data[i].color)
						if j == 0:
							candidate[i] = arrow
						else:
							candidate.append(arrow)
					if ArrowPuzzle.solution(candidate).size() == candidate.size():
						data = candidate
						used[cell] = true
						accepted = true
						break
				if accepted:
					break
			if accepted:
				break
	return data
