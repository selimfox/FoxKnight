class_name V02LevelController
extends Node2D

signal level_won
signal retry_requested
signal main_menu_requested

enum RoundState { INITIALIZING, PREPARING, OBSERVING, AIMING, EXECUTING, RESOLVED }
const SLASH_SCENE := preload("res://scenes/combat/prototype_slash.tscn")
const AGGREGATE_ORIGIN_HINT := Vector2(160.0, 94.0)

@export_range(0, 12, 1) var adjustment_count := 2
@export_range(24.0, 240.0, 2.0) var arc_radius := 90.0
@export_range(0.0, 1.0, 0.01) var settlement_delay := 0.18
@export_category("Aggregate Grid")
@export_range(16.0, 256.0, 1.0) var aggregate_cell_size := 64.0
@export var aggregate_grid_bounds := Rect2i(0, 0, 11, 7)

var round_state := RoundState.INITIALIZING
var attack_committed := false
var is_final_level := false
var _prepared_slash: PrototypeSlash
var _aim_direction := Vector2.ZERO
var _aim_distance := 0.0
var _aim_valid := false
var _aim_mode := PrototypeSlash.SlashMode.STRAIGHT
var terrain_grid: AggregateTerrainMap
var player: PlayerController
var enemies: Node
var projectiles: Node
var effects: Node
var actors: CanvasItem
var backdrop: CanvasItem
var hud: V02HUD
var _enemy_nodes: Array[V02EnemyController] = []
var _source_grids: Array[TerrainGrid] = []
var _player_count := 0

func _enter_tree() -> void:
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("move_up", [KEY_W, KEY_UP])
	_ensure_key_action("move_down", [KEY_S, KEY_DOWN])

func _ready() -> void:
	_discover_level_content()
	if hud == null or projectiles == null or effects == null:
		push_error("v0.2 Level 缺少运行所需节点")
		return
	if player != null:
		player.aim_started.connect(_on_aim_started)
		player.aim_released.connect(_on_aim_released)
		player.aim_cancel_requested.connect(_on_aim_cancel_requested)
	hud.battle_start_requested.connect(start_battle)
	hud.undo_requested.connect(undo_last_adjustment)
	hud.retry_requested.connect(func() -> void: retry_requested.emit())
	hud.next_requested.connect(func() -> void: level_won.emit())
	hud.main_menu_requested.connect(func() -> void: main_menu_requested.emit())
	terrain_grid.moves_changed.connect(hud.set_moves)
	terrain_grid.drag_feedback.connect(hud.set_drag_message)
	terrain_grid.undo_availability_changed.connect(hud.set_undo_available)
	terrain_grid.battle_readiness_changed.connect(_on_battle_readiness_changed)
	terrain_grid.configure_aggregate(
		_source_grids,
		adjustment_count,
		player,
		_enemy_nodes,
		aggregate_cell_size,
		AGGREGATE_ORIGIN_HINT,
		aggregate_grid_bounds
	)
	if _player_count != 1:
		terrain_grid.add_external_configuration_error("关卡必须且只能包含一只狐狸，当前为 %d" % _player_count)
	if player != null:
		player.set_terrain_grid(terrain_grid)
		player.set_input_enabled(false)
	for enemy: V02EnemyController in _enemy_nodes:
		enemy.configure_v02(self, terrain_grid, player)
		enemy.set_physics_process(false)
		enemy.died.connect(_on_enemy_died)
	hud.set_enemy_count(get_alive_enemy_count())
	hud.show_preparing(adjustment_count)
	round_state = RoundState.PREPARING
	_on_battle_readiness_changed(terrain_grid.battle_ready)
	var development_warnings: PackedStringArray = []
	if not terrain_grid.configuration_warnings.is_empty():
		development_warnings.append(terrain_grid.get_warning_message())
	if not development_warnings.is_empty():
		push_warning("%s：%s" % [name, "；".join(development_warnings)])
	if not terrain_grid.structure_valid:
		var message := terrain_grid.get_configuration_message()
		hud.set_start_available(false)
		push_error(message)
	_apply_preparing_visuals(true)

