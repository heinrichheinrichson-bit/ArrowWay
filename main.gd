extends Node2D

const SPEED := 950.0
const TITLES := ["Erste Lichtung", "Herzenswege", "Das erste Haus", "Winterlabyrinth", "Herzklopfen", "Haus bei Nacht", "Flügeltanz", "Meerespause", "Neonblüte"]
const SHAPES := [1, 2, 0, 1, 2, 0, 3, 4, 5]
var base_level_count := 9
var workshop_deleted: Array = []
var workshop_manifest_path := "res://collections/workshop_manifest.json"
var level_files: Array[String] = []
var catalog_metadata := {}
var collection_filter := "all"
var gallery_page := 0
var gallery_scroll := 0
var gallery_view_key := ""
var library_query := ""
var library_status := "all"
var library_tag := ""
var favorites_only := false
var favorite_paths: Array[String] = []
const GALLERY_PAGE_SIZE := 12
var catalog_directory := "res://levels"
var scan_user_exports := not OS.get_cmdline_user_args().has("--test")
var arrows: Array[Dictionary] = []
var editor_data: Array[Dictionary] = []
var draft := PackedVector2Array()
var status := ""
var detail := ""
var cleared := 0
var mistakes := 0
var level := 0
var shape_index := 0
var unlocked := 0
var selected := -1
var editor := false
var testing := false
var draw_tool := true
var controls: Array[Control] = []
var next_button: Button
var level_picker: OptionButton
var panel: Control
var board_navigation: Node
var board_clip: Control
var play_atmosphere: ColorRect
var home_menu: Control
var journey: Control
var journey_mode := not OS.get_cmdline_user_args().has("--test") and not OS.get_cmdline_user_args().has("--editor-tool")
var journey_index_revision := 0
var journey_seen: Array[String] = []
var journey_access_groups: Array[String] = []
var journey_legacy_paths: Array[String] = []
var journey_scroll_memory := {}
var journey_reward := {}
var app_state_reloading := false
var app_state_backup: Node
var session_store: Node
var ads: Node
var session_in_progress := false
var resume_enabled := not OS.get_cmdline_user_args().has("--test")
var compact_buttons: Array[Button] = []
var play_title: Label
var discovery_card: Panel
var safe_area_override := Rect2()
var board: Node2D
var generation_seed := 9121
var clock_time := 0.0
var storage_prefix := "user://test_" if OS.get_cmdline_user_args().has("--test") else "user://"
var authoring := OS.has_feature("editor") and OS.get_cmdline_user_args().has("--editor-tool")
var known_free := {}
var scan_clock := 0.0
var generating := false
var feedback: FeedbackAudio
var sound_button: Button
var win_time := -1.0
var display_progress := 0.0
var completed: Array[int] = []
var gallery: Control
var motif := {}
var studio: Window
var studio_draft := {}
const MOODS := ["Zum Ankommen", "Ruhig entdecken", "Verflochten", "Neue Wege", "Knifflig", "Für Tüftler", "Flügel entfalten", "Verschnaufpause", "Blüte für Tüftler"]

static func escape_distance(time: float) -> float:
	const RAMP := 0.12
	if time < RAMP:
		return SPEED * (time * 0.5 - RAMP * sin(PI * time / RAMP) / (2.0 * PI))
	return SPEED * (time - RAMP * 0.5)

func _ready() -> void:
	var recovery: int = load("res://app_state_backup.gd").recover(storage_prefix)
	if recovery != OK:
		set_process(false); set_process_input(false); set_process_unhandled_input(false)
		push_error("App-state recovery failed; refusing to overwrite the interrupted restore.")
		var notice := AcceptDialog.new()
		AppLanguage.initialize(storage_prefix, authoring)
		notice.dialog_text = AppLanguage.text("Die vorherige Sicherung konnte nicht wiederhergestellt werden. Bitte starte die App erneut.")
		add_child(notice)
		notice.confirmed.connect(func(): get_tree().quit())
		notice.canceled.connect(func(): get_tree().quit())
		notice.popup_centered(Vector2i(400,220))
		return
	AppLanguage.initialize(storage_prefix, authoring)
	if authoring:
		var store: RefCounted = load("res://catalog_workshop_store.gd").new()
		if not store.recover(): push_error(store.error)
	if journey_mode: get_tree().quit_on_go_back=false
	get_window().title = "arrow.joy · " + str(ProjectSettings.get_setting("application/config/version", "")) + (AppLanguage.text(" · Level-Werkzeug") if authoring else "")
	feedback = FeedbackAudio.new()
	add_child(feedback)
	var preferences := ConfigFile.new()
	if preferences.load(storage_prefix + "settings.cfg") == OK:
		feedback.set_enabled(bool(preferences.get_value("audio", "enabled", true)))
	play_atmosphere=ColorRect.new()
	play_atmosphere.set_script(load("res://play_atmosphere.gd"))
	play_atmosphere.game=self
	add_child(play_atmosphere)
	var clip := Control.new()
	board_clip = clip
	clip.position = Vector2(20, 165)
	clip.size = Vector2(500, 510)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	board = Node2D.new()
	board.position = -clip.position
	board.set_script(load("res://board.gd"))
	board.set("game", self)
	clip.add_child(board)
	board_navigation = Node.new()
	board_navigation.set_script(load("res://board_navigation.gd"))
	board_navigation.game = self
	add_child(board_navigation)
	var theme := Theme.new()
	theme.default_font_size = 14
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color("#17253b") if state == "normal" else Color("#254461")
		if state == "disabled":
			box.bg_color = Color("#10192a")
		box.set_corner_radius_all(9)
		box.set_content_margin_all(6)
		theme.set_stylebox(state, "Button", box)
		theme.set_stylebox(state, "OptionButton", box)
	var search_box := StyleBoxFlat.new()
	search_box.bg_color = Color("#17253b")
	search_box.set_corner_radius_all(9)
	search_box.set_content_margin_all(8)
	theme.set_stylebox("normal", "LineEdit", search_box)
	discover_levels()
	load_library_preferences()
	var config := ConfigFile.new()
	if config.load(storage_prefix + "progress.cfg") == OK:
		unlocked = clampi(int(config.get_value("game", "unlocked", 0)), 0, maxi(0, base_level_count - 1))
		level = clampi(int(config.get_value("game", "level", 0)), 0, unlocked)
		for index in config.get_value("game", "completed", range(unlocked)):
			if index is int and index >= 0 and index < TITLES.size():
				var original_index := level_files.find("res://levels/%02d.json" % (index + 1))
				if original_index >= 0 and not completed.has(original_index): completed.append(original_index)
		var custom_path: String = config.get_value("game", "custom_level", "")
		if level_files.has(custom_path): level = level_files.find(custom_path)
		for id in config.get_value("game", "journey_seen", []):
			if id is String: journey_seen.append(id)
		for path in config.get_value("game", "journey_legacy_paths", []):
			if path is String and level_files.has(path): journey_legacy_paths.append(path)
		if journey_mode and not bool(config.get_value("game", "journey_migrated", false)) and level_files.has(custom_path) and not custom_path.is_empty(): journey_legacy_paths.append(custom_path)
		for path in config.get_value("game", "completed_custom", []):
			var index := level_files.find(str(path))
			if index >= base_level_count and not completed.has(index): completed.append(index)
		if config.has_section_key("game", "completed_paths"):
			completed.clear()
			for path in config.get_value("game", "completed_paths", []):
				var saved_index := level_files.find(str(path))
				if saved_index >= 0 and not completed.has(saved_index): completed.append(saved_index)
	session_store=Node.new()
	session_store.set_script(load("res://session_store.gd"))
	session_store.game=self
	add_child(session_store)
	session_store.recover_progress()
	JourneyProgress.migrate_access(self,config)
	ads=Node.new()
	ads.set_script(load("res://ad_controller.gd")); ads.game=self
	add_child(ads); ads.initialize()
	app_state_backup=Node.new()
	app_state_backup.set_script(load("res://app_state_backup.gd")); app_state_backup.game=self
	add_child(app_state_backup)
	var saved_level: int=level_files.find(session_store.active_path)
	if saved_level>=0 and level_available(saved_level): level=saved_level
	if journey_mode and not level_available(level): level=JourneyProgress.resume_index(self)
	var startup_args := OS.get_cmdline_user_args()
	var requested := startup_args.find("--play-level")
	if requested >= 0 and requested + 1 < startup_args.size():
		var requested_index := level_files.find(startup_args[requested + 1])
		if requested_index >= 0 and level_available(requested_index): level = requested_index
	var ui := CanvasLayer.new()
	add_child(ui)
	panel = Control.new()
	panel.theme = theme
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(panel)
	get_viewport().size_changed.connect(update_play_layout)
	reset(true)
	if authoring:
		enter_editor()
		open_studio()
		studio.call_deferred("choose_catalog")
	elif startup_args.has("--library") or startup_args.has("--journey"):
		if journey_mode: open_journey()
		else: open_gallery()
	elif not startup_args.has("--test") and requested < 0:
		open_home()

