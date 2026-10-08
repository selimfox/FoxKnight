@tool
extends Sprite2D

## The painted plate matches only Level 1's original rectangular TileMap layout.
## If the TileMap is reauthored, show its real tiles rather than lying about walls.
@export var use_painted_plate := true

@onready var _floor: TileMapLayer = get_node("../Floor")
@onready var _walls: TileMapLayer = get_node("../Walls")
@onready var _decoration: TileMapLayer = get_node("../Decoration")


func _ready() -> void:
	_refresh_visual_source()
	set_process(true)


func _process(_delta: float) -> void:
	_refresh_visual_source()


func _refresh_visual_source() -> void:
	if _floor == null or _walls == null or _decoration == null:
		return
	var plate_matches_map := use_painted_plate and _is_original_layout()
	visible = plate_matches_map
	_floor.modulate.a = 0.0 if plate_matches_map else 1.0
	_walls.modulate.a = 0.0 if plate_matches_map else 1.0
	_decoration.visible = not plate_matches_map


func _is_original_layout() -> bool:
	if _floor.get_used_cells().size() != 28 * 15:
		return false
	if _walls.get_used_cells().size() != 28 * 2 + 13 * 2:
		return false
	for y in range(1, 16):
		for x in range(1, 29):
			var cell := Vector2i(x, y)
			if _floor.get_cell_source_id(cell) != 0 or _floor.get_cell_atlas_coords(cell) != Vector2i.ZERO:
				return false
			var should_be_wall := x == 1 or x == 28 or y == 1 or y == 15
			if should_be_wall:
				if _walls.get_cell_source_id(cell) != 0 or _walls.get_cell_atlas_coords(cell) != Vector2i(1, 0):
					return false
			elif _walls.get_cell_source_id(cell) != -1:
				return false
	return true
