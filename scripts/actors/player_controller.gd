class_name PlayerController
extends CharacterBody2D

const ARC_FILL_COLOR := Color(1.0, 0.44, 0.08, 0.20)
const ARC_LINE_COLOR := Color(1.0, 0.78, 0.22, 0.96)
const ARC_OUTLINE_COLOR := Color(1.0, 0.58, 0.14, 0.92)
const STRAIGHT_FILL_COLOR := Color(0.10, 0.72, 1.0, 0.18)
const STRAIGHT_LINE_COLOR := Color(0.62, 0.95, 1.0, 0.96)
const STRAIGHT_OUTLINE_COLOR := Color(0.25, 0.82, 1.0, 0.92)
const ARC_BOUNDARY_MIN_ALPHA := 0.12
const ARC_BOUNDARY_MAX_ALPHA := 0.24
const ARC_BOUNDARY_BREATH_PERIOD := 1.6
const FORM_SWITCH_FLASH_DURATION := 0.18

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
var _preview_arc_boundary_radius := 0.0
var _preview_mode := "NONE"
var _preview_visual_language := "NONE"
var _arc_boundary_visual_language := "NONE"
var _arc_boundary_breath_elapsed := 0.0
var _last_attack_pose := "NONE"
var _form_switch_feedback_count := 0
var _form_switch_tween: Tween

@onready var _visual: Node2D = $Visual
@onready var _sprite: Sprite2D = $Visual/Sprite
@onready var _aim_preview: Node2D = $AimPreview
@onready var _aim_preview_fill: Polygon2D = $AimPreview/Fill
@onready var _aim_preview_center: Line2D = $AimPreview/CenterLine
@onready var _aim_preview_outline: Line2D = $AimPreview/Outline
@onready var _aim_preview_arc_boundary: Line2D = $AimPreview/ArcBoundaryOutline
@onready var _aim_preview_form_switch_flash: Line2D = $AimPreview/FormSwitchFlash
@onready var _form_switch_audio: AudioStreamPlayer = $FormSwitchAudio


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


func _process(delta: float) -> void:
	if not _aim_preview_arc_boundary.visible:
		return

	_arc_boundary_breath_elapsed = fmod(
		_arc_boundary_breath_elapsed + delta,
		ARC_BOUNDARY_BREATH_PERIOD
	)
	var breath_phase := _arc_boundary_breath_elapsed / ARC_BOUNDARY_BREATH_PERIOD * TAU - PI * 0.5
	var breath_weight := (sin(breath_phase) + 1.0) * 0.5
	_aim_preview_arc_boundary.modulate.a = lerpf(
		ARC_BOUNDARY_MIN_ALPHA,
		ARC_BOUNDARY_MAX_ALPHA,
		breath_weight
	)


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


func update_straight_aim_preview(
	direction: Vector2,
	distance: float,
	width: float,
	form_threshold_radius: float = 0.0
) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO:
		set_aim_preview_invalid()
		return

	var previous_mode := _preview_mode
	_is_aiming = true
	_facing = normalized_direction
	_preview_distance = distance
	_preview_width = width
	_preview_radius = 0.0
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
	_apply_form_preview_visuals("STRAIGHT", previous_mode, form_threshold_radius)
	_aim_preview.visible = true


func update_aim_preview(direction: Vector2, distance: float, width: float) -> void:
	update_straight_aim_preview(direction, distance, width)


func update_arc_aim_preview(radius: float) -> void:
	var previous_mode := _preview_mode
	_is_aiming = true

	_preview_distance = 0.0
	_preview_width = radius * 2.0
	_preview_radius = radius
	_preview_mode = "ARC"
	_aim_preview.rotation = 0.0

	var circle := _build_circle_points(radius)
	var outline := circle.duplicate()
	if not outline.is_empty():
		outline.append(outline[0])
	_aim_preview_fill.polygon = circle
	_aim_preview_center.points = PackedVector2Array()
	_aim_preview_center.visible = false
	_aim_preview_outline.points = outline
	_apply_form_preview_visuals("ARC", previous_mode, radius)
	_aim_preview.visible = true


func set_aim_preview_invalid() -> void:
	_is_aiming = true
	_preview_distance = 0.0
	_preview_width = 0.0
	_preview_radius = 0.0
	_preview_arc_boundary_radius = 0.0
	_preview_mode = "NONE"
	_preview_visual_language = "NONE"
	_arc_boundary_visual_language = "NONE"
	_arc_boundary_breath_elapsed = 0.0
	_aim_preview_arc_boundary.scale = Vector2.ONE
	_aim_preview_arc_boundary.modulate = Color(1.0, 1.0, 1.0, ARC_BOUNDARY_MIN_ALPHA)
	_aim_preview_arc_boundary.visible = false
	_aim_preview.visible = false


