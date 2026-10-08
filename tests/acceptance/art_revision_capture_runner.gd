extends SceneTree

const OUTPUT := "res://output/art_revision_20260930/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var campaign: Node = load("res://scenes/prototype/campaign.tscn").instantiate()
	root.add_child(campaign)
	for viewport in [Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1600, 540)]:
		DisplayServer.window_set_size(viewport)
		await _settle()
		await _save("menu_%dx%d" % [viewport.x, viewport.y])
	campaign.queue_free()
	await process_frame
	DisplayServer.window_set_size(Vector2i(960, 540))
	await _settle()
	for number in range(1, 4):
		var level := load("res://scenes/prototype/levels/level_%02d.tscn" % number).instantiate() as PrototypeLevel
		root.add_child(level)
		await _settle()
		var player := level.get_node("Actors/Player") as PlayerController
		var sprite := player.get_node("Visual/Sprite") as CharacterAnimation
		var hud := level.get_node("HUD") as PrototypeHUD
		await _save("level_%02d_observe" % number)
		level.set_process(false)
		level.call("_on_aim_started", player.global_position + Vector2(32, 0))
		await _settle()
		await _save("level_%02d_arc" % number)
		level.call("_update_aim", player.global_position + Vector2(400, -145))
		await create_timer(0.22).timeout
		await _settle()
		await _save("level_%02d_straight" % number)
		# Real movement inputs keep physics and the existing controller active.
		Input.action_press("move_down")
		await create_timer(0.14).timeout
		level.call("_update_aim", player.global_position + Vector2(400, -145))
		await _save("level_%02d_moving_aim" % number)
		Input.action_release("move_down")
		level.call("_on_aim_cancel_requested")
		await _save("level_%02d_cancel" % number)
		player.set_input_enabled(false)
		level.call("_on_aim_started", player.global_position + Vector2(400, 0))
		level.call("_on_aim_released", player.global_position + Vector2(400, 0))
		for frame in range(6):
			await create_timer(0.04).timeout
			await _save("level_%02d_release_%02d" % [number, frame])
		await create_timer(0.6).timeout
		await _save("level_%02d_result" % number)
		if number == 1:
			# Test presentation avoidance on actual actors at both screen edges.
			var survivors: Array[Vector2] = [Vector2(380, 450), Vector2(550, 140)]
			hud.show_result(false, 2, true, false, survivors)
			await _save("result_survivor_avoidance")
			hud.get_node("Root/ResultPanel").hide()
			player.global_position = Vector2(480, 464)
			sprite.play("idle", "front")
			await _save("south_wall_actor")
			var water := level.get_node("Arena/WaterSurface") as TileMapLayer
			player.global_position = water.to_global(water.map_to_local(Vector2i(4, 4)))
			for frame in range(4):
				sprite.play("walk", ["front", "left", "back", "side"][frame])
				await create_timer(0.04).timeout
				await _save("water_turn_%02d" % frame)
			player.global_position = Vector2(480, 272)
			await _settle()
			await _save("water_exit")
			for edge in ["west", "east", "north", "south"]:
				player.position = {"west": Vector2(80, 272), "east": Vector2(880, 272), "north": Vector2(480, 80), "south": Vector2(480, 464)}[edge]
				sprite.play("idle", "front")
				await _settle()
				await _save("actor_edge_" + edge)
		level.queue_free()
		await process_frame
	await _capture_dense_result()
	await _capture_water_sequence()
	print("RESULT | PASS | Actual art revision captures")
	quit()


func _capture_dense_result() -> void:
	var level: PrototypeLevel = load("res://scenes/prototype/levels/level_02.tscn").instantiate()
	root.add_child(level)
	await _settle()
	level.set_process(false)
	var enemies := level.get_node("Actors/Enemies")
	var positions := [Vector2(100, 130), Vector2(800, 130), Vector2(100, 450), Vector2(800, 450), Vector2(330, 450), Vector2(570, 130)]
	while enemies.get_child_count() < positions.size():
		var soldier: Node = load("res://scenes/actors/enemy.tscn").instantiate()
		enemies.add_child(soldier)
	var protected: Array[Rect2] = []
	for index in positions.size():
		var enemy := enemies.get_child(index) as EnemyController
		enemy.set_physics_process(false)
		enemy.position = positions[index]
		var sprite := enemy.get_node("Visual/Sprite") as Sprite2D
		protected.append((sprite.get_global_transform_with_canvas() * sprite.get_rect()).grow(8))
	var points: Array[Vector2] = []
	(level.get_node("HUD") as PrototypeHUD).show_result(false, positions.size(), true, false, points, protected)
	await _settle()
	await _save("result_dense_survivor_avoidance")
	level.queue_free()
	await process_frame


func _capture_water_sequence() -> void:
	var level: PrototypeLevel = load("res://scenes/prototype/levels/level_01.tscn").instantiate()
	root.add_child(level)
	await _settle()
	var player := level.get_node("Actors/Player") as PlayerController
	var surface := level.get_node("Arena/WaterReflections")
	player.position = Vector2(80, 138)
	await _settle()
	var sequence_index := 0
	var entered := false
	var exited := false
	Input.action_press("move_right")
	for frame in range(6):
		await create_timer(0.08).timeout
		await _save("water_sequence_%02d" % sequence_index)
		entered = entered or _check_live_water_foot(player, surface)
		sequence_index += 1
	Input.action_release("move_right")
	await create_timer(0.12).timeout
	for action in ["move_down", "move_left", "move_up", "move_right"]:
		Input.action_press(action)
		await create_timer(0.08).timeout
		await _save("water_sequence_%02d" % sequence_index)
		assert(_check_live_water_foot(player, surface), "Four-way turn remains inside the water mask")
		sequence_index += 1
		Input.action_release(action)
		for frame in range(2):
			await create_timer(0.08).timeout
			await _save("water_sequence_%02d" % sequence_index)
			_check_live_water_foot(player, surface)
			sequence_index += 1
	Input.action_press("move_right")
	for frame in range(12):
		await create_timer(0.08).timeout
		await _save("water_sequence_%02d" % sequence_index)
		var wet := _check_live_water_foot(player, surface)
		exited = exited or (entered and not wet)
		sequence_index += 1
	Input.action_release("move_right")
	assert(entered and exited, "Real controller sequence enters and leaves water")
	print("WATER SEQUENCE | PASS | ", sequence_index, " continuous frames, live mask/reflection synchronized")
	level.queue_free()
	await process_frame


func _check_live_water_foot(player: PlayerController, surface: Node) -> bool:
	var wet: bool = surface.call("_has_water_at", player.get_visual_foot_anchor_global())
	var reflection: Sprite2D = surface.call("get_reflection_for_actor", player)
	assert(reflection != null and reflection.visible == wet, "Live reflection agrees with the current foot mask")
	return wet


func _settle() -> void:
	for frame in range(4):
		await process_frame


func _save(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var result := root.get_viewport().get_texture().get_image().save_png(OUTPUT + filename + ".png")
	assert(result == OK)
	print("CAPTURE | ", filename)
