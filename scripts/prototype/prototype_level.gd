class_name PrototypeLevel
extends Node2D

enum RoundState {
	INITIALIZING,
	OBSERVING,
	AIMING,
	EXECUTING,
	RESOLVED,
}

const SLASH_SCENE := preload("res://scenes/combat/prototype_slash.tscn")
const ARENA_BOUNDS := Rect2(62.0, 72.0, 836.0, 396.0)

@export_category("Prototype Flow")
@export_range(0.0, 1.0, 0.01) var settlement_delay: float = 0.18

@export_category("Prototype Slash Forms")
@export_range(24.0, 400.0, 4.0) var slash_form_distance_threshold: float = 180.0
@export_range(24.0, 240.0, 2.0) var arc_radius: float = 90.0
@export_range(0.0, 240.0, 2.0) var arc_move_distance: float = 80.0
@export_range(0.0, 160.0, 1.0) var arc_direction_deadzone_radius: float = 24.0

@export_category("Prototype Debug")
@export var show_round_state: bool = false

var round_state := RoundState.INITIALIZING
var attack_committed := false
var state_history: Array[String] = []
var _prepared_slash: PrototypeSlash
var _aim_direction := Vector2.ZERO
var _aim_distance := 0.0
var _aim_valid := false
var _aim_mode := PrototypeSlash.SlashMode.STRAIGHT

@onready var _player: PlayerController = $Actors/Player
@onready var _enemies: Node2D = $Actors/Enemies
@onready var _effects: Node2D = $Effects
@onready var _feedback: FeedbackController = $FeedbackController
@onready var _hud: PrototypeHUD = $HUD


func _enter_tree() -> void:
	_ensure_input_actions()


func _ready() -> void:
	_state_history_push(RoundState.INITIALIZING)
	_player.aim_started.connect(_on_aim_started)
	_player.aim_released.connect(_on_aim_released)
	_player.aim_cancel_requested.connect(_on_aim_cancel_requested)
	_hud.retry_requested.connect(retry)
	for enemy: EnemyController in _enemies.get_children():
		enemy.died.connect(_on_enemy_died)

	_hud.set_attack_count(1)
	_hud.set_enemy_count(get_alive_enemy_count())
	_hud.set_observing_hint()
	await get_tree().process_frame
	_set_state(RoundState.OBSERVING)


func _exit_tree() -> void:
	_cleanup_prepared_slash()


