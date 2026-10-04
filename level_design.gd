class_name LevelDesign
extends RefCounted

static func metrics(data: Array[Dictionary]) -> Dictionary:
	var blockers: Array[Array] = []
	var free := 0
	var edges := 0
	var longest := 0
	for i in range(data.size()):
		var dependencies: Array[int] = []
		longest = maxi(longest, data[i].points.size())
		for j in range(data.size()):
			if i != j and ArrowPuzzle.ray_hits(data[i].points, data[j].points):
				dependencies.append(j)
		blockers.append(dependencies)
		edges += dependencies.size()
		if dependencies.is_empty():
			free += 1
	var order := ArrowPuzzle.solution(data)
	var depths := {}
	var depth := 0
	for i in order:
		var value := 1
		for blocker in blockers[i]:
			value = maxi(value, int(depths.get(blocker, 0)) + 1)
		depths[i] = value
		depth = maxi(depth, value)
	return {"solvable": order.size() == data.size(), "paths": data.size(), "starts": free, "edges": edges, "depth": depth, "longest": longest}

static func score(data: Array[Dictionary], target: int) -> float:
	var m := metrics(data)
	if not m.solvable:
		return -100000.0
	# Start choices dominate; length and dependency depth break ties.
	return -absf(m.starts - target) * 80.0 + minf(m.depth, 16) * 4.0 + minf(m.edges, 130) * 0.1 + minf(m.longest, 65) * 0.25

static func refine(shape: int, seed_value: int, target: int, attempts: int = 350) -> Array[Dictionary]:
	var data := ArrowPuzzle.generate(shape, seed_value)
	if data.is_empty():
		return data
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 947
	var best := score(data, target)
	var current := best
	var best_data: Array[Dictionary] = data.duplicate()
	for iteration in range(attempts):
		var candidate: Array[Dictionary] = data.duplicate()
		var i := rng.randi_range(0, data.size() - 1)
		var p: PackedVector2Array = data[i].points
		if iteration % 4 == 0:
			var reversed := p.duplicate()
			reversed.reverse()
			candidate[i] = ArrowPuzzle.make_arrow(reversed, data[i].color)
		else:
			var owners := {}
			for index in range(data.size()):
				for point in data[index].points:
					owners[point] = index
			var neighbors: Array[int] = []
			for point in p:
				for offset in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
					var owner := int(owners.get(point + offset * ArrowPuzzle.CELL, i))
					if owner != i and not neighbors.has(owner) and MotifBuilder.region(shape, ArrowPuzzle.grid(p[0])) == MotifBuilder.region(shape, ArrowPuzzle.grid(data[owner].points[0])):
						neighbors.append(owner)
			if neighbors.is_empty():
				continue
			var j := neighbors[rng.randi_range(0, neighbors.size() - 1)]
			var q: PackedVector2Array = data[j].points.duplicate()
			if rng.randf() < 0.5:
				q.reverse()
			if iteration % 4 == 1:
				if data.size() <= 22 or p.size() + q.size() > 70:
					continue
				var joined := PackedVector2Array()
				for flip_p in range(2):
					for flip_q in range(2):
						var first := p.duplicate()
						var second := q.duplicate()
						if flip_p == 1:
							first.reverse()
						if flip_q == 1:
							second.reverse()
						if first[-1].distance_to(second[0]) == ArrowPuzzle.CELL:
							joined = first
							joined.append_array(second)
				if joined.is_empty():
					continue
				candidate[i] = ArrowPuzzle.make_arrow(joined, data[i].color)
				candidate.remove_at(j)
				var merged_score := score(candidate, target)
				if merged_score > current + 0.001:
					data = candidate
					current = merged_score
					if merged_score > best:
						best = merged_score
						best_data = data.duplicate()
				continue
			# Reconnect adjacent parallel edges. Both new paths retain every original cell.
			var cuts: Array[Vector2i] = []
			for a in range(p.size() - 1):
				for b in range(q.size() - 1):
					if p[a].distance_to(q[b]) == ArrowPuzzle.CELL and p[a + 1].distance_to(q[b + 1]) == ArrowPuzzle.CELL:
						cuts.append(Vector2i(a, b))
			if cuts.is_empty():
				continue
			var cut := cuts[rng.randi_range(0, cuts.size() - 1)]
			var first := p.slice(0, cut.x + 1)
			var q_prefix := q.slice(0, cut.y + 1)
			q_prefix.reverse()
			first.append_array(q_prefix)
			var second := p.slice(cut.x + 1)
			second.reverse()
			second.append_array(q.slice(cut.y + 1))
			if first.size() > 70 or second.size() > 70:
				continue
			if rng.randf() < 0.5:
				first.reverse()
			if rng.randf() < 0.5:
				second.reverse()
			candidate[i] = ArrowPuzzle.make_arrow(first, data[i].color)
			candidate[j] = ArrowPuzzle.make_arrow(second, data[j].color)
		if ArrowPuzzle.self_blocked(candidate[i].points):
			continue
		var value := score(candidate, target)
		# Explore alternative connections, then keep the best completely solvable layout.
		var temperature := 70.0 * (1.0 - float(iteration) / attempts) + 2.0
		if value > current + 0.001 or (value > -100000 and rng.randf() < exp((value - current) / temperature)):
			data = candidate
			current = value
			if value > best:
				best = value
				best_data = data.duplicate()
	return best_data
