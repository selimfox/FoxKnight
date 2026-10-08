extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number in range(1, 4):
		var level := (load("res://scenes/prototype/levels/level_%02d.tscn" % number) as PackedScene).instantiate() as PrototypeLevel
		root.add_child(level)
		for frame in 4:
			await process_frame
		await _save("res://output/environment_level_%02d_960x540.png" % number)
		if number == 1:
			var player := level.get_node("Actors/Player") as PlayerController
			var water := level.get_node("Arena/WaterSurface") as TileMapLayer
			var reflection := level.get_node("Arena/WaterReflections")
			player.set_input_enabled(false)
			player.set_physics_process(false)
			player.global_position = water.to_global(water.map_to_local(Vector2i(4, 4)))
			await process_frame
			await process_frame
			await _save("res://output/environment_water_01_enter.png")
			var visual := player.get_node("Visual/Sprite") as CharacterAnimation
			visual.play("walk", "side")
			reflection.call("_process", 0.0)
			await process_frame
			await _save("res://output/environment_water_02_turn.png")
			await create_timer(0.14).timeout
			reflection.call("_process", 0.0)
			await _save("res://output/environment_water_03_walk_frame.png")
			visual.play("arc", "front")
			reflection.call("_process", 0.0)
			await process_frame
			await _save("res://output/environment_water_04_arc_frame.png")
			player.global_position = Vector2(224, 272)
			reflection.call("_process", 0.0)
			await process_frame
			await _save("res://output/environment_water_05_exit.png")
		level.queue_free()
		await process_frame
	quit()


func _save(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_viewport().get_texture().get_image()
	var result := image.save_png(path)
	print("ENVIRONMENT CAPTURE | ", path, " | ", image.get_size(), " | ", result)
