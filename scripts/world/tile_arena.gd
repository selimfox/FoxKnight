class_name TileArena
extends Node2D

@onready var floor_layer: TileMapLayer = $Floor
@onready var wall_layer: TileMapLayer = $Walls

var _wall_body: StaticBody2D
var _path_grid: AStarGrid2D


func _ready() -> void:
	_wall_body = StaticBody2D.new()
	_wall_body.name = "TileWallCollisions"
	_wall_body.collision_layer = 1
	_wall_body.collision_mask = 0
	add_child(_wall_body)
	for cell: Vector2i in wall_layer.get_used_cells():
		var shape := RectangleShape2D.new()
		shape.size = Vector2(32.0, 32.0)
		var collision := CollisionShape2D.new()
		collision.shape = shape
		collision.position = wall_layer.map_to_local(cell)
		_wall_body.add_child(collision)
	_path_grid = AStarGrid2D.new()
	_path_grid.region = floor_layer.get_used_rect()
	_path_grid.cell_size = Vector2(32.0, 32.0)
	_path_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	_path_grid.update()
	for cell: Vector2i in wall_layer.get_used_cells():
		if _path_grid.is_in_boundsv(cell):
			_path_grid.set_point_solid(cell)


func get_next_path_point(from_global: Vector2, to_global: Vector2) -> Vector2:
	if _path_grid == null:
		return to_global
	var from_cell := floor_layer.local_to_map(floor_layer.to_local(from_global))
	var to_cell := floor_layer.local_to_map(floor_layer.to_local(to_global))
	if not _path_grid.is_in_boundsv(from_cell) or not _path_grid.is_in_boundsv(to_cell):
		return to_global
	var path := _path_grid.get_id_path(from_cell, to_cell)
	if path.is_empty():
		return from_global
	if path.size() < 2:
		return to_global
	return floor_layer.to_global(floor_layer.map_to_local(path[1]))


func get_slash_distance(origin: Vector2, direction: Vector2, maximum_distance: float) -> float:
	if direction == Vector2.ZERO or maximum_distance <= 0.0:
		return 0.0
	var query := PhysicsRayQueryParameters2D.create(origin, origin + direction * maximum_distance, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return maximum_distance
	return maxf(0.0, origin.distance_to(hit.position) - 16.0)