func set_campaign_context(index: int, total: int) -> void:
	is_final_level = index == total - 1

func start_battle() -> void:
	if round_state != RoundState.PREPARING or not terrain_grid.structure_valid or not terrain_grid.battle_ready or terrain_grid.has_active_drag():
		return
	round_state = RoundState.OBSERVING
	terrain_grid.set_preparing(false)
	_apply_preparing_visuals(false)
	player.set_input_enabled(true)
	for enemy: V02EnemyController in _enemy_nodes:
		enemy.set_physics_process(true)
	hud.show_battle()


func undo_last_adjustment() -> bool:
	if round_state != RoundState.PREPARING:
		return false
	return terrain_grid.undo_last_move()


func _on_battle_readiness_changed(ready: bool) -> void:
	if hud == null:
		return
	hud.set_start_available(ready)

func _process(_delta: float) -> void:
	if round_state == RoundState.AIMING:
		_update_aim(player.get_global_mouse_position())

func _on_aim_started(target_position: Vector2) -> void:
	if round_state != RoundState.OBSERVING or attack_committed:
		return
	_cleanup_prepared_slash()
	_prepared_slash = SLASH_SCENE.instantiate()
	round_state = RoundState.AIMING
	hud.show_aiming()
	_update_aim(target_position)

func _on_aim_released(target_position: Vector2) -> void:
	if round_state != RoundState.AIMING or attack_committed:
		return
	_update_aim(target_position)
	if _aim_valid:
		_commit_attack()
	else:
		_cancel_aim()

func _on_aim_cancel_requested() -> void:
	if round_state == RoundState.AIMING and not attack_committed:
		_cancel_aim()

func _cancel_aim() -> void:
	player.clear_aim_preview()
	_cleanup_prepared_slash()
	round_state = RoundState.OBSERVING
	hud.show_battle()

func _update_aim(target_position: Vector2) -> void:
	if round_state != RoundState.AIMING or _prepared_slash == null:
		return
	var aim_vector := target_position - player.global_position
	var effective_arc := arc_radius * _prepared_slash.hitbox_tolerance_multiplier
	_aim_valid = true
	if aim_vector.length() < effective_arc:
		_aim_mode = PrototypeSlash.SlashMode.ARC
		_aim_direction = Vector2.ZERO
		_aim_distance = 0.0
		player.update_arc_aim_preview(effective_arc)
	else:
		_aim_mode = PrototypeSlash.SlashMode.STRAIGHT
		_aim_direction = aim_vector.normalized()
		_aim_distance = terrain_grid.get_straight_allowed_distance(player.global_position, _aim_direction, _prepared_slash.distance)
		_aim_valid = _aim_distance > 1.0
		if _aim_valid:
			player.update_straight_aim_preview(_aim_direction, _aim_distance, _prepared_slash.width * _prepared_slash.hitbox_tolerance_multiplier, effective_arc)
		else:
			player.set_aim_preview_invalid()

func _commit_attack() -> void:
	var slash := _prepared_slash
	_prepared_slash = null
	if slash == null:
		slash = SLASH_SCENE.instantiate()
	attack_committed = true
	round_state = RoundState.EXECUTING
	player.set_input_enabled(false)
	hud.show_executing()
	effects.add_child(slash)
	slash.finished.connect(_on_slash_finished)
	slash.hit_enemy.connect(_on_slash_hit_enemy)
	slash.execute(player, player.global_position, _aim_mode, _aim_direction, _aim_distance, arc_radius)

func request_player_damage(_source: Node) -> bool:
	if round_state != RoundState.OBSERVING and round_state != RoundState.AIMING:
		return false
	round_state = RoundState.RESOLVED
	player.set_input_enabled(false)
	_stop_combat()
	hud.show_result(false, 0, is_final_level)
	return true

