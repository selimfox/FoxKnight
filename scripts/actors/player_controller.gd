class_name PlayerController
extends CharacterBody2D

signal aim_started(target_position: Vector2)
signal aim_released(target_position: Vector2)
signal aim_cancel_requested

@export_category("Prototype Movement")
@export_range(40.0, 500.0, 5.0) var move_speed: float = 180.0
@export_range(0.0, 3000.0, 25.0) var acceleration: float = 1400.0
@export_range(0.0, 3000.0, 25.0) var deceleration: float = 1800.0
@export var default_facing: Vector2 = Vector2.RIGHT

@export_category("Prototype Visuals")
@export var idle_texture: Texture2D
@export var walk_texture: Texture2D
@export var ready_texture: Texture2D
@export var dash_texture: Texture2D

var _input_enabled := true
var _facing := Vector2.RIGHT
var _is_attacking := false
var _is_aiming := false
var _preview_distance := 0.0
var _preview_width := 0.0
var _preview_radius := 0.0
var _preview_deadzone_radius := 0.0
var _preview_mode := "NONE"
var _last_attack_pose := "NONE"

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite
@onready var _aim_preview: Node2D = $AimPreview
@onready var _aim_preview_fill: Polygon2D = $AimPreview/Fill
@onready var _aim_preview_center: Line2D = $AimPreview/CenterLine
@onready var _aim_preview_outline: Line2D = $AimPreview/Outline
@onready var _aim_preview_deadzone: Line2D = $AimPreview/DeadzoneOutline


func _ready() -> void:
	_facing = default_facing.normalized()
	if _facing == Vector2.ZERO:
		_facing = Vector2.RIGHT
	_update_facing_visual()


func _physics_process(delta: float) -> void:
	if not _input_enabled:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		var movement_direction := input_vector.normalized()
		velocity = velocity.move_toward(movement_direction * move_speed, acceleration * delta)
		if not _is_aiming:
			_facing = movement_direction
			_update_facing_visual()
		_set_movement_texture(true)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
		_set_movement_texture(false)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if not _input_enabled or not (event is InputEventMouseButton):
		return

	var mouse_event := event as InputEventMouseButton
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if mouse_event.pressed:
			aim_started.emit(get_global_mouse_position())
		else:
			aim_released.emit(get_global_mouse_position())
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
		aim_cancel_requested.emit()


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		clear_aim_preview()


func is_input_enabled() -> bool:
	return _input_enabled


func get_facing() -> Vector2:
	return _facing


func update_straight_aim_preview(direction: Vector2, distance: float, width: float) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO:
		set_aim_preview_invalid()
		return

	_is_aiming = true
	_facing = normalized_direction
	_preview_distance = distance
	_preview_width = width
	_preview_radius = 0.0
	_preview_deadzone_radius = 0.0
	_preview_mode = "STRAIGHT"
	_update_facing_visual()

	var half_width := width * 0.5
	var rectangle := PackedVector2Array([
		Vector2(0.0, -half_width),
		Vector2(distance, -half_width),
		Vector2(distance, half_width),
		Vector2(0.0, half_width),
	])
	var outline := PackedVector2Array([
		rectangle[0],
		rectangle[1],
		rectangle[2],
		rectangle[3],
		rectangle[0],
	])

	_aim_preview.rotation = normalized_direction.angle()
	_aim_preview_fill.polygon = rectangle
	_aim_preview_center.points = PackedVector2Array([Vector2.ZERO, Vector2(distance, 0.0)])
	_aim_preview_center.visible = true
	_aim_preview_outline.points = outline
	_aim_preview_deadzone.visible = false
	_aim_preview.visible = true


func update_aim_preview(direction: Vector2, distance: float, width: float) -> void:
	update_straight_aim_preview(direction, distance, width)


func update_arc_aim_preview(
	radius: float,
	deadzone_radius: float,
	move_direction: Vector2,
	move_distance: float
) -> void:
	var normalized_move := move_direction.normalized()
	_is_aiming = true
	if normalized_move != Vector2.ZERO:
		_facing = normalized_move
		_update_facing_visual()

	_preview_distance = move_distance
	_preview_width = radius * 2.0
	_preview_radius = radius
	_preview_deadzone_radius = maxf(deadzone_radius, 0.0)
	_preview_mode = "ARC"
	_aim_preview.rotation = 0.0

	var circle := _build_circle_points(radius)
	var outline := circle.duplicate()
	if not outline.is_empty():
		outline.append(outline[0])
	_aim_preview_fill.polygon = circle
	_aim_preview_center.points = _build_arrow_points(normalized_move, move_distance)
	_aim_preview_center.visible = normalized_move != Vector2.ZERO and move_distance > 0.0
	_aim_preview_outline.points = outline
	_aim_preview_deadzone.points = _build_circle_outline(_preview_deadzone_radius)
	_aim_preview_deadzone.visible = _preview_deadzone_radius > 0.0
	_aim_preview.visible = true


