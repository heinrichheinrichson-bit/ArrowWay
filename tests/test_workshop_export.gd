extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://main.tscn").instantiate(); root.add_child(scene)
	scene.enter_editor(); scene.open_studio()
	var studio: Window = scene.studio
	studio.choose_player_export()
	var dialog = studio.get_child(studio.get_child_count() - 1)
	if not dialog is FileDialog: push_error("APK export dialog did not open"); quit(1); return
	var path := ProjectSettings.globalize_path("res://../ArrowWay-S22-Werkstatt-0.22.apk")
	dialog.file_selected.emit(path)
	var deadline := Time.get_ticks_msec() + 120000
	while studio.player_export_worker != null and Time.get_ticks_msec() < deadline: await create_timer(0.1).timeout
	var success: bool = studio.player_export_worker == null and studio.notice.text.begins_with("Spieler-APK erstellt:") and FileAccess.file_exists(path)
	if success: print("PASS actual workshop APK dialog and background export finish without exposing author tools")
	else: push_error(studio.notice.text)
	scene.queue_free(); await process_frame
	quit(0 if success else 1)
