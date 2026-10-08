class_name PixelFXPlayer
extends Node2D

# Cosmetic-only playback of the authored 16 px FX atlas. Never drives hit queries.
const FRAME_SIZE := 32
const COLUMNS := 8
const FRAME_SECONDS := 0.045
const HIT_ATLAS := preload("res://assets/art/production/fx/revision_20260930/export/hit.png")
const DEATH_ATLAS := preload("res://assets/art/production/fx/revision_20260930/export/death.png")
const SEQUENCES := {
	"hit": Vector2i(0, 4),
	"straight": Vector2i(6, 4),
	"arc": Vector2i(10, 4),
	"switch_warm": Vector2i(14, 4),
	"switch_cool": Vector2i(18, 4),
	"death": Vector2i(22, 4),
}

@export var atlas: Texture2D

var _sprites: Array[Sprite2D] = []
var _sequence := ""
var _elapsed := 0.0
var _one_shot := false
var _auto_free := true


func configure(sequence: String, positions: Array[Vector2], one_shot: bool = false, auto_free: bool = true) -> void:
	assert(SEQUENCES.has(sequence), "Unknown pixel FX sequence: " + sequence)
	_sequence = sequence
	_elapsed = 0.0
	_one_shot = one_shot
	_auto_free = auto_free
	for sprite in _sprites:
		sprite.queue_free()
	_sprites.clear()
	for point in positions:
		var sprite := Sprite2D.new()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.centered = true
		sprite.position = point.round()
		sprite.texture = _frame_texture(int(SEQUENCES[sequence].x))
		add_child(sprite)
		_sprites.append(sprite)
	set_process(true)


func set_point(index: int, point: Vector2) -> void:
	if index >= 0 and index < _sprites.size():
		_sprites[index].position = point.round()


func set_progress(progress: float) -> void:
	if not SEQUENCES.has(_sequence):
		return
	var sequence_info: Vector2i = SEQUENCES[_sequence]
	var local_frame := mini(int(floorf(clampf(progress, 0.0, 0.999) * float(sequence_info.y))), sequence_info.y - 1)
	_show_frame(sequence_info.x + local_frame)


func get_sequence_name() -> String:
	return _sequence


func get_sprite_count() -> int:
	return _sprites.size()


func clear() -> void:
	_sequence = ""
	set_process(false)
	for sprite in _sprites:
		sprite.visible = false


func _process(delta: float) -> void:
	if _sequence.is_empty():
		return
	_elapsed += delta
	var sequence_info: Vector2i = SEQUENCES[_sequence]
	var frame_seconds := 0.0225 if _sequence == "hit" else FRAME_SECONDS
	var local_frame := int(_elapsed / frame_seconds)
	if _one_shot and local_frame >= sequence_info.y:
		if _auto_free:
			queue_free()
		else:
			for sprite in _sprites:
				sprite.visible = false
			_sequence = ""
			set_process(false)
		return
	_show_frame(sequence_info.x + (local_frame % sequence_info.y))


func _show_frame(atlas_index: int) -> void:
	var frame_texture := _frame_texture(atlas_index)
	for sprite in _sprites:
		sprite.texture = frame_texture


func _frame_texture(atlas_index: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	if _sequence == "hit" or _sequence == "death":
		frame.atlas = HIT_ATLAS if _sequence == "hit" else DEATH_ATLAS
		frame.region = Rect2((atlas_index - int(SEQUENCES[_sequence].x)) * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
		return frame
	frame.atlas = atlas
	frame.region = Rect2(
		(atlas_index % COLUMNS) * FRAME_SIZE,
		int(atlas_index / COLUMNS) * FRAME_SIZE,
		FRAME_SIZE,
		FRAME_SIZE
	)
	return frame
