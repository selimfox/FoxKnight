extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number in range(1, 4):
		var level := (load("res://scenes/prototype/levels/level_%02d.tscn" % number) as PackedScene).instantiate()
		root.add_child(level)
		await process_frame
		await process_frame
		var props := level.get_node("Arena/Props") as TileMapLayer
		var walls := level.get_node("Arena/Walls") as TileMapLayer
		var light := level.get_node("Arena/Moonlight")
		var flames := level.get_node_or_null("Arena/TorchFlames") as Node2D
		_assert(props.z_index > walls.z_index, "L%d torch sprite is in front of wall art" % number)
		_assert(light.get("_fire_positions").size() == 4, "L%d has four animated flame anchors" % number)
		_assert(flames != null and flames.z_index > props.z_index, "L%d pixel flame is in front of its metal cup" % number)
		for position in [Vector2i(2, 2), Vector2i(27, 2), Vector2i(2, 14), Vector2i(27, 14)]:
			_assert(props.get_cell_source_id(position) >= 0 and props.get_cell_atlas_coords(position).y == 0,
				"L%d brazier at %s uses complete 32x64 pixel tile" % [number, position])
		if DisplayServer.get_name() != "headless":
			var image := root.get_viewport().get_texture().get_image()
			_assert(image.save_png("res://output/fire_visual_level_%02d.png" % number) == OK,
				"L%d capture" % number)
			await create_timer(0.25).timeout
			await process_frame
			var animated_image := root.get_viewport().get_texture().get_image()
			_assert(_flame_pixels_changed(image, animated_image, Rect2i(68, 66, 28, 42)),
				"L%d upper-left torch pixel cel changes over time" % number)
			if number == 1:
				_assert(animated_image.save_png("res://output/fire_visual_level_01_animated.png") == OK,
					"L1 animated capture")
		level.queue_free()
		await process_frame
	if _failures.is_empty():
		print("FIRE VISUAL PASS")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS | " + message)
	else:
		_failures.append(message)


func _flame_pixels_changed(a: Image, b: Image, bounds: Rect2i) -> bool:
	var palette := [Color8(173, 67, 36), Color8(240, 127, 42),
		Color8(255, 190, 73), Color8(255, 236, 157)]
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var before := a.get_pixel(x, y)
			var after := b.get_pixel(x, y)
			if before != after and (before in palette or after in palette):
				return true
	return false
