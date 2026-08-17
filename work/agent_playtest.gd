extends SceneTree

const LEVEL_SCENE := preload("res://scenes/prototype/prototype_level.tscn")
const RESULT_WAIT := 0.9

var _results: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _play_attempt(1, "原地水平远距直线斩")
	await _play_attempt(2, "向敌群靠近后原地近身弧斩")
	await _play_attempt(3, "WASD 向上但鼠标向右的弧斩")
	await _play_attempt(4, "先右键取消，再重新瞄准")
	await _play_attempt(5, "等待巡逻并移动后寻找最佳远距直线")

	var result_file := FileAccess.open("res://work/agent_playtest_results.json", FileAccess.WRITE)
	result_file.store_string(JSON.stringify(_results, "\t"))
	result_file.close()
	print("PLAYTEST_RESULT | %s" % JSON.stringify(_results))
	quit(0)


func _play_attempt(index: int, label: String) -> void:
	_release_all_inputs()
	var level := LEVEL_SCENE.instantiate() as PrototypeLevel
	root.add_child(level)
	await process_frame
	await process_frame

	var player := level.get_node("Actors/Player") as PlayerController
	var canceled_once := false

	match index:
		1:
			await _aim_hold_capture_and_release(
				level,
				player,
				player.global_position + Vector2.RIGHT * 400.0,
				0.08,
				"agent_playtest_%d_aim.png" % index
			)
		2:
			await _drive(["move_right"], 0.65)
			var target := player.global_position + Vector2.RIGHT * 12.0
			await _aim_hold_capture_and_release(
				level, player, target, 0.3, "agent_playtest_%d_aim.png" % index
			)
		3:
			await _drive(["move_right", "move_down"], 0.55)
			var target := player.global_position + Vector2.RIGHT * 60.0
			await _aim_hold_capture_and_release(
				level,
				player,
				target,
				0.18,
				"agent_playtest_%d_aim.png" % index,
				["move_up"]
			)
		4:
			await _aim_begin(level, player, _enemy_at(level, 0).global_position)
			await create_timer(0.4).timeout
			await _capture(level, "agent_playtest_%d_before_cancel.png" % index)
			_send_mouse_button(player, MOUSE_BUTTON_RIGHT, true)
			_send_mouse_button(player, MOUSE_BUTTON_RIGHT, false)
			_send_mouse_button(player, MOUSE_BUTTON_LEFT, false)
			level.set_process(true)
			await process_frame
			await process_frame
			canceled_once = level.get_round_state_name() == "OBSERVING" and not level.is_attack_committed()
			var retarget := _find_best_target(level, player)
			await _aim_hold_capture_and_release(
				level, player, retarget, 0.55, "agent_playtest_%d_aim.png" % index
			)
		5:
			await create_timer(1.4).timeout
			await _drive(["move_right", "move_down"], 0.68)
			var best_target := _find_best_target(level, player)
			await _aim_hold_capture_and_release(
				level, player, best_target, 0.75, "agent_playtest_%d_aim.png" % index
			)

	await create_timer(RESULT_WAIT).timeout
	await _capture(level, "agent_playtest_%d_result.png" % index)

	var surviving_enemies: Array[Array] = []
	for child: Node in level.get_node("Actors/Enemies").get_children():
		if child is EnemyController:
			var enemy := child as EnemyController
			surviving_enemies.append([
				enemy.global_position.x,
				enemy.global_position.y,
				enemy.is_alive(),
			])

	_results.append({
		"attempt": index,
		"label": label,
		"player_position": [player.global_position.x, player.global_position.y],
		"surviving_enemies": surviving_enemies,
		"canceled_once": canceled_once,
		"slash_mode": level.get_aim_mode_name(),
		"alive_count": level.get_alive_enemy_count(),
		"result_state": level.get_round_state_name(),
		"state_history": level.get_state_history(),
	})
	print("PLAYTEST_ATTEMPT | %d | %s | alive=%d | canceled=%s | states=%s" % [
		index,
		label,
		level.get_alive_enemy_count(),
		str(canceled_once),
		str(level.get_state_history()),
	])

	level.queue_free()
	await process_frame
	await process_frame


func _release_all_inputs() -> void:
	for action: String in ["move_up", "move_down", "move_left", "move_right"]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _drive(actions: Array[String], duration: float) -> void:
	for action: String in actions:
		Input.action_press(action)
	await create_timer(duration).timeout
	for action: String in actions:
		Input.action_release(action)
	await physics_frame


func _aim_begin(level: PrototypeLevel, player: PlayerController, target: Vector2) -> void:
	player.aim_started.emit(target)
	level.set_process(false)
	await process_frame


func _aim_hold_capture_and_release(
	level: PrototypeLevel,
	player: PlayerController,
	target: Vector2,
	hold_time: float,
	capture_name: String,
	held_actions: Array[String] = []
) -> void:
	for action: String in held_actions:
		Input.action_press(action)
	await _aim_begin(level, player, target)
	await create_timer(hold_time).timeout
	level._update_aim(target)
	await _capture(level, capture_name)
	player.aim_released.emit(target)
	level.set_process(true)
	for action: String in held_actions:
		Input.action_release(action)
	await create_timer(0.05).timeout
	await _capture(level, capture_name.replace("_aim.png", "_execute.png"))
	await process_frame


func _send_mouse_button(player: PlayerController, button: MouseButton, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = root.get_viewport().get_mouse_position()
	event.global_position = event.position
	player._unhandled_input(event)


func _enemy_at(level: PrototypeLevel, index: int) -> EnemyController:
	return level.get_node("Actors/Enemies").get_child(index) as EnemyController


func _find_best_target(level: PrototypeLevel, player: PlayerController) -> Vector2:
	var best_direction := Vector2.RIGHT
	var best_hits := -1
	for degrees: int in range(0, 360, 2):
		var direction := Vector2.RIGHT.rotated(deg_to_rad(float(degrees)))
		var distance := level._calculate_allowed_slash_distance(player.global_position, direction, 400.0)
		var hits := 0
		for child: Node in level.get_node("Actors/Enemies").get_children():
			if not child is EnemyController:
				continue
			var enemy := child as EnemyController
			if not enemy.is_alive():
				continue
			var relative := enemy.global_position - player.global_position
			var along := relative.dot(direction)
			var perpendicular := absf(relative.cross(direction))
			if along >= 0.0 and along <= distance and perpendicular <= 52.0:
				hits += 1
		if hits > best_hits:
			best_hits = hits
			best_direction = direction
	return player.global_position + best_direction * 400.0


func _capture(level: PrototypeLevel, file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := level.get_viewport().get_texture().get_image()
	var error := image.save_png("res://work/%s" % file_name)
	if error != OK:
		push_error("PLAYTEST_CAPTURE_FAIL | %s | %s" % [file_name, error_string(error)])
