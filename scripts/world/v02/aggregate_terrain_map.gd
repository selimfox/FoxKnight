class_name AggregateTerrainMap
extends TerrainGrid

signal configuration_changed(valid: bool, message: String)
signal battle_readiness_changed(ready: bool)

const HISTORY_TERRAIN := "terrain"
const HISTORY_ENEMY := "enemy"
const LARGE_MAPPING_WARNING_RATIO := 0.2

var configuration_valid := false
var structure_valid := false
var battle_ready := false
var configuration_errors: PackedStringArray = []
var configuration_warnings: PackedStringArray = []
var _managed_grids: Array[TerrainGrid] = []
var _player: PlayerController
var _enemies: Array[V02EnemyController] = []
var _mixed_history: Array[Dictionary] = []
var _drag_kind := ""
var _drag_enemy: V02EnemyController
var _drag_source_world := Vector2.ZERO
var _authored_cell_mappings: Array[Dictionary] = []


func _ready() -> void:
	set_process(false)


func configure_aggregate(
	grids: Array[TerrainGrid],
	adjustment_count: int,
	player: PlayerController,
	enemies: Array[V02EnemyController],
	level_cell_size: float,
	level_grid_origin: Vector2,
	level_grid_bounds: Rect2i
) -> PackedStringArray:
	_cancel_aggregate_drag()
	_managed_grids = grids.duplicate()
	_player = player
	_enemies = enemies.duplicate()
	_cells.clear()
	configuration_errors.clear()
	configuration_warnings.clear()
	_mixed_history.clear()
	_authored_cell_mappings.clear()
	remaining_moves = maxi(adjustment_count, 0)
	preparing = true
	cell_size = level_cell_size
	grid_bounds = level_grid_bounds

	var authored_cells: Array[TerrainCell] = []
	if _managed_grids.is_empty():
		_add_error("未找到 TerrainGrid")
	else:
		for grid: TerrainGrid in _managed_grids:
			grid.set_process(false)
			if not is_equal_approx(grid.cell_size, cell_size):
				_add_error("TerrainGrid %s 的 cell_size %.2f 与统一尺寸 %.2f 不一致" % [grid.get_path(), grid.cell_size, cell_size])
			for cell: TerrainCell in _collect_cells(grid):
				authored_cells.append(cell)

	if not authored_cells.is_empty():
		grid_origin = _derive_grid_origin(authored_cells, level_grid_origin)
		for cell: TerrainCell in authored_cells:
			_register_cell(cell)

	if _cells.is_empty():
		_add_error("未找到 TerrainCell")
	_align_actors_with_authored_cells()
	_validate_actor_starts()
	_bind_inputs()
	structure_valid = configuration_errors.is_empty()
	# Kept as a compatibility alias for existing tooling. Runtime decisions use
	# structure_valid and battle_ready separately.
	configuration_valid = structure_valid
	_refresh_battle_ready()
	set_process(true)
	moves_changed.emit(remaining_moves)
	undo_availability_changed.emit(false)
	configuration_changed.emit(configuration_valid, get_configuration_message())
	_refresh_aggregate_states()
	return configuration_errors.duplicate()


func get_configuration_message() -> String:
	return "" if configuration_valid else "关卡配置错误：%s" % "；".join(configuration_errors)


func get_warning_message() -> String:
	if configuration_warnings.is_empty():
		return ""
	var visible: PackedStringArray = []
	var visible_count := mini(configuration_warnings.size(), 5)
	for index: int in range(visible_count):
		visible.append(configuration_warnings[index])
	var suffix := "" if configuration_warnings.size() <= visible_count else "；另 %d 项已吸附" % (configuration_warnings.size() - visible_count)
	return "地块运行时吸附（%d 项）：%s%s" % [configuration_warnings.size(), "；".join(visible), suffix]


func get_configuration_summary() -> String:
	if configuration_valid:
		return ""
	var categories: PackedStringArray = []
	for error: String in configuration_errors:
		var category := error
		if error.contains("cell_size"):
			category = "地块尺寸不一致"
		elif error.contains("重复地形坐标"):
			category = "地块坐标重复"
		elif error.contains("未对齐统一格点"):
			category = "节点未对齐格点"
		elif error.contains("不在基础地形上"):
			category = "角色不在地面上"
		elif error.contains("多个角色占用"):
			category = "角色位置重叠"
		if not categories.has(category):
			categories.append(category)
	return "关卡配置错误：%s。详见运行日志。" % "、".join(categories)


