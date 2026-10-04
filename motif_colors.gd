class_name MotifColors
extends RefCounted

const MODES := ["Einfarbig", "Sanfte Schattierungen", "Oben hell · unten warm", "Links hell · rechts dunkel", "Leuchtende Mitte"]
const SUGGESTIONS := ["Natürlich", "Wärmer", "Pastell", "Kräftiger"]

static func shades(base: Color, strength: float = 0.55, variant: int = 0) -> Array:
	var hue := base.h
	var saturation := base.s
	var value := base.v
	if variant == 1:
		hue = lerpf(hue, 0.08 if hue < 0.5 else 0.92, 0.12)
	elif variant == 2:
		saturation *= 0.68
		value = maxf(value, 0.96)
	elif variant == 3:
		saturation = minf(1, saturation * 1.20)
		value = maxf(value, 0.94)
	var warm := 0.025 * strength if hue < 0.2 else 0.012 * strength
	var light := Color.from_hsv(fposmod(hue + warm, 1), saturation * (1 - strength * 0.45), minf(1, value + strength * 0.12))
	var center := Color.from_hsv(hue, saturation, value)
	var shadow := Color.from_hsv(fposmod(hue - warm, 1), minf(1, saturation + strength * 0.15), maxf(value * (1 - strength * 0.26), minf(value, 0.55)))
	return [light.to_html(false), center.to_html(false), shadow.to_html(false)]

static func bounds_for(motif: Dictionary, part: int) -> Array:
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for cell in motif.cells:
		if motif.cells[cell] == part:
			var pos := ArrowPuzzle.pixel(cell)
			minimum = minimum.min(pos)
			maximum = maximum.max(pos)
	if not minimum.is_finite():
		return [0.0, 0.0, 1.0, 1.0]
	return [minimum.x, minimum.y, maxf(maximum.x - minimum.x, 1), maxf(maximum.y - minimum.y, 1)]

static func bounds_of_path(points: PackedVector2Array) -> Array:
	var minimum := points[0]
	var maximum := minimum
	for point in points:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return [minimum.x, minimum.y, maxf(maximum.x - minimum.x, 1), maxf(maximum.y - minimum.y, 1)]

static func valid_style(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.get("mode") is float and not value.get("mode") is int:
		return {}
	if not is_finite(float(value.mode)):
		return {}
	var mode := int(value.mode)
	if float(value.mode) != mode or mode < 1 or mode > 5 or not value.get("colors") is Array or value.colors.size() != 3 or not value.get("bounds") is Array or value.bounds.size() != 4:
		return {}
	for color in value.colors:
		if not color is String or not Color.html_is_valid(color):
			return {}
	for number in value.bounds:
		if not number is float and not number is int or not is_finite(float(number)) or absf(float(number)) > 10000:
			return {}
	if float(value.bounds[2]) <= 0 or float(value.bounds[3]) <= 0:
		return {}
	var strength = value.get("strength", 0.55)
	if not strength is float and not strength is int or not is_finite(float(strength)) or float(strength) < 0 or float(strength) > 1:
		return {}
	return {"mode": mode, "colors": value.colors.duplicate(), "bounds": value.bounds.duplicate(), "strength": float(strength)}

static func color_at(style: Dictionary, point: Vector2) -> Color:
	var colors: Array = style.colors
	if int(style.mode) == 1:
		return Color(colors[1])
	var bounds: Array = style.bounds
	var uv := Vector2(clampf((point.x - float(bounds[0])) / float(bounds[2]), 0, 1), clampf((point.y - float(bounds[1])) / float(bounds[3]), 0, 1))
	var t := 0.5
	match int(style.mode):
		2: t = 0.5 + sin(uv.x * 5.2 + uv.y * 3.7) * 0.24 + cos(uv.y * 6.0 - uv.x * 2.0) * 0.17
		3: t = uv.y
		4: t = uv.x
		5: t = clampf((uv - Vector2.ONE * 0.5).length() * 2, 0, 1)
	t = smoothstep(0, 1, clampf(t, 0, 1))
	return Color(colors[0]).lerp(Color(colors[1]), t * 2) if t < 0.5 else Color(colors[1]).lerp(Color(colors[2]), (t - 0.5) * 2)

static func apply(motif: Dictionary, paths: Array[Dictionary], part: int = -1, keep_manual: bool = true) -> void:
	var styles: Dictionary = motif.get("styles", {})
	for id in styles:
		styles[id].bounds = bounds_for(motif, id)
	for index in range(paths.size()):
		var arrow: Dictionary = paths[index]
		var region := int(motif.cells.get(ArrowPuzzle.grid(arrow.points[0]), -1))
		if part >= 0 and region != part:
			continue
		if keep_manual and arrow.get("manual_color", false):
			continue
		arrow.erase("manual_color")
		arrow.erase("color_style")
		if styles.has(region):
			arrow.color_style = styles[region].duplicate(true)
			arrow.color = color_at(arrow.color_style, arrow.points[arrow.points.size() / 2])
		else:
			arrow.color = MotifBuilder.color_for(6, region, index, motif)

static func copy_appearance(source: Dictionary, target: Dictionary) -> void:
	for key in ["color_style", "manual_color"]:
		if source.has(key):
			target[key] = source[key].duplicate(true) if source[key] is Dictionary else source[key]

static func color_lookup(points: PackedVector2Array, style: Dictionary) -> Image:
	var lengths: Array[float] = [0.0]
	for index in range(1, points.size()):
		lengths.append(lengths[-1] + points[index - 1].distance_to(points[index]))
	var image := Image.create(128, 1, false, Image.FORMAT_RGBA8)
	var segment := 0
	for sample in range(128):
		var distance := lengths[-1] * sample / 127.0
		while segment < points.size() - 2 and lengths[segment + 1] < distance:
			segment += 1
		var t := (distance - lengths[segment]) / maxf(lengths[segment + 1] - lengths[segment], 0.001)
		image.set_pixel(sample, 0, color_at(style, points[segment].lerp(points[segment + 1], t)))
	return image
