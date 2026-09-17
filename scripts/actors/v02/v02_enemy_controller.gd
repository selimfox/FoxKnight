class_name V02EnemyController
extends EnemyController

signal preparation_drag_pressed(enemy: V02EnemyController)

@export_category("v0.2 Awareness")
@export_range(0.0, 1000.0, 8.0) var detection_radius: float = 420.0

var terrain_grid: TerrainGrid
var level_controller: Node
var target_player: PlayerController
var detected := false
var _preparing_interaction := false
var _preparing_draggable := false
var _preparing_hovered := false
var _preparing_dragging := false
var _preparing_drag_valid := false


func _ready() -> void:
	super._ready()
	_state_label.visible = true
	_state_label.text = "未警觉"
	input_pickable = false
	input_event.connect(_on_preparing_input_event)
	mouse_entered.connect(_on_preparing_mouse_entered)
	mouse_exited.connect(_on_preparing_mouse_exited)


func configure_v02(level: Node, grid: TerrainGrid, player: PlayerController) -> void:
	level_controller = level
	terrain_grid = grid
	target_player = player


func set_preparing_interaction(value: bool, draggable_now: bool) -> void:
	_preparing_interaction = value
	_preparing_draggable = value and draggable_now
	if not value:
		_preparing_hovered = false
		_preparing_dragging = false
	input_pickable = _preparing_draggable
	z_index = 12 if value else 0
	queue_redraw()


func is_preparing_draggable() -> bool:
	return _preparing_interaction and _preparing_draggable


func set_drag_feedback(is_dragging: bool, is_valid: bool) -> void:
	_preparing_dragging = is_dragging
	_preparing_drag_valid = is_valid
	queue_redraw()


func get_preparing_visual_state() -> String:
	if _preparing_dragging:
		return "DRAG_VALID" if _preparing_drag_valid else "DRAG_INVALID"
	if _preparing_hovered and _preparing_draggable:
		return "HOVER"
	return "DRAGGABLE" if _preparing_draggable else "NORMAL"


func _on_preparing_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _preparing_draggable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		preparation_drag_pressed.emit(self)
		get_viewport().set_input_as_handled()


func _on_preparing_mouse_entered() -> void:
	_preparing_hovered = true
	queue_redraw()


func _on_preparing_mouse_exited() -> void:
	_preparing_hovered = false
	queue_redraw()


func _draw() -> void:
	if not _preparing_interaction:
		return
	var color := Color(0.92, 0.50, 1.0, 0.92)
	var width := 2.5
	if _preparing_dragging:
		color = Color(0.58, 1.0, 0.68, 1.0) if _preparing_drag_valid else Color(1.0, 0.30, 0.28, 1.0)
		width = 4.5
	elif _preparing_hovered and _preparing_draggable:
		color = Color(1.0, 0.58, 0.94, 1.0)
		width = 4.0
	elif not _preparing_draggable:
		color = Color(0.72, 0.18, 0.20, 0.72)
	draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 40, color, width, true)


func update_detection() -> bool:
	if detected:
		return true
	if target_player != null and global_position.distance_to(target_player.global_position) <= detection_radius:
		detected = true
		_state_label.text = "已警觉"
	return detected


func move_toward_target(delta: float, target_world: Vector2) -> bool:
	if terrain_grid == null:
		velocity = global_position.direction_to(target_world) * move_speed
		move_and_slide()
		return true
	var path := terrain_grid.get_path_world(global_position, target_world)
	if path.is_empty():
		velocity = Vector2.ZERO
		_update_v02_sprite()
		return false
	if path.size() == 1:
		velocity = global_position.direction_to(target_world) * move_speed
	else:
		velocity = global_position.direction_to(path[1]) * move_speed
	var candidate := global_position + velocity * delta
	if terrain_grid.is_world_circle_walkable(candidate, 14.0):
		global_position = candidate
	else:
		velocity = Vector2.ZERO
	_update_v02_sprite()
	return true


func move_away_from_target(delta: float) -> bool:
	if terrain_grid == null or target_player == null:
		return false
	var current_cell := terrain_grid.world_to_cell(global_position)
	var best_cell := current_cell
	var best_distance := global_position.distance_squared_to(target_player.global_position)
	for neighbor: Vector2i in [current_cell + Vector2i.LEFT, current_cell + Vector2i.RIGHT, current_cell + Vector2i.UP, current_cell + Vector2i.DOWN]:
		if not terrain_grid.has_cell(neighbor):
			continue
		var distance := terrain_grid.cell_to_world(neighbor).distance_squared_to(target_player.global_position)
		if distance > best_distance:
			best_distance = distance
			best_cell = neighbor
	if best_cell == current_cell:
		velocity = Vector2.ZERO
		return false
	return move_toward_target(delta, terrain_grid.cell_to_world(best_cell))


func check_contact_damage() -> void:
	if level_controller != null and target_player != null and global_position.distance_to(target_player.global_position) <= 27.0:
		level_controller.call("request_player_damage", self)


func _update_v02_sprite() -> void:
	var movement_texture := walk_texture if velocity.length_squared() > 1.0 else idle_texture
	if movement_texture:
		_sprite.texture = movement_texture
	_sprite.flip_h = velocity.x < -0.05
