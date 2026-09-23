extends SceneTree

func _initialize() -> void:
	var scene := load("res://scenes/prototype/v03/level_01.tscn") as PackedScene
	var root := scene.instantiate()
	var floor_layer := root.get_node("Terrain/Floor") as TileMapLayer
	var wall_layer := root.get_node("Terrain/Walls") as TileMapLayer
	for y in range(2, 15):
		for x in range(2, 28):
			floor_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	for x in range(2, 28):
		wall_layer.set_cell(Vector2i(x, 2), 0, Vector2i(1, 0))
		wall_layer.set_cell(Vector2i(x, 14), 0, Vector2i(1, 0))
	for y in range(3, 14):
		wall_layer.set_cell(Vector2i(2, y), 0, Vector2i(1, 0))
		wall_layer.set_cell(Vector2i(27, y), 0, Vector2i(1, 0))
	if scene.pack(root) != OK:
		push_error("Could not pack v0.3 example")
	elif ResourceSaver.save(scene, "res://scenes/prototype/v03/level_01.tscn") != OK:
		push_error("Could not save v0.3 example")
	root.free()
	quit()
