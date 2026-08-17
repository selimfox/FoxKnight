class_name PrototypeSlash
extends Node2D

signal hit_enemy(enemy: EnemyController)
signal finished(hit_count: int)

enum SlashMode {
	STRAIGHT,
	ARC,
}

@export_category("Prototype Slash")
@export_range(40.0, 700.0, 5.0) var distance: float = 400.0
@export_range(10.0, 240.0, 2.0) var width: float = 80.0
@export_range(0.05, 1.5, 0.01) var duration: float = 0.22
@export_range(0.5, 2.0, 0.05) var hitbox_tolerance_multiplier: float = 1.0

@export_category("Prototype Debug")
@export var show_slash_hitbox: bool = false

@onready var _visual: Sprite2D = $SlashVisual
@onready var _debug_line: Line2D = $HitboxDebug

var _arc_visual_active := false
var _arc_visual_radius := 0.0
var _arc_visual_progress := 0.0


func execute(
	player: PlayerController,
	origin: Vector2,
	mode: SlashMode,
	direction: Vector2,
	allowed_distance: float = -1.0,
	arc_radius: float = 90.0
) -> void:
	if mode == SlashMode.ARC:
		await _execute_arc(player, origin, direction, allowed_distance, arc_radius)
	else:
		await _execute_straight(player, origin, direction, allowed_distance)


func _execute_straight(
	player: PlayerController,
	origin: Vector2,
	direction: Vector2,
	allowed_distance: float
) -> void:
	global_position = origin
	var slash_direction := direction.normalized()
	if slash_direction == Vector2.ZERO:
		slash_direction = Vector2.RIGHT

	rotation = slash_direction.angle()
	var actual_distance := distance if allowed_distance < 0.0 else minf(distance, allowed_distance)
	actual_distance = maxf(actual_distance, 1.0)
	_configure_straight_visual(actual_distance)
	player.play_straight_attack_pose()

	await get_tree().physics_frame
	var hit_count := _query_straight_hits(player, origin, slash_direction, actual_distance)

	var target := origin + slash_direction * actual_distance
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(player, "global_position", target, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(_visual, "modulate", Color(1.0, 0.96, 0.72, 0.0), duration).set_trans(Tween.TRANS_QUAD)
	await tween.finished
	finished.emit(hit_count)
	queue_free()


func _execute_arc(
	player: PlayerController,
	origin: Vector2,
	direction: Vector2,
	allowed_distance: float,
	arc_radius: float
) -> void:
	global_position = origin
	var move_direction := direction.normalized()
	var actual_distance := maxf(allowed_distance, 0.0) if move_direction != Vector2.ZERO else 0.0
	var actual_radius := maxf(arc_radius * hitbox_tolerance_multiplier, 1.0)
	rotation = 0.0
	_configure_arc_visual(actual_radius)
	player.play_arc_attack_pose(duration)
	var target := origin + move_direction * actual_distance
	var hit_enemies: Dictionary = {}
	var circle := CircleShape2D.new()
	circle.radius = actual_radius
	var elapsed := 0.0
	while elapsed < duration:
		var progress := clampf(elapsed / duration, 0.0, 1.0)
		var eased_progress := 1.0 - pow(1.0 - progress, 4.0)
		player.global_position = origin.lerp(target, eased_progress)
		global_position = player.global_position
		_arc_visual_progress = progress
		modulate.a = lerpf(1.0, 0.42, progress)
		queue_redraw()
		_collect_circle_hits(player, circle, global_position, hit_enemies)
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	player.global_position = target
	global_position = target
	_arc_visual_progress = 1.0
	queue_redraw()
	_collect_circle_hits(player, circle, global_position, hit_enemies)
	finished.emit(hit_enemies.size())
	queue_free()


func _query_straight_hits(player: PlayerController, origin: Vector2, direction: Vector2, actual_distance: float) -> int:
	var query_shape := RectangleShape2D.new()
	query_shape.size = Vector2(actual_distance, width * hitbox_tolerance_multiplier)
	return _query_enemies(
		player,
		query_shape,
		Transform2D(direction.angle(), origin + direction * actual_distance * 0.5)
	)


func _collect_circle_hits(
	player: PlayerController,
	circle: CircleShape2D,
	center: Vector2,
	hit_enemies: Dictionary
) -> void:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, center)
	query.collision_mask = 4
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]

	var results := get_world_2d().direct_space_state.intersect_shape(query, 64)
	for result: Dictionary in results:
		var collider: Object = result.get("collider") as Object
		if not (collider is EnemyController):
			continue
		var enemy := collider as EnemyController
		var enemy_id := enemy.get_instance_id()
		if hit_enemies.has(enemy_id) or not enemy.is_alive():
			continue
		hit_enemies[enemy_id] = true
		enemy.take_hit()
		hit_enemy.emit(enemy)


