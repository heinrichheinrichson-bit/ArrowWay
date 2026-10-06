extends SceneTree

func _initialize() -> void: call_deferred("run")
func run() -> void:
	var recipes: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/expansion_recipes.json"))
	var sources: Array=[]
	var counts := {}
	var previous_orders := {}
	if FileAccess.file_exists("res://collections/expansion_masks.json"):
		var previous: Array=JSON.parse_string(FileAccess.get_file_as_string("res://collections/expansion_masks.json"))
		for entry in previous:
			previous_orders[entry.key]=int(entry.collection.order)
			counts[entry.collection.id]=maxi(int(counts.get(entry.collection.id,0)),int(entry.collection.order))
	var categories := {}
	var taxonomy: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/taxonomy.json"))
	for world in taxonomy.worlds:
		for category in world.categories: categories[category.id]=category.title
	for item in recipes.entries:
		var image:=Image.new()
		if image.load_svg_from_string(FileAccess.get_file_as_string(item.svg))!=OK: push_error("Invalid vector: "+item.key); quit(1); return
		image.resize(26,30,Image.INTERPOLATE_LANCZOS)
		var cells := {}
		for y in 30:
			for x in 26:
				var pixel:=image.get_pixel(x,y)
				if pixel.a>0.5 and pixel.r>0.42: cells[Vector2i(x+1,y+1)]=0
		# Remove unplayable isolated single cells, without changing the main silhouette.
		for cleanup in 8:
			var lonely: Array=[]
			for cell: Vector2i in cells:
				var adjacent:=false
				for d in ArrowPuzzle.DIRECTIONS:
					if cells.has(cell+d): adjacent=true; break
				if not adjacent: lonely.append(cell)
			if lonely.is_empty(): break
			for cell in lonely: cells.erase(cell)
		var encoded: Array=[]
		for cell: Vector2i in cells: encoded.append([cell.x,cell.y,0])
		encoded.sort_custom(func(a,b): return a[1]<b[1] if a[1]!=b[1] else a[0]<b[0])
		if encoded.size()<65: push_error("Too sparse: "+item.key); quit(1); return
		var motif := {"title":item.title,"cells":encoded,"parts":[{"id":0,"name":item.title,"colors":[item.colors[0],item.colors[0],item.colors[0]]}]}
		var group: String="expanded_"+item.category
		if not previous_orders.has(item.key): counts[group]=int(counts.get(group,0))+1
		var order: int=int(previous_orders.get(item.key,counts[group]))
		sources.append({"key":item.key,"collection":{"id":group,"title":categories[item.category],"order":order},"tags":[categories[item.category],item.world],"recipe":"vector:"+item.key,"motif":motif,"attribution":item.attribution})
	var file:=FileAccess.open("res://collections/expansion_masks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(sources,"\t")); file.close()
	print("RASTERIZED ",sources.size()," curated silhouettes")
	quit()
