class_name EnemyController
extends CharacterBody2D

signal died(enemy: EnemyController)

@export_category("Chase Soldier")
@export_range(0.0, 300.0, 5.0) var move_speed: float = 45.0
@export_range(0.0, 4000.0, 10.0) var detection_radius: float = 0.0 # 0 = entire level
@export_range(8.0, 96.0, 1.0) var stop_distance: float = 28.0

@export_category("Prototype Debug")
@export var show_path: bool = false:
	set(value):
		show_path = value
		queue_redraw()
@export var show_state: bool = false

@export_category("Prototype Visuals")

var _alive := true
var _target: PlayerController
var _arena: TileArena
var _facing := Vector2.DOWN

@onready var _visual: Node2D = $Visual
@onready var _sprite: CharacterAnimation = $Visual/Sprite
@onready var _ground_shadow: DynamicActorShadow = $GroundShadow
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _state_label: Label = $StateLabel


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_target = get_node_or_null("../../Player") as PlayerController
	_arena = get_node_or_null("../../../Arena") as TileArena
	_state_label.visible = show_state
	_state_label.text = "CHASE"
	_sprite.play("idle", _cardinal_direction())
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if not _alive:
		return
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	var displacement := _target.global_position - global_position
	var target_distance := displacement.length()
	var in_range := detection_radius <= 0.0 or target_distance <= detection_radius
	if in_range and target_distance > stop_distance:
		var chase_point := _target.global_position
		if is_instance_valid(_arena):
			chase_point = _arena.get_next_path_point(global_position, chase_point)
		velocity = global_position.direction_to(chase_point) * move_speed
	else:
		velocity = Vector2.ZERO
	if velocity != Vector2.ZERO:
		_facing = velocity.normalized()
	_sprite.play("walk" if velocity != Vector2.ZERO else "idle", _cardinal_direction())
	move_and_slide()
	if show_path:
		queue_redraw()


func _draw() -> void:
	if show_path and is_instance_valid(_target) and _alive:
		draw_dashed_line(Vector2.ZERO, to_local(_target.global_position), Color(0.95, 0.42, 0.35, 0.65), 2.0, 7.0)


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
	_sprite.play("hit", _cardinal_direction(), false)

	await get_tree().create_timer(0.10).timeout
	_sprite.play("death", _cardinal_direction(), false, 0.26)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_visual, "modulate", Color(1.0, 0.8, 0.45, 0.0), 0.30).set_delay(0.20)
	tween.tween_method(_ground_shadow.set_shadow_fade, 1.0, 0.0, 0.30).set_delay(0.15)
	await tween.finished
	queue_free()


func is_alive() -> bool:
	return _alive


func _cardinal_direction() -> String:
	if absf(_facing.x) >= absf(_facing.y):
		return "side" if _facing.x >= 0.0 else "left"
	return "front" if _facing.y >= 0.0 else "back"


func get_current_animation_frame_texture() -> Texture2D:
	return _sprite.get_current_frame_texture()


func get_visual_foot_anchor_global() -> Vector2:
	return _sprite.to_global(_sprite.get_frame_foot_anchor())
