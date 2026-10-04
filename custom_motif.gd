class_name CustomMotif
extends RefCounted

const PALETTES := {
	"Grün": ["#20f58a", "#85ef44", "#16dfad"],
	"Erde": ["#b97836", "#dc914b", "#eeac61"],
	"Wasser": ["#51ddff", "#4abaff", "#68f0f8"],
	"Pink": ["#ff548e", "#ff72bb", "#f537a8"],
	"Gold": ["#ffe977", "#ffcf54", "#fff5b2"],
	"Violett": ["#a875ff", "#c06bff", "#867dff"]}

static func from_shape(shape: int) -> Dictionary:
	var result := {"cells": {}, "palettes": {}, "names": {}, "title": "Eigenes Motiv"}
	for cell in ArrowPuzzle.mask(shape):
		var part := MotifBuilder.region(shape, cell)
		result.cells[cell] = part
		if not result.palettes.has(part):
			result.palettes[part] = [MotifBuilder.color_for(shape, part, 0).to_html(), MotifBuilder.color_for(shape, part, 1).to_html(), MotifBuilder.color_for(shape, part, 2).to_html()]
			result.names[part] = "Fläche %d" % (part + 1)
	return result

static func encode(motif: Dictionary) -> Dictionary:
	var cells: Array = []
	for cell in motif.get("cells", {}):
		cells.append([cell.x, cell.y, motif.cells[cell]])
	var parts: Array = []
	for part in motif.get("palettes", {}):
		parts.append({"id": part, "name": motif.get("names", {}).get(part, "Fläche"), "colors": motif.palettes[part]})
	return {"cells": cells, "parts": parts, "title": motif.get("title", "Eigenes Motiv"), "reference_png": motif.get("reference_png", ""), "fit": motif.get("fit", [])}