func _process(_delta: float) -> void:
	if round_state == RoundState.AIMING:
		_update_aim(_player.get_global_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if round_state == RoundState.RESOLVED and event.is_action_pressed("retry"):
		retry()


func _on_aim_started(target_position: Vector2) -> void:
	if round_state != RoundState.OBSERVING or attack_committed:
		return

	_cleanup_prepared_slash()
	_prepared_slash = SLASH_SCENE.instantiate()
	_set_state(RoundState.AIMING)
	_hud.set_aiming_hint()
	_update_aim(target_position)


func _on_aim_released(target_position: Vector2) -> void:
	if round_state != RoundState.AIMING or attack_committed:
		return

	_update_aim(target_position)
	if not _aim_valid:
		_cancel_aim()
		return

	_commit_attack()


func _on_aim_cancel_requested() -> void:
	if round_state == RoundState.AIMING and not attack_committed:
		_cancel_aim()


func _cancel_aim() -> void:
	_player.clear_aim_preview()
	_cleanup_prepared_slash()
	_aim_direction = Vector2.ZERO
	_aim_distance = 0.0
	_aim_valid = false
	_aim_mode = PrototypeSlash.SlashMode.STRAIGHT
	_set_state(RoundState.OBSERVING)
	_hud.set_observing_hint()


func _commit_attack() -> void:
	var origin := _player.global_position
	var direction := _aim_direction
	var allowed_distance := _aim_distance
	var slash_mode := _aim_mode
	var slash := _prepared_slash
	_prepared_slash = null
	if slash == null:
		slash = SLASH_SCENE.instantiate()

	attack_committed = true
	_set_state(RoundState.EXECUTING)
	_player.set_input_enabled(false)
	_hud.set_attack_count(0)
	_hud.set_executing_hint()
	_feedback.play_slash()

	_effects.add_child(slash)
	slash.hit_enemy.connect(_on_slash_hit_enemy)
	slash.finished.connect(_on_slash_finished)
	slash.execute(_player, origin, slash_mode, direction, allowed_distance, arc_radius)


func _update_aim(target_position: Vector2) -> void:
	if round_state != RoundState.AIMING or _prepared_slash == null:
		return

	var aim_vector := target_position - _player.global_position
	var mouse_distance := aim_vector.length()
	_aim_valid = true
	if mouse_distance < slash_form_distance_threshold:
		_aim_mode = PrototypeSlash.SlashMode.ARC
		if mouse_distance < arc_direction_deadzone_radius or is_zero_approx(mouse_distance):
			_aim_direction = Vector2.ZERO
			_aim_distance = 0.0
		else:
			_aim_direction = aim_vector.normalized()
			_aim_distance = _calculate_allowed_slash_distance(
				_player.global_position,
				_aim_direction,
				arc_move_distance
			)
		var effective_radius := arc_radius * _prepared_slash.hitbox_tolerance_multiplier
		_player.update_arc_aim_preview(
			effective_radius,
			arc_direction_deadzone_radius,
			_aim_direction,
			_aim_distance
		)
		return

	_aim_mode = PrototypeSlash.SlashMode.STRAIGHT
	_aim_direction = aim_vector.normalized()
	_aim_distance = _calculate_allowed_slash_distance(
		_player.global_position,
		_aim_direction,
		_prepared_slash.distance
	)
	var effective_width := _prepared_slash.width * _prepared_slash.hitbox_tolerance_multiplier
	_player.update_straight_aim_preview(_aim_direction, _aim_distance, effective_width)


func _calculate_allowed_slash_distance(origin: Vector2, direction: Vector2, maximum_distance: float) -> float:
	if maximum_distance <= 0.0 or direction == Vector2.ZERO:
		return 0.0
	var allowed_distance := maximum_distance
	if direction.x > 0.0:
		allowed_distance = minf(allowed_distance, (ARENA_BOUNDS.end.x - origin.x) / direction.x)
	elif direction.x < 0.0:
		allowed_distance = minf(allowed_distance, (ARENA_BOUNDS.position.x - origin.x) / direction.x)
	if direction.y > 0.0:
		allowed_distance = minf(allowed_distance, (ARENA_BOUNDS.end.y - origin.y) / direction.y)
	elif direction.y < 0.0:
		allowed_distance = minf(allowed_distance, (ARENA_BOUNDS.position.y - origin.y) / direction.y)
	return clampf(allowed_distance, 0.0, maximum_distance)


func _cleanup_prepared_slash() -> void:
	if is_instance_valid(_prepared_slash):
		_prepared_slash.free()
	_prepared_slash = null


func _on_slash_hit_enemy(enemy: EnemyController) -> void:
	_feedback.play_hit(enemy)


func _on_enemy_died(_enemy: EnemyController) -> void:
	_hud.set_enemy_count(get_alive_enemy_count())


func _on_slash_finished(_hit_count: int) -> void:
	await get_tree().create_timer(settlement_delay).timeout
	_resolve_round()


func _resolve_round() -> void:
	if round_state != RoundState.EXECUTING:
		return
	var alive_count := get_alive_enemy_count()
	var victory := alive_count == 0
	_set_state(RoundState.RESOLVED)
	_feedback.play_result(victory)
	_hud.show_result(victory, alive_count)


func retry() -> void:
	if round_state != RoundState.RESOLVED:
		return
	get_tree().reload_current_scene()


func get_alive_enemy_count() -> int:
	var count := 0
	for enemy in _enemies.get_children():
		if enemy is EnemyController and enemy.is_alive():
			count += 1
	return count


func get_round_state_name() -> String:
	return RoundState.keys()[round_state]


func get_state_history() -> Array[String]:
	return state_history.duplicate()


func is_attack_committed() -> bool:
	return attack_committed


func is_player_input_enabled() -> bool:
	return _player.is_input_enabled()


func is_aim_preview_visible() -> bool:
	return _player.is_aim_preview_visible()


func get_aim_preview_distance() -> float:
	return _player.get_aim_preview_distance()


func get_aim_preview_width() -> float:
	return _player.get_aim_preview_width()


func get_aim_preview_radius() -> float:
	return _player.get_aim_preview_radius()


func get_aim_preview_deadzone_radius() -> float:
	return _player.get_aim_preview_deadzone_radius()


func is_aim_direction_arrow_visible() -> bool:
	return _player.is_aim_direction_arrow_visible()


func is_aim_deadzone_visible() -> bool:
	return _player.is_aim_deadzone_visible()


func get_aim_mode_name() -> String:
	return PrototypeSlash.SlashMode.keys()[_aim_mode]


func get_slash_form_distance_threshold() -> float:
	return slash_form_distance_threshold


func get_arc_radius() -> float:
	return arc_radius


func get_arc_move_distance() -> float:
	return arc_move_distance


func get_arc_direction_deadzone_radius() -> float:
	return arc_direction_deadzone_radius


func _set_state(next_state: RoundState) -> void:
	if round_state == next_state:
		_hud.set_round_state(get_round_state_name(), show_round_state)
		return
	round_state = next_state
	_state_history_push(next_state)
	_hud.set_round_state(get_round_state_name(), show_round_state)


func _state_history_push(state: RoundState) -> void:
	state_history.append(RoundState.keys()[state])


func _ensure_input_actions() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("move_up", [KEY_W, KEY_UP])
	_ensure_key_action("move_down", [KEY_S, KEY_DOWN])
	_ensure_key_action("retry", [KEY_R])


func _ensure_key_action(action_name: StringName, keys: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for keycode: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)
