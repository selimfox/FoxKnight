extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number: int in range(1, 4):
		var path := "res://scenes/prototype/levels/level_%02d.tscn" % number
		var level: Node = (load(path) as PackedScene).instantiate()
		var floor: TileMapLayer = level.get_node("Arena/Floor")
		var walls: TileMapLayer = level.get_node("Arena/Walls")
		var water: TileMapLayer = level.get_node("Arena/WaterSurface")
		var decor: TileMapLayer = level.get_node("Arena/Decoration")
		var player: PlayerController = level.get_node("Actors/Player")
		var reflections: Node2D = level.get_node("Arena/WaterReflections")
		_check(floor.get_used_cells().size() == 420, "%d full floor coverage" % number)
		_check(walls.get_used_cells().size() == 82, "%d closed wall count preserved" % number)
		_check(water.get_used_cells().size() == 9, "%d editable 3x3 water" % number)
		_check(decor.get_used_cells().size() > 15 and decor.get_used_cells().size() < 30, "%d sparse editable decor" % number)
		for y: int in range(1, 16):
			for x: int in range(1, 29):
				_check(floor.get_cell_source_id(Vector2i(x, y)) == 2, "%d floor macro source at %d,%d" % [number, x, y])
		for cell: Vector2i in water.get_used_cells():
			_check(water.get_cell_source_id(cell) == 1, "%d water macro source" % number)
		var pool_origin: Vector2i = [Vector2i(3, 3), Vector2i(24, 3), Vector2i(3, 11)][number - 1]
		for dy: int in 3:
			for dx: int in 3:
				_check(water.get_cell_atlas_coords(pool_origin + Vector2i(dx, dy)) == Vector2i(dx, dy), "%d water/mask mapping %d,%d" % [number, dx, dy])
		root.add_child(level)
		await process_frame
		await physics_frame
		_check(level.get_node("Arena/TileWallCollisions").get_child_count() == 82, "%d wall collisions preserved" % number)
		if DisplayServer.get_name() != "headless":
			await process_frame
			_capture("res://output/environment_pixel_level_%02d.png" % number)
		# Position foot at the center of the opaque mask, not merely at a water cell.
		var desired_foot: Vector2 = water.to_global(water.map_to_local(pool_origin + Vector2i.ONE))
		player.global_position += desired_foot - player.get_visual_foot_anchor_global()
		await physics_frame
		await process_frame
		reflections.call("_process", 0.0)
		var reflection: Sprite2D = reflections.get_reflection_for_actor(player)
		if reflection == null or not reflection.visible:
			print("WATER DEBUG ", number, " foot=", player.get_visual_foot_anchor_global(), " desired=", desired_foot, " cell=", water.local_to_map(water.to_local(player.get_visual_foot_anchor_global())), " inside=", reflections.call("_has_water_at", player.get_visual_foot_anchor_global()), " tex=", reflection.texture if reflection != null else "none")
		_check(reflection != null and reflection.visible, "%d actor enters real water reflection" % number)
		if number == 1 and DisplayServer.get_name() != "headless":
			_capture("res://output/environment_pixel_water_enter.png")
		player.global_position = Vector2(480, 272)
		await process_frame
		_check(not reflection.visible, "%d actor exits water reflection" % number)
		level.queue_free()
		await process_frame
	if failures.is_empty():
		print("RESULT | PASS | Pixel environment modules and reflections")
		quit(0)
	else:
		print("RESULT | FAIL | ", failures.size(), " checks")
		quit(1)


func _check(ok: bool, label: String) -> void:
	if not ok:
		failures.append(label)
		push_error("FAIL | " + label)


func _capture(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	_check(image.save_png(path) == OK, "Capture " + path)
