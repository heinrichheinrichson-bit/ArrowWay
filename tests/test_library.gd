extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func require(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func click(position: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = pressed
		event.position = position; event.global_position = position
		root.push_input(event,true)
func cards(scene: Node2D) -> GridContainer: return scene.gallery.get_child(3).get_child(0)
func fresh_game() -> Node2D:
	var scene = load("res://main.tscn").instantiate()
	scene.storage_prefix = "user://test_library_ui_"
	scene.scan_user_exports = true
	root.add_child(scene)
	return scene
func run() -> void:
	DirAccess.remove_absolute("user://test_library_ui_library.cfg")
	var scene := fresh_game()
	var initial_level: int = scene.level
	var initial_paths := CustomMotif.encode_paths(scene.arrows)
	scene.open_gallery()
	var search: LineEdit = scene.gallery.get_node("LibrarySearch")
	search.grab_focus()
	await process_frame
	var typed_query := "palme am strand"
	for character in typed_query:
		var event := InputEventKey.new()
		event.pressed = true; event.unicode = character.unicode_at(0)
		root.push_input(event,true)
	await process_frame
	require(scene.library_query == typed_query and cards(scene).get_child_count() == 1, "Actual typing searches the catalog immediately")
	require(search.has_focus() and search.caret_column == typed_query.length(), "Refreshing results preserves input focus and caret")
	require(cards(scene).get_child(0).title == "Palme am Strand", "Search selects the correct matching motif")
	await process_frame
	var palm_index: int = cards(scene).get_child(0).number
	var star: Button = cards(scene).get_child(0).get_node("FavoriteStar")
	click(star.global_position + star.size * 0.5)
	require(scene.favorite_paths.has(scene.level_path(palm_index)), "Actual star click adds a favorite")
	require(scene.level == initial_level and is_instance_valid(scene.gallery), "Star click does not launch or reset the puzzle")
	require(CustomMotif.encode_paths(scene.arrows) == initial_paths, "Browsing preserves the actual puzzle paths")
	var favorite_path: String = scene.level_path(palm_index)
	scene.gallery.get_node("LibraryReset").pressed.emit()
	scene.gallery.get_node("LibraryFavorites").toggled.emit(true)
	require(cards(scene).get_child_count() == 1, "Favorites-only filter shows the saved motif")
	var reopened := fresh_game()
	require(reopened.favorite_paths.has(favorite_path), "Favorites persist across a fresh game instance by path")
	reopened.queue_free()
	scene.toggle_favorite(palm_index)
	require(cards(scene).get_child_count() == 0 and scene.gallery.get_node("LibraryEmpty").visible, "Removing the last favorite produces a clear empty state")
	scene.gallery.get_node("LibraryReset").pressed.emit()
	search.text = "van gogh"
	search.text_changed.emit(search.text)
	require(cards(scene).get_child_count() == 2, "Search finds artist tags across titles")
	search.text = "grOße WELLE"
	search.text_changed.emit(search.text)
	require(cards(scene).get_child_count() == 1 and cards(scene).get_child(0).title == "Die große Neonwelle", "Case-insensitive multiword search handles German characters")
	search.text = "nicht vorhandenes motiv"
	search.text_changed.emit(search.text)
	require(cards(scene).get_child_count() == 0 and scene.gallery.get_child(5).disabled and scene.gallery.get_child(6).disabled, "No results disable paging")
	scene.gallery.get_node("LibraryReset").pressed.emit()
	require(scene.library_query.is_empty() and scene.library_tag.is_empty() and not scene.favorites_only and cards(scene).get_child_count() == 12, "Alles zeigen resets every filter and returns to the first page")
	var tag_picker: OptionButton = scene.gallery.get_node("LibraryTag")
	for index in range(tag_picker.item_count):
		if tag_picker.get_item_text(index) == "Thema: Pflanzen": tag_picker.item_selected.emit(index); break
	require(scene.matching_library_levels().size() >= 7, "Plant theme spans collections and the campaign")
	for index in scene.matching_library_levels(): require(scene.level_tags(index).has("Pflanzen"), "Theme results only contain matching tags")
	scene.collection_filter = "art"
	scene.refresh_gallery(true)
	require(cards(scene).get_child_count() == 2, "Collection and theme filters combine")
	scene.gallery.get_node("LibraryReset").pressed.emit()
	var eiffel: int = scene.level_files.find("res://collections/levels/world_01_eiffel.json")
	scene.completed.append(eiffel)
	scene.gallery.get_node("LibraryStatus").item_selected.emit(2)
	require(cards(scene).get_child_count() == 1 and cards(scene).get_child(0).number == eiffel, "Completed filter reflects stored completion")
	scene.gallery.get_node("LibraryStatus").item_selected.emit(1)
	require(not scene.matching_library_levels().has(eiffel), "Unfinished filter excludes completed puzzles")
	scene.gallery.get_node("LibraryStatus").item_selected.emit(3)
	for index in scene.matching_library_levels(): require(scene.level_available(index), "Available filter excludes locked campaign entries")
	require(LibraryIndex.matches("grun", "Grüner Baum", "Natur", []), "Search accepts omitted umlauts")
	require(LibraryIndex.tags(["Natur",null,"Natur",14," "]) == ["Natur"], "Malformed or duplicate tags are discarded")
	scene.gallery.get_node("LibraryReset").pressed.emit()
	await process_frame
	var scroll: ScrollContainer = scene.gallery.get_child(3)
	scroll.scroll_vertical = 250
	var saved_scroll := scroll.scroll_vertical
	scene.close_gallery()
	scene.open_gallery()
	await process_frame
	require(scene.gallery.get_child(3).scroll_vertical == saved_scroll and saved_scroll > 0, "Leaving and reopening the library restores the actual scroll position")
	for index in range(scene.level_count()):
		if scene.level_collection(index).id == "custom":
			scene.toggle_favorite(index)
			require(scene.favorite_paths.has(scene.level_path(index)), "User exports support independent favorites")
			break
	scene.close_gallery()
	for filename in ["library.cfg","progress.cfg","settings.cfg"]: DirAccess.remove_absolute(scene.storage_prefix + filename)
	print("PASS library: real typing, focus, real star input, persistence, themes, combined filters, empty states, reset and puzzle preservation" if failures == 0 else "%d FAILURES" % failures)
	quit(0 if failures == 0 else 1)