func add_external_configuration_error(message: String) -> void:
	_add_error(message)
	structure_valid = false
	configuration_valid = false
	_refresh_battle_ready()
	configuration_changed.emit(false, get_configuration_message())
	_refresh_aggregate_states()


func get_cell_count() -> int:
	return _cells.size()


func get_managed_grid_count() -> int:
	return _managed_grids.size()


func try_move_cell(source: Vector2i, target: Vector2i) -> bool:
	if not preparing or not structure_valid or remaining_moves <= 0 or not _cells.has(source):
		return false
	if not is_terrain_move_valid(source, target):
		return false
	var cell := _cells[source] as TerrainCell
	_cells.erase(source)
	_cells[target] = cell
	cell.global_position = cell_to_world(target)
	_mixed_history.append({"type": HISTORY_TERRAIN, "source": source, "target": target, "object": cell})
	_consume_adjustment()
	return true


func try_move_enemy(enemy: V02EnemyController, target: Vector2i) -> bool:
	if not preparing or not structure_valid or remaining_moves <= 0 or not is_instance_valid(enemy):
		return false
	var source_world := enemy.global_position
	var source := world_to_cell(source_world)
	if not is_enemy_move_valid(enemy, source, target):
		return false
	enemy.global_position = cell_to_world(target)
	_mixed_history.append({"type": HISTORY_ENEMY, "source": source, "source_world": source_world, "target": target, "object": enemy})
	_consume_adjustment()
	return true


func undo_last_move() -> bool:
	if not preparing or _mixed_history.is_empty():
		return false
	_cancel_aggregate_drag()
	var record: Dictionary = _mixed_history.pop_back()
	var source: Vector2i = record["source"]
	var target: Vector2i = record["target"]
	var object: Node2D = record["object"]
	if record["type"] == HISTORY_TERRAIN:
		if not _cells.has(target) or _cells[target] != object or _cells.has(source):
			push_error("Terrain undo history is inconsistent")
			_mixed_history.append(record)
			return false
		_cells.erase(target)
		_cells[source] = object
		object.global_position = cell_to_world(source)
	elif record["type"] == HISTORY_ENEMY:
		if not is_instance_valid(object) or world_to_cell(object.global_position) != target:
			push_error("Enemy undo history is inconsistent")
			_mixed_history.append(record)
			return false
		object.global_position = record.get("source_world", cell_to_world(source))
	else:
		push_error("Unknown adjustment history type")
		_mixed_history.append(record)
		return false
	remaining_moves += 1
	moves_changed.emit(remaining_moves)
	undo_availability_changed.emit(not _mixed_history.is_empty())
	drag_feedback.emit("已撤回上一步调整", true)
	_refresh_battle_ready()
	_refresh_aggregate_states()
	return true


func get_history_size() -> int:
	return _mixed_history.size()


func get_last_history_type() -> String:
	return "" if _mixed_history.is_empty() else String(_mixed_history.back()["type"])


func is_move_valid(source: Vector2i, target: Vector2i) -> bool:
	return is_terrain_move_valid(source, target)


func is_terrain_move_valid(source: Vector2i, target: Vector2i) -> bool:
	if not structure_valid or source == target or _cells.has(target) or not grid_bounds.has_point(target):
		return false
	if _actor_at_cell(source) != null:
		return false
	var simulated := _cells.duplicate()
	simulated.erase(source)
	simulated[target] = true
	for actor: Node2D in _all_actors():
		if not _is_world_circle_walkable_in(simulated, actor.global_position, _get_actor_radius(actor)):
			return false
	return true


func is_enemy_move_valid(enemy: V02EnemyController, source: Vector2i, target: Vector2i) -> bool:
	if not structure_valid or not _enemies.has(enemy) or source == target:
		return false
	return _cells.has(target) and _actor_at_cell(target, enemy) == null


func set_preparing(value: bool) -> void:
	preparing = value
	_cancel_aggregate_drag()
	if not value:
		_mixed_history.clear()
		undo_availability_changed.emit(false)
	for cell: TerrainCell in _cells.values():
		cell.set_preparing(value)
	for enemy: V02EnemyController in _enemies:
		if is_instance_valid(enemy):
			enemy.set_preparing_interaction(value, false)
	_refresh_aggregate_states()


func _unhandled_input(event: InputEvent) -> void:
	if _drag_kind.is_empty():
		return
	if event is InputEventMouseMotion:
		_update_drag(get_global_mouse_position())
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_commit_drag()
		get_viewport().set_input_as_handled()


