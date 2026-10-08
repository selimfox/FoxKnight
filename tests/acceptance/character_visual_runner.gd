extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var player := load("res://scenes/actors/player.tscn").instantiate() as PlayerController
	root.add_child(player)
	await process_frame
	var fox := player.get_node("Visual/Sprite") as CharacterAnimation
	var fox_shadow := player.get_node("GroundShadow") as DynamicActorShadow
	_check(fox.get_frame_count("idle", "front") >= 2, "Fox idle has distinct frames")
	_check(fox.get_frame_count("walk", "side") == 6, "Fox walk has six frames")
	_check(fox.get_frame_count("ready", "left") == 2, "Fox ready has two frames")
	_check(fox.get_frame_count("straight", "back") == 4, "Fox straight has four frames")
	_check(fox.get_frame_count("arc", "front") == 6, "Fox arc has six frames")
	_check(player.get_current_animation_frame_texture() != null, "Fox exports current frame")
	_check(player.get_visual_foot_anchor_global().distance_to(player.global_position) < 0.01, "Fox sprite foot anchor meets actor origin")
	player.set_input_enabled(false)
	fox.play("walk", "side")
	var first_region := (fox.texture as AtlasTexture).region
	await create_timer(0.12).timeout
	_check(fox.get_frame_index() > 0, "Fox walk advances in runtime")
	_check((fox.texture as AtlasTexture).region != first_region, "Fox runtime frame uses another atlas rect")
	player.update_arc_aim_preview(100.0)
	_check(fox.get_animation_name() == "ready", "Fox aim maps to ready")
	player.play_arc_attack_pose(0.22)
	_check(fox.get_animation_name() == "arc", "Fox arc commit maps to arc frames")
	var first_direction := fox_shadow.get_projection_direction()
	fox_shadow.main_light_world_position = Vector2(500.0, 500.0)
	_check(first_direction.dot(fox_shadow.get_projection_direction()) < 0.0, "Projection follows changed light position")
	_check(fox_shadow.frame_source == fox, "Projection consumes current animation frame")
	player.queue_free()
	await process_frame

	var enemy := load("res://scenes/actors/enemy.tscn").instantiate() as EnemyController
	root.add_child(enemy)
	await process_frame
	var soldier := enemy.get_node("Visual/Sprite") as CharacterAnimation
	_check(soldier.get_frame_count("idle", "front") >= 2, "Soldier idle has two frames")
	_check(soldier.get_frame_count("walk", "side") == 6, "Soldier pursuit uses six walk frames")
	_check(soldier.get_frame_count("hit", "back") == 2, "Soldier hit has two frames")
	_check(soldier.get_frame_count("death", "left") == 5, "Soldier death has five frames")
	_check(enemy.get_visual_foot_anchor_global().distance_to(enemy.global_position) < 0.01, "Soldier foot anchor meets actor origin")
	enemy.take_hit()
	_check(not enemy.is_alive() and soldier.get_animation_name() == "hit", "Hit visual begins at death truth event")
	await create_timer(0.12).timeout
	_check(is_instance_valid(enemy) and soldier.get_animation_name() == "death", "Death visual follows hit")
	await create_timer(0.55).timeout
	_check(not is_instance_valid(enemy), "Soldier is eventually freed after death visual")
	if DisplayServer.get_name() != "headless":
		var level: Node = load("res://scenes/prototype/levels/level_01.tscn").instantiate()
		root.add_child(level)
		for frame in 4:
			await process_frame
		var capture_path := "res://output/character_visual_level01_20260926.png"
		var image := root.get_viewport().get_texture().get_image()
		_check(image.save_png(capture_path) == OK, "Rendered Level 1 character capture saved")
		print("CHARACTER CAPTURE | ", capture_path, " | ", image.get_size())
		var scene_player := level.get_node("Actors/Player") as PlayerController
		var scene_shadow := scene_player.get_node("GroundShadow") as DynamicActorShadow
		# The courtyard light controller normally owns this property each frame.
		# Pause that owner while testing a deliberate left/right light change.
		var courtyard_light := level.get_node("Arena/Moonlight") as Node2D
		courtyard_light.set_process(false)
		scene_player.global_position = Vector2(480.0, 272.0)
		scene_shadow.main_light_world_position = Vector2(300.0, 80.0)
		scene_shadow.queue_redraw()
		await RenderingServer.frame_post_draw
		var left_light_image := root.get_viewport().get_texture().get_image()
		_check(left_light_image.save_png("res://output/character_shadow_light_left.png") == OK, "Directional shadow capture from left light saved")
		scene_shadow.main_light_world_position = Vector2(660.0, 80.0)
		scene_shadow.queue_redraw()
		await RenderingServer.frame_post_draw
		var right_light_image := root.get_viewport().get_texture().get_image()
		_check(right_light_image.save_png("res://output/character_shadow_light_right.png") == OK, "Directional shadow capture from right light saved")
		_check(left_light_image.get_region(Rect2i(430, 245, 100, 75)).get_data() != right_light_image.get_region(Rect2i(430, 245, 100, 75)).get_data(), "Light move changes rendered shadow pixels near fox")
		level.queue_free()
		await process_frame
	print("RESULT | ", "FAIL" if _failed else "PASS", " | Character visual acceptance")
	quit(1 if _failed else 0)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failed = true
	print("FAIL" if not condition else "PASS", " | ", label)
