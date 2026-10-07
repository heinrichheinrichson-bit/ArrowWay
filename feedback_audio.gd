class_name FeedbackAudio
extends Node

const SAMPLE_RATE := 44100
const ESCAPE_SOUND = preload("res://audio/arrow_escape.wav")
static var bank := {}
var enabled := true
var quiet := OS.get_cmdline_user_args().has("--test")
var voices: Array[AudioStreamPlayer] = []
var last_played := {}
var next_voice := 0
var flight_samples: Array = []
var flight_cache := {}
var flight_voices := {}
var flight_paused := false

func _ready() -> void:
	flight_samples = JSON.parse_string(FileAccess.get_file_as_string("res://audio/arrow_flight.json")).entries
	if bank.is_empty():
		bank["escape"] = ESCAPE_SOUND
		bank["blocked"] = synthesize([[185.0, 0.0, 0.10, 0.28]], 0.11)
		bank["release"] = synthesize([[880.0, 0.0, 0.14, 0.12]], 0.15)
		bank["hint"] = synthesize([[783.99, 0.0, 0.24, 0.25]], 0.25)
		bank["win"] = synthesize([[392.0, 0.0, 0.55, 0.27], [493.88, 0.12, 0.55, 0.24], [587.33, 0.24, 0.55, 0.24], [783.99, 0.36, 0.55, 0.22]], 0.95)
	for i in range(6):
		var player := AudioStreamPlayer.new()
		player.volume_db = -12.0
		add_child(player)
		voices.append(player)

static func synthesize(notes: Array, length_seconds: float) -> AudioStreamWAV:
	var count := int(ceil(length_seconds * SAMPLE_RATE))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var value := 0.0
		for note: Array in notes:
			var u := t - float(note[1])
			var duration: float = note[2]
			if u < 0.0 or u >= duration:
				continue
			var attack := pow(sin(minf(u / 0.008, 1.0) * PI * 0.5), 2.0)
			var release := pow(sin(minf((duration - u) / 0.028, 1.0) * PI * 0.5), 2.0)
			var phase := TAU * float(note[0]) * u
			var tone := sin(phase) + sin(phase * 2.0) * 0.20 + sin(phase * 4.0) * 0.055
			value += tone * attack * release * exp(-u * 7.0) * float(note[3])
		bytes.encode_s16(i * 2, int(round(clampf(value, -0.75, 0.75) * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		stop_all()

func stop_all() -> void:
	for id in flight_voices.keys(): stop_escape(id)
	for voice in voices:
		voice.stop()
	last_played.clear()

func play(cue: String) -> bool:
	if not enabled or quiet or not bank.has(cue) or voices.is_empty():
		return false
	var now := Time.get_ticks_msec()
	var cooldown := 45 if cue == "escape" else 140
	if now - int(last_played.get(cue, -10000)) < cooldown:
		return false
	last_played[cue] = now
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stop()
	voice.stream = bank[cue]
	voice.pitch_scale = 1.0
	voice.play()
	return true

func flight_stream(duration: float) -> AudioStreamWAV:
	var selected: Dictionary = flight_samples[0]
	var difference := INF
	for sample in flight_samples:
		var distance := absf(log(float(sample.duration) / maxf(duration, 0.01)))
		if distance < difference: selected = sample; difference = distance
	var path: String = selected.path
	if not flight_cache.has(path):
		if flight_cache.size() >= 8: flight_cache.erase(flight_cache.keys()[0])
		flight_cache[path] = load(path)
	return flight_cache[path]

func play_escape(id: int, duration: float, elapsed: float = 0.0) -> bool:
	if not enabled or quiet or duration <= elapsed or duration <= 0.0: return false
	if flight_voices.has(id): return true
	var player := AudioStreamPlayer.new()
	var stream := flight_stream(duration)
	player.stream = stream; player.pitch_scale = stream.get_length() / duration
	player.volume_db = -12.0
	add_child(player)
	flight_voices[id] = player
	player.play(elapsed * player.pitch_scale)
	player.stream_paused = flight_paused
	return true

func stop_escape(id: int) -> void:
	if not flight_voices.has(id): return
	var player: AudioStreamPlayer = flight_voices[id]
	player.stop(); player.queue_free(); flight_voices.erase(id)

func pause_escape(paused: bool) -> void:
	if flight_paused == paused: return
	flight_paused = paused
	for player in flight_voices.values(): player.stream_paused = paused