static func decode(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.get("cells") is Array or not value.get("parts") is Array:
		return {}
	if value.cells.size() > ArrowPuzzle.COLS * ArrowPuzzle.ROWS or value.parts.size() > 256:
		return {}
	var result := {"cells": {}, "palettes": {}, "names": {}, "title": str(value.get("title", "Eigenes Motiv")).left(80)}
	for part in value.parts:
		if not part is Dictionary or not part.get("id") is float and not part.get("id") is int or not part.get("colors") is Array:
			return {}
		var id := int(part.id)
		if float(part.id) != id or id < 0 or id > 255 or result.palettes.has(id) or part.colors.is_empty() or part.colors.size() > 8:
			return {}
		for color in part.colors:
			if not color is String or not Color.html_is_valid(color):
				return {}
		result.palettes[id] = part.colors.duplicate()
		result.names[id] = str(part.get("name", "Fläche")).left(60)
	for item in value.cells:
		if not item is Array or item.size() != 3:
			return {}
		for number in item:
			if not number is float and not number is int:
				return {}
			if not is_finite(float(number)) or float(number) != int(number):
				return {}
		var cell := Vector2i(int(item[0]), int(item[1]))
		var part := int(item[2])
		if cell.x < 0 or cell.x >= ArrowPuzzle.COLS or cell.y < 0 or cell.y >= ArrowPuzzle.ROWS or result.cells.has(cell) or not result.palettes.has(part):
			return {}
		result.cells[cell] = part
	var reference = value.get("reference_png", "")
	var fit = value.get("fit", [])
	if reference is String and reference.length() <= 4000000 and fit is Array and fit.size() == 4:
		var valid := true
		for number in fit:
			valid = valid and (number is float or number is int) and is_finite(float(number)) and absf(float(number)) <= 64
		if valid and float(fit[2]) > 0 and float(fit[3]) > 0:
			result.reference_png = reference
			result.fit = fit.duplicate()
	return result

static func encode_paths(paths: Array[Dictionary]) -> Array:
	var result: Array = []
	for arrow in paths:
		var points: Array = []
		for point in arrow.points:
			points.append([point.x, point.y])
		result.append({"points": points, "color": arrow.color.to_html()})
	return result

static func decode_paths(value: Variant, motif: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not value is Array or value.size() > 500:
		return result
	var used := {}
	for arrow in value:
		if not arrow is Dictionary or not arrow.get("points") is Array or arrow.points.size() < 2 or arrow.points.size() > 500 or not arrow.get("color") is String or not Color.html_is_valid(arrow.color):
			return []
		var points := PackedVector2Array()
		var part := -1
		for xy in arrow.points:
			if not xy is Array or xy.size() != 2:
				return []
			for number in xy:
				if not number is float and not number is int or not is_finite(float(number)):
					return []
			var point := Vector2(xy[0], xy[1])
			var cell := ArrowPuzzle.grid(point)
			if point != ArrowPuzzle.pixel(cell) or not motif.cells.has(cell) or used.has(cell):
				return []
			if part < 0:
				part = motif.cells[cell]
			if motif.cells[cell] != part or (not points.is_empty() and point.distance_to(points[-1]) != ArrowPuzzle.CELL):
				return []
			points.append(point)
			used[cell] = true
		result.append(ArrowPuzzle.make_arrow(points, Color(arrow.color)))
	if used.size() != motif.cells.size() or ArrowPuzzle.solution(result).size() != result.size():
		return []
	return result

static func components(cells: Dictionary, part: int) -> Array[Array]:
	var remaining := {}
	for cell in cells:
		if cells[cell] == part:
			remaining[cell] = true
	var result: Array[Array] = []
	while not remaining.is_empty():
		var queue: Array = [remaining.keys()[0]]
		remaining.erase(queue[0])
		var cursor := 0
		while cursor < queue.size():
			var cell: Vector2i = queue[cursor]
			cursor += 1
			for direction in ArrowPuzzle.DIRECTIONS:
				var neighbor: Vector2i = cell + direction
				if remaining.has(neighbor):
					remaining.erase(neighbor)
					queue.append(neighbor)
		result.append(queue)
	return result

static func isolated(motif: Dictionary) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for part in motif.palettes:
		for group in components(motif.cells, part):
			if group.size() == 1:
				result.append(group[0])
	return result

static func next_part(motif: Dictionary) -> int:
	for id in range(256):
		if not motif.palettes.has(id):
			return id
	return -1

static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var count := maxi(absi(a.x - b.x), absi(a.y - b.y))
	for step in range(count + 1):
		var cell := Vector2i(Vector2(a).lerp(Vector2(b), float(step) / maxf(count, 1)).round())
		if not result.has(cell):
			result.append(cell)
	return result

static func split(motif: Dictionary, part: int, barrier: Array[Vector2i]) -> bool:
	var scratch: Dictionary = motif.cells.duplicate()
	for cell in barrier:
		if scratch.get(cell, -1) == part:
			scratch.erase(cell)
	var groups := components(scratch, part)
	if groups.size() <= components(motif.cells, part).size() or groups.size() + motif.palettes.size() > 256:
		return false
	groups.sort_custom(func(a: Array, b: Array): return a.size() > b.size())
	var copy := motif.duplicate(true)
	for index in range(groups.size()):
		var id := part if index == 0 else next_part(copy)
		if index > 0:
			copy.palettes[id] = copy.palettes[part].duplicate()
			copy.names[id] = "%s · Teil %d" % [copy.names.get(part, "Fläche"), index + 1]
		for cell in groups[index]:
			copy.cells[cell] = id
	# Assign separator cells to their closest side; never create an empty stripe.
	for cell in barrier:
		if motif.cells.get(cell, -1) != part:
			continue
		var nearest := 100000
		var owner := part
		for group in groups:
			for neighbor: Vector2i in group:
				var distance := (cell - neighbor).length_squared()
				if distance < nearest:
					nearest = distance
					owner = copy.cells[neighbor]
		copy.cells[cell] = owner
	motif.merge(copy, true)
	return true