func _on_cell_drag_pressed(cell: TerrainCell) -> void:
	if not preparing or remaining_moves <= 0 or not cell.is_draggable_now():
		drag_feedback.emit("该地形当前不可调整", false)
		return
	_cancel_aggregate_drag()
	_drag_kind = HISTORY_TERRAIN
	_drag_cell = cell
	_drag_source = world_to_cell(cell.global_position)
	_drag_target = _drag_source
	_drag_valid = false
	_refresh_battle_ready()
	cell.z_index = 20
	cell.set_drag_feedback(true, false)
	drag_feedback.emit("正在调整地形：拖到空网格目标", false)


func _on_enemy_drag_pressed(enemy: V02EnemyController) -> void:
	if not preparing or remaining_moves <= 0 or not enemy.is_preparing_draggable():
		drag_feedback.emit("该敌人当前不可调整", false)
		return
	_cancel_aggregate_drag()
	_drag_kind = HISTORY_ENEMY
	_drag_enemy = enemy
	_drag_source = world_to_cell(enemy.global_position)
	_drag_source_world = enemy.global_position
	_drag_target = _drag_source
	_drag_valid = false
	_refresh_battle_ready()
	enemy.set_drag_feedback(true, false)
	_highlight_enemy_targets(enemy, _drag_source)
	drag_feedback.emit("正在调整敌人：拖到任意高亮空地", false)


func _update_drag(mouse_position: Vector2) -> void:
	_drag_target = world_to_cell(mouse_position)
	if _drag_kind == HISTORY_TERRAIN and is_instance_valid(_drag_cell):
		_drag_valid = is_terrain_move_valid(_drag_source, _drag_target)
		_drag_cell.global_position = cell_to_world(_drag_target)
		_drag_cell.set_drag_feedback(true, _drag_valid)
	elif _drag_kind == HISTORY_ENEMY and is_instance_valid(_drag_enemy):
		_drag_valid = is_enemy_move_valid(_drag_enemy, _drag_source, _drag_target)
		_drag_enemy.global_position = cell_to_world(_drag_target)
		_drag_enemy.set_drag_feedback(true, _drag_valid)
	var subject := "地形" if _drag_kind == HISTORY_TERRAIN else "敌人"
	drag_feedback.emit("%s：%s" % [subject, "可放置" if _drag_valid else "不可放置"], _drag_valid)


func _commit_drag() -> void:
	var kind := _drag_kind
	var source := _drag_source
	var target := _drag_target
	var valid := _drag_valid
	var cell := _drag_cell
	var enemy := _drag_enemy
	_restore_drag_object()
	_clear_target_highlights()
	_drag_kind = ""
	_drag_cell = null
	_drag_enemy = null
	if kind == HISTORY_TERRAIN and valid and try_move_cell(source, target):
		drag_feedback.emit("已调整地形", true)
		_refresh_battle_ready()
	elif kind == HISTORY_ENEMY and valid and try_move_enemy(enemy, target):
		drag_feedback.emit("已调整敌人", true)
		_refresh_battle_ready()
	else:
		drag_feedback.emit("未调整，不消耗次数", false)
		_refresh_battle_ready()


func _cancel_aggregate_drag() -> void:
	var had_active_drag := not _drag_kind.is_empty()
	_restore_drag_object()
	_clear_target_highlights()
	_drag_kind = ""
	_drag_cell = null
	_drag_enemy = null
	if had_active_drag:
		_refresh_battle_ready()


func _restore_drag_object() -> void:
	if _drag_kind == HISTORY_TERRAIN and is_instance_valid(_drag_cell):
		_drag_cell.global_position = cell_to_world(_drag_source)
		_drag_cell.z_index = 0
		_drag_cell.set_drag_feedback(false, false)
	elif _drag_kind == HISTORY_ENEMY and is_instance_valid(_drag_enemy):
		_drag_enemy.global_position = _drag_source_world
		_drag_enemy.set_drag_feedback(false, false)


func _consume_adjustment() -> void:
	remaining_moves -= 1
	moves_changed.emit(remaining_moves)
	undo_availability_changed.emit(true)
	_refresh_battle_ready()
	_refresh_aggregate_states()


func _refresh_aggregate_states() -> void:
	for coordinate: Vector2i in _cells:
		var cell := _cells[coordinate] as TerrainCell
		cell.set_preparing(preparing)
		cell.set_draggable(_cell_has_legal_target(coordinate))
	for enemy: V02EnemyController in _enemies:
		if is_instance_valid(enemy):
			enemy.set_preparing_interaction(preparing, _enemy_has_legal_target(enemy))


