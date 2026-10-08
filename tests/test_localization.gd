extends SceneTree

var failures := 0
const PREFIX := "user://test_localization_"
var game: Node2D

func check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)

func _initialize() -> void: call_deferred("run")

func labels(node: Node) -> Array[String]:
	var result: Array[String] = []
	if node is Label or node is Button or node is RichTextLabel: result.append(node.text)
	for child in node.get_children(): result.append_array(labels(child))
	return result

func capture(name: String) -> void:
	var args := OS.get_cmdline_user_args()
	var index := args.find("--capture-dir")
	if index < 0 or index + 1 >= args.size(): return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(args[index + 1].path_join("language-" + name + ".png"))

func run() -> void:
	for name in ["settings.cfg", "progress.cfg", "library.cfg", "sessions.json", "sessions.json.bak", "ads.json", "ads.json.bak"]:
		DirAccess.remove_absolute(PREFIX + name)
	check(AppLanguage.resolved_language("system", "de_AT") == "de", "Austrian German system locale selects German")
	check(AppLanguage.resolved_language("system", "de-DE") == "de", "German locale with a hyphen selects German")
	check(AppLanguage.resolved_language("system", "en_GB") == "en", "English system locale selects English")
	check(AppLanguage.resolved_language("system", "fr_FR") == "en", "Unsupported system language falls back to English")
	check(AppLanguage.resolved_language("de", "en_US") == "de", "Explicit German overrides system locale")
	check(AppLanguage.resolved_language("en", "de_AT") == "en", "Explicit English overrides system locale")
	AppLanguage.system_override = "en_GB"
	game = load("res://main.tscn").instantiate()
	game.storage_prefix = PREFIX; game.journey_mode = true; game.scan_user_exports = true
	root.add_child(game); game.set_process(false)
	await process_frame
	check(AppLanguage.selection == "system" and AppLanguage.locale == "en", "Fresh install defaults to system language")
	game.open_home(); await process_frame
	check(labels(game.home_menu).has("My artworks") and labels(game.home_menu).has("Your journey"), "Home is fully English")
	await capture("en-home")
	game.home_menu.navigate("settings"); await process_frame
	var picker: OptionButton = game.home_menu.get_node("LanguagePicker")
	check(picker.item_count == 3 and picker.selected == 0, "Settings exposes exactly system, German and English")
	check(picker.get_item_text(0) == "System language" and picker.get_item_text(2) == "English", "English language options are translated")
	await capture("en-settings")
	var before_arrows := JSON.stringify(game.arrows)
	var before_completed: Array = game.completed.duplicate()
	var before_level: int = game.level
	game.board_navigation.zoom = 1.4
	# Exercise the actual settings callback, including its deferred UI rebuild.
	picker.item_selected.emit(1); await process_frame; await process_frame
	check(AppLanguage.locale == "de" and AppLanguage.selection == "de", "Settings changes language immediately")
	check(labels(game.home_menu).has("Einstellungen"), "Open settings rebuilds in German")
	check(game.home_menu.get_index() > game.play_title.get_index(), "Rebuilt gameplay toolbar stays below the settings menu")
	check(TranslationServer.translate("Einstellungen") == "Einstellungen", "German rendered controls do not fall back to English")
	await capture("de-settings")
	check(JSON.stringify(game.arrows) == before_arrows and game.completed == before_completed and game.level == before_level, "Switch preserves puzzle and progress")
	check(is_equal_approx(game.board_navigation.zoom, 1.4), "Switch preserves board zoom")
	game.toggle_sound()
	var preferences := ConfigFile.new(); preferences.load(PREFIX + "settings.cfg")
	check(preferences.get_value("language", "selection", "") == "de", "Sound toggle preserves language preference")
	var sound_enabled: bool = game.feedback.enabled
	game.set_language("en"); await process_frame
	preferences.load(PREFIX + "settings.cfg")
	check(preferences.get_value("audio", "enabled", not sound_enabled) == sound_enabled, "Language preference preserves sound setting")
	var german_worlds: Array = JourneyProgress.definition.worlds.duplicate(true)
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json"))
	var entries: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://collections/discoveries.json")).entries
	var count := 0
	for index in game.level_count():
		if JourneyProgress.world_index(game.level_collection(index).id) < 0: continue
		var path: String = game.level_path(index)
		var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var authored: String = str(document.get("title", ""))
		if not authored.is_empty():
			check(AppLanguage.messages.has(authored) or (AppLanguage.motif_messages.get(path,{}).get("reviewed_de",{}).get("title","")==authored and not str(AppLanguage.motif_messages.get(path,{}).get("en",{}).get("title","")).is_empty()), "Every active puzzle title has a translation: " + authored)
			check(game.level_title(index) == AppLanguage.motif_text(authored,path,"title").left(80), "Puzzle title getter displays English")
		if entries.has(path):
			check(AppLanguage.messages.has(entries[path].text) or (AppLanguage.motif_messages.get(path,{}).get("reviewed_de",{}).get("text","")==entries[path].text and not str(AppLanguage.motif_messages.get(path,{}).get("en",{}).get("text","")).is_empty()), "Every active completion text has a translation: " + path)
			game.level = index
			var localized: Dictionary = load("res://discoveries.gd").for_level(game)
			check(localized.text == AppLanguage.motif_text(entries[path].text,path,"text"), "Completion text uses English")
			check(localized.get("url", "") == entries[path].get("url", ""), "Translation preserves factual source URLs")
		count += 1
	for world: Dictionary in german_worlds:
		check(AppLanguage.messages.has(world.title), "Every world has an English name")
	check(JourneyProgress.definition.worlds == german_worlds, "Translation never mutates world definition")
	for entry: Dictionary in catalogue.levels:
		check(AppLanguage.messages.has(entry.collection.title), "Every category has an English name")
	game.level = before_level
	game.reset(); game.set_process(false)
	game.close_home(); game.open_journey(); await process_frame
	await capture("en-map")
	game.journey.navigate("collection", 0, "base"); await process_frame
	await capture("en-collection")
	game.close_journey(); await process_frame
	await capture("en-play")
	for arrow in game.arrows: arrow.removed = true
	game.cleared = game.arrows.size(); game.finish_puzzle(true)
	game.close_home(); game.open_home(); game.home_menu.navigate("settings")
	var reveal: float = game.win_time
	var completed: Array = game.completed.duplicate()
	game.set_language("de"); await process_frame
	check(game.win_time == reveal and game.completed == completed, "Language change preserves completed artwork reveal and achievements")
	check(game.next_button.visible and not game.next_button.disabled and game.next_button.text == "Weiterreisen", "Completed artwork retains a usable, translated Continue button")
	game.set_language("en"); await process_frame
	check(game.discovery_card.body.text == AppLanguage.motif_text(entries[game.level_path(game.level)].text,game.level_path(game.level),"text"), "Visible completion card refreshes in English")
	game.close_home(); game.discovery_card._process(0); await process_frame
	await capture("en-completion")
	AppLanguage.initialize(PREFIX)
	check(AppLanguage.selection == "en" and AppLanguage.locale == "en", "Selection survives reinitialization")
	game.set_language("system"); AppLanguage.system_override = "de_AT"
	check(AppLanguage.refresh_system() and AppLanguage.locale == "de", "System setting follows changed device locale")
	AppLanguage.initialize(PREFIX, true)
	check(AppLanguage.locale == "de", "Private author workshop keeps source language")
	game.feedback.stop_all(); root.remove_child(game); game.free()
	await process_frame; await create_timer(0.3).timeout
	for name in ["settings.cfg", "progress.cfg", "library.cfg", "sessions.json", "sessions.json.bak", "ads.json", "ads.json.bak"]:
		DirAccess.remove_absolute(PREFIX + name)
	AppLanguage.system_override = ""; AppLanguage.private_workshop = false
	if failures == 0: print("PASS localization: ", count, " active puzzles, all completion texts, language picker, system fallback, live switching and persistence")
	quit(1 if failures else 0)
