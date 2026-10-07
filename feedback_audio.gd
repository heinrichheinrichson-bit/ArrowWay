class_name FeedbackAudio
extends Node

const SAMPLE_RATE := 44100
const ESCAPE_PITCHES := [0.98, 1.02, 1.0, 1.035, 0.965]
static var bank := {}
var enabled := true
var quiet := OS.get_cmdline_user_args().has("--test")
var voices: Array[AudioStreamPlayer] = []
var last_played := {}
var next_voice := 0
var note_index := 0

func _ready() -> void:
	if bank.is_empty():
		bank["escape"] = synthesize_escape()
		bank["blocked"] = synthesize([[185.0, 0.0, 0.10, 0.28]], 0.11)
		bank["release"] = synthesize([[880.0, 0.0, 0.14, 0.12]], 0.15)
		bank["hint"] = synthesize([[783.99, 0.0, 0.24, 0.25]], 0.25)
		bank["win"] = synthesize([[392.0, 0.0, 0.55, 0.27], [493.88, 0.12, 0.55, 0.24], [587.33, 0.24, 0.55, 0.24], [783.99, 0.36, 0.55, 0.22]], 0.95)
	for i in range(6):
		var player := AudioStreamPlayer.new()
		player.volume_db = -12.0
		add_child(player)
		voices.append(player)

static func synthesize_escape() -> AudioStreamWAV:
	# A short breath of air: remove the low thump and soften the very top end.
	const DURATION := 0.17
	var count := int(ceil(DURATION * SAMPLE_RATE))
	var bytes := PackedByteArray(); bytes.resize(count * 2)
	var random := RandomNumberGenerator.new(); random.seed = 640219
	var highpass_alpha := 1.0 / (1.0 + TAU * 1800.0 / SAMPLE_RATE)
	var lowpass_alpha := TAU * 5000.0 / (SAMPLE_RATE + TAU * 5000.0)
	var previous_noise := 0.0
	var highpass := 0.0
	var previous_highpass := 0.0
	var second_highpass := 0.0
	var softened := 0.0
	var airy := 0.0
	for index in range(count):
		var time := float(index) / SAMPLE_RATE
		var noise := random.randf_range(-1.0, 1.0)
		highpass = highpass_alpha * (highpass + noise - previous_noise)
		previous_noise = noise
		second_highpass = highpass_alpha * (second_highpass + highpass - previous_highpass)
		previous_highpass = highpass
		softened += lowpass_alpha * (second_highpass - softened)
		airy += lowpass_alpha * (softened - airy)
		var attack := pow(sin(minf(time / 0.018, 1.0) * PI * 0.5), 2.0)
		var release := pow(sin(minf((DURATION - time) / 0.035, 1.0) * PI * 0.5), 2.0)
		var envelope := attack * release * exp(-time * 11.0)
		bytes.encode_s16(index * 2, int(round(clampf(airy * envelope * 0.42, -0.75, 0.75) * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = SAMPLE_RATE; stream.stereo = false; stream.data = bytes
	return stream

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
	for voice in voices:
		voice.stop()
	last_played.clear()
	note_index = 0

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
	voice.pitch_scale = ESCAPE_PITCHES[note_index % ESCAPE_PITCHES.size()] if cue == "escape" else 1.0
	if cue == "escape":
		note_index += 1
	voice.play()
	return true
