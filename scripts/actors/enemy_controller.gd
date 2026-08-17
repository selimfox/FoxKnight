class_name EnemyController
extends CharacterBody2D

signal died(enemy: EnemyController)

@export_category("Prototype Patrol")
@export_range(0.0, 300.0, 5.0) var move_speed: float = 45.0
@export var move_direction: Vector2 = Vector2.DOWN
@export_range(0.0, 300.0, 4.0) var patrol_distance: float = 48.0

@export_category("Prototype Debug")
@export var show_path: bool = false:
	set(value):
		show_path = value
		queue_redraw()
@export var show_state: bool = false

@export_category("Prototype Visuals")
@export var idle_texture: Texture2D
@export var walk_texture: Texture2D
@export var hit_texture: Texture2D
@export var death_texture: Texture2D

var _alive := true
var _origin := Vector2.ZERO
var _patrol_axis := Vector2.DOWN
var _travel_sign := 1.0

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite
@onready var _death_burst: Sprite2D = $Visual/DeathBurst
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _state_label: Label = $StateLabel


func _ready() -> void:
	_origin = global_position
	_patrol_axis = move_direction.normalized()
	if _patrol_axis == Vector2.ZERO:
		_patrol_axis = Vector2.DOWN
	_state_label.visible = show_state
	_state_label.text = "PATROL"
	if idle_texture:
		_sprite.texture = idle_texture
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not _alive:
		return

	var offset := (global_position - _origin).dot(_patrol_axis)
	if offset >= patrol_distance:
		_travel_sign = -1.0
	elif offset <= -patrol_distance:
		_travel_sign = 1.0

	velocity = _patrol_axis * move_speed * _travel_sign
	var movement_texture := walk_texture if not is_zero_approx(move_speed) else idle_texture
	if movement_texture:
		_sprite.texture = movement_texture
	_sprite.flip_h = velocity.x < -0.05
	move_and_slide()
	if show_path:
		queue_redraw()


func _draw() -> void:
	if not show_path:
		return
	var world_endpoints := get_patrol_path_world_endpoints()
	var start := to_local(world_endpoints[0])
	var finish := to_local(world_endpoints[1])
	draw_dashed_line(start, finish, Color(0.95, 0.42, 0.35, 0.65), 2.0, 7.0)
	draw_circle(start, 3.0, Color(0.95, 0.42, 0.35, 0.8))
	draw_circle(finish, 3.0, Color(0.95, 0.42, 0.35, 0.8))


func get_patrol_path_world_endpoints() -> PackedVector2Array:
	return PackedVector2Array([
		_origin - _patrol_axis * patrol_distance,
		_origin + _patrol_axis * patrol_distance,
	])


func take_hit() -> void:
	if not _alive:
		return

	_alive = false
	velocity = Vector2.ZERO
	set_physics_process(false)
	_collision_shape.set_deferred("disabled", true)
	collision_layer = 0
	collision_mask = 0
	_state_label.visible = show_state
	_state_label.text = "DEAD"
	died.emit(self)
	if hit_texture:
		_sprite.texture = hit_texture
	_sprite.flip_h = false

	await get_tree().create_timer(0.07).timeout
	if death_texture:
		_sprite.texture = death_texture
	_death_burst.visible = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "scale", Vector2(1.8, 0.25), 0.18).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(_visual, "modulate", Color(1.0, 0.8, 0.45, 0.0), 0.24)
	await tween.finished
	queue_free()


func is_alive() -> bool:
	return _alive