func button(label: String, x: float, y: float, width: float, action: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.position = Vector2(x, y)
	b.size = Vector2(width, 38)
	b.pressed.connect(action)
	panel.add_child(b)
	controls.append(b)
	return b

func level_count() -> int:
	return level_files.size() if not level_files.is_empty() else base_level_count

func level_path(index: int) -> String:
	return level_files[index] if index < level_files.size() else "res://levels/%02d.json" % (index + 1)

func level_shape(index: int) -> int:
	return SHAPES[index] if index < SHAPES.size() else 1

func level_available(index: int) -> bool:
	if journey_mode and not authoring: return JourneyProgress.level_open(self,index)
	return index >= base_level_count or index <= unlocked

func discover_levels(include_user_exports: bool = true, directory: String = "") -> void:
	journey_index_revision += 1
	if directory.is_empty(): directory = catalog_directory
	var current_path := level_path(level) if not level_files.is_empty() else ""
	var completed_paths: Array[String] = []
	for index in completed:
		if index >= 0 and index < level_files.size(): completed_paths.append(level_files[index])
	level_files.clear()
	catalog_metadata.clear()
	var manifest: Dictionary = {}
	if directory == "res://levels" and FileAccess.file_exists(workshop_manifest_path):
		manifest = JSON.parse_string(FileAccess.get_file_as_string(workshop_manifest_path))
	workshop_deleted = manifest.get("deleted", [])
	if manifest.has("intro_paths"):
		for path in manifest.intro_paths:
			if FileAccess.file_exists(path): level_files.append(path)
	else:
		for index in range(TITLES.size()): level_files.append(directory.path_join("%02d.json" % (index + 1)))
	base_level_count = level_files.size()
	if include_user_exports and scan_user_exports and directory == "res://levels":
		var catalog = JSON.parse_string(FileAccess.get_file_as_string("res://collections/catalog.json")) if FileAccess.file_exists("res://collections/catalog.json") else null
		if catalog is Dictionary and catalog.get("levels") is Array:
			for entry in catalog.levels:
				if not entry is Dictionary or not entry.get("path") is String or not entry.path.begins_with("res://collections/levels/") or not entry.get("collection") is Dictionary or not FileAccess.file_exists(entry.path): continue
				if workshop_deleted.has(entry.path): continue
				catalog_metadata[entry.path] = entry
				if level_files.has(entry.path): continue
				level_files.append(entry.path)
	if include_user_exports and scan_user_exports:
		var files := Array(DirAccess.get_files_at(directory))
		files.sort_custom(func(a: String, b: String): return a.naturalnocasecmp_to(b) < 0)
		for filename in files:
			var path := directory.path_join(filename)
			if filename.get_extension().to_lower() != "json" or level_files.has(path) or workshop_deleted.has(path): continue
			var data = JSON.parse_string(FileAccess.get_file_as_string(path))
			if not data is Dictionary or (data.get("version") != 1 and data.get("version") != 2) or not (data.get("shape") is int or data.get("shape") is float): continue
			var shape := int(data.shape)
			if float(data.shape) != shape or shape < 0 or shape > 6: continue
			var imported := CustomMotif.decode(data.get("motif")) if shape == 6 else CustomMotif.from_shape(shape)
			if imported.is_empty() or CustomMotif.decode_paths(data.get("paths"), imported).is_empty(): continue
			level_files.append(path)
			catalog_metadata[path] = {"title":data.get("title", filename.get_basename()),"collection":data.get("collection", {}),"tags":LibraryIndex.tags(data.get("tags", []))}
	if journey_mode and not authoring and directory == "res://levels":
		var published = JSON.parse_string(FileAccess.get_file_as_string("res://collections/published.json"))
		if published is Dictionary and published.get("levels") is Array:
			for entry in published.levels:
				if not entry is Dictionary or not entry.get("path") is String or not entry.get("group") is String: continue
				if not entry.path.begins_with("res://levels/") or not catalog_metadata.has(entry.path) or not level_files.has(entry.path) or JourneyProgress.world_index(entry.group)<0: continue
				catalog_metadata[entry.path]["collection"]={"id":entry.group,"title":entry.get("collection_title",entry.group)}
				catalog_metadata[entry.path]["published"]=true
	level = level_files.find(current_path) if level_files.has(current_path) else clampi(level, 0, maxi(0, level_files.size() - 1))
	var retained: Array[int] = []
	for path in completed_paths:
		if level_files.has(path): retained.append(level_files.find(path))
	completed = retained

func level_title(index: int) -> String:
	if catalog_metadata.has(level_path(index)): return AppLanguage.motif_text(str(catalog_metadata[level_path(index)].get("title", "Eigenes Motiv")),level_path(index),"title").left(80)
	var fallback: String = TITLES[index] if index < TITLES.size() else level_path(index).get_file().get_basename()
	var data = JSON.parse_string(FileAccess.get_file_as_string(level_path(index)))
	return AppLanguage.motif_text(str(data.get("title", fallback)),level_path(index),"title").left(80) if data is Dictionary else AppLanguage.motif_text(fallback,level_path(index),"title")

func build_controls() -> void:
	for c in controls:
		panel.remove_child(c)
		c.queue_free()
	controls.clear()
	compact_buttons.clear()
	discovery_card=null
	next_button = null
	sound_button = button(AppLanguage.text("Ton: An") if feedback.enabled else AppLanguage.text("Ton: Aus"), 402, 30, 108, toggle_sound)
	if editor:
		var studio_button := button(AppLanguage.text("Bild & Flächen"), 285, 73, 225, open_studio)
		studio_button.size.y = 24
		var shapes := OptionButton.new()
		shapes.position = Vector2(30, 101)
		shapes.size = Vector2(240, 38)
		for name in [AppLanguage.text("Haus"), AppLanguage.text("Weihnachtsbaum"), AppLanguage.text("Herz"), AppLanguage.text("Schmetterling"), AppLanguage.text("Fisch"), AppLanguage.text("Blume")]:
			shapes.add_item(name)
		if shape_index == 6:
			shapes.add_item(AppLanguage.text("Eigenes Bildmotiv"))
		shapes.select(shape_index)
		shapes.tooltip_text = AppLanguage.text("Neue Schablone auswählen; ersetzt die aktuellen Pfade.")
		shapes.item_selected.connect(func(index: int):
			if index == 6:
				open_studio()
				return
			shape_index = index
			motif.clear()
			arrows.clear()
			draft.clear()
			selected = -1
			status = AppLanguage.text("Neue Schablone. Zeichne Pfade oder drücke Füllen."))
		panel.add_child(shapes)
		controls.append(shapes)
		button(AppLanguage.text("Füllen"), 290, 101, 105, fill_template)
		button(AppLanguage.text("Spiel"), 415, 101, 95, leave_editor)
		button(AppLanguage.text("Zeichnen"), 30, 741, 91, func(): draw_tool = true; selected = -1; status = AppLanguage.text("Rasterpunkte anklicken, dann Fertig drücken."))
		button(AppLanguage.text("Auswahl"), 128, 741, 85, func(): draw_tool = false; draft.clear(); status = AppLanguage.text("Pfad anklicken, dann drehen oder löschen."))
		button(AppLanguage.text("Fertig"), 220, 741, 65, finish_draft)
		button(AppLanguage.text("Drehen"), 292, 741, 67, reverse_selected)
		button(AppLanguage.text("Zurück"), 366, 741, 65, undo_edit)
		button(AppLanguage.text("Leer"), 438, 741, 72, func(): arrows.clear(); draft.clear(); selected = -1; status = AppLanguage.text("Leere Schablone – zeichne deinen ersten Pfad."))
		button(AppLanguage.text("Prüfen"), 30, 791, 90, check_editor)
		button(AppLanguage.text("Testen"), 127, 791, 90, test_editor)
		button(AppLanguage.text("Speichern"), 224, 791, 96, save_custom)
		button(AppLanguage.text("Laden"), 327, 791, 82, load_custom)
		button("Export", 416, 791, 94, export_level)
	else:
		var picker := OptionButton.new()
		level_picker = picker
		picker.position = Vector2(30, 101)
		picker.size = Vector2(330, 37)
		for i in range(level_count()):
			picker.add_item("%02d / %s" % [i + 1, level_title(i)])
			picker.set_item_disabled(i, not level_available(i))
		picker.select(level)
		if testing and shape_index == 6:
			picker.set_item_text(level, "Test / " + str(motif.get("title", AppLanguage.text("Eigenes Motiv"))))
		picker.item_selected.connect(func(index: int): level = index; testing = false; reset())
		panel.add_child(picker)
		controls.append(picker)
		picker.size.x = 352
		var gallery_button := button(AppLanguage.text("Alle Levels"), 394, 101, 116, open_gallery)
		gallery_button.visible = not authoring
		gallery_button.disabled = testing
		button(AppLanguage.text("Neustart"), 90, 751, 165, reset)
		button(AppLanguage.text("Hinweis"), 285, 751, 165, show_hint)
		if authoring:
			button(AppLanguage.text("Zum Level-Werkzeug"), 140, 101, 260, enter_editor)
			picker.visible = false
		next_button = button(AppLanguage.text("Zurück zum Editor") if testing else AppLanguage.text("Nächstes Puzzle"), 130, 805, 280, enter_editor if testing else advance)
		next_button.visible = false
	if compact_play():
		for control in controls: control.hide()
		compact_buttons.append(button("‹", 0, 0, 48, open_current_journey if journey_mode else open_home))
		compact_buttons.append(button("↻", 0, 0, 48, request_restart))
		compact_buttons.append(button("?", 0, 0, 48, show_hint))
		var icon_paths := ["<path d='M15 5L8 12l7 7'/>", "<path d='M19 8a8 8 0 1 0 1 7'/><path d='M19 3v5h-5'/>", "<path d='M9 18h6m-5 3h4M8 14a6 6 0 1 1 8 0l-1 3H9z'/>"]
		for index in compact_buttons.size():
			var image := Image.new()
			image.load_svg_from_string("<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'><g fill='none' stroke='#b7c9dc' stroke-width='1.7' stroke-linecap='round' stroke-linejoin='round'>" + icon_paths[index] + "</g></svg>")
			compact_buttons[index].text = ""
			compact_buttons[index].icon = ImageTexture.create_from_image(image)
		play_title = Label.new()
		play_title.text = level_title(level)
		play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		play_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		play_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		play_title.add_theme_font_size_override("font_size", 16)
		play_title.modulate = Color("#9aabc2")
		play_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(play_title)
		controls.append(play_title)
		discovery_card=Panel.new()
		discovery_card.set_script(load("res://discovery_card.gd"))
		discovery_card.game=self
		discovery_card.data=load("res://discoveries.gd").for_level(self)
		panel.add_child(discovery_card)
		controls.append(discovery_card)
		compact_buttons[0].tooltip_text = AppLanguage.text("Dein Weg") if journey_mode else AppLanguage.text("Hauptmenü")
		compact_buttons[1].tooltip_text = AppLanguage.text("Neu beginnen")
		compact_buttons[2].tooltip_text = AppLanguage.text("Hinweis")
		next_button.text = AppLanguage.text("Weiter")
	# Menus must remain above newly rebuilt gameplay controls after a language
	# change or layout refresh.
	for overlay in [gallery, journey, home_menu]:
		if is_instance_valid(overlay) and overlay.get_parent() == panel:
			panel.move_child(overlay, panel.get_child_count() - 1)
	update_play_layout()

func compact_play() -> bool:
	return not editor and not authoring

func update_play_layout() -> void:
	if not is_instance_valid(board): return
	var viewport_size := get_viewport_rect().size
	if is_instance_valid(journey): journey.relayout()
	if is_instance_valid(home_menu) and home_menu.has_method("relayout"):
		home_menu.relayout()
	elif is_instance_valid(home_menu):
		home_menu.size = viewport_size
		home_menu.get_child(0).size = viewport_size
		home_menu.get_child(1).position.y = viewport_size.y * 0.22
		home_menu.get_child(1).size.x = viewport_size.x
		for index in range(3):
			home_menu.get_child(index + 2).position = Vector2((viewport_size.x - 280) * 0.5, viewport_size.y * 0.42 + index * 70)
	if is_instance_valid(gallery):
		gallery.position.x = maxf(0, (viewport_size.x - 540) * 0.5)
		gallery.size = Vector2(540, viewport_size.y)
		gallery.get_child(0).position.x = -gallery.position.x
		gallery.get_child(0).size = viewport_size
		gallery.get_child(3).size.y = maxf(160, viewport_size.y - 423)
		for control in gallery.get_children():
			if control.position.y >= 700 or control.has_meta("footer_y"):
				if not control.has_meta("footer_y"): control.set_meta("footer_y", control.position.y)
				control.position.y = float(control.get_meta("footer_y")) + viewport_size.y - 850
	if not compact_play():
		board_clip.position = Vector2(20, 165)
		board_clip.size = Vector2(500, 510)
		board.position = -board_clip.position
		board.scale = Vector2.ONE
		queue_redraw()
		return
	var size := get_viewport_rect().size
	var safe: Rect2=load("res://play_safe_area.gd").for_game(self)
	var title_width:=maxf(0,safe.size.x-208)
	var title_height:=48.0
	var header_y:=safe.position.y+16
	var board_top:=header_y+60
	var board_bottom:=safe.end.y-86
	if is_instance_valid(discovery_card):
		var card_width:=safe.size.x-48
		var text_height:=ThemeDB.fallback_font.get_multiline_string_size(discovery_card.data.text,HORIZONTAL_ALIGNMENT_LEFT,card_width-40,18).y
		var card_height:=text_height+58+(44 if discovery_card.source!=null else 0)
		discovery_card.position=Vector2(safe.position.x+24,safe.end.y-80-card_height)
		discovery_card.size=Vector2(card_width,card_height)
		if win_time>=0: board_bottom=discovery_card.position.y-18
	var area := Rect2(safe.position.x+12,board_top,safe.size.x-24,maxf(100,board_bottom-board_top))
	var bounds := Rect2()
	var first := true
	for arrow in arrows:
		for point in arrow.points:
			if first: bounds = Rect2(point, Vector2.ZERO); first = false
			else: bounds = bounds.expand(point)
	bounds = bounds.grow(20)
	var zoom := minf(area.size.x / maxf(bounds.size.x, 1), area.size.y / maxf(bounds.size.y, 1))
	board_clip.position = area.position
	board_clip.size = area.size
	board_navigation.configure(bounds,zoom)
	if compact_buttons.size() == 3:
		compact_buttons[0].position = Vector2(safe.position.x+16, header_y)
		compact_buttons[1].position = Vector2(safe.end.x - 120, header_y)
		compact_buttons[2].position = Vector2(safe.end.x - 64, header_y)
		for control in compact_buttons: control.size = Vector2(48, 48)
		play_title.position = Vector2(safe.position.x+76, header_y)
		play_title.size = Vector2(title_width,title_height)
	if is_instance_valid(next_button):
		next_button.position = Vector2(safe.get_center().x-110, safe.end.y - 64)
		next_button.size = Vector2(220, 48)
		next_button.visible = win_time >= 0
		next_button.disabled = win_time >= 0 and win_time < 1.95
	queue_redraw()

func request_restart() -> void:
	if cleared == 0 and not arrows.any(func(a): return a.escaping):
		reset()
		return
	var dialog := ConfirmationDialog.new()
	dialog.title = AppLanguage.text("Neu beginnen?")
	dialog.dialog_text = AppLanguage.text("Dieses Rätsel wird zurückgesetzt.")
	dialog.ok_button_text = AppLanguage.text("Neu beginnen")
	dialog.cancel_button_text = AppLanguage.text("Weiter spielen")
	dialog.confirmed.connect(reset)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func close_home() -> void:
	if is_instance_valid(home_menu):
		panel.remove_child(home_menu)
		home_menu.queue_free()
	home_menu = null

func open_home() -> void:
	queue_session()
	if is_instance_valid(home_menu): return
	if journey_mode:
		close_journey()
		close_gallery()
		refresh_journey_catalog()
		home_menu = Control.new()
		home_menu.set_script(load("res://journey_view.gd"))
		home_menu.game = self
		home_menu.screen = "home"
		panel.add_child(home_menu)
		return
	home_menu = Control.new()
	home_menu.size = get_viewport_rect().size
	panel.add_child(home_menu)
	var background := ColorRect.new()
	background.color = Color("#080e19")
	background.size = home_menu.size
	home_menu.add_child(background)
	var heading := Label.new()
	heading.text = "arrow.joy"
	heading.add_theme_font_size_override("font_size", 36)
	heading.position = Vector2(0, home_menu.size.y * 0.22)
	heading.size.x = home_menu.size.x
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	home_menu.add_child(heading)
	var actions := [close_home, func(): close_home(); open_gallery(), open_settings]
	var titles := [AppLanguage.text("Weiter spielen"), AppLanguage.text("Motive entdecken"), AppLanguage.text("Einstellungen")]
	for index in titles.size():
		var item := Button.new()
		item.text = titles[index]
		item.position = Vector2((home_menu.size.x - 280) * 0.5, home_menu.size.y * 0.42 + index * 70)
		item.size = Vector2(280, 54)
		item.pressed.connect(actions[index])
		home_menu.add_child(item)

func open_settings() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = AppLanguage.text("Einstellungen")
	dialog.dialog_text = ""
	var toggle := CheckButton.new()
	toggle.text = AppLanguage.text("Soundeffekte")
	toggle.button_pressed = feedback.enabled
	toggle.toggled.connect(func(_enabled): toggle_sound())
	dialog.add_child(toggle)
	var language := OptionButton.new()
	language.name = "LanguagePicker"
	language.position = Vector2(24, 88)
	language.size = Vector2(260, 42)
	var choices := ["system", "de", "en"]
	for title in ["Systemsprache", "Deutsch", "Englisch"]: language.add_item(AppLanguage.text(title))
	language.select(choices.find(AppLanguage.selection))
	language.item_selected.connect(func(index: int):
		set_language(choices[index])
		dialog.queue_free()
		open_settings.call_deferred())
	dialog.add_child(language)
	dialog.min_size = Vector2i(310, 195)
	toggle.position = Vector2(24, 36)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func close_journey() -> void:
	if is_instance_valid(journey):
		journey_scroll_memory=journey.scroll_positions.duplicate(true)
		if is_instance_valid(journey.scroller):
			var key: String="%s:%d:%s:%s" % [journey.screen,journey.world,journey.group,journey.history]
			journey_scroll_memory[key]=journey.scroller.get_meta("wanted_scroll",journey.scroller.scroll_vertical)
		panel.remove_child(journey)
		journey.queue_free()
	journey = null

func open_current_journey() -> void:
	var group: String=level_collection(level).id
	open_journey(JourneyProgress.world_index(group),group)

func refresh_journey_catalog() -> void:
	var previous_path:=level_path(level)
	discover_levels()
	if not level_files.has(previous_path):
		level=0
		reset()

func open_journey(selected_world := -1, selected_group := "") -> void:
	queue_session()
	if not journey_mode:
		open_home()
		return
	close_home()
	close_gallery()
	close_journey()
	refresh_journey_catalog()
	if journey_mode and not selected_group.is_empty() and not JourneyProgress.group_visible(self,selected_group): selected_group=""; selected_world=-1
	journey = Control.new()
	journey.set_script(load("res://journey_view.gd"))
	journey.game = self
	journey.world = selected_world
	journey.group = selected_group
	journey.scroll_positions=journey_scroll_memory.duplicate(true)
	journey.screen = "collection" if not selected_group.is_empty() else "map"
	panel.add_child(journey)

func open_album() -> void:
	queue_session()
	close_home(); close_gallery(); close_journey()
	refresh_journey_catalog()
	journey = Control.new()
	journey.set_script(load("res://journey_view.gd"))
	journey.game = self; journey.screen = "album"
	panel.add_child(journey)

func remember_journey_stations(ids: Array[String]) -> void:
	var changed := false
	for id in ids:
		if not journey_seen.has(id): journey_seen.append(id); changed = true
	if changed: save_progress()

func start_journey_puzzle(index: int) -> void:
	if not level_available(index): return
	close_journey()
	close_home()
	select_gallery_level(index)
	session_in_progress=true
	queue_session()

func close_gallery() -> void:
	if is_instance_valid(gallery):
		gallery_scroll = gallery.get_child(3).scroll_vertical
		gallery_view_key = library_view_key()
		panel.remove_child(gallery)
		gallery.queue_free()
	gallery = null

func select_gallery_level(index: int) -> void:
	if index < 0 or index >= level_count() or not level_available(index):
		return
	close_gallery()
	if index != level or win_time>=0:
		queue_session()
		var replay: bool = (completed.has(index) and not session_store.has_unfinished(level_path(index))) or (index==level and win_time>=0)
		level = index
		testing = false
		reset(not replay)
		save_progress()

func open_gallery() -> void:
	if journey_mode:
		open_album()
		return
	discover_levels()
	if editor or testing or is_instance_valid(gallery):
		return
	gallery = Control.new()
	gallery.size = Vector2(540, 850)
	feedback.stop_all()
	panel.add_child(gallery)
	var background := ColorRect.new()
	background.color = Color("#080e19")
	background.size = gallery.size
	gallery.add_child(background)
	var heading := Label.new()
	heading.text = AppLanguage.text("DEINE ENTDECKUNGEN") if journey_mode else AppLanguage.text("MOTIVBIBLIOTHEK")
	heading.position = Vector2(30, 28)
	heading.add_theme_font_size_override("font_size", 24)
	gallery.add_child(heading)
	var progress := Label.new()
	progress.text = AppLanguage.text("%d / %d Puzzles geschafft · Dein Tempo zählt") % [completed.size(), level_count()]
	if journey_mode: progress.text=AppLanguage.text("Deine freigeschalteten Kunstwerke · Suche & Favoriten")
	progress.position = Vector2(30, 73)
	progress.add_theme_font_size_override("font_size", 14)
	gallery.add_child(progress)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(30, 282)
	scroll.size = Vector2(480, 427)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	gallery.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	var collections := {"all":AppLanguage.text("Alle Motive"), "base":AppLanguage.text("Erste Neonreise")}
	for index in range(level_count()):
		if journey_mode and not level_available(index): continue
		var group := level_collection(index)
		collections[group.id] = group.title
	if not collections.has(collection_filter):
		collection_filter = "all"
	var filters := OptionButton.new()
	filters.position = Vector2(30, 106)
	filters.size = Vector2(480, 36)
	filters.fit_to_longest_item = false
	var filter_ids := collections.keys()
	for id in filter_ids:
		var total := 0
		var done := 0
		for index in range(level_count()):
			if id == "all" or level_collection(index).id == id:
				total += 1
				if completed.has(index): done += 1
		filters.add_item("%s · %d/%d" % [collections[id],done,total])
	filters.select(filter_ids.find(collection_filter))
	filters.item_selected.connect(func(index: int):
		collection_filter = filter_ids[index]; refresh_gallery(true))
	gallery.add_child(filters)
	for offset in [-1,1]:
		var navigation := Button.new()
		navigation.text = AppLanguage.text("← Zurück") if offset < 0 else AppLanguage.text("Weiter →")
		navigation.position = Vector2(30 if offset < 0 else 350, 723)
		navigation.size = Vector2(160, 36)
		navigation.pressed.connect(func(): gallery_page += offset; refresh_gallery())
		gallery.add_child(navigation)
	var page_label := Label.new()
	page_label.position = Vector2(210,731)
	page_label.size.x = 120
	page_label.add_theme_font_size_override("font_size", 12)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gallery.add_child(page_label)
	var back := Button.new()
	back.text = AppLanguage.text("Zur Reise") if journey_mode else AppLanguage.text("Weiter spielen")
	back.position = Vector2(150, 787)
	back.size = Vector2(240, 40)
	back.pressed.connect(func(): close_gallery(); open_journey()) if journey_mode else back.pressed.connect(close_gallery)
	gallery.add_child(back)
	var search := LineEdit.new()
	search.name = "LibrarySearch"
	search.position = Vector2(30, 152)
	search.size = Vector2(480, 36)
	search.placeholder_text = AppLanguage.text("Motiv, Sammlung oder Thema suchen …")
	search.clear_button_enabled = true
	search.text = library_query
	search.text_changed.connect(func(value: String): library_query = value; refresh_gallery(true))
	gallery.add_child(search)
	var status_filter := OptionButton.new()
	status_filter.name = "LibraryStatus"
	status_filter.position = Vector2(30, 196)
	status_filter.size = Vector2(308, 34)
	var status_ids := ["all", "open", "complete", "available"]
	for label in [AppLanguage.text("Alle Fortschritte"), AppLanguage.text("Noch nicht geschafft"), AppLanguage.text("Geschafft"), AppLanguage.text("Spielbar")]: status_filter.add_item(label)
	status_filter.select(maxi(0, status_ids.find(library_status)))
	status_filter.item_selected.connect(func(index: int): library_status = status_ids[index]; refresh_gallery(true))
	gallery.add_child(status_filter)
	var favorites := Button.new()
	favorites.name = "LibraryFavorites"
	favorites.text = AppLanguage.text("★ Favoriten")
	favorites.toggle_mode = true
	favorites.button_pressed = favorites_only
	favorites.position = Vector2(350,196)
	favorites.size = Vector2(160,34)
	favorites.toggled.connect(func(pressed: bool): favorites_only = pressed; refresh_gallery(true))
	gallery.add_child(favorites)
	var tag_filter := OptionButton.new()
	tag_filter.name = "LibraryTag"
	tag_filter.position = Vector2(30,238)
	tag_filter.size = Vector2(368,34)
	tag_filter.fit_to_longest_item = false
	var tag_ids: Array[String] = [""]
	for index in range(level_count()):
		if journey_mode and not level_available(index): continue
		for tag in level_tags(index):
			if not tag_ids.has(tag): tag_ids.append(tag)
	tag_ids.sort()
	for tag in tag_ids: tag_filter.add_item(AppLanguage.text("Thema: ") + (AppLanguage.text("Alle Themen") if tag.is_empty() else tag))
	if not tag_ids.has(library_tag): library_tag = ""
	tag_filter.select(tag_ids.find(library_tag))
	tag_filter.item_selected.connect(func(index: int): library_tag = tag_ids[index]; refresh_gallery(true))
	gallery.add_child(tag_filter)
	var empty := Label.new()
	empty.name = "LibraryEmpty"
	empty.position = Vector2(45,380)
	empty.size = Vector2(450,150)
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gallery.add_child(empty)
	var clear := Button.new()
	clear.name = "LibraryReset"
	clear.text = AppLanguage.text("Alles zeigen")
	clear.position = Vector2(410,238)
	clear.size = Vector2(100,34)
	clear.pressed.connect(func():
		library_query = ""; library_tag = ""; library_status = "all"; favorites_only = false; collection_filter = "all"
		search.text = ""; filters.select(0); status_filter.select(0); tag_filter.select(0); favorites.set_pressed_no_signal(false)
		refresh_gallery(true))
	gallery.add_child(clear)
	refresh_gallery()
	update_play_layout()
	if gallery_view_key == library_view_key(): scroll.set_deferred("scroll_vertical", gallery_scroll)
	back.grab_focus()

func library_view_key() -> String:
	return JSON.stringify([collection_filter,library_query,library_status,library_tag,favorites_only,gallery_page])

func level_tags(index: int) -> Array[String]:
	if index < base_level_count and index < SHAPES.size():
		return LibraryIndex.tags([AppLanguage.text("Pflanzen"), AppLanguage.text("Natur")] if SHAPES[index] in [1,5] else ([AppLanguage.text("Tiere"), AppLanguage.text("Natur")] if SHAPES[index] in [3,4] else ([AppLanguage.text("Architektur")] if SHAPES[index] == 0 else [AppLanguage.text("Symbole")])))
	var tags := LibraryIndex.tags(catalog_metadata.get(level_path(index), {}).get("tags", []))
	for i in tags.size(): tags[i] = AppLanguage.text(tags[i])
	return tags

func matching_library_levels() -> Array[int]:
	var result: Array[int] = []
	for index in range(level_count()):
		if journey_mode and not level_available(index): continue
		var group := level_collection(index)
		if collection_filter != "all" and collection_filter != group.id: continue
		if favorites_only and not favorite_paths.has(level_path(index)): continue
		if library_status == "open" and completed.has(index): continue
		if library_status == "complete" and not completed.has(index): continue
		if library_status == "available" and not level_available(index): continue
		var tags := level_tags(index)
		if not library_tag.is_empty() and not tags.has(library_tag): continue
		if not LibraryIndex.matches(library_query, level_title(index), group.title, tags): continue
		result.append(index)
	return result

func refresh_gallery(reset_page: bool = false) -> void:
	if not is_instance_valid(gallery): return
	var scroll: ScrollContainer = gallery.get_child(3)
	var grid: GridContainer = scroll.get_child(0)
	for card in grid.get_children():
		grid.remove_child(card)
		card.queue_free()
	if reset_page: gallery_page = 0
	var matching := matching_library_levels()
	var page_count := maxi(1, ceili(float(matching.size()) / GALLERY_PAGE_SIZE))
	gallery_page = clampi(gallery_page, 0, page_count - 1)
	var begin := gallery_page * GALLERY_PAGE_SIZE
	for page_index in range(begin, mini(begin + GALLERY_PAGE_SIZE, matching.size())):
		var index := matching[page_index]
		var card := Button.new()
		card.set_script(load("res://level_card.gd"))
		card.custom_minimum_size = Vector2(228,170)
		card.number = index
		card.title = level_title(index)
		card.tooltip_text = card.title + "\n" + ", ".join(level_tags(index))
		card.subtitle = AppLanguage.text(MOODS[index]) if index < MOODS.size() else level_collection(index).title
		card.selected = index == level
		card.complete = completed.has(index)
		card.disabled = not level_available(index)
		var document = JSON.parse_string(FileAccess.get_file_as_string(level_path(index)))
		var thumbnail: Array[Dictionary] = []
		if document is Dictionary and document.get("paths") is Array:
			for path in document.paths:
				var points := PackedVector2Array()
				for xy in path.points: points.append(Vector2(xy[0],xy[1]))
				var arrow := {"points":rounded_points(points),"color":Color(path.color)}
				CustomMotif.read_appearance(path,arrow)
				thumbnail.append(arrow)
		card.paths = thumbnail
		card.pressed.connect(select_gallery_level.bind(index))
		grid.add_child(card)
		var star := Button.new()
		star.name = "FavoriteStar"
		star.position = Vector2(183,5)
		star.size = Vector2(38,32)
		star.text = "★" if favorite_paths.has(level_path(index)) else "☆"
		star.add_theme_color_override("font_color", Color("#ffe18a"))
		star.tooltip_text = AppLanguage.text("Aus Favoriten entfernen") if favorite_paths.has(level_path(index)) else AppLanguage.text("Als Favorit merken")
		star.pressed.connect(toggle_favorite.bind(index))
		card.add_child(star)
	scroll.scroll_vertical = 0
	gallery.get_child(5).disabled = gallery_page == 0
	gallery.get_child(6).disabled = gallery_page >= page_count - 1
	gallery.get_child(7).text = AppLanguage.text("%d / %d · %d Motive") % [gallery_page+1,page_count,matching.size()]
	var empty: Label = gallery.get_node("LibraryEmpty")
	empty.visible = matching.is_empty()
	empty.text = AppLanguage.text("Noch keine Favoriten.\nMerke dir Motive mit dem Stern auf ihrer Karte.") if favorites_only and favorite_paths.is_empty() else AppLanguage.text("Keine passenden Motive.\nÄndere die Suche oder die Filter.")

func load_library_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(storage_prefix + "library.cfg") != OK: return
	var paths = config.get_value("library", "favorites", [])
	if paths is Array or paths is PackedStringArray:
		for path in paths:
			if path is String and level_files.has(path) and not favorite_paths.has(path): favorite_paths.append(path)

func toggle_favorite(index: int) -> void:
	if journey_mode and not JourneyProgress.album_indices(self).has(index): return
	var path := level_path(index)
	if favorite_paths.has(path): favorite_paths.erase(path)
	else: favorite_paths.append(path)
	var config := ConfigFile.new()
	config.set_value("library", "favorites", favorite_paths)
	config.save(storage_prefix + "library.cfg")
	refresh_gallery()

func clone_data(data: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for a in data:
		var copy := ArrowPuzzle.make_arrow(a.points.duplicate(), a.color)
		MotifColors.copy_appearance(a, copy)
		result.append(copy)
	return result

func reset(resume_saved := false) -> void:
	if is_instance_valid(board_navigation): board_navigation.reset_view()
	feedback.stop_all()
	win_time = -1.0
	display_progress = 0.0
	if not testing:
		shape_index = level_shape(level)
	if testing:
		arrows = clone_data(editor_data)
	elif not read_custom(level_path(level)):
		arrows = ArrowPuzzle.generate(level_shape(level), 4817 + level * 173)
	if is_instance_valid(play_atmosphere): play_atmosphere.configure()
	cleared = 0
	mistakes = 0
	clock_time = 0.0
	session_in_progress=not resume_saved
	selected = -1
	status = AppLanguage.text("Welche Spitze hat freie Bahn?")
	detail = AppLanguage.text("Tippe auf einen Pfad. Er folgt seiner Linie nach draußen.")
	build_controls()
	known_free.clear()
	for i in free_paths():
		known_free[i] = true
	scan_clock = 0.0
	queue_redraw()
	if board != null:
		board.queue_redraw()

	if is_instance_valid(session_store):
		session_store.configure()
		if resume_saved: session_store.restore()
		queue_session()

func queue_session() -> void:
	if is_instance_valid(session_store): session_store.capture()

func save_progress() -> int:
	var config := ConfigFile.new()
	config.load(storage_prefix + "progress.cfg")
	JourneyProgress.remember_access(self)
	config.set_value("game", "journey_version", 3)
	config.set_value("game", "journey_access_groups", journey_access_groups)
	config.set_value("game", "journey_seen", journey_seen)
	config.set_value("game", "journey_legacy_paths", journey_legacy_paths)
	config.set_value("game", "journey_migrated", journey_mode)
	config.set_value("game", "unlocked", unlocked)
	config.set_value("game", "level", level)
	config.set_value("game", "completed", completed)
	var completed_paths: Array[String] = []
	for index in completed:
		if index >= 0 and index < level_files.size(): completed_paths.append(level_path(index))
	config.set_value("game", "completed_paths", completed_paths)
	config.set_value("game", "custom_level", level_path(level) if level >= base_level_count else "")
	var custom_completed: Array[String] = []
	for index in completed:
		if index >= base_level_count and index < level_files.size(): custom_completed.append(level_path(index))
	config.set_value("game", "completed_custom", custom_completed)
	return config.save(storage_prefix + "progress.cfg")

func toggle_sound() -> void:
	feedback.set_enabled(not feedback.enabled)
	sound_button.text = AppLanguage.text("Ton: An") if feedback.enabled else AppLanguage.text("Ton: Aus")
	var preferences := ConfigFile.new()
	preferences.load(storage_prefix + "settings.cfg")
	preferences.set_value("audio", "enabled", feedback.enabled)
	preferences.save(storage_prefix + "settings.cfg")

func set_language(choice: String) -> void:
	if AppLanguage.choose(choice, storage_prefix) != OK:
		push_error("Could not save language preference.")
		return
	refresh_language()

func refresh_language() -> void:
	# Rebuild presentation only. Arrow state, zoom, sessions and achievements stay
	# in place, including an already completed puzzle's reveal timer.
	var next_visible := is_instance_valid(next_button) and next_button.visible
	var next_disabled := is_instance_valid(next_button) and next_button.disabled
	var next_text := AppLanguage.original(next_button.text) if is_instance_valid(next_button) else "Weiter"
	status = AppLanguage.text(AppLanguage.original(status))
	detail = AppLanguage.text(AppLanguage.original(detail))
	if win_time >= 0:
		status = AppLanguage.text("Geschafft! Alle Wege sind frei.")
		detail = AppLanguage.text("%d Pfade befreit · %d blockierte Versuche") % [cleared, mistakes]
	build_controls()
	if is_instance_valid(next_button):
		next_button.visible = next_visible
		next_button.disabled = next_disabled
		next_button.text = AppLanguage.text(next_text)
	if is_instance_valid(gallery): close_gallery(); open_gallery()
	queue_redraw()

func next_collection_level(index: int) -> int:
	if journey_mode: return JourneyProgress.next_open(self,index)
	if index < base_level_count:
		return index + 1 if index < base_level_count - 1 else -1
	var group: String = level_collection(index).id
	for candidate in range(index + 1, level_count()):
		if level_collection(candidate).id == group: return candidate
	return -1

func advance() -> void:
	if journey_mode:
		var group: String = level_collection(level).id
		var world := JourneyProgress.world_index(group)
		var next := JourneyProgress.next_open(self,level)
		if group != "custom" and JourneyProgress.group_complete(self,group): open_journey()
		elif next >= 0: ads.transition(world,func(): start_journey_puzzle(next))
		else: open_journey(world,group)
		return
	var next := next_collection_level(level)
	if next < 0:
		collection_filter = level_collection(level).id
		gallery_page = 0
		library_query = ""; library_tag = ""; library_status = "all"; favorites_only = false
		open_gallery()
		return
	level = next
	if level < base_level_count: unlocked = maxi(unlocked, level)
	save_progress()
	reset()

func _process(delta: float) -> void:
	var flight_paused: bool = (is_instance_valid(ads) and ads.showing) or is_instance_valid(gallery) or is_instance_valid(home_menu) or is_instance_valid(journey)
	feedback.pause_escape(flight_paused)
	if is_instance_valid(ads) and ads.showing: return
	if is_instance_valid(gallery) or is_instance_valid(home_menu) or is_instance_valid(journey):
		return
	clock_time += delta
	if win_time >= 0.0:
		win_time += delta
		if compact_buttons.size() == 3: compact_buttons[2].disabled = true
		next_button.disabled = win_time < 1.95
	display_progress = lerpf(display_progress, float(cleared) / maxf(arrows.size(), 1.0), 1.0 - exp(-delta * 12.0))
	for a in arrows:
		a.flash = maxf(0.0, a.flash - delta)
		a.hint = maxf(0.0, a.hint - delta)
		a.release = maxf(0.0, a.release - delta)
		if a.escaping and not a.removed:
			if not a.has("escape_duration"): a.escape_duration = escape_duration(a)
			if not a.has("escape_sound_id"): a.escape_sound_id = arrows.find(a)
			feedback.play_escape(a.escape_sound_id, a.escape_duration, a.escape_time)
			a.escape_time += delta
			a.travel = escape_distance(a.escape_time)
			var p := visible_points(a)
			if a.travel > path_length(a.draw_points) and not Rect2(12, 157, 516, 526).has_point(p[0]):
				a.removed = true
				feedback.stop_escape(a.escape_sound_id)
				cleared += 1
				if cleared == arrows.size(): finish_puzzle()
				queue_session()
	if not editor and cleared < arrows.size():
		scan_clock -= delta
		if scan_clock <= 0:
			scan_clock = 0.14
			mark_releases()
	queue_redraw()
	board.queue_redraw()

func finish_puzzle(restored := false) -> void:
	win_time = 2.2 if restored else 0.0
	board_navigation.reset_view()
	if not restored: feedback.play("win")
	status = AppLanguage.text("Geschafft! Alle Wege sind frei.")
	detail = AppLanguage.text("%d Pfade befreit · %d blockierte Versuche") % [cleared, mistakes]
	next_button.visible = true
	next_button.disabled = not restored
	if not testing:
		if next_collection_level(level) < 0:
			next_button.text = AppLanguage.text("Zur Levelübersicht")
		if journey_mode: next_button.text = AppLanguage.text("Weiterreisen")
		if not completed.has(level):
			completed.append(level)
			if not restored and journey_mode and not authoring and JourneyProgress.world_index(level_collection(level).id)>=0:
				ads.completed(level_path(level),JourneyProgress.world_index(level_collection(level).id))
			if journey_mode:
				var group: String = level_collection(level).id
				var wi := JourneyProgress.world_index(group)
				if wi>=0 and JourneyProgress.group_complete(self,group): journey_reward={"group":group,"world":wi,"next":JourneyProgress.frontier(self) if JourneyProgress.world_complete(self,wi) and wi+1<JourneyProgress.worlds().size() else -1}
		if level < base_level_count: unlocked = maxi(unlocked, mini(level + 1, base_level_count - 1))
		level_picker.set_item_disabled(unlocked, false)
		save_progress()
	session_in_progress=false
	update_play_layout()
	update_play_layout.call_deferred()
	queue_session()

func free_paths() -> Array[int]:
	var result: Array[int] = []
	for i in range(arrows.size()):
		if not arrows[i].removed and not arrows[i].escaping and not is_blocked(i):
			result.append(i)
	return result

func mark_releases() -> void:
	var free := free_paths()
	var opened := 0
	for i in free:
		if not known_free.has(i):
			arrows[i].release = 0.8
			opened += 1
	known_free.clear()
	for i in free:
		known_free[i] = true
	if opened > 0 and not status.begins_with(AppLanguage.text("Der weiß")):
		status = AppLanguage.text("Ein neuer Weg ist jetzt frei.") if opened == 1 else AppLanguage.text("%d neue Wege sind jetzt frei.") % opened
		detail = AppLanguage.text("Deine Auswahl öffnet weitere Möglichkeiten.")

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_RESUMED and is_instance_valid(board):
		if AppLanguage.refresh_system(): refresh_language.call_deferred()
		else: update_play_layout.call_deferred()
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_CLOSE_REQUEST,NOTIFICATION_WM_GO_BACK_REQUEST] and is_instance_valid(session_store):
		queue_session(); session_store.flush()
	if what != NOTIFICATION_WM_GO_BACK_REQUEST or not journey_mode: return
	if is_instance_valid(ads) and ads.showing: ads.dismiss(); return
	for child in get_children():
		if child is Window and child.visible:
			child.hide(); child.queue_free(); return
	if is_instance_valid(journey): journey.go_back()
	elif is_instance_valid(home_menu):
		if home_menu.screen in ["settings","backup"]: home_menu.go_back()
		else: get_tree().quit()
	else: open_current_journey()

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(journey):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: journey.go_back()
		return
	if is_instance_valid(home_menu):
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE: close_home()
		return
	if is_instance_valid(gallery) and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_gallery()
		get_viewport().set_input_as_handled()
		return
	if generating:
		return
	if not editor and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		open_home()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.device == InputEvent.DEVICE_ID_EMULATION or compact_play(): return
		click_at(board.get_global_transform().affine_inverse() * event.position)
	elif (editor or authoring) and event is InputEventScreenTouch and event.pressed:
		click_at(board.get_global_transform().affine_inverse() * event.position)
	elif editor and event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER:
			finish_draft()
		elif event.keycode == KEY_BACKSPACE or event.keycode == KEY_DELETE:
			undo_edit()
		elif event.keycode == KEY_ESCAPE:
			draft.clear()

func pick(pos: Vector2) -> int:
	var chosen := -1
	var nearest := 9.0 if editor else 18.0 / maxf(board.scale.x,0.001)
	for index in range(arrows.size()):
		var a := arrows[index]
		if a.removed or a.escaping:
			continue
		var p: PackedVector2Array = a.points
		for i in range(p.size() - 1):
			var distance := pos.distance_to(Geometry2D.get_closest_point_to_segment(pos, p[i], p[i + 1]))
			if distance < nearest:
				nearest = distance
				chosen = index
	return chosen

func click_at(pos: Vector2) -> void:
	if is_instance_valid(gallery) or is_instance_valid(home_menu) or is_instance_valid(journey):
		return
	if editor:
		if draw_tool:
			add_draft(pos)
		else:
			selected = pick(pos)
			status = AppLanguage.text("Pfad gewählt – Drehen oder Zurück zum Löschen.") if selected >= 0 else AppLanguage.text("Kein Pfad getroffen.")
		return
	var chosen := pick(pos)
	if chosen < 0:
		return
	session_in_progress=true
	if is_blocked(chosen):
		arrows[chosen].flash = 0.35
		feedback.play("blocked")
		mistakes += 1
		status = AppLanguage.text("Noch blockiert. Schau in Richtung der Spitze.")
		detail = AppLanguage.text("Ein anderer Pfad versperrt diesen Weg.")
	else:
		arrows[chosen].escaping = true
		arrows[chosen].escape_duration = escape_duration(arrows[chosen])
		arrows[chosen].escape_sound_id = chosen
		feedback.play_escape(chosen, arrows[chosen].escape_duration)
		status = AppLanguage.text("Freie Bahn!")
		detail = AppLanguage.text("Du kannst während der Animation weiterspielen.")
	queue_session()

func is_blocked(index: int) -> bool:
	if ArrowPuzzle.self_blocked(arrows[index].points):
		return true
	for other in range(arrows.size()):
		if other != index and not arrows[other].removed and ArrowPuzzle.ray_hits(arrows[index].points, visible_points(arrows[other])):
			return true
	return false

func show_hint() -> void:
	for i in range(arrows.size()):
		if not arrows[i].removed and not arrows[i].escaping and not is_blocked(i):
			arrows[i].hint = 2.5
			feedback.play("hint")
			status = AppLanguage.text("Der weiß leuchtende Pfad hat freie Bahn.")
			return
	status = AppLanguage.text("Warte kurz, bis die laufenden Pfade draußen sind.")

func enter_editor() -> void:
	if not testing:
		editor_data = clone_data(arrows)
	arrows = clone_data(editor_data)
	editor = true
	testing = false
	selected = -1
	draft.clear()
	draw_tool = true
	status = AppLanguage.text("Zeichne auf der Schablone oder wähle einen Pfad.")
	detail = AppLanguage.text("Rasterpunkte → Fertig. Enter / Rücktaste funktionieren auch.")
	build_controls()

func open_studio() -> void:
	if not OS.has_feature("editor"): return
	if is_instance_valid(studio):
		studio.show()
		studio.grab_focus()
		return
	get_viewport().gui_embed_subwindows = DisplayServer.get_name() == "headless"
	studio = Window.new()
	studio.set_script(load("res://motif_studio.gd"))
	studio.set("game", self)
	var initial := motif.duplicate(true) if shape_index == 6 else CustomMotif.from_shape(shape_index)
	if not studio_draft.is_empty():
		initial = studio_draft.motif.duplicate(true)
		studio.set("paths", clone_data(studio_draft.paths))
	else:
		studio.set("paths", clone_data(arrows))
	studio.set("motif", initial)
	add_child(studio)
	if not studio_draft.is_empty(): studio.restore_workshop_state(studio_draft.get("workshop", {}))
	studio.popup_centered(Vector2i(1040, 800))

func fill_template() -> void:
	if generating:
		return
	generating = true
	status = AppLanguage.text("Die Pfade werden gefüllt und miteinander verflochten …")
	for control in controls:
		if control is BaseButton:
			control.disabled = true
	await get_tree().process_frame
	generation_seed += 173
	var filled := LevelDesign.refine(shape_index, generation_seed, 10, 600, motif)
	if not filled.is_empty():
		arrows = filled
		if shape_index == 6:
			MotifColors.apply(motif, arrows)
	generating = false
	for control in controls:
		if control is BaseButton:
			control.disabled = false
	draft.clear()
	selected = -1
	status = AppLanguage.text("Keine vollständige Füllung gefunden. Korrigiere enge Stellen in Bild & Flächen.") if filled.is_empty() else AppLanguage.text("Neue Füllung: %d verflochtene Pfade, lösbar.") % arrows.size()
	detail = AppLanguage.text("Du kannst einzelne Pfade auswählen, umdrehen und neu prüfen.")

func leave_editor() -> void:
	editor = false
	testing = false
	draft.clear()
	reset()

func add_draft(pos: Vector2) -> void:
	var cell := ArrowPuzzle.grid(pos)
	var allowed := ArrowPuzzle.mask(shape_index, motif)
	if not allowed.has(cell):
		status = AppLanguage.text("Bitte innerhalb der gepunkteten Form zeichnen.")
		return
	var addition := PackedVector2Array()
	if draft.is_empty():
		addition.append(ArrowPuzzle.pixel(cell))
	else:
		var current := ArrowPuzzle.grid(draft[-1])
		while current.x != cell.x:
			current.x += 1 if cell.x > current.x else -1
			addition.append(ArrowPuzzle.pixel(current))
		while current.y != cell.y:
			current.y += 1 if cell.y > current.y else -1
			addition.append(ArrowPuzzle.pixel(current))
	for point in addition:
		if shape_index == 6 and not draft.is_empty() and MotifBuilder.region(6, ArrowPuzzle.grid(point), motif) != MotifBuilder.region(6, ArrowPuzzle.grid(draft[0]), motif):
			status = AppLanguage.text("Ein Pfeil bleibt innerhalb seiner Fläche.")
			return
		if not allowed.has(ArrowPuzzle.grid(point)) or draft.has(point):
			status = AppLanguage.text("Bleibe in der Form; der Pfad darf sich nicht kreuzen.")
			return
		for a in arrows:
			if a.points.has(point):
				status = AppLanguage.text("Dieser Rasterpunkt gehört bereits zu einem Pfad.")
				return
	draft.append_array(addition)
	status = AppLanguage.text("%d Rasterpunkte · Fertig schließt den Pfad ab.") % draft.size()

func finish_draft() -> void:
	if draft.size() < 2:
		status = AppLanguage.text("Ein Pfad braucht mindestens zwei Rasterpunkte.")
		return
	arrows.append(ArrowPuzzle.make_arrow(draft.duplicate(), MotifBuilder.color_for(shape_index, MotifBuilder.region(shape_index, ArrowPuzzle.grid(draft[0]), motif), arrows.size(), motif)))
	if shape_index == 6:
		MotifColors.apply(motif, arrows)
	selected = arrows.size() - 1
	draft.clear()
	status = AppLanguage.text("Pfad hinzugefügt. Zeichne weiter oder prüfe die Lösung.")

func reverse_selected() -> void:
	if selected >= 0 and selected < arrows.size():
		var p: PackedVector2Array = arrows[selected].points
		p.reverse()
		arrows[selected].points = p
		status = AppLanguage.text("Pfeilrichtung umgedreht. Prüfen testet die Lösung.")
	else:
		status = AppLanguage.text("Erst Auswahl drücken und einen Pfad anklicken.")

func undo_edit() -> void:
	if not draft.is_empty():
		draft.remove_at(draft.size() - 1)
	elif selected >= 0 and selected < arrows.size():
		arrows.remove_at(selected)
		selected = -1
	elif not arrows.is_empty():
		arrows.pop_back()
	status = AppLanguage.text("Letzten Punkt oder Pfad entfernt.")

func check_editor() -> bool:
	if shape_index == 6:
		var used := {}
		for arrow in arrows:
			for point in arrow.points:
				used[ArrowPuzzle.grid(point)] = true
		if used.size() != motif.get("cells", {}).size():
			status = AppLanguage.text("Das Bildmotiv ist noch nicht vollständig gefüllt. Nutze Bild & Flächen → Füllen.")
			return false
	if arrows.is_empty() or not draft.is_empty():
		status = AppLanguage.text("Zeichne einen Pfad und schließe ihn mit Fertig ab.")
		return false
	var order := ArrowPuzzle.solution(arrows)
	if order.size() == arrows.size():
		status = AppLanguage.text("Lösbar! Alle %d Pfade lassen sich entfernen.") % arrows.size()
		var analysis := LevelDesign.metrics(arrows)
		detail = AppLanguage.text("%d freie Startzüge · %d Freispielstufen · Testen startet das Puzzle.") % [analysis.starts, analysis.depth]
		return true
	status = AppLanguage.text("Blockade: %d von %d Pfaden lassen sich entfernen.") % [order.size(), arrows.size()]
	detail = AppLanguage.text("Drehe oder entferne einen der rot markierten Pfade.")
	for i in range(arrows.size()):
		if not order.has(i):
			arrows[i].flash = 1.5
	return false

func test_editor() -> void:
	if check_editor():
		editor_data = clone_data(arrows)
		editor = false
		testing = true
		reset()

func level_document() -> Dictionary:
	var paths: Array = []
	for a in arrows:
		var points: Array = []
		for p in a.points:
			points.append([p.x, p.y])
		var item := {"points": points, "color": a.color.to_html()}
		MotifColors.copy_appearance(a, item)
		paths.append(item)
	var document := {"version": 1, "shape": shape_index, "title": level_title(level), "paths": paths}
	if shape_index == 6:
		document.version = 2
		document.title = motif.get("title", AppLanguage.text("Eigenes Motiv"))
		document["motif"] = CustomMotif.encode(motif)
	return document

func save_custom() -> void:
	if not check_editor():
		return
	var file := FileAccess.open(storage_prefix + "custom_puzzle.json", FileAccess.WRITE)
	if file == null:
		status = AppLanguage.text("Speichern fehlgeschlagen.")
		return
	file.store_string(JSON.stringify(level_document(), "\t"))
	status = AppLanguage.text("Dein Puzzle ist lokal gespeichert.")
	detail = AppLanguage.text("Laden öffnet den Entwurf; Export schreibt eine Leveldatei.")

func export_level() -> void:
	if not check_editor():
		return
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.json ; arrow.joy Level"])
	dialog.current_dir = ProjectSettings.globalize_path("res://levels")
	dialog.current_file = str(motif.get("title", AppLanguage.text("Eigenes Motiv"))).validate_filename() + ".json" if shape_index == 6 else "%02d.json" % (level + 1)
	dialog.title = AppLanguage.text("Level für das Spiel exportieren")
	add_child(dialog)
	dialog.file_selected.connect(func(path: String):
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(level_document(), "\t"))
			status = AppLanguage.text("Exportiert: ") + path.get_file()
			detail = AppLanguage.text("Im Spiel: Alle Levels → Eigenes Motiv. Die Übersicht liest neue Exporte automatisch ein.") if path.get_base_dir() == ProjectSettings.globalize_path("res://levels").trim_suffix("/") else AppLanguage.text("Für das Spiel die JSON-Datei im Projektordner levels speichern.")
		else:
			status = AppLanguage.text("Export fehlgeschlagen.")
		dialog.queue_free())
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(500, 650))

