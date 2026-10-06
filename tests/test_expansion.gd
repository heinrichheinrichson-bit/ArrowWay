extends SceneTree

var failures := 0
func require(ok: bool, message: String) -> void:
	if not ok: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var catalog: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	var recipes: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/expansion_recipes.json"))
	var credits: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/art_credits.json"))
	var discoveries: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/discoveries.json"))
	var sources := {}; var texts := {}; var added := 0
	for entry in catalog.levels:
		if not entry.path.get_file().begins_with("expanded_"): continue
		added+=1
		require(credits.entries.has(entry.path),"Every new artwork has a credit")
		require(credits.entries[entry.path]==entry.attribution,"Catalog and published credits agree")
		require(not sources.has(entry.attribution.source),"New motifs use different vector sources")
		sources[entry.attribution.source]=true
		var text: String=discoveries.entries[entry.path].text
		require(not texts.has(text),"Every new motif has a different completion text")
		texts[text]=true
		var document: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(entry.path))
		require(document.attribution==entry.attribution,"Editable document keeps its source attribution")
	require(added==314 and recipes.entries.size()==added and credits.entries.size()==added,"All 314 additions are fully integrated")
	var game=load("res://main.tscn").instantiate()
	game.storage_prefix="user://test_expansion_"; game.journey_mode=true; game.resume_enabled=false
	root.add_child(game); game.set_process(false)
	for dimensions in [Vector2i(360,780),Vector2i(540,1170)]:
		root.size=dimensions; await process_frame
		game.open_home(); game.home_menu.navigate("settings"); await process_frame
		game.home_menu.show_art_credits(); await process_frame
		var dialog: AcceptDialog=game.home_menu.get_child(game.home_menu.get_child_count()-1)
		require(dialog.visible and dialog.size.x<=game.get_viewport_rect().size.x and dialog.size.y<=game.get_viewport_rect().size.y,"Scrollable credits fit the phone")
		var scroll: ScrollContainer=dialog.get_child(0)
		# Window internals are implementation dependent: locate the authored scroll.
		for child in dialog.get_children():
			if child is ScrollContainer: scroll=child
		var body: RichTextLabel=scroll.get_child(0)
		require(body.text.contains("Originalquelle ansehen") and body.bbcode_enabled,"Per-motif sources are readable links")
		if OS.get_cmdline_user_args().has("--capture"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://previews/credits-%d.png" % dimensions.x)
		dialog.queue_free(); game.close_home(); await process_frame
	game.queue_free(); await process_frame
	print("PASS expansion: 314 distinct sources, individual texts, preserved attribution and phone credits" if failures==0 else "%d FAILURES" % failures)
	quit(1 if failures else 0)
