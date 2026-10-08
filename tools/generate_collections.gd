extends SceneTree
var failed := 0
func _initialize() -> void: call_deferred("generate")
func generate() -> void:
	var args := OS.get_cmdline_user_args()
	var source_path := "res://collections/source_masks.json"
	var output_path := "res://collections/catalog.json"
	if args.has("--source"): source_path=args[args.find("--source")+1]
	if args.has("--output"): output_path=args[args.find("--output")+1]
	var source = JSON.parse_string(FileAccess.get_file_as_string(source_path))
	# Curated replacements override repetitive recipes, keeping stable public paths.
	if FileAccess.file_exists("res://collections/variety_recipes.json"):
		var curated:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/variety_recipes.json"))
		var tax:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/taxonomy.json"))
		for recipe in curated.entries:
			var found:=false
			for item in source:
				var original_path:String=item.get("path","res://collections/levels/%s_%02d_%s.json" % [item.collection.id,item.collection.order,item.key])
				if original_path != recipe.path: continue
				item.motif=recipe.motif.duplicate(true); item.erase("attribution"); item["path"]=recipe.path
				found=true; break
			if found: continue
			for assignment in tax.assignments:
				if assignment.path != recipe.path: continue
				var document:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(recipe.path))
				source.append({"key":recipe.path.get_file().get_basename(),"path":recipe.path,"collection":document.collection,"tags":document.tags,"motif":recipe.motif.duplicate(true)})
				break
	if args.has("--limit"): source=source.slice(0,int(args[args.find("--limit")+1]))
	var entries: Array = []
	var previous_order := {}
	var existing = JSON.parse_string(FileAccess.get_file_as_string(output_path)) if FileAccess.file_exists(output_path) else null
	if existing is Dictionary:
		for entry in existing.get("levels",[]): previous_order[entry.path]=previous_order.size()
	var protected: Dictionary = {}
	if FileAccess.file_exists("res://collections/editor_overrides.json"):
		protected = JSON.parse_string(FileAccess.get_file_as_string("res://collections/editor_overrides.json")).entries
	var group_order: Array[String] = []
	for index in range(source.size()):
		var item: Dictionary = source[index]
		if not group_order.has(item.collection.id): group_order.append(item.collection.id)
		var filename: String = "%s_%02d_%s.json" % [item.collection.id, item.collection.order, item.key]
		var path:String = item.get("path", "res://collections/levels/" + filename)
		var source_hash := JSON.stringify(item).sha256_text()
		var protection: Dictionary = protected.get(path.trim_prefix("res://"), {})
		if protection.get("deleted", false): continue
		var manually_edited := not protection.is_empty()
		if manually_edited and not FileAccess.file_exists(path):
			push_error("Protected catalog motif missing: " + path); quit(1); return
		if FileAccess.file_exists(path) and (manually_edited or not OS.get_cmdline_user_args().has("--rebuild")):
			var cached = JSON.parse_string(FileAccess.get_file_as_string(path))
			if cached is Dictionary and (manually_edited or cached.get("source_hash", "") == source_hash or index < 28):
				var cached_motif := CustomMotif.decode(cached.motif)
				if not CustomMotif.decode_paths(cached.paths,cached_motif).is_empty():
					entries.append({"path":path,"title":cached.title,"collection":cached.collection,"tags":cached.get("tags",[]),"design":cached.design})
					if cached.has("attribution"): entries[-1].attribution=cached.attribution
					print("CACHED %d/%d %s" % [index+1,source.size(),item.key])
					continue
		if manually_edited:
			push_error("Protected catalog motif invalid: " + path); quit(1); return
		var motif := CustomMotif.decode(item.motif)
		var source_cells: int = motif.get("cells",{}).size()
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
		if motif.cells.size() < source_cells * 0.90:
			push_error("Excessive contour loss: " + item.key); failed += 1; continue
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
		var tags := LibraryIndex.tags(item.get("tags", []))
		var document := {"version":2,"shape":6,"title":motif.title,"collection":item.collection,"tags":tags,"source_hash":source_hash,"source_cells":source_cells,"motif":CustomMotif.encode(motif),"paths":CustomMotif.encode_paths(paths),"design":design}
		if item.has("attribution"): document.attribution=item.attribution
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(document, "\t"))
		entries.append({"path":path,"title":motif.title,"collection":item.collection,"tags":tags,"design":design})
		if item.has("attribution"): entries[-1].attribution=item.attribution
		print("BUILT %02d/%02d %s: %d cells, %d arrows, %d starts, depth %d" % [index+1,source.size(),item.key,motif.cells.size(),paths.size(),design.starts,design.depth])
	# Author-created motifs have no immutable source recipe but remain in the catalog.
	if existing is Dictionary:
		for entry in existing.get("levels", []):
			var protection: Dictionary = protected.get(str(entry.path).trim_prefix("res://"), {})
			if protection.is_empty() or protection.get("deleted", false) or entries.any(func(item): return item.path == entry.path): continue
			if not FileAccess.file_exists(entry.path): push_error("Protected motif missing: " + entry.path); failed += 1; continue
			entries.append(entry)
	entries.sort_custom(func(a: Dictionary, b: Dictionary):
		if previous_order.has(a.path) or previous_order.has(b.path):
			return int(previous_order.get(a.path,previous_order.size()))<int(previous_order.get(b.path,previous_order.size()))
		var left := group_order.find(a.collection.id)
		var right := group_order.find(b.collection.id)
		return left < right if left != right else int(a.collection.order) < int(b.collection.order))
	if failed == 0:
		# Taxonomy is independent of the immutable source recipe and puzzle files.
		var taxonomy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/taxonomy.json"))
		var journey: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/journey.json"))
		var assignments := {}
		for item in taxonomy.assignments: assignments[item.path]=item
		for entry in entries:
			if not assignments.has(entry.path): continue
			var item: Dictionary = assignments[entry.path]
			entry.legacy_collection=entry.collection.duplicate()
			entry.collection={"id":item.group,"title":journey.groups[item.group].title,"order":entry.legacy_collection.order}
			entry.taxonomy={"world":item.world,"category":item.category_id}
		var catalog := FileAccess.open(output_path, FileAccess.WRITE)
		catalog.store_string(JSON.stringify({"version":1,"levels":entries}, "\t"))
	print("DONE %d levels; %d failures" % [entries.size(),failed])
	quit(0 if failed == 0 else 1)