func read_custom(path: String = "") -> bool:
	if path.is_empty():
		path = storage_prefix + "custom_puzzle.json"
	if not FileAccess.file_exists(path):
		status = AppLanguage.text("Noch kein eigenes Puzzle gespeichert.")
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	status = AppLanguage.text("Die Puzzle-Datei ist ungültig.")
	if not data is Dictionary or (data.get("version") != 1 and data.get("version") != 2) or not data.get("shape") is float and not data.get("shape") is int:
		return false
	if not data.get("paths") is Array or data.paths.size() > 500 or int(data.shape) < 0 or int(data.shape) > 6 or float(data.shape) != int(data.shape):
		return false
	var loaded: Array[Dictionary] = []
	var occupied := {}
	var shape := int(data.shape)
	var imported := {}
	if shape == 6:
		if data.version != 2:
			return false
		imported = CustomMotif.decode(data.get("motif"))
		if imported.is_empty() or imported.cells.is_empty():
			return false
	var allowed := ArrowPuzzle.mask(shape, imported)
	for a in data.paths:
		if not a is Dictionary or not a.get("points") is Array or a.points.size() < 2 or a.points.size() > 500:
			return false
		if not a.get("color") is String or not Color.html_is_valid(a.color):
			return false
		var p := PackedVector2Array()
		for xy in a.points:
			if not xy is Array or xy.size() != 2 or not (xy[0] is float or xy[0] is int) or not (xy[1] is float or xy[1] is int):
				return false
			var point := Vector2(float(xy[0]), float(xy[1]))
			if not point.is_finite() or point != ArrowPuzzle.pixel(ArrowPuzzle.grid(point)) or occupied.has(point) or not allowed.has(ArrowPuzzle.grid(point)):
				return false
			if not p.is_empty() and point.distance_to(p[-1]) != ArrowPuzzle.CELL:
				return false
			if shape == 6 and not p.is_empty() and imported.cells[ArrowPuzzle.grid(point)] != imported.cells[ArrowPuzzle.grid(p[0])]:
				return false
			occupied[point] = true
			p.append(point)
		var arrow := ArrowPuzzle.make_arrow(p, Color(str(a.get("color", "65e5ff"))))
		if not CustomMotif.read_appearance(a, arrow):
			return false
		loaded.append(arrow)
	if (shape == 6 and occupied.size() != allowed.size()) or loaded.is_empty() or ArrowPuzzle.solution(loaded).size() != loaded.size():
		status = AppLanguage.text("Die gespeicherte Datei enthält kein lösbares Puzzle.")
		return false
	shape_index = shape
	motif = imported
	arrows = loaded
	status = AppLanguage.text("Gespeichertes Puzzle geladen.")
	return true

