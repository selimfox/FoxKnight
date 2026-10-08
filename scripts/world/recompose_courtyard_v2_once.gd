extends SceneTree

## One-time visual reauthoring of the already editable scenes. Never run this
## as an import hook: subsequent hand edits in the Godot editor are canonical.
const FLOOR := preload("res://assets/art/production/environment/courtyard_floor_tileset.tres")
const DECOR := preload("res://assets/art/production/environment/courtyard_decor_tileset.tres")
const WATER := preload("res://assets/art/production/environment/courtyard_water_tileset.tres")
const PROPS := preload("res://assets/art/production/environment/courtyard_props_tileset.tres")


func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--apply"):
		push_error("One-time visual reauthoring requires -- --apply. Back up levels first.")
		quit(2)
		return
	for index in range(1, 4):
		var path := "res://scenes/prototype/levels/level_%02d.tscn" % index
		var level := (load(path) as PackedScene).instantiate() as Node2D
		var arena := level.get_node("Arena") as Node2D
		var floor := arena.get_node("Floor") as TileMapLayer
		var decor := arena.get_node("Decoration") as TileMapLayer
		var water := arena.get_node("WaterSurface") as TileMapLayer
		var props := arena.get_node("Props") as TileMapLayer
		floor.tile_set = FLOOR
		decor.tile_set = DECOR
		water.tile_set = WATER
		props.tile_set = PROPS
		_recompose_floor(floor, index)
		_recompose_water_and_shore(water, decor, index)
		_recompose_edges(decor, props, index)
		var packed := PackedScene.new()
		if packed.pack(level) != OK or ResourceSaver.save(packed, path) != OK:
			push_error("Could not save " + path)
			level.free()
			quit(1)
			return
		print("RECOMPOSED | " + path)
		level.free()
	quit(0)


func _recompose_floor(floor: TileMapLayer, index: int) -> void:
	# Roughly 38% quiet A, 17% B, 12% C and E after the large slabs.
	# Seed uses cell coordinates only so authoring order cannot change the result.
	for cell: Vector2i in floor.get_used_cells():
		var seed := _seed(cell, index)
		var variant := 0
		if seed >= 42 and seed < 61:
			variant = 1
		elif seed >= 61 and seed < 75:
			variant = 2
		elif seed >= 75 and seed < 89:
			variant = 4
		elif seed >= 89 and seed < 95:
			variant = 3
		elif seed >= 95:
			variant = 5
		floor.set_cell(cell, 0, Vector2i(variant % 3, int(variant / 3)))
	var anchor_sets := [
		[Vector2i(5, 4), Vector2i(7, 4), Vector2i(14, 5), Vector2i(21, 4), Vector2i(23, 4), Vector2i(5, 10), Vector2i(7, 10), Vector2i(15, 11), Vector2i(21, 10), Vector2i(23, 10)],
		[Vector2i(5, 5), Vector2i(7, 5), Vector2i(14, 4), Vector2i(21, 5), Vector2i(23, 5), Vector2i(5, 11), Vector2i(7, 11), Vector2i(14, 10), Vector2i(21, 11), Vector2i(23, 11)],
		[Vector2i(5, 4), Vector2i(7, 4), Vector2i(14, 7), Vector2i(21, 4), Vector2i(23, 4), Vector2i(5, 11), Vector2i(7, 11), Vector2i(14, 12), Vector2i(21, 11), Vector2i(23, 11)],
	]
	for anchor: Vector2i in anchor_sets[index - 1]:
		if floor.get_cell_source_id(anchor) < 0 or floor.get_cell_source_id(anchor + Vector2i(1, 1)) < 0:
			continue
		var group := posmod(anchor.x * 3 + anchor.y * 5 + index, 4)
		for y in range(2):
			for x in range(2):
				floor.set_cell(anchor + Vector2i(x, y), 1, Vector2i(group * 2 + x, y))


func _recompose_water_and_shore(water: TileMapLayer, decor: TileMapLayer, index: int) -> void:
	var start := Vector2i(3, 3) if index == 1 else (Vector2i(24, 3) if index == 2 else Vector2i(3, 11))
	var extras := {
		start + Vector2i(1, -1): Vector2i(0, 3),
		start + Vector2i(-1, 1): Vector2i(1, 3),
		start + Vector2i(3, 1): Vector2i(2, 3),
		start + Vector2i(1, 3): Vector2i(0, 4),
	}
	for cell: Vector2i in extras:
		decor.erase_cell(cell)
		water.set_cell(cell, 0, extras[cell])
	for offset: Vector2i in [Vector2i(-1, -1), Vector2i(3, -1), Vector2i(-1, 3), Vector2i(3, 3)]:
		var cell := start + offset
		if water.get_cell_source_id(cell) < 0:
			decor.set_cell(cell, 0, Vector2i(0 if offset.x < 0 else 1, 3))


func _recompose_edges(decor: TileMapLayer, props: TileMapLayer, index: int) -> void:
	# Sparse fine cracks/chips vary the broad stone fields. Keep the middle
	# quieter so actors and the real aim preview remain visually dominant.
	for y in range(2, 15):
		for x in range(2, 28):
			var cell := Vector2i(x, y)
			var center_lane := x >= 9 and x <= 22 and y >= 5 and y <= 11
			var density := 4 if center_lane else 11
			if _seed(cell, index + 17) < density and decor.get_cell_source_id(cell) == -1:
				var chip := _seed(cell, index + 31)
				decor.set_cell(cell, 0, Vector2i(chip % 2, 0 if chip < 50 else 1))
	for cell: Vector2i in [Vector2i(4, 2), Vector2i(9, 2), Vector2i(18, 2), Vector2i(24, 2), Vector2i(4, 14), Vector2i(10, 14), Vector2i(19, 14), Vector2i(25, 14), Vector2i(2, 6), Vector2i(27, 7), Vector2i(2, 10), Vector2i(27, 11)]:
		if decor.get_cell_source_id(cell) == -1:
			decor.set_cell(cell, 0, Vector2i(posmod(cell.x + index, 4), 2))
	for cell: Vector2i in [Vector2i(4, 4), Vector2i(25, 4), Vector2i(4, 12), Vector2i(25, 12), Vector2i(11, 2), Vector2i(19, 2), Vector2i(11, 14), Vector2i(19, 14)]:
		if props.get_cell_source_id(cell) == -1:
			props.set_cell(cell, 0, Vector2i(posmod(cell.x + cell.y + index, 4), 3 if cell.y < 8 else 4))
	# Attach tall props to the inaccessible wall strip, never in a walkable
	# combat lane where an uncollidable column would promise false blocking.
	for x in [8, 22]:
		props.set_cell(Vector2i(x, 1), 0, Vector2i(posmod(x + index, 2), 2))
	for old_anchor: Vector2i in [Vector2i(15, 1), Vector2i(4, 1), Vector2i(25, 1)]:
		props.erase_cell(old_anchor)
	props.set_cell(Vector2i(15, 2), 0, Vector2i(2 if index != 2 else 3, 1))
	props.set_cell(Vector2i(4, 2), 0, Vector2i(2, 2))
	props.set_cell(Vector2i(25, 2), 0, Vector2i(3, 2))


func _seed(cell: Vector2i, index: int) -> int:
	var value := (cell.x * 73856093) ^ (cell.y * 19349663) ^ (index * 83492791)
	return posmod(value, 100)