func spawn_arrow(arrow: Node, start: Vector2, direction: Vector2, speed: float) -> void:
	if round_state != RoundState.OBSERVING and round_state != RoundState.AIMING:
		arrow.queue_free()
		return
	projectiles.add_child(arrow)
	arrow.call("setup", self, player, start, direction, speed)

func _on_slash_hit_enemy(_enemy: EnemyController) -> void:
	pass

func _on_enemy_died(_enemy: EnemyController) -> void:
	hud.set_enemy_count(get_alive_enemy_count())

func _on_slash_finished(_hit_count: int) -> void:
	await get_tree().create_timer(settlement_delay).timeout
	if round_state != RoundState.EXECUTING:
		return
	var alive := get_alive_enemy_count()
	var victory := alive == 0
	round_state = RoundState.RESOLVED
	_stop_combat()
	hud.show_result(victory, alive, is_final_level)

func _stop_combat() -> void:
	for enemy: V02EnemyController in _enemy_nodes:
		if is_instance_valid(enemy):
			enemy.set_physics_process(false)
	for arrow: Node in projectiles.get_children():
		arrow.queue_free()

func get_alive_enemy_count() -> int:
	var count := 0
	for enemy: V02EnemyController in _enemy_nodes:
		if is_instance_valid(enemy) and enemy.is_alive():
			count += 1
	return count

func get_round_state_name() -> String:
	return RoundState.keys()[round_state]

func get_actor_positions() -> Array[Vector2]:
	return _get_actor_positions()

func _get_actor_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = [player.global_position]
	for enemy: V02EnemyController in _enemy_nodes:
		if is_instance_valid(enemy):
			positions.append(enemy.global_position)
	return positions

func is_damage_immune() -> bool:
	return round_state == RoundState.EXECUTING or (round_state == RoundState.RESOLVED and attack_committed)

func _apply_preparing_visuals(value: bool) -> void:
	if actors != null:
		actors.modulate = Color.WHITE
	if player != null:
		player.modulate = Color(0.48, 0.48, 0.58, 1.0) if value else Color.WHITE
	if backdrop != null:
		backdrop.modulate = Color(0.55, 0.55, 0.62, 1.0) if value else Color.WHITE


func get_enemy_nodes() -> Array[V02EnemyController]:
	return _enemy_nodes.duplicate()


func get_source_terrain_grids() -> Array[TerrainGrid]:
	return _source_grids.duplicate()


func _discover_level_content() -> void:
	var players: Array[PlayerController] = []
	_collect_runtime_nodes(self, players, _enemy_nodes, _source_grids)
	player = players[0] if not players.is_empty() else null
	enemies = get_node_or_null("Actors/Enemies")
	projectiles = get_node_or_null("Projectiles")
	effects = get_node_or_null("Effects")
	actors = get_node_or_null("Actors") as CanvasItem
	backdrop = get_node_or_null("Backdrop") as CanvasItem
	hud = _find_hud(self)
	terrain_grid = AggregateTerrainMap.new()
	terrain_grid.name = "RuntimeTerrainMap"
	add_child(terrain_grid)
	_player_count = players.size()


func _collect_runtime_nodes(node: Node, players: Array[PlayerController], found_enemies: Array[V02EnemyController], grids: Array[TerrainGrid]) -> void:
	for child: Node in node.get_children():
		if child is PlayerController:
			players.append(child)
		elif child is V02EnemyController:
			found_enemies.append(child)
		elif child is TerrainGrid and not child is AggregateTerrainMap:
			grids.append(child)
		_collect_runtime_nodes(child, players, found_enemies, grids)


func _find_hud(node: Node) -> V02HUD:
	for child: Node in node.get_children():
		if child is V02HUD:
			return child
		var nested := _find_hud(child)
		if nested != null:
			return nested
	return null

func _cleanup_prepared_slash() -> void:
	if is_instance_valid(_prepared_slash):
		_prepared_slash.free()
	_prepared_slash = null

func _ensure_key_action(action_name: StringName, keys: Array) -> void:
	if InputMap.has_action(action_name):
		return
	InputMap.add_action(action_name)
	for keycode: Key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)