func load_custom() -> void:
	if read_custom():
		draft.clear()
		selected = -1
		status = AppLanguage.text("Gespeichertes Puzzle geladen.")

func play_custom() -> void:
	if read_custom():
		editor_data = clone_data(arrows)
		testing = true
		reset()

func escape_duration(arrow: Dictionary) -> float:
	visible_points(arrow)
	var points: PackedVector2Array = arrow.draw_points
	var direction := (points[-1] - points[-2]).normalized()
	var boundary := Rect2(12, 157, 516, 526)
	var outside := INF
	if direction.x > 0.0001: outside = minf(outside, (boundary.end.x - points[-1].x) / direction.x)
	elif direction.x < -0.0001: outside = minf(outside, (boundary.position.x - points[-1].x) / direction.x)
	if direction.y > 0.0001: outside = minf(outside, (boundary.end.y - points[-1].y) / direction.y)
	elif direction.y < -0.0001: outside = minf(outside, (boundary.position.y - points[-1].y) / direction.y)
	var distance := path_length(points) + maxf(0.0, outside)
	var low := 0.0
	var high := distance / SPEED + 0.12
	for iteration in range(32):
		var middle := (low + high) * 0.5
		if escape_distance(middle) < distance: low = middle
		else: high = middle
	return high

func path_length(p: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(p.size() - 1):
		total += p[i].distance_to(p[i + 1])
	return total

func point_along(p: PackedVector2Array, distance: float) -> Vector2:
	for i in range(p.size() - 1):
		var length := p[i].distance_to(p[i + 1])
		if distance <= length:
			return p[i].lerp(p[i + 1], distance / length)
		distance -= length
	return p[-1] + (p[-1] - p[-2]).normalized() * distance

func visible_points(a: Dictionary) -> PackedVector2Array:
	if not a.has("draw_points") or a.get("draw_source") != a.points:
		a.draw_source = a.points.duplicate()
		a.draw_points = rounded_points(a.points)
	var p: PackedVector2Array = a.draw_points
	var travel: float = a.travel
	if travel == 0.0:
		return p
	var result := PackedVector2Array([point_along(p, travel)])
	var walked := 0.0
	for i in range(1, p.size()):
		walked += p[i - 1].distance_to(p[i])
		if walked > travel:
			result.append(p[i])
	result.append(point_along(p, path_length(p) + travel))
	return result

func rounded_points(source: PackedVector2Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in range(source.size()):
		if i > 0 and i < source.size() - 1 and (source[i] - source[i - 1]).normalized().is_equal_approx((source[i + 1] - source[i]).normalized()):
			continue
		p.append(source[i])
	if p.size() < 3:
		return p
	var smooth := PackedVector2Array([p[0]])
	for i in range(1, p.size() - 1):
		var incoming := (p[i] - p[i - 1]).normalized()
		var outgoing := (p[i + 1] - p[i]).normalized()
		var radius := minf(4.8, minf(p[i].distance_to(p[i - 1]), p[i].distance_to(p[i + 1])) * 0.44)
		var center := p[i] - incoming * radius + outgoing * radius
		var start := p[i] - incoming * radius
		var finish := p[i] + outgoing * radius
		var angle := (start - center).angle()
		var turn := wrapf((finish - center).angle() - angle, -PI, PI)
		for step in range(9):
			smooth.append(center + Vector2.from_angle(angle + turn * step / 8.0) * radius)
	smooth.append(p[-1])
	return smooth

func text_at(text: String, pos: Vector2, size: int, color: Color, width: float = -1) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT if width < 0 else HORIZONTAL_ALIGNMENT_CENTER, width, size, color)

func _draw() -> void:
	if compact_play():
		var size := get_viewport_rect().size
		return
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#080d18")
	box.set_corner_radius_all(22)
	draw_style_box(box, Rect2(20, 165, 500, 510))
	text_at(AppLanguage.text("ARROW / WAY"), Vector2(30, 55), 30, Color("#eef5ff"))
	text_at(AppLanguage.text("LEVEL-WERKZEUG") if editor else "NEON TRAILS", Vector2(31, 79), 12, Color("#839ab8"))
	if not editor:
		text_at("%d / %d" % [cleared, arrows.size()], Vector2(36, 658), 14, Color("#839ab8"))
		var ratio := display_progress
		draw_line(Vector2(125, 653), Vector2(492, 653), Color("#24394e"), 4, true)
		if ratio > 0:
			draw_line(Vector2(125, 653), Vector2(125 + ratio * 367, 653), Color("#65e5ff"), 4, true)
	text_at(status, Vector2(20, 701), 17, Color("#e0e8f5"), 500)
	text_at(detail, Vector2(20, 724), 12, Color("#8296b0"), 500)

func level_collection(index: int) -> Dictionary:
	if journey_mode and index >= base_level_count and level_path(index).begins_with("res://levels/") and not bool(catalog_metadata.get(level_path(index),{}).get("published",false)): return {"id":"custom","title":AppLanguage.text("Eigene Motive")}
	if index < base_level_count: return {"id":"base","title":AppLanguage.text("Erste Neonreise")}
	var data: Dictionary = catalog_metadata.get(level_path(index), {})
	var group: Dictionary = data.get("collection", {}) if data.get("collection", {}) is Dictionary else {}
	if not group.get("id") is String or not group.get("title") is String:
		return {"id":"custom","title":AppLanguage.text("Eigene Motive")}
	return AppLanguage.fields(group)

func reload_app_state() -> void:
	var restored: Node2D = load("res://main.tscn").instantiate()
	restored.storage_prefix = storage_prefix
	restored.journey_mode = journey_mode
	restored.scan_user_exports = scan_user_exports
	restored.resume_enabled = resume_enabled
	restored.authoring = authoring
	process_mode = Node.PROCESS_MODE_DISABLED
	var parent := get_parent()
	parent.add_child(restored)
	if get_tree().current_scene == self: get_tree().current_scene = restored
	queue_free()
	if not is_instance_valid(restored.home_menu): restored.open_home()
	if is_instance_valid(restored.home_menu):
		restored.home_menu.navigate("backup")
		restored.home_menu.tell(AppLanguage.text("Dein App-Stand wurde wiederhergestellt."))