func set_aim_preview_invalid() -> void:
	_is_aiming = true
	_preview_distance = 0.0
	_preview_width = 0.0
	_preview_radius = 0.0
	_preview_deadzone_radius = 0.0
	_preview_mode = "NONE"
	_aim_preview.visible = false


func clear_aim_preview() -> void:
	_is_aiming = false
	_preview_distance = 0.0
	_preview_width = 0.0
	_preview_radius = 0.0
	_preview_deadzone_radius = 0.0
	_preview_mode = "NONE"
	_aim_preview.visible = false
	_update_facing_visual()


func is_aim_preview_visible() -> bool:
	return _aim_preview.visible


func get_aim_preview_distance() -> float:
	return _preview_distance


func get_aim_preview_width() -> float:
	return _preview_width


func get_aim_preview_radius() -> float:
	return _preview_radius


func get_aim_preview_deadzone_radius() -> float:
	return _preview_deadzone_radius


func is_aim_direction_arrow_visible() -> bool:
	return _aim_preview_center.visible and _preview_mode == "ARC"


func is_aim_deadzone_visible() -> bool:
	return _aim_preview_deadzone.visible and _preview_mode == "ARC"


func get_aim_preview_mode() -> String:
	return _preview_mode


func _build_circle_points(radius: float, segments: int = 40) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_radius := maxf(radius, 1.0)
	for index: int in range(segments):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * safe_radius)
	return points


func _build_circle_outline(radius: float, segments: int = 32) -> PackedVector2Array:
	var points := _build_circle_points(radius, segments)
	if not points.is_empty():
		points.append(points[0])
	return points


func _build_arrow_points(direction: Vector2, distance: float) -> PackedVector2Array:
	if direction == Vector2.ZERO or distance <= 0.0:
		return PackedVector2Array()
	var end := direction * distance
	var head_length := minf(14.0, maxf(distance * 0.3, 6.0))
	var left_head := end - direction.rotated(-0.55) * head_length
	var right_head := end - direction.rotated(0.55) * head_length
	return PackedVector2Array([
		Vector2.ZERO,
		end,
		left_head,
		end,
		right_head,
	])


func play_attack_pose() -> void:
	play_straight_attack_pose()


func play_straight_attack_pose() -> void:
	_last_attack_pose = "STRAIGHT"
	_is_attacking = true
	_visual.rotation = _facing.angle()
	_sprite.flip_h = false
	if ready_texture:
		_sprite.texture = ready_texture

	var tween := create_tween()
	tween.tween_interval(0.035)
	tween.tween_callback(func() -> void:
		if dash_texture:
			_sprite.texture = dash_texture
	)
	tween.tween_property(_visual, "scale", Vector2(1.25, 0.75), 0.06)
	tween.tween_property(_visual, "scale", Vector2.ONE, 0.14)
	tween.tween_callback(func() -> void:
		_is_attacking = false
		_set_movement_texture(false)
		_update_facing_visual()
	)


func play_arc_attack_pose(attack_duration: float) -> void:
	_last_attack_pose = "ARC"
	_is_attacking = true
	_visual.rotation = 0.0
	_sprite.flip_h = _facing.x < -0.05
	if ready_texture:
		_sprite.texture = ready_texture

	var pose_duration := maxf(attack_duration, 0.12)
	var spin_tween := create_tween()
	spin_tween.tween_interval(0.025)
	spin_tween.tween_callback(func() -> void:
		if dash_texture:
			_sprite.texture = dash_texture
	)
	spin_tween.tween_property(_visual, "rotation", TAU * 1.12, pose_duration - 0.025).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	spin_tween.tween_callback(func() -> void:
		_visual.rotation = 0.0
		_visual.scale = Vector2.ONE
		_is_attacking = false
		_set_movement_texture(false)
		_update_facing_visual()
	)

	var squash_tween := create_tween()
	squash_tween.tween_property(_visual, "scale", Vector2(1.16, 0.84), 0.05).set_trans(Tween.TRANS_QUAD)
	squash_tween.tween_property(_visual, "scale", Vector2.ONE, pose_duration - 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func get_last_attack_pose_name() -> String:
	return _last_attack_pose


func _update_facing_visual() -> void:
	if _is_attacking:
		return
	_visual.rotation = 0.0
	_sprite.flip_h = _facing.x < -0.05


func _set_movement_texture(moving: bool) -> void:
	if _is_attacking:
		return
	var target_texture := walk_texture if moving else idle_texture
	if target_texture and _sprite.texture != target_texture:
		_sprite.texture = target_texture
