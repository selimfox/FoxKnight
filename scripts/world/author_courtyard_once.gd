extends SceneTree

## One-time scene conversion. The saved TileMap cells are the authored source;
## do not rerun after manually editing scenes.
const FLOOR := preload("res://assets/art/production/environment/courtyard_floor_tileset.tres")
const WALL := preload("res://assets/art/production/environment/courtyard_wall_tileset.tres")
const DECOR := preload("res://assets/art/production/environment/courtyard_decor_tileset.tres")
const WATER := preload("res://assets/art/production/environment/courtyard_water_tileset.tres")
const PROPS := preload("res://assets/art/production/environment/courtyard_props_tileset.tres")
const WATER_SCRIPT := preload("res://scripts/world/water_surface.gd")


func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--force"):
		push_error("This conversion has already been applied. Refusing to overwrite authored TileMap edits without -- --force.")
		quit(2)
		return
	for index in range(1, 4):
		var path := "res://scenes/prototype/levels/level_%02d.tscn" % index
		var packed := load(path) as PackedScene
		var scene := packed.instantiate() as Node2D
		var arena := scene.get_node("Arena") as Node2D
		var plate := arena.get_node_or_null("CourtyardPlate")
		if plate != null:
			arena.remove_child(plate)
			plate.free()
		var floor := arena.get_node("Floor") as TileMapLayer
		var walls := arena.get_node("Walls") as TileMapLayer
		floor.tile_set = FLOOR
		floor.modulate = Color.WHITE
		floor.z_index = -2
		walls.tile_set = WALL
		walls.modulate = Color.WHITE
		walls.z_index = 2
		for cell: Vector2i in floor.get_used_cells():
			var seed := posmod(cell.x * 73 + cell.y * 131 + cell.x * cell.y * 17 + index * 29, 97)
			var variant := 0 if seed < 84 else (1 if seed < 89 else (2 if seed < 93 else (3 if seed < 96 else (4 if seed < 98 else 5))))
			floor.set_cell(cell, 0, Vector2i(variant % 3, variant / 3))
		for cell: Vector2i in walls.get_used_cells():
			var atlas := Vector2i(0, 0)
			if cell.y <= 1:
				atlas = Vector2i(2 if cell.x <= 1 else (3 if cell.x >= 28 else posmod(cell.x + index, 2)), 0)
			elif cell.y >= 15:
				atlas = Vector2i(2 if cell.x <= 1 else (3 if cell.x >= 28 else posmod(cell.x + index, 2)), 1)
			else:
				atlas = Vector2i(0 if cell.x <= 1 else 2, 2)
			walls.set_cell(cell, 0, atlas)
		var decor := arena.get_node_or_null("Decoration") as TileMapLayer
		if decor == null:
			decor = _layer(arena, scene, "Decoration", DECOR, -1)
		else:
			decor.tile_set = DECOR
			decor.visible = true
			decor.z_index = -1
			for cell: Vector2i in decor.get_used_cells():
				var old_atlas := decor.get_cell_atlas_coords(cell)
				decor.set_cell(cell, 0, old_atlas)
		if index > 1:
			for cell: Vector2i in [Vector2i(4, 3), Vector2i(9, 12), Vector2i(24, 4), Vector2i(18, 13), Vector2i(12, 3), Vector2i(26, 12)]:
				decor.set_cell(cell, 0, Vector2i(posmod(cell.x + index, 4), posmod(cell.y + index, 2)))
		for cell: Vector2i in [Vector2i(4, 2), Vector2i(8, 3), Vector2i(13, 2), Vector2i(20, 3), Vector2i(25, 2), Vector2i(3, 6), Vector2i(26, 8), Vector2i(3, 11), Vector2i(7, 14), Vector2i(14, 13), Vector2i(21, 14), Vector2i(26, 12)]:
			decor.set_cell(cell, 0, Vector2i(posmod(cell.x * 3 + index, 4), posmod(cell.y + index, 2)))
		var water := arena.get_node_or_null("WaterSurface") as TileMapLayer
		if water == null:
			water = _layer(arena, scene, "WaterSurface", WATER, -1)
		water.tile_set = WATER
		water.clear()
		var start := Vector2i(3, 3) if index == 1 else (Vector2i(24, 3) if index == 2 else Vector2i(3, 11))
		for y in range(3):
			for x in range(3):
				var atlas := Vector2i(0, 0)
				if y == 0:
					atlas = [Vector2i(2, 1), Vector2i(1, 0), Vector2i(0, 2)][x]
				elif y == 1:
					atlas = [Vector2i(0, 1), Vector2i(0, 0), Vector2i(1, 1)][x]
				else:
					atlas = [Vector2i(1, 2), Vector2i(2, 0), Vector2i(2, 2)][x]
				water.set_cell(start + Vector2i(x, y), 0, atlas)
		for shore_cell: Vector2i in [start + Vector2i(-1, 0), start + Vector2i(3, 1), start + Vector2i(3, 2), start + Vector2i(0, 3)]:
			decor.set_cell(shore_cell, 0, Vector2i(2 if shore_cell.x < start.x else 3, 0))
		var props := arena.get_node_or_null("Props") as TileMapLayer
		if props == null:
			props = _layer(arena, scene, "Props", PROPS, 0)
		props.tile_set = PROPS
		props.clear()
		for cell: Vector2i in [Vector2i(2, 2), Vector2i(27, 2), Vector2i(2, 14), Vector2i(27, 14)]:
			props.set_cell(cell, 0, Vector2i(posmod(cell.x + index, 2), 0))
		for cell: Vector2i in [Vector2i(5, 2), Vector2i(25, 14), Vector2i(23, 2), Vector2i(6, 14)]:
			props.set_cell(cell, 0, Vector2i(posmod(cell.x, 2), 1))
		var reflection := arena.get_node_or_null("WaterReflections") as Node2D
		if reflection == null:
			reflection = Node2D.new()
			reflection.name = "WaterReflections"
			reflection.script = WATER_SCRIPT
			arena.add_child(reflection)
			reflection.owner = scene
			reflection.z_index = -1
		var moon := arena.get_node_or_null("Moonlight")
		if moon != null:
			moon.z_index = -1
		var output := PackedScene.new()
		var packed_ok := output.pack(scene)
		if packed_ok != OK:
			push_error("Failed to pack " + path)
			quit(1)
			return
		var saved := ResourceSaver.save(output, path)
		if saved != OK:
			push_error("Failed to save " + path)
			quit(1)
			return
		print("AUTHORED | " + path)
		scene.free()
	quit(0)


func _layer(parent: Node2D, owner: Node, name: String, tiles: TileSet, depth: int) -> TileMapLayer:
	var layer := TileMapLayer.new()
	layer.name = name
	layer.tile_set = tiles
	layer.z_index = depth
	parent.add_child(layer)
	layer.owner = owner
	return layer
