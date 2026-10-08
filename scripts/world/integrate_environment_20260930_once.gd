extends SceneTree

# Explicit authoring utility; saved TileMaps stay editable and are never regenerated at runtime.
const PACKAGE := "res://assets/art/production/environment_20260930/"
const RESOURCES := "res://assets/art/production/environment/"


func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--apply"):
		quit(2)
		return
	for index in range(1, 4):
		var path := "res://scenes/prototype/levels/level_%02d.tscn" % index
		var level := (load(path) as PackedScene).instantiate()
		var floor := level.get_node("Arena/Floor") as TileMapLayer
		var walls := level.get_node("Arena/Walls") as TileMapLayer
		var decor := level.get_node("Arena/Decoration") as TileMapLayer
		var water := level.get_node("Arena/WaterSurface") as TileMapLayer
		var original_floor := floor.get_used_cells()
		var original_walls := walls.get_used_cells()
		var original_water := water.get_used_cells()
		var floor_set := _tileset("floor_level_%02d_world2x.png" % index, Vector2i(9, 12), 2)
		ResourceSaver.save(floor_set, RESOURCES + "courtyard_floor_level_%02d_tileset.tres" % index)
		floor.tile_set = load(RESOURCES + "courtyard_floor_level_%02d_tileset.tres" % index)
		for cell in original_floor:
			var block := Vector2i(floori(float(cell.x) / 3.0), floori(float(cell.y) / 3.0))
			var variant := posmod(block.x * 5 + block.y * 3 + index, 8)
			if cell.x <= 4 or cell.x >= 25 or cell.y <= 3 or cell.y >= 13:
				var seed := posmod(block.x * 17 + block.y * 31 + index * 11, 10)
				if seed >= 7:
					variant = 8 + posmod(seed + index, 4)
			floor.set_cell(cell, 2, Vector2i((variant % 3) * 3 + posmod(cell.x, 3), int(variant / 3) * 3 + posmod(cell.y, 3)))
		var wall_set := _tileset("wall_world2x.png", Vector2i(4, 3), 0)
		ResourceSaver.save(wall_set, RESOURCES + "courtyard_wall_20260930_tileset.tres")
		walls.tile_set = load(RESOURCES + "courtyard_wall_20260930_tileset.tres")
		var decor_set := _tileset("decor_world2x.png", Vector2i(4, 2), 0)
		ResourceSaver.save(decor_set, RESOURCES + "courtyard_decor_20260930_tileset.tres")
		var decoration_cells := decor.get_used_cells()
		decor.tile_set = load(RESOURCES + "courtyard_decor_20260930_tileset.tres")
		for cell in decoration_cells:
			if cell.x > 5 and cell.x < 24 and cell.y > 3 and cell.y < 13:
				decor.erase_cell(cell)
			else:
				decor.set_cell(cell, 0, Vector2i(posmod(cell.x * 3 + index, 4), posmod(cell.y + index, 2)))
		var water_set := _tileset("water_world2x.png", Vector2i(4, 5), 1)
		ResourceSaver.save(water_set, RESOURCES + "courtyard_water_20260930_tileset.tres")
		water.tile_set = load(RESOURCES + "courtyard_water_20260930_tileset.tres")
		for cell in original_water:
			water.set_cell(cell, 1, _shore(cell, original_water, index))
		assert(floor.get_used_cells().size() == original_floor.size())
		assert(walls.get_used_cells() == original_walls)
		assert(water.get_used_cells() == original_water)
		var packed := PackedScene.new()
		assert(packed.pack(level) == OK)
		assert(ResourceSaver.save(packed, path) == OK)
		print("INTEGRATED | ", path, " | floor=", original_floor.size(), " wall=", original_walls.size(), " water=", original_water.size())
		level.free()
	quit()


func _tileset(filename: String, cells: Vector2i, source_id: int) -> TileSet:
	var source := TileSetAtlasSource.new()
	source.texture = load(PACKAGE + filename)
	source.texture_region_size = Vector2i(32, 32)
	for y in range(cells.y):
		for x in range(cells.x):
			source.create_tile(Vector2i(x, y))
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(32, 32)
	tileset.add_source(source, source_id)
	return tileset


func _shore(cell: Vector2i, cells: Array[Vector2i], index: int) -> Vector2i:
	var n := cells.has(cell + Vector2i.UP)
	var e := cells.has(cell + Vector2i.RIGHT)
	var s := cells.has(cell + Vector2i.DOWN)
	var w := cells.has(cell + Vector2i.LEFT)
	if not n and not w: return Vector2i(0, 1)
	if not n and not e: return Vector2i(2, 1)
	if not s and not e: return Vector2i(0, 2)
	if not s and not w: return Vector2i(2, 2)
	if not n: return Vector2i(1, 1)
	if not e: return Vector2i(3, 1)
	if not s: return Vector2i(1, 2)
	if not w: return Vector2i(3, 2)
	if not cells.has(cell + Vector2i(-1, -1)): return Vector2i(0, 3)
	if not cells.has(cell + Vector2i(1, -1)): return Vector2i(1, 3)
	if not cells.has(cell + Vector2i(1, 1)): return Vector2i(2, 3)
	if not cells.has(cell + Vector2i(-1, 1)): return Vector2i(3, 3)
	return Vector2i(posmod(cell.x + cell.y + index, 4), 0)
