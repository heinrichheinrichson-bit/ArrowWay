extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	scene.storage_prefix = "user://test_reference_flight_"
	root.add_child(scene); scene.set_process(false); scene.editor = false
	var audio: FeedbackAudio = scene.feedback; audio.quiet = false
	scene.arrows.clear()
	scene.arrows.append(ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(200,300),Vector2(186,300),Vector2(172,300)]), Color.CYAN))
	scene.arrows.append(ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(100,450),Vector2(114,450),Vector2(128,450),Vector2(128,464),Vector2(142,464),Vector2(156,464),Vector2(156,478),Vector2(170,478),Vector2(184,478)]), Color.PINK))
	scene.arrows.append(ArrowPuzzle.make_arrow(PackedVector2Array([Vector2(350,400),Vector2(350,386),Vector2(350,372)]), Color.GREEN))
	scene.cleared = 0; scene.win_time = -1.0
	for index in range(3):
		var duration: float = scene.escape_duration(scene.arrows[index])
		var copy: Dictionary = scene.arrows[index].duplicate(true)
		copy.travel = scene.escape_distance(duration - 0.001)
		check(Rect2(12,157,516,526).has_point(scene.visible_points(copy)[0]), "Tail is still visible just before computed duration")
		copy.travel = scene.escape_distance(duration + 0.001)
		check(not Rect2(12,157,516,526).has_point(scene.visible_points(copy)[0]), "Tail is outside just after computed duration")
		scene.click_at(scene.arrows[index].points[-1])
		check(audio.flight_voices.has(index), "Each launched arrow gets its own synchronized voice")
		var voice: AudioStreamPlayer = audio.flight_voices[index]
		check(is_equal_approx(voice.stream.get_length() / voice.pitch_scale, duration), "Sound duration equals the exact flight duration")
	check(audio.flight_voices.size() == 3, "Rapid launches do not cut off earlier arrows")
	var elapsed: float = scene.arrows[0].escape_time
	var menu := Control.new(); scene.gallery = menu
	scene._process(0.2)
	check(scene.arrows[0].escape_time == elapsed and audio.flight_voices[0].stream_paused, "Menu pauses sound together with the arrow")
	menu.free(); scene.gallery = null
	for step in range(100):
		scene._process(0.01)
		for index in range(3):
			check(audio.flight_voices.has(index) == not scene.arrows[index].removed, "Sound stops on the exact arrow removal frame")
		if scene.cleared == 3: break
	check(scene.cleared == 3 and audio.flight_voices.is_empty(), "All sounds end with their individual flights")
	check(FeedbackAudio.bank.win.get_length() > 0.8, "Completion sound remains a separate cue")
	audio.play_escape(10,0.5); audio.set_enabled(false)
	check(audio.flight_voices.is_empty() and not audio.play_escape(11,0.5), "Mute stops and suppresses flight voices")
	audio.stop_all(); scene.queue_free(); await process_frame; await process_frame
	await create_timer(0.3).timeout
	if failures == 0: print("PASS reference audio matches each arrow flight, overlapping launches, menu pause, removal and mute")
	quit(1 if failures else 0)
