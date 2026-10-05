extends SceneTree

var failures:=0
func require(value: bool,message: String) -> void:
	if not value: failures+=1; push_error(message)
func _initialize() -> void: call_deferred("run")

func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	scene.storage_prefix="user://test_discoveries_"; scene.scan_user_exports=true
	root.add_child(scene); scene.set_process(false)
	await process_frame
	var safe_script=load("res://play_safe_area.gd")
	var converted: Rect2=safe_script.calculate(Rect2(0,80,1080,2200),[Rect2(490,0,100,96)],Vector2.ZERO,Transform2D(Vector2(2,0),Vector2(0,2),Vector2.ZERO),Rect2(0,0,540,1170))
	require(converted.position.y==48 and converted.end.y==1140,"Physical camera and safe area convert into logical UI coordinates")
	var entries: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://collections/discoveries.json")).entries
	require(entries.has("res://collections/levels/animals_08_animals_08.json"),"Known motif keeps its own discovery")
	for path in entries:
		require(FileAccess.file_exists(path),"Discovery refers to an existing motif")
		require(entries[path].text is String and not entries[path].text.strip_edges().is_empty() and entries[path].text.length()<=400,"Editorial text stays short and nonempty")
		if entries[path].kind!="Ein kleiner Gedanke": require(entries[path].has("source") and entries[path].has("url"),"Facts and art histories carry a source")
		if entries[path].has("source"): require(entries[path].url.begins_with("https://"),"Facts have an accessible source")
	for screen_size in [Vector2i(360,780),Vector2i(540,850),Vector2i(540,1170)]:
		root.size=screen_size; await process_frame
		var logical: Vector2=scene.get_viewport_rect().size
		scene.safe_area_override=Rect2(0,48,logical.x,logical.y-78)
		scene.reset(); scene.set_process(false)
		scene.play_title.text="Ein besonders schöner Sonnenuntergang am See"
		scene.update_play_layout(); await process_frame
		require(scene.play_title.position.y>=60,"Title stays below camera")
		require(scene.play_title.size.x==logical.x-208,"Title fits between toolbar buttons")
		require(scene.play_title.get_line_count()>=1 and scene.play_title.size.y>=scene.play_title.get_minimum_size().y,"Compact title stays within toolbar")
		require(not scene.discovery_card.visible,"No text card interrupts gameplay")
		for arrow in scene.arrows: arrow.removed=true
		scene.cleared=scene.arrows.size(); scene.finish_puzzle()
		scene.win_time=1.3; scene.discovery_card._process(0)
		require(not scene.discovery_card.visible,"Artwork gets its reveal before the text")
		scene.win_time=2.6; scene._process(0); scene.discovery_card._process(0)
		await process_frame
		require(scene.discovery_card.visible and not scene.next_button.disabled,"Text appears without blocking Continue")
		require(scene.board_clip.position.y+scene.board_clip.size.y<=scene.discovery_card.position.y,"Text does not cover the artwork")
		require(scene.discovery_card.position.y+scene.discovery_card.size.y<=scene.next_button.position.y,"Text does not cover Continue")
		if OS.get_cmdline_user_args().has("--capture"):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://previews/discovery-%dx%d.png" % [screen_size.x,screen_size.y])
	var koala: int=scene.level_files.find("res://collections/levels/animals_08_animals_08.json")
	scene.level=koala; scene.reset(); scene.set_process(false)
	require(scene.discovery_card.source!=null,"Fact card exposes source action")
	for arrow in scene.arrows: arrow.removed=true
	scene.cleared=scene.arrows.size(); scene.finish_puzzle(); scene.win_time=2.6
	scene.discovery_card._process(0); await process_frame
	require(scene.discovery_card.body.size.y>=scene.discovery_card.body.get_content_height(),"Fact text fits with source button")
	if OS.get_cmdline_user_args().has("--capture"):
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://previews/discovery-koala.png")
	root.size=Vector2i(540,850); await process_frame
	scene.safe_area_override=Rect2(0,48,scene.get_viewport_rect().size.x,scene.get_viewport_rect().size.y-78)
	for path in entries:
		scene.level=scene.level_files.find(path); scene.reset(); scene.set_process(false)
		for arrow in scene.arrows: arrow.removed=true
		scene.cleared=scene.arrows.size(); scene.finish_puzzle(); scene.win_time=2.6
		scene.discovery_card._process(0); await process_frame
		require(scene.discovery_card.body.size.y>=scene.discovery_card.body.get_content_height(),"Every curated text fits without clipping: "+path)
	scene.reset(); require(not scene.discovery_card.visible,"Restart removes completion text")
	scene.queue_free(); await process_frame
	DirAccess.remove_absolute("user://test_discoveries_progress.cfg")
	if failures==0: print("PASS discoveries: sourced content, delayed reveal, safe camera area, compact title, portrait layouts and restart")
	quit(1 if failures else 0)