func _cell_has_legal_target(source: Vector2i) -> bool:
	if not preparing or not structure_valid or remaining_moves <= 0 or _actor_at_cell(source) != null:
		return false
	for y: int in range(grid_bounds.position.y, grid_bounds.end.y):
		for x: int in range(grid_bounds.position.x, grid_bounds.end.x):
			if is_terrain_move_valid(source, Vector2i(x, y)):
				return true
	return false


func _enemy_has_legal_target(enemy: V02EnemyController) -> bool:
	if not preparing or not structure_valid or remaining_moves <= 0:
		return false
	var source := world_to_cell(enemy.global_position)
	for coordinate: Vector2i in _cells:
		if is_enemy_move_valid(enemy, source, coordinate):
			return true
	return false


func _highlight_enemy_targets(enemy: V02EnemyController, source: Vector2i) -> void:
	_clear_target_highlights()
	for coordinate: Vector2i in _cells:
		if is_enemy_move_valid(enemy, source, coordinate):
			(_cells[coordinate] as TerrainCell).set_target_highlight(TerrainCell.TargetHighlight.LEGAL)


func _clear_target_highlights() -> void:
	for cell: TerrainCell in _cells.values():
		cell.set_target_highlight(TerrainCell.TargetHighlight.NONE)


func _derive_grid_origin(cells: Array[TerrainCell], preferred_origin: Vector2) -> Vector2:
	return Vector2(
		_derive_axis_origin(cells, true, preferred_origin.x, grid_bounds.position.x, grid_bounds.size.x),
		_derive_axis_origin(cells, false, preferred_origin.y, grid_bounds.position.y, grid_bounds.size.y)
	)


func _derive_axis_origin(cells: Array[TerrainCell], use_x: bool, preferred: float, bound_start: int, bound_size: int) -> float:
	const PHASE_SAMPLES := 256
	var best_phase := fposmod(preferred, cell_size)
	var best_max_error := INF
	var best_total_error := INF
	for sample_index: int in range(PHASE_SAMPLES):
		var phase := cell_size * float(sample_index) / float(PHASE_SAMPLES)
		var max_error := 0.0
		var total_error := 0.0
		for cell: TerrainCell in cells:
			var value := cell.global_position.x if use_x else cell.global_position.y
			var residue := fposmod(value, cell_size)
			var direct_error := absf(residue - phase)
			var circular_error := minf(direct_error, cell_size - direct_error)
			max_error = maxf(max_error, circular_error)
			total_error += circular_error
		if max_error < best_max_error - 0.001 or (is_equal_approx(max_error, best_max_error) and total_error < best_total_error):
			best_phase = phase
			best_max_error = max_error
			best_total_error = total_error

	var raw_min := 2147483647
	var raw_max := -2147483648
	for cell: TerrainCell in cells:
		var value := cell.global_position.x if use_x else cell.global_position.y
		var raw_index := roundi((value - best_phase) / cell_size)
		raw_min = mini(raw_min, raw_index)
		raw_max = maxi(raw_max, raw_index)

	var preferred_shift := roundi((preferred - best_phase) / cell_size)
	var minimum_shift := raw_max - (bound_start + bound_size - 1)
	var maximum_shift := raw_min - bound_start
	var selected_shift := preferred_shift
	if minimum_shift <= maximum_shift:
		selected_shift = clampi(preferred_shift, minimum_shift, maximum_shift)
	return best_phase + float(selected_shift) * cell_size


func _register_cell(cell: TerrainCell) -> void:
	cell.configure_size(cell_size)
	var actual := cell.global_position
	var relative := (actual - grid_origin) / cell_size
	var rounded := relative.round()
	var expected := grid_origin + rounded * cell_size
	var difference := actual - expected
	var tolerance := cell_size * LARGE_MAPPING_WARNING_RATIO
	if not actual.is_equal_approx(expected):
		var magnitude := "较大偏差" if absf(difference.x) > tolerance or absf(difference.y) > tolerance else "轻微偏差"
		configuration_warnings.append("%s %s：实际 %s -> 运行格点 %s" % [cell.get_path(), magnitude, actual, expected])
	var coordinate := Vector2i(rounded)
	if not grid_bounds.has_point(coordinate):
		_add_error("TerrainCell %s 的推导坐标 %s 超出关卡网格边界 %s" % [cell.get_path(), coordinate, grid_bounds])
		return
	if _cells.has(coordinate):
		_add_error("自动映射后重复地形坐标 %s：%s 与 %s（实际 %s，运行格点 %s）" % [coordinate, (_cells[coordinate] as Node).get_path(), cell.get_path(), actual, expected])
		return
	_authored_cell_mappings.append({"actual": actual, "expected": expected, "cell": cell})
	_cells[coordinate] = cell
	cell.global_position = expected


