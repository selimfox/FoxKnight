class_name FeedbackController
extends Node

@export_category("Prototype Feedback")
@export_range(-30.0, 0.0, 1.0) var volume_db: float = -9.0
@export_range(0.0, 0.5, 0.01) var hit_flash_duration: float = 0.10

@onready var _slash_player: AudioStreamPlayer = $SlashAudio
@onready var _hit_player: AudioStreamPlayer = $HitAudio
@onready var _result_player: AudioStreamPlayer = $ResultAudio


func _ready() -> void:
	_slash_player.volume_db = volume_db
	_hit_player.volume_db = volume_db
	_result_player.volume_db = volume_db
	_slash_player.stream = _make_tone(620.0, 0.10, 0.65, -260.0)
	_hit_player.stream = _make_tone(150.0, 0.09, 0.8, -70.0)


func play_slash() -> void:
	_slash_player.play()


func play_hit(enemy: EnemyController) -> void:
	_hit_player.play()
	if not is_instance_valid(enemy):
		return
	var visual := enemy.get_node_or_null("Visual")
	if visual == null:
		return
	visual.modulate = Color(1.0, 1.0, 0.65)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, hit_flash_duration)


func play_result(victory: bool) -> void:
	_result_player.stream = _make_tone(520.0 if victory else 210.0, 0.24, 0.62, 260.0 if victory else -90.0)
	_result_player.play()


func _make_tone(frequency: float, seconds: float, amplitude: float, sweep: float = 0.0) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * seconds)
	var data := PackedByteArray()
	data.resize(sample_count)
	for sample_index in sample_count:
		var time := float(sample_index) / float(sample_rate)
		var progress := float(sample_index) / float(maxi(sample_count - 1, 1))
		var current_frequency := frequency + sweep * progress
		var envelope := 1.0 - progress
		var sample := sin(TAU * current_frequency * time) * amplitude * envelope
		data[sample_index] = int(clampf(128.0 + sample * 120.0, 0.0, 255.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream

