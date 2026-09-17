class_name TerrainGrid
extends Node2D

signal moves_changed(remaining: int)
signal drag_feedback(message: String, valid: bool)
signal undo_availability_changed(available: bool)

@export var cell_size: float = 64.0
@export var grid_origin := Vector2(160.0, 94.0)
@export var grid_bounds := Rect2i(0, 0, 11, 7)

var remaining_moves := 0
var preparing := true
var _cells: Dictionary = {}
var _drag_cell: TerrainCell
var _drag_source := Vector2i.ZERO
var _drag_target := Vector2i.ZERO
var _drag_valid := false
var _actors_provider: Callable
var _move_history: Array[Dictionary] = []
var _pulse_elapsed := 0.0


func _ready() -> void:
	# A TerrainGrid inside a v0.2 Level is an authoring chunk. The Level-owned
	# aggregate map validates raw authored transforms before any snapping occurs.
	set_process(false)


func _process(delta: float) -> void:
	if not preparing:
		return
	_pulse_elapsed = fmod(_pulse_elapsed + delta, 2.8)
	var pulse := (sin((_pulse_elapsed / 2.8) * TAU - PI * 0.5) + 1.0) * 0.5
	for cell: TerrainCell in _cells.values():
		cell.set_prepare_pulse(pulse)


func rebuild() -> void:
	_cells.clear()
	for child: Node in get_children():
		if child is TerrainCell:
			var cell := child as TerrainCell
			cell.configure_size(cell_size)
			var coordinate := world_to_cell(cell.global_position)
			cell.global_position = cell_to_world(coordinate)
			_cells[coordinate] = cell
			if not cell.drag_pressed.is_connected(_on_cell_drag_pressed):
				cell.drag_pressed.connect(_on_cell_drag_pressed)


func configure(adjustment_count: int, actors_provider: Callable) -> void:
	rebuild()
	remaining_moves = maxi(adjustment_count, 0)
	_actors_provider = actors_provider
	_move_history.clear()
	moves_changed.emit(remaining_moves)
	undo_availability_changed.emit(false)
	_refresh_cell_states()
	set_process(true)


func set_preparing(value: bool) -> void:
	preparing = value
	_cancel_drag()
	if not value:
		_move_history.clear()
		undo_availability_changed.emit(false)
	for cell: TerrainCell in _cells.values():
		cell.set_preparing(value)
	_refresh_cell_states()


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(((world_position - grid_origin) / cell_size).round())


func cell_to_world(coordinate: Vector2i) -> Vector2:
	return grid_origin + Vector2(coordinate) * cell_size


func has_cell(coordinate: Vector2i) -> bool:
	return _cells.has(coordinate)


func is_world_walkable(world_position: Vector2) -> bool:
	return has_cell(world_to_cell(world_position))


func is_world_circle_walkable(world_position: Vector2, radius: float) -> bool:
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
		if not has_cell(world_to_cell(world_position + offset)):
			return false
	return true


func get_path_world(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	var start := world_to_cell(from_world)
	var goal := world_to_cell(to_world)
	var coordinates := _find_path(start, goal)
	var result := PackedVector2Array()
	for coordinate: Vector2i in coordinates:
		result.append(cell_to_world(coordinate))
	return result


func get_straight_allowed_distance(origin: Vector2, direction: Vector2, maximum_distance: float, body_radius: float = 14.0) -> float:
	if direction == Vector2.ZERO or maximum_distance <= 0.0:
		return 0.0
	var step := 4.0
	var distance := 0.0
	while distance + step <= maximum_distance:
		var candidate := origin + direction.normalized() * (distance + step)
		if not is_world_circle_walkable(candidate, body_radius):
			break
		distance += step
	return distance


func try_move_cell(source: Vector2i, target: Vector2i) -> bool:
	if not preparing or remaining_moves <= 0 or not _cells.has(source):
		return false
	if not _is_move_valid(source, target):
		return false
	var cell := _cells[source] as TerrainCell
	_cells.erase(source)
	_cells[target] = cell
	cell.global_position = cell_to_world(target)
	_move_history.append({"source": source, "target": target, "cell": cell})
	remaining_moves -= 1
	moves_changed.emit(remaining_moves)
	undo_availability_changed.emit(true)
	_refresh_cell_states()
	return true


func undo_last_move() -> bool:
	if not preparing or _move_history.is_empty():
		return false
	_cancel_drag()
	var move: Dictionary = _move_history.pop_back()
	var source: Vector2i = move["source"]
	var target: Vector2i = move["target"]
	var cell := move["cell"] as TerrainCell
	if not _cells.has(target) or _cells[target] != cell or _cells.has(source):
		push_error("Terrain undo history is inconsistent")
		_move_history.append(move)
		return false
	_cells.erase(target)
	_cells[source] = cell
	cell.global_position = cell_to_world(source)
	remaining_moves += 1
	moves_changed.emit(remaining_moves)
	undo_availability_changed.emit(not _move_history.is_empty())
	drag_feedback.emit("已撤回上一步调整", true)
	_refresh_cell_states()
	return true


func get_history_size() -> int:
	return _move_history.size()


func get_cell(coordinate: Vector2i) -> TerrainCell:
	return _cells.get(coordinate) as TerrainCell


func is_move_valid(source: Vector2i, target: Vector2i) -> bool:
	return _is_move_valid(source, target)


func _unhandled_input(event: InputEvent) -> void:
	if _drag_cell == null:
		return
	if event is InputEventMouseMotion:
		_update_drag(get_global_mouse_position())
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_commit_drag()
		get_viewport().set_input_as_handled()


func _on_cell_drag_pressed(cell: TerrainCell) -> void:
	if not preparing or remaining_moves <= 0 or not cell.is_draggable_now():
		drag_feedback.emit("调整次数已用完", false)
		return
	_drag_cell = cell
	_drag_source = world_to_cell(cell.global_position)
	_drag_target = _drag_source
	_drag_valid = false
	cell.z_index = 20
	drag_feedback.emit("拖到空白格；绿色表示合法", false)


func _update_drag(mouse_position: Vector2) -> void:
	_drag_target = world_to_cell(mouse_position)
	_drag_valid = _is_move_valid(_drag_source, _drag_target)
	_drag_cell.global_position = cell_to_world(_drag_target)
	_drag_cell.set_drag_feedback(true, _drag_valid)
	drag_feedback.emit("可放置" if _drag_valid else "不可放置", _drag_valid)


func _commit_drag() -> void:
	var cell := _drag_cell
	var valid := _drag_valid
	var target := _drag_target
	cell.global_position = cell_to_world(_drag_source)
	cell.z_index = 0
	cell.set_drag_feedback(false, false)
	_drag_cell = null
	if valid and try_move_cell(_drag_source, target):
		drag_feedback.emit("已调整地形", true)
	else:
		drag_feedback.emit("未调整，不消耗次数", false)


func _cancel_drag() -> void:
	if _drag_cell == null:
		return
	_drag_cell.global_position = cell_to_world(_drag_source)
	_drag_cell.z_index = 0
	_drag_cell.set_drag_feedback(false, false)
	_drag_cell = null


func _is_move_valid(source: Vector2i, target: Vector2i) -> bool:
	if source == target or _cells.has(target) or not grid_bounds.has_point(target):
		return false
	var simulated := _cells.duplicate()
	simulated.erase(source)
	simulated[target] = true
	if _actors_provider.is_valid():
		for actor_position: Vector2 in _actors_provider.call():
			if not simulated.has(world_to_cell(actor_position)):
				return false
	return true


func _refresh_cell_states() -> void:
	for coordinate: Vector2i in _cells:
		var cell := _cells[coordinate] as TerrainCell
		cell.set_draggable(_cell_has_legal_target(coordinate))


func _cell_has_legal_target(source: Vector2i) -> bool:
	if not preparing or remaining_moves <= 0 or _is_actor_on_cell(source):
		return false
	for y: int in range(grid_bounds.position.y, grid_bounds.end.y):
		for x: int in range(grid_bounds.position.x, grid_bounds.end.x):
			if _is_move_valid(source, Vector2i(x, y)):
				return true
	return false


func _is_actor_on_cell(coordinate: Vector2i) -> bool:
	if not _actors_provider.is_valid():
		return false
	for actor_position: Vector2 in _actors_provider.call():
		if world_to_cell(actor_position) == coordinate:
			return true
	return false


func _find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if not _cells.has(start) or not _cells.has(goal):
		return []
	var came_from := {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_front()
		if current == goal:
			break
		for next: Vector2i in _neighbors(current):
			if _cells.has(next) and not came_from.has(next):
				came_from[next] = current
				queue.append(next)
	if not came_from.has(goal):
		return []
	var reversed: Array[Vector2i] = []
	var cursor := goal
	while cursor != start:
		reversed.append(cursor)
		cursor = came_from[cursor]
	reversed.append(start)
	reversed.reverse()
	return reversed


func _neighbors(coordinate: Vector2i) -> Array[Vector2i]:
	return [coordinate + Vector2i.LEFT, coordinate + Vector2i.RIGHT, coordinate + Vector2i.UP, coordinate + Vector2i.DOWN]
