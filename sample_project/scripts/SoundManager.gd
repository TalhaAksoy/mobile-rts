class_name SoundManager
extends Node

static var instance: SoundManager

func _init() -> void:
	instance = self

static func play_sound(sound_type: String) -> void:
	if instance != null:
		instance._play(sound_type)

func _play(sound_type: String) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = _create_sound_stream(sound_type)
	player.volume_db = -6.0
	player.play()
	player.finished.connect(func(): player.queue_free())

func _create_sound_stream(type: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	
	var duration: float = 0.2
	var samples_count = int(stream.mix_rate * duration)
	var data = PackedByteArray()
	data.resize(samples_count * 2)
	
	var freq: float = 440.0
	match type:
		"click":
			freq = 880.0
			duration = 0.05
		"build":
			freq = 320.0
			duration = 0.18
		"train":
			freq = 660.0
			duration = 0.22
		"attack":
			freq = 240.0
			duration = 0.12
		"shoot":
			freq = 550.0
			duration = 0.15
		"hit":
			freq = 180.0
			duration = 0.10
		"gather":
			freq = 500.0
			duration = 0.08
		"victory":
			freq = 523.25
			duration = 0.6
		"defeat":
			freq = 160.0
			duration = 0.7
		_:
			freq = 440.0
	
	samples_count = int(stream.mix_rate * duration)
	data.resize(samples_count * 2)
	
	for i in range(samples_count):
		var t = float(i) / float(stream.mix_rate)
		var env = 1.0 - (float(i) / float(samples_count))
		var sample_val: float = 0.0
		
		if type == "shoot":
			# Noise sweep
			var f = freq * (1.0 - (t / duration) * 0.7)
			sample_val = sin(t * f * TAU) * env
		elif type == "attack" or type == "hit":
			# Distorted impact
			var f = freq * (1.0 - (t / duration) * 0.5)
			var n = (randf() * 2.0 - 1.0) * 0.4
			sample_val = clamp(sin(t * f * TAU) + n, -1.0, 1.0) * env
		elif type == "victory":
			# Fanfare arpeggio
			var step = int(t * 12.0) % 3
			var f = freq * (1.0 if step == 0 else (1.25 if step == 1 else 1.5))
			sample_val = sin(t * f * TAU) * env
		elif type == "defeat":
			var f = freq * (1.0 - (t / duration) * 0.4)
			sample_val = sin(t * f * TAU) * env
		else:
			sample_val = sin(t * freq * TAU) * env
			
		var val_int = int(clamp(sample_val, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, val_int)
		
	stream.data = data
	return stream