func _query_enemies(player: PlayerController, query_shape: Shape2D, query_transform: Transform2D) -> int:

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = query_shape
	query.transform = query_transform
	query.collision_mask = 4
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [player.get_rid()]

	var results := get_world_2d().direct_space_state.intersect_shape(query, 64)
	var unique_enemies: Dictionary = {}
	for result: Dictionary in results:
		var collider: Object = result.get("collider") as Object
		if collider is EnemyController and collider.is_alive():
			unique_enemies[collider.get_instance_id()] = collider

	for enemy: EnemyController in unique_enemies.values():
		enemy.take_hit()
		hit_enemy.emit(enemy)

	return unique_enemies.size()


func _configure_straight_visual(actual_distance: float) -> void:
	_arc_visual_active = false
	_visual.visible = true
	var texture_size := _visual.texture.get_size()
	_visual.position = Vector2(actual_distance * 0.5, 0.0)
	_visual.scale = Vector2(actual_distance / texture_size.x, width / texture_size.y)

	var debug_half_width := width * hitbox_tolerance_multiplier * 0.5
	_debug_line.points = PackedVector2Array([
		Vector2(0.0, -debug_half_width),
		Vector2(actual_distance, -debug_half_width),
		Vector2(actual_distance, debug_half_width),
		Vector2(0.0, debug_half_width),
		Vector2(0.0, -debug_half_width),
	])
	_debug_line.visible = show_slash_hitbox or not is_equal_approx(hitbox_tolerance_multiplier, 1.0)
	queue_redraw()


func _configure_arc_visual(actual_radius: float) -> void:
	_visual.visible = false
	_arc_visual_active = true
	_arc_visual_radius = actual_radius
	_arc_visual_progress = 0.0
	_debug_line.points = _build_circle_outline(actual_radius)
	_debug_line.visible = show_slash_hitbox or not is_equal_approx(hitbox_tolerance_multiplier, 1.0)
	queue_redraw()


func _draw() -> void:
	if not _arc_visual_active or _arc_visual_radius <= 0.0:
		return
	var sweep_angle := _arc_visual_progress * TAU * 1.35
	var blade_start := sweep_angle - PI * 0.72
	var blade_end := sweep_angle + PI * 0.72
	draw_arc(Vector2.ZERO, _arc_visual_radius, 0.0, TAU, 64, Color(1.0, 0.62, 0.16, 0.22), 3.0, true)
	draw_arc(Vector2.ZERO, _arc_visual_radius * 0.82, blade_start, blade_end, 42, Color(1.0, 0.42, 0.08, 0.18), 22.0, true)
	draw_arc(Vector2.ZERO, _arc_visual_radius * 0.82, blade_start, blade_end, 42, Color(1.0, 0.78, 0.24, 0.92), 10.0, true)
	draw_arc(Vector2.ZERO, _arc_visual_radius * 0.82, blade_start + 0.08, blade_end - 0.08, 42, Color(1.0, 1.0, 0.82, 0.98), 3.0, true)
	draw_arc(Vector2.ZERO, _arc_visual_radius * 0.55, blade_start - 0.35, blade_end - 0.9, 28, Color(1.0, 0.68, 0.16, 0.72), 5.0, true)


func _build_circle_outline(actual_radius: float, segments: int = 48) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index: int in range(segments + 1):
		var angle := TAU * float(index) / float(segments)
		points.append(Vector2(cos(angle), sin(angle)) * actual_radius)
	return points


func is_arc_visual_active() -> bool:
	return _arc_visual_active


func get_arc_visual_radius() -> float:
	return _arc_visual_radius
