class_name MotifImport
extends RefCounted

static func color_distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()

static func neon_palette(color: Color) -> Array:
	if color.v < 0.18 or color.s < 0.12:
		return CustomMotif.PALETTES["Wasser"].duplicate()
	if color.h < 0.13 and color.h > 0.04 and color.v < 0.65:
		return CustomMotif.PALETTES["Erde"].duplicate()
	var result: Array = []
	for offset in [-0.025, 0.0, 0.025]:
		result.append(Color.from_hsv(fposmod(color.h + offset, 1), maxf(color.s, 0.6), maxf(color.v, 0.92)).to_html())
	return result

static func analyze(source: Image, mode: int = 0, threshold: float = 0.5) -> Dictionary:
	if source == null or source.is_empty():
		return {}
	var image := source.duplicate() as Image
	var scale := minf(1.0, 384.0 / maxf(image.get_width(), image.get_height()))
	if scale < 1:
		image.resize(maxi(1, int(image.get_width() * scale)), maxi(1, int(image.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGBA8)
	var w := image.get_width()
	var h := image.get_height()
	var count := w * h
	var pixels: Array[Color] = []
	var transparent := false
	var colorful := 0
	for y in range(h):
		for x in range(w):
			var color := image.get_pixel(x, y)
			pixels.append(color)
			transparent = transparent or color.a < 0.1
			if color.a > 0.2 and color.s > 0.25:
				colorful += 1
	var outlines := mode == 1 or (mode == 0 and not transparent and colorful < count * 0.015)
	var labels := PackedInt32Array()
	labels.resize(count)
	labels.fill(-1)
	var ink := PackedByteArray()
	ink.resize(count)
	var colors: Array[Color] = []
	if outlines:
		for i in range(count):
			ink[i] = 1 if pixels[i].a > 0.15 and pixels[i].get_luminance() < threshold else 0
		var visited := PackedByteArray()
		visited.resize(count)
		for start in range(count):
			if visited[start] or ink[start]:
				continue
			var queue: Array[int] = [start]
			visited[start] = 1
			var edge := false
			var cursor := 0
			while cursor < queue.size():
				var index := queue[cursor]
				cursor += 1
				var x := index % w
				var y := index / w
				edge = edge or x == 0 or y == 0 or x == w - 1 or y == h - 1
				for neighbor in [index - w, index + w, index - 1 if x > 0 else -1, index + 1 if x < w - 1 else -1]:
					if neighbor >= 0 and neighbor < count and not visited[neighbor] and not ink[neighbor]:
						visited[neighbor] = 1
						queue.append(neighbor)
			if not edge and queue.size() >= 5 and colors.size() < 64:
				var part := colors.size()
				colors.append(Color(CustomMotif.PALETTES.values()[part % CustomMotif.PALETTES.size()][0]))
				for index in queue:
					labels[index] = part
	else:
		var corners := [pixels[0], pixels[w - 1], pixels[(h - 1) * w], pixels[-1]]
		var background: Color = corners[0]
		var best := -1
		for color: Color in corners:
			var votes := 0
			for other: Color in corners:
				votes += 1 if color_distance(color, other) < 0.12 else 0
			if votes > best:
				background = color
				best = votes
		for i in range(count):
			var color := pixels[i]
			if color.a < 0.15 or (not transparent and color_distance(color, background) < 0.16):
				continue
			if colorful > count * 0.015 and color.v < 0.20:
				ink[i] = 1
				continue
			var nearest := -1
			var distance := 100.0
			for part in range(colors.size()):
				var d := color_distance(color, colors[part])
				if d < distance:
					nearest = part
					distance = d
			if distance > 0.24 and colors.size() < 64:
				nearest = colors.size()
				colors.append(color)
			labels[i] = nearest
	# Absorb dark contour strokes into nearby interiors, without filling the background.
	for iteration in range(4):
		var next := labels.duplicate()
		for i in range(count):
			if not ink[i] or labels[i] >= 0:
				continue
			var x := i % w
			for neighbor in [i - w, i + w, i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1]:
				if neighbor >= 0 and neighbor < count and labels[neighbor] >= 0:
					next[i] = labels[neighbor]
					break
		labels = next
	var minimum := Vector2i(w, h)
	var maximum := Vector2i(-1, -1)
	for i in range(count):
		if labels[i] >= 0:
			minimum = Vector2i(mini(minimum.x, i % w), mini(minimum.y, i / w))
			maximum = Vector2i(maxi(maximum.x, i % w), maxi(maximum.y, i / w))
	if maximum.x < 0:
		return {}
	var bounds := Rect2i(minimum, maximum - minimum + Vector2i.ONE)
	var factor := minf(27.0 / bounds.size.x, 31.0 / bounds.size.y)
	var extent := Vector2(bounds.size) * factor
	var offset := (Vector2(28, 32) - extent) * 0.5
	var result := {"cells": {}, "palettes": {}, "names": {}, "title": "Importiertes Motiv", "fit": [offset.x, offset.y, extent.x, extent.y]}
	for y in range(ArrowPuzzle.ROWS):
		for x in range(ArrowPuzzle.COLS):
			var pos := (Vector2(x, y) - offset) / factor + Vector2(minimum)
			var px := int(floor(pos.x))
			var py := int(floor(pos.y))
			if not bounds.has_point(Vector2i(px, py)):
				continue
			var part := labels[py * w + px]
			if part < 0:
				continue
			result.cells[Vector2i(x, y)] = part
			if not result.palettes.has(part):
				result.palettes[part] = neon_palette(colors[part])
				result.names[part] = "Fläche %d" % (part + 1)
	result.reference_png = Marshalls.raw_to_base64(image.get_region(bounds).save_png_to_buffer())
	result["detection"] = "Umrisse" if outlines else "Farben / Transparenz"
	return result
