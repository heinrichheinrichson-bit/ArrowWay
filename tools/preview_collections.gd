extends SceneTree

func _initialize() -> void: call_deferred("render")

func render() -> void:
	var args := OS.get_cmdline_user_args()
	var catalog_path := "res://collections/catalog.json"
	if args.has("--catalog"): catalog_path=args[args.find("--catalog")+1]
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(catalog_path))
	if OS.get_cmdline_user_args().has("--pending"):
		catalog.levels.clear()
		for filename in DirAccess.get_files_at("res://collections/levels"):
			if filename.get_extension() != "json": continue
			var path := "res://collections/levels/" + filename
			var parsed := JSON.new()
			if parsed.parse(FileAccess.get_file_as_string(path)) != OK or not parsed.data is Dictionary: continue
			var document: Dictionary = parsed.data
			catalog.levels.append({"path":path,"title":document.title,"collection":document.collection})
	var rounder := Node2D.new()
	rounder.set_script(load("res://main.gd"))
	var groups := {}
	for entry in catalog.levels:
		if not groups.has(entry.collection.id): groups[entry.collection.id] = []
		groups[entry.collection.id].append(entry)
	for id in groups:
		var requested := OS.get_cmdline_user_args().find("--group")
		if requested >= 0 and OS.get_cmdline_user_args()[requested+1] != id: continue
		var columns := 4 if groups[id].size() > 8 else 3
		var step := 350 if columns == 4 else 420
		var width := 1200 / columns
		var zoom := 0.54 if columns == 4 else 0.68
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1200, maxi(900, ceili(float(groups[id].size()) / float(columns)) * step + 60))
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var heading := Label.new()
		heading.text = "ArrowWay · " + groups[id][0].collection.title
		heading.position = Vector2(24, 16)
		heading.add_theme_font_size_override("font_size", 26)
		viewport.add_child(heading)
		for index in range(groups[id].size()):
			var entry: Dictionary = groups[id][index]
			var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(entry.path))
			var preview := Node2D.new()
			preview.set_script(load("res://motif_preview.gd"))
			preview.rounder = rounder
			preview.motif = CustomMotif.decode(data.motif)
			preview.arrows = CustomMotif.decode_paths(data.paths, preview.motif)
			preview.scale = Vector2.ONE * zoom
			preview.position = Vector2(index % columns * width + (4 if columns == 4 else 14), index / columns * step - (49 if columns == 4 else 51))
			viewport.add_child(preview)
			var label := Label.new()
			label.text = entry.title
			label.position = Vector2(index % columns * width + 10, index / columns * step + step - 26)
			label.size.x = width - 20
			label.clip_text = true
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 15 if columns == 4 else 18)
			viewport.add_child(label)
		for frame in range(12): await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://previews/collection-" + id + ".png")
		viewport.queue_free()
		print("Rendered ", id)
	rounder.free()
	if args.has("--catalog"): quit(); return
	var game = load("res://main.tscn").instantiate()
	game.storage_prefix = "user://test_preview_"
	game.scan_user_exports = true
	root.add_child(game)
	game.collection_filter = "world"
	game.open_gallery()
	for frame in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://previews/collection-gallery.png")
	quit()
