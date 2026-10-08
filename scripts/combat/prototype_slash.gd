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

@onready var _debug_line: Line2D = $HitboxDebug
const ARC_BLADE := preload("res://assets/art/production/fx/revision_20260930/export/arc_blade.png")
const STRAIGHT_BLADE := preload("res://assets/art/production/fx/revision_20260930/export/straight_blade.png")
const STRAIGHT_TIP := preload("res://assets/art/production/fx/revision_20260930/export/straight_tip.png")

var _arc_visual_active := false
var _arc_visual_radius := 0.0
var _arc_visual_progress := 0.0
var _execution_visual_language := "NONE"
var _actual_visual_distance := 0.0
var _straight_visual_progress := 0.0
var _query_started := false


func execute(
	player: PlayerController,
	origin: Vector2,
	mode: SlashMode,
	direction: Vector2,
	allowed_distance: float = -1.0,
	arc_radius: float = 90.0
) -> void:
	if mode == SlashMode.ARC:
		await _execute_arc(player, origin, arc_radius)
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
	_query_started = true
	queue_redraw()

	var target := origin + slash_direction * actual_distance
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(player, "global_position", target, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_straight_progress, 0.0, 1.0, duration)
	await tween.finished
	finished.emit(hit_count)
	queue_free()


func _execute_arc(
	player: PlayerController,
	origin: Vector2,
	arc_radius: float
) -> void:
	global_position = origin
	player.global_position = origin
	var actual_radius := maxf(arc_radius * hitbox_tolerance_multiplier, 1.0)
	rotation = 0.0
	_configure_arc_visual(actual_radius)
	player.play_arc_attack_pose(duration)
	var hit_enemies: Dictionary = {}
	var circle := CircleShape2D.new()
	circle.radius = actual_radius
	var elapsed := 0.0
	while elapsed < duration:
		var progress := clampf(elapsed / duration, 0.0, 1.0)
		_arc_visual_progress = progress
		modulate.a = lerpf(1.0, 0.42, progress)
		queue_redraw()
		_collect_circle_hits(player, circle, origin, hit_enemies)
		_query_started = true
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	player.global_position = origin
	global_position = origin
	_arc_visual_progress = 1.0
	queue_redraw()
	_collect_circle_hits(player, circle, origin, hit_enemies)
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
	_execution_visual_language = "COOL_STRAIGHT"
	_actual_visual_distance = actual_distance
	_straight_visual_progress = 0.0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var debug_half_width := width * hitbox_tolerance_multiplier * 0.5
	_debug_line.points = PackedVector2Array([
		Vector2(0.0, -debug_half_width),
		Vector2(actual_distance, -debug_half_width),
		Vector2(actual_distance, debug_half_width),
		Vector2(0.0, debug_half_width),
		Vector2(0.0, -debug_half_width),
	])
	_debug_line.default_color = Color(0.25, 0.82, 1.0, 0.95)
	_debug_line.visible = show_slash_hitbox or not is_equal_approx(hitbox_tolerance_multiplier, 1.0)
	queue_redraw()


func _configure_arc_visual(actual_radius: float) -> void:
	_arc_visual_active = true
	_execution_visual_language = "WARM_ARC"
	_arc_visual_radius = actual_radius
	_arc_visual_progress = 0.0
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_debug_line.points = _build_circle_outline(actual_radius)
	_debug_line.default_color = Color(1.0, 0.58, 0.14, 0.95)
	_debug_line.visible = show_slash_hitbox or not is_equal_approx(hitbox_tolerance_multiplier, 1.0)
	queue_redraw()


func _set_straight_progress(progress: float) -> void:
	_straight_visual_progress = progress
	queue_redraw()


func _draw() -> void:
	if not _query_started:
		return
	if _arc_visual_active:
		# The entire actual circle is already live. The bright local blade is an
		# action trail, never a claim of sequential angular damage activation.
		draw_colored_polygon(_build_circle_outline(_arc_visual_radius, 96), Color(0.95, 0.65, 0.24, 0.055))
		var frame := mini(5, int(_arc_visual_progress * 6.0))
		if is_equal_approx(_arc_visual_radius, 110.0):
			draw_texture_rect_region(ARC_BLADE, Rect2(-120, -120, 240, 240), Rect2(frame * 240, 0, 240, 240))
		else:
			# Parameterized test scenes retain their true radius without stretching
			# the approved 110px raster into an unrelated-size pixel asset.
			var angle := _arc_visual_progress * TAU
			draw_arc(Vector2.ZERO, maxf(0.0, _arc_visual_radius - 2.0), angle - 1.4, angle, 36, Color(1.0, 0.8, 0.44), 2.0, false)
	else:
		var fade := 1.0 - _straight_visual_progress
		var actual_width := width * hitbox_tolerance_multiplier
		draw_rect(Rect2(0.0, -actual_width * 0.5, _actual_visual_distance, actual_width), Color(0.42, 0.80, 0.88, 0.11 * fade))
		var frame := mini(3, int(_straight_visual_progress * 4.0))
		# The authored texture points down. Rotate the draw basis to point along
		# local +X, then tile/crop without scaling either source dimension.
		draw_set_transform(Vector2.ZERO, -PI * 0.5)
		var tip_length := minf(32.0, _actual_visual_distance)
		var body_length := _actual_visual_distance - tip_length
		var along := 0.0
		while along < body_length:
			var segment := minf(72.0, body_length - along)
			draw_texture_rect_region(STRAIGHT_BLADE, Rect2(-16.0, along, 32.0, segment), Rect2(frame * 32, 0, 32.0, segment), Color(1, 1, 1, fade))
			along += segment
		draw_texture_rect_region(STRAIGHT_TIP, Rect2(-16.0, body_length, 32.0, tip_length), Rect2(frame * 32, 32.0 - tip_length, 32.0, tip_length), Color(1, 1, 1, fade))
		draw_set_transform(Vector2.ZERO)


func has_execution_coverage() -> bool:
	return _query_started


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


func get_execution_visual_language() -> String:
	return _execution_visual_language
