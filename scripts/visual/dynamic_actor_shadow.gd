class_name DynamicActorShadow
extends Node2D

@export var frame_source: CharacterAnimation
@export var main_light_world_position := Vector2(-120.0, -120.0)
@export_range(0.0, 80.0, 1.0) var projection_length := 12.0
@export_range(0.0, 1.0, 0.01) var projection_alpha := 0.20
@export_range(0.0, 1.0, 0.01) var contact_alpha := 0.16

var _fade := 1.0
var _water_factor := 1.0


func set_water_shadow_factor(value: float) -> void:
	_water_factor = clampf(value, 0.0, 1.0)
	queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if frame_source != null:
		frame_source.visual_frame_changed.connect(queue_redraw)
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func set_shadow_fade(value: float) -> void:
	_fade = clampf(value, 0.0, 1.0)
	queue_redraw()


func get_projection_direction() -> Vector2:
	var direction := (global_position - main_light_world_position).normalized()
	return direction if direction != Vector2.ZERO else Vector2(0.7, 0.7).normalized()


func _draw() -> void:
	var lifted := frame_source != null and frame_source.get_animation_name() == "walk" and frame_source.get_frame_index() % 2 == 1
	var contact_opacity := contact_alpha * (0.64 if lifted else 1.0) * _fade * _water_factor
	_draw_contact_ellipse(17.0, 5.0, contact_opacity * 0.34)
	_draw_contact_ellipse(11.0, 3.0, contact_opacity * 0.66)
	if frame_source == null or frame_source.get_current_frame_texture() == null:
		return
	var light_direction := get_projection_direction()
	var side := light_direction.orthogonal()
	# Three tapered bands rotate with the light and shift with the walk pose.
	# An abstract cast shape reads as light on the ground, not duplicated sprite art.
	for layer in 3:
		var width_near := 8.0 + float(layer) * 2.0
		var width_far := 11.0 + float(layer) * 3.0
		var cast_length := projection_length * (0.72 + float(layer) * 0.14) * (1.08 if lifted else 1.0)
		var reach := light_direction * cast_length
		var points := PackedVector2Array([
			(side * width_near).round(),
			(-side * width_near).round(),
			(reach - side * width_far).round(),
			(reach + side * width_far).round(),
		])
		draw_colored_polygon(points, Color(0.025, 0.03, 0.06, projection_alpha * _fade * _water_factor / 3.0))


func _draw_contact_ellipse(horizontal_radius: float, vertical_radius: float, alpha: float) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(cos(angle) * horizontal_radius, sin(angle) * vertical_radius + 2.0))
	draw_colored_polygon(points, Color(0.025, 0.035, 0.07, alpha))
