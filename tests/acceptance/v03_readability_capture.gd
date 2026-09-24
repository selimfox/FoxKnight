extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _capture(label: String) -> void:
	await process_frame
	if label == "aim":
		var level := current_scene as V03Level
		level._update_aim(level.statues()[0].global_position)
		level._update_hud()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := "res://.godot/v03_readability_%s.png" % label
	var error := image.save_png(ProjectSettings.globalize_path(path))
	print("CAPTURE | %s | %s | %s" % [label, path, error_string(error)])

func _run() -> void:
	var level := load("res://scenes/prototype/v03/level_01.tscn").instantiate() as V03Level
	root.add_child(level)
	current_scene = level
	level.chain_config.direct_kills_required = 1 # Capture the continuation state independent of authored board threshold.
	for statue in level.statues():
		statue.shot_clock = 1000.0
	await _capture("normal")
	var sample_corpse := level._spawn_projectile(V03Projectile.Kind.CORPSE, Vector2(300, 390), Vector2.RIGHT, 260, 0, 12, 2)
	await create_timer(0.12).timeout
	await _capture("corpse_flight")
	sample_corpse.consume()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	level._unhandled_input(key)
	level._on_aim_started(level.statues()[0].global_position)
	level.set_process(false)
	await _capture("aim")
	level._on_aim_released(level.statues()[0].global_position)
	level.set_process(true)
	var shot := level._spawn_projectile(V03Projectile.Kind.ENEMY, level.fox.global_position + Vector2(60, 0), Vector2.LEFT, 250, 0, 7, 4)
	level._cut_enemy_bullet(shot, shot.global_position)
	await _capture("bullet_cut")
	level._end_slash()
	await _capture("choosing")
	quit()