func _align_actors_with_authored_cells() -> void:
	var half_extent := cell_size * 0.5
	for actor: Node2D in _all_actors():
		var best_mapping: Dictionary = {}
		var best_distance := INF
		for mapping: Dictionary in _authored_cell_mappings:
			var actual: Vector2 = mapping["actual"]
			var delta := actor.global_position - actual
			if absf(delta.x) > half_extent or absf(delta.y) > half_extent:
				continue
			var distance := delta.length_squared()
			if distance < best_distance:
				best_distance = distance
				best_mapping = mapping
		if not best_mapping.is_empty():
			var actual: Vector2 = best_mapping["actual"]
			var expected: Vector2 = best_mapping["expected"]
			actor.global_position += expected - actual


func _validate_actor_starts() -> void:
	if _player == null:
		_add_error("未找到狐狸")
	var occupied: Dictionary = {}
	for actor: Node2D in _all_actors():
		var radius := _get_actor_radius(actor)
		if not _is_world_circle_walkable_in(_cells, actor.global_position, radius):
			_add_error("角色 %s 占地圆未完全位于基础地形：中心 %s，半径 %.2f" % [actor.get_path(), actor.global_position, radius])
		for other: Node2D in occupied.values():
			var minimum_distance := radius + _get_actor_radius(other)
			if actor.global_position.distance_to(other.global_position) < minimum_distance:
				_add_error("初始角色重叠：%s 与 %s（距离 %.2f，至少 %.2f）" % [other.get_path(), actor.get_path(), actor.global_position.distance_to(other.global_position), minimum_distance])
		occupied[actor.get_instance_id()] = actor


func _actor_at_cell(coordinate: Vector2i, ignored: Node2D = null) -> Node2D:
	for actor: Node2D in _all_actors():
		if actor != ignored and world_to_cell(actor.global_position) == coordinate:
			return actor
	return null


func _all_actors() -> Array[Node2D]:
	var result: Array[Node2D] = []
	if is_instance_valid(_player):
		result.append(_player)
	for enemy: V02EnemyController in _enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			result.append(enemy)
	return result


func _get_actor_radius(actor: Node2D) -> float:
	if actor is PlayerController:
		return 15.0
	return 14.0


func _is_world_circle_walkable_in(occupancy: Dictionary, world_position: Vector2, radius: float) -> bool:
	var safe_radius := maxf(radius, 0.0)
	var samples := PackedVector2Array([
		Vector2.ZERO,
		Vector2.LEFT * safe_radius,
		Vector2.RIGHT * safe_radius,
		Vector2.UP * safe_radius,
		Vector2.DOWN * safe_radius,
		Vector2(-1.0, -1.0).normalized() * safe_radius,
		Vector2(1.0, -1.0).normalized() * safe_radius,
		Vector2(-1.0, 1.0).normalized() * safe_radius,
		Vector2(1.0, 1.0).normalized() * safe_radius,
	])
	for offset: Vector2 in samples:
		if not occupancy.has(world_to_cell(world_position + offset)):
			return false
	return true


func _collect_cells(root: Node) -> Array[TerrainCell]:
	var result: Array[TerrainCell] = []
	_collect_cells_recursive(root, result)
	return result


func _collect_cells_recursive(node: Node, result: Array[TerrainCell]) -> void:
	for child: Node in node.get_children():
		if child is TerrainGrid:
			continue
		if child is TerrainCell:
			result.append(child)
		_collect_cells_recursive(child, result)


func _bind_inputs() -> void:
	for grid: TerrainGrid in _managed_grids:
		for cell: TerrainCell in _collect_cells(grid):
			var previous := Callable(grid, "_on_cell_drag_pressed")
			if cell.drag_pressed.is_connected(previous):
				cell.drag_pressed.disconnect(previous)
	for cell: TerrainCell in _cells.values():
		if not cell.drag_pressed.is_connected(_on_cell_drag_pressed):
			cell.drag_pressed.connect(_on_cell_drag_pressed)
	for enemy: V02EnemyController in _enemies:
		if not enemy.preparation_drag_pressed.is_connected(_on_enemy_drag_pressed):
			enemy.preparation_drag_pressed.connect(_on_enemy_drag_pressed)


func _add_error(message: String) -> void:
	if not configuration_errors.has(message):
		configuration_errors.append(message)


func has_active_drag() -> bool:
	return not _drag_kind.is_empty()


func _refresh_battle_ready() -> void:
	battle_ready = structure_valid and not has_active_drag()
	battle_readiness_changed.emit(battle_ready)