func clear_aim_preview() -> void:
	_is_aiming = false
	_preview_distance = 0.0
	_preview_width = 0.0
	_preview_radius = 0.0
	_preview_arc_boundary_radius = 0.0
	_preview_mode = "NONE"
	_preview_visual_language = "NONE"
	_arc_boundary_visual_language = "NONE"
	_arc_boundary_breath_elapsed = 0.0
	_aim_preview_arc_boundary.scale = Vector2.ONE
	_aim_preview_arc_boundary.modulate = Color(1.0, 1.0, 1.0, ARC_BOUNDARY_MIN_ALPHA)
	_aim_preview_arc_boundary.visible = false
	_stop_form_switch_flash()
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


func get_aim_arc_boundary_radius() -> float:
	return _preview_arc_boundary_radius


func is_aim_arc_boundary_visible() -> bool:
	return _aim_preview_arc_boundary.visible and _aim_preview.visible


func is_form_switch_flash_visible() -> bool:
	return _aim_preview_form_switch_flash.visible


func get_form_switch_feedback_count() -> int:
	return _form_switch_feedback_count


func has_form_switch_audio_stream() -> bool:
	return _form_switch_audio.stream != null


func get_aim_preview_visual_language() -> String:
	return _preview_visual_language


func get_aim_arc_boundary_visual_language() -> String:
	return _arc_boundary_visual_language


func get_aim_arc_boundary_alpha() -> float:
	return _aim_preview_arc_boundary.modulate.a


func get_aim_arc_boundary_scale() -> Vector2:
	return _aim_preview_arc_boundary.scale


func get_aim_arc_boundary_line_width() -> float:
	return _aim_preview_arc_boundary.width


func get_aim_preview_mode() -> String:
	return _preview_mode


func _apply_form_preview_visuals(mode: String, previous_mode: String, arc_boundary_radius: float) -> void:
	_preview_arc_boundary_radius = maxf(arc_boundary_radius, 0.0)
	_aim_preview_arc_boundary.points = _build_circle_outline(_preview_arc_boundary_radius, 64)
	_aim_preview_arc_boundary.scale = Vector2.ONE
	_aim_preview_arc_boundary.visible = mode == "STRAIGHT" and _preview_arc_boundary_radius > 0.0

	if mode == "ARC":
		_preview_visual_language = "WARM_ARC"
		_arc_boundary_visual_language = "MERGED_WITH_ARC_RANGE"
		_aim_preview_fill.color = ARC_FILL_COLOR
		_aim_preview_center.default_color = ARC_LINE_COLOR
		_aim_preview_outline.default_color = ARC_OUTLINE_COLOR
	else:
		_preview_visual_language = "COOL_STRAIGHT"
		_arc_boundary_visual_language = "WARM_ARC_PREVIEW"
		_aim_preview_arc_boundary.default_color = Color(
			ARC_LINE_COLOR.r,
			ARC_LINE_COLOR.g,
			ARC_LINE_COLOR.b,
			1.0
		)
		_aim_preview_fill.color = STRAIGHT_FILL_COLOR
		_aim_preview_center.default_color = STRAIGHT_LINE_COLOR
		_aim_preview_outline.default_color = STRAIGHT_OUTLINE_COLOR

	if previous_mode != mode:
		_arc_boundary_breath_elapsed = 0.0
		_aim_preview_arc_boundary.modulate = Color(1.0, 1.0, 1.0, ARC_BOUNDARY_MIN_ALPHA)

	if previous_mode != "NONE" and previous_mode != mode:
		_play_form_switch_feedback(mode)


func _play_form_switch_feedback(mode: String) -> void:
	_form_switch_feedback_count += 1
	if _form_switch_tween != null and _form_switch_tween.is_valid():
		_form_switch_tween.kill()

	_aim_preview_form_switch_flash.points = _build_circle_outline(_preview_arc_boundary_radius, 64)
	_aim_preview_form_switch_flash.default_color = ARC_LINE_COLOR if mode == "ARC" else STRAIGHT_LINE_COLOR
	_aim_preview_form_switch_flash.scale = Vector2.ONE * 0.96
	_aim_preview_form_switch_flash.modulate = Color.WHITE
	_aim_preview_form_switch_flash.visible = _preview_arc_boundary_radius > 0.0

	_form_switch_tween = create_tween()
	_form_switch_tween.set_parallel(true)
	_form_switch_tween.tween_property(
		_aim_preview_form_switch_flash,
		"scale",
		Vector2.ONE * 1.08,
		FORM_SWITCH_FLASH_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_form_switch_tween.tween_property(
		_aim_preview_form_switch_flash,
		"modulate",
		Color(1.0, 1.0, 1.0, 0.0),
		FORM_SWITCH_FLASH_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_form_switch_tween.finished.connect(func() -> void:
		_aim_preview_form_switch_flash.visible = false
	)

	if _form_switch_audio.stream != null:
		_form_switch_audio.pitch_scale = 0.94 if mode == "ARC" else 1.06
		_form_switch_audio.play()


func _stop_form_switch_flash() -> void:
	if _form_switch_tween != null and _form_switch_tween.is_valid():
		_form_switch_tween.kill()
	_aim_preview_form_switch_flash.visible = false
	_aim_preview_form_switch_flash.scale = Vector2.ONE
	_aim_preview_form_switch_flash.modulate = Color.WHITE


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
