extends SceneTree
var failed := 0
func _initialize() -> void: call_deferred("generate")
func generate() -> void:
	var source = JSON.parse_string(FileAccess.get_file_as_string("res://collections/source_masks.json"))
	var entries: Array = []
	for index in range(source.size()):
		var item: Dictionary = source[index]
		var motif := CustomMotif.decode(item.motif)
		if motif.is_empty() or not CustomMotif.isolated(motif).is_empty():
			push_error("Invalid mask: " + item.key); failed += 1; continue
		# Rasterized curves sometimes leave a one-cell tip that cannot form an arrow.
		# Reassign internal color-border tips; trim only exposed outer tips, never holes.
		var adjusted := 0
		for cleanup in range(8):
			var probe := MotifBuilder.build(6, 92317 + index * 173, motif)
			var used := {}
			for arrow in probe:
				for point in arrow.points: used[ArrowPuzzle.grid(point)] = true
			if used.size() == motif.cells.size(): break
			var changed := false
			for cell: Vector2i in motif.cells.keys():
				if used.has(cell): continue
				var adjacent: Array[int] = []
				var exposed := false
				for direction in ArrowPuzzle.DIRECTIONS:
					var next: Vector2i = cell + direction
					if not motif.cells.has(next): exposed = true
					elif motif.cells[next] != motif.cells[cell]: adjacent.append(motif.cells[next])
				if not adjacent.is_empty():
					motif.cells[cell] = adjacent[0]; changed = true; adjusted += 1
				elif exposed:
					motif.cells.erase(cell); changed = true; adjusted += 1
			if not changed: break
		if adjusted > 0: print("Smoothed ",item.key,": ",adjusted," border points")
		motif["styles"] = {}
		for part in motif.palettes:
			var color := Color(motif.palettes[part][0])
			var colors := MotifColors.shades(color, 0.42)
			motif.palettes[part] = colors
			motif.styles[part] = {"mode":5 if item.key in ["apple","star","saturn","turtle","moon"] else 3,"colors":colors,"strength":0.42,"bounds":MotifColors.bounds_for(motif,part)}
		var paths: Array[Dictionary] = []
		for attempt in range(5):
			paths = LevelDesign.refine(6, 92317 + index * 173 + attempt * 3109, maxi(6, 14 - int(item.collection.order)), 160, motif)
			if not paths.is_empty(): break
		if paths.is_empty():
			push_error("No complete solution: " + item.key); failed += 1; continue
		MotifColors.apply(motif, paths)
		var design := LevelDesign.metrics(paths)
		var filename: String = "%s_%02d_%s.json" % [item.collection.id, item.collection.order, item.key]
		var path := "res://collections/levels/" + filename
		var document := {"version":2,"shape":6,"title":motif.title,"collection":item.collection,"motif":CustomMotif.encode(motif),"paths":CustomMotif.encode_paths(paths),"design":design}
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(document, "\t"))
		entries.append({"path":path,"title":motif.title,"collection":item.collection,"design":design})
		print("BUILT %02d/%02d %s: %d cells, %d arrows, %d starts, depth %d" % [index+1,source.size(),item.key,motif.cells.size(),paths.size(),design.starts,design.depth])
	var group_order := ["world", "garden", "taste", "space", "art"]
	entries.sort_custom(func(a: Dictionary, b: Dictionary):
		var left := group_order.find(a.collection.id)
		var right := group_order.find(b.collection.id)
		return left < right if left != right else int(a.collection.order) < int(b.collection.order))
	var catalog := FileAccess.open("res://collections/catalog.json", FileAccess.WRITE)
	catalog.store_string(JSON.stringify({"version":1,"levels":entries}, "\t"))
	print("DONE %d levels; %d failures" % [entries.size(),failed])
	quit(0 if failed == 0 else 1)
