extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var scene = load("res://main.tscn").instantiate(); root.add_child(scene)
	scene.enter_editor(); scene.open_studio()
	var studio: Window = scene.studio
	studio.pages.current_tab = 2
	check(studio.pages.current_tab == 2, "Completion metadata tab remains open without redirecting to area tools")
	studio.choose_catalog()
	var browser: Window = studio.get_child(studio.get_child_count() - 1)
	await process_frame; await process_frame
	check(browser.grid.get_child_count() == 9 and browser.entries.size() == 823, "Browser renders nine previews while retaining full private catalog")
	check(not browser.grid.get_child(0).paths.is_empty(), "Preview uses actual arrow geometry")
	browser.grid.get_child(0).pressed.emit()
	check(not browser.selected_path.is_empty() and not browser.open_button.disabled, "Selecting a card enables clear edit actions")
	browser.query.text = "Schreibmaschine"; browser.query.text_changed.emit(browser.query.text)
	await process_frame
	check(browser.filtered.size() > 0 and browser.filtered.all(func(item): return (str(item.title) + " " + str(item.collection.title)).to_lower().contains("schreibmaschine")), "Search finds named puzzles")
	browser.query.text = "__no_such_motif__"; browser.query.text_changed.emit(browser.query.text)
	await process_frame
	check(browser.grid.get_child_count() == 0, "Empty search stays clear")
	browser.query.text = ""; browser.query.text_changed.emit(browser.query.text)
	browser.page = 1; browser.render(); await process_frame
	check(browser.grid.get_child_count() == 9 and browser.page_label.text.begins_with("Seite 2"), "Pagination loads next preview page")
	browser.page = 0; browser.render()
	await process_frame; await process_frame
	check(browser.grid.get_rect().end.y < browser.size.y - 50, "Preview grid fits above footer")
	var selected_target := {}
	studio.choose_workshop_target(func(target: Dictionary): selected_target.merge(target, true))
	var target_dialog: Window = studio.get_child(studio.get_child_count() - 1)
	var box: VBoxContainer = target_dialog.get_child(0)
	var world_picker: OptionButton = box.get_child(1)
	var category_picker: OptionButton = box.get_child(3)
	var group_picker: OptionButton = box.get_child(5)
	world_picker.select(1); world_picker.item_selected.emit(1)
	category_picker.select(2); category_picker.item_selected.emit(2)
	check(group_picker.item_count > 0, "Cascading category picker offers its valid collection")
	box.get_child(6).pressed.emit()
	check(selected_target.get("world") == "animals" and selected_target.get("category_id") == "animals_03", "Three-step picker supplies the chosen taxonomy instead of a long flat menu")
	studio.save_draft(false)
	browser.drafts_mode = true; browser.reload_entries(); await process_frame
	check(browser.entries.size() > 0 and browser.entries.all(func(item): return item.collection.id == "draft"), "Central draft browser finds privately saved works")
	browser.drafts_mode = false; browser.reload_entries(); browser.selected_path = browser.entries[0].path; browser.render()
	if OS.get_cmdline_user_args().has("--capture"):
		await create_timer(0.4).timeout
		browser.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../ArrowWay-Werkstatt-0.22.png"))
	browser.queue_free(); studio.catalog_path = ""; scene.queue_free(); await process_frame
	if failures == 0: print("PASS workshop browser previews, selection, search, pagination and layout")
	quit(1 if failures else 0)
