extends SceneTree

func _initialize() -> void: call_deferred("render")

func render() -> void:
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	var rounder := Node2D.new()
	rounder.set_script(load("res://main.gd"))
	var groups := {}
	for entry in catalog.levels:
		if not groups.has(entry.collection.id): groups[entry.collection.id] = []
		groups[entry.collection.id].append(entry)
	for id in groups:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1200, 900)
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
			preview.scale = Vector2.ONE * 0.68
			preview.position = Vector2(index % 3 * 400 + 14, index / 3 * 420 - 51)
			viewport.add_child(preview)
			var label := Label.new()
			label.text = entry.title
			label.position = Vector2(index % 3 * 400 + 16, index / 3 * 420 + 405)
			label.size.x = 368
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size", 18)
			viewport.add_child(label)
		for frame in range(12): await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("res://previews/collection-" + id + ".png")
		viewport.queue_free()
		print("Rendered ", id)
	rounder.free()
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
