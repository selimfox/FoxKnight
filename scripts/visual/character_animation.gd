class_name CharacterAnimation
extends Sprite2D

signal visual_frame_changed

@export var atlas: Texture2D
@export_enum("fox", "soldier") var actor_key := "fox"
@export_file("*.json") var frame_manifest := "res://assets/art/production/characters/e_20260930/frames.json"

var _frames: Dictionary = {}
var _animation := ""
var _direction := ""
var _frame_index := 0
var _elapsed := 0.0
var _loop := true
var _time_scale := 1.0
var _foot_anchor := Vector2(24.0, 50.0)


func _ready() -> void:
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_load_manifest()
	play("idle", "front")


func _process(delta: float) -> void:
	var sequence: Array = _frames.get(_animation + "/" + _direction, [])
	if sequence.size() < 2:
		return
	_elapsed += delta * _time_scale
	var duration := float(sequence[_frame_index]["duration_ms"]) / 1000.0
	while _elapsed >= duration and duration > 0.0:
		_elapsed -= duration
		if _frame_index == sequence.size() - 1 and not _loop:
			_elapsed = 0.0
			return
		_frame_index = (_frame_index + 1) % sequence.size()
		_apply_frame(sequence[_frame_index])
		duration = float(sequence[_frame_index]["duration_ms"]) / 1000.0


func play(animation: String, direction: String, loop_animation: bool = true, target_duration: float = 0.0) -> void:
	var key := animation + "/" + direction
	if not _frames.has(key):
		return
	if animation == _animation and direction == _direction and loop_animation == _loop and target_duration <= 0.0:
		return
	_animation = animation
	_direction = direction
	_loop = loop_animation
	_frame_index = 0
	_elapsed = 0.0
	var sequence: Array = _frames[key]
	var nominal_duration := 0.0
	for frame: Dictionary in sequence:
		nominal_duration += float(frame["duration_ms"]) / 1000.0
	_time_scale = nominal_duration / target_duration if target_duration > 0.0 else 1.0
	_apply_frame(sequence[0])


func get_current_frame_texture() -> Texture2D:
	return texture


func get_foot_anchor_local() -> Vector2:
	return Vector2.ZERO


func get_frame_foot_anchor() -> Vector2:
	return _foot_anchor


func get_animation_name() -> String:
	return _animation


func get_direction_name() -> String:
	return _direction


func get_frame_index() -> int:
	return _frame_index


func get_frame_count(animation: String, direction: String) -> int:
	return (_frames.get(animation + "/" + direction, []) as Array).size()


func _load_manifest() -> void:
	if not FileAccess.file_exists(frame_manifest):
		push_error("Character frame manifest not found: " + frame_manifest)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(frame_manifest))
	if not (parsed is Dictionary) or not parsed.has(actor_key):
		push_error("Character frame manifest missing actor: " + actor_key)
		return
	for entry: Dictionary in parsed[actor_key]["frames"]:
		var key: String = str(entry["animation"]) + "/" + str(entry["direction"])
		if not _frames.has(key):
			_frames[key] = []
		_frames[key].append(entry)


func _apply_frame(frame: Dictionary) -> void:
	if atlas == null:
		return
	var rect: Array = frame["rect"]
	var anchor: Array = frame["foot_anchor"]
	var current := AtlasTexture.new()
	current.atlas = atlas
	current.region = Rect2(float(rect[0]) * 2.0, float(rect[1]) * 2.0, float(rect[2]) * 2.0, float(rect[3]) * 2.0)
	texture = current
	_foot_anchor = Vector2(float(anchor[0]), float(anchor[1])) * 2.0
	position = -_foot_anchor
	visual_frame_changed.emit()
