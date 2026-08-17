extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed_scene := load("res://scenes/prototype/prototype_level.tscn") as PackedScene
	_expect(packed_scene != null, "AC-01: Prototype scene loads")
	if packed_scene == null:
		_finish()
		return

	_release_all_inputs()
	var level := packed_scene.instantiate() as PrototypeLevel
	root.add_child(level)
	await process_frame
	await process_frame

	_expect(level.get_round_state_name() == "OBSERVING", "AC-01: Initial state reaches OBSERVING")
	_expect(level.get_alive_enemy_count() == 3, "AC-01: Three target enemies are registered")
	_expect(level.is_player_input_enabled(), "AC-01: Player input is enabled while observing")

	var debug_enemy := level.get_node("Actors/Enemies/EnemyA") as EnemyController
	_expect(not debug_enemy.show_path, "DEBUG-01: Enemy patrol path defaults to hidden")
	var path_before_move := debug_enemy.get_patrol_path_world_endpoints()
	var enemy_position_before_check := debug_enemy.global_position
	debug_enemy.global_position += Vector2(37.0, 19.0)
	var path_after_move := debug_enemy.get_patrol_path_world_endpoints()
	_expect(path_after_move == path_before_move, "DEBUG-01: Patrol path remains anchored to spawn origin")
	debug_enemy.global_position = enemy_position_before_check

	var player := level.get_node("Actors/Player") as PlayerController
	var left_press := InputEventMouseButton.new()
	left_press.button_index = MOUSE_BUTTON_LEFT
	left_press.pressed = true
	player._unhandled_input(left_press)
	_expect(level.get_round_state_name() == "AIMING", "AC-02: Mouse left press event enters AIMING")
	var right_press := InputEventMouseButton.new()
	right_press.button_index = MOUSE_BUTTON_RIGHT
	right_press.pressed = true
	player._unhandled_input(right_press)
	_expect(level.get_round_state_name() == "OBSERVING", "AC-02: Mouse right press event cancels AIMING")
	var left_release := InputEventMouseButton.new()
	left_release.button_index = MOUSE_BUTTON_LEFT
	left_release.pressed = false
	player._unhandled_input(left_release)
	_expect(level.get_round_state_name() == "OBSERVING", "AC-02: Mouse left release event after cancel is ignored")

	var near_target := player.global_position + Vector2.RIGHT * (level.get_slash_form_distance_threshold() - 1.0)
	player.aim_started.emit(near_target)
	_expect(level.get_round_state_name() == "AIMING", "AC-02: Left press enters AIMING")
	_expect(not level.is_attack_committed(), "AC-02: Entering AIMING does not consume the attack")
	_expect(level.is_player_input_enabled(), "AC-01: Player movement remains enabled while aiming")
	_expect(level.is_aim_preview_visible(), "AC-01/02: Near aim displays the arc preview")
	_expect(level.get_aim_mode_name() == "ARC", "AC-01/02: Distance below threshold selects ARC")
	_expect(level.is_aim_form_threshold_visible(), "AC-01: Aiming displays the slash-form threshold circle")
	_expect(is_equal_approx(level.get_aim_form_threshold_radius(), level.get_slash_form_distance_threshold()), "AC-01: Threshold circle radius matches the real slash-form threshold")
	_expect(level.get_aim_preview_visual_language() == "WARM_ARC", "AC-06: Arc preview uses the warm visual language")
	_expect(player.get_aim_form_threshold_visual_language() == "COOL_STRAIGHT_PREVIEW", "AC-01: ARC uses a cool outer circle to preview the next STRAIGHT form")
	var arc_threshold_radius := player.get_aim_form_threshold_radius()
	var arc_threshold_scale := player.get_aim_form_threshold_scale()
	var arc_threshold_line_width := player.get_aim_form_threshold_line_width()
	var arc_threshold_alpha_before := player.get_aim_form_threshold_alpha()
	level.set_process(false)
	await create_timer(0.4).timeout
	level.set_process(true)
	_expect(absf(player.get_aim_form_threshold_alpha() - arc_threshold_alpha_before) > 0.01, "AC-01: The persistent next-form circle breathes through alpha")
	_expect(is_equal_approx(player.get_aim_form_threshold_radius(), arc_threshold_radius), "AC-01: Breathing does not change the next-form circle radius")
	_expect(player.get_aim_form_threshold_scale().is_equal_approx(arc_threshold_scale), "AC-01: Breathing does not change the next-form circle scale")
	_expect(is_equal_approx(player.get_aim_form_threshold_line_width(), arc_threshold_line_width), "AC-01: Breathing does not change the next-form circle line width")
	_expect(level.has_form_switch_audio_stream(), "AC-01: Slash-form switch feedback has an assigned audio stream")
	_expect(level.get_form_switch_feedback_count() == 0, "AC-01: Initial aim selection does not count as a form switch")
	_expect(is_equal_approx(level.get_aim_preview_radius(), level.get_arc_radius()), "AC-01/03: Arc preview uses the effective radius")
	_expect(is_equal_approx(level.get_aim_preview_deadzone_radius(), level.get_arc_direction_deadzone_radius()), "AC-01/02: Arc preview displays the configured circular direction deadzone")
	_expect(level.is_aim_deadzone_visible(), "AC-01/02: Arc direction deadzone is visible")
	_expect(level.is_aim_direction_arrow_visible(), "AC-01/02: Arc preview displays a mouse-facing movement arrow outside the deadzone")
	_expect(is_equal_approx(level.get_aim_preview_distance(), level.get_arc_move_distance()), "AC-01/03: Arc arrow displays the actual short movement distance")

	level.call("_update_aim", near_target + Vector2.UP)
	_expect(level.get_form_switch_feedback_count() == 0, "AC-01: Updating within ARC does not repeat switch feedback")
	var switch_to_straight_target := player.global_position + Vector2.RIGHT * level.get_slash_form_distance_threshold()
	level.call("_update_aim", switch_to_straight_target)
	_expect(level.get_aim_mode_name() == "STRAIGHT", "AC-01/02: Crossing the threshold updates the preview to STRAIGHT")
	_expect(level.get_form_switch_feedback_count() == 1, "AC-01: ARC to STRAIGHT triggers one switch feedback event")
	_expect(level.is_form_switch_flash_visible(), "AC-01: A real form switch displays the threshold-circle flash")
	_expect(level.get_aim_preview_visual_language() == "COOL_STRAIGHT", "AC-06: Straight preview uses the cool visual language")
	_expect(player.get_aim_form_threshold_visual_language() == "WARM_ARC_PREVIEW", "AC-01: STRAIGHT uses a warm outer circle to preview the next ARC form")
	_expect(player.get_aim_form_threshold_scale().is_equal_approx(Vector2.ONE), "AC-01: Form switches keep the persistent preview circle at fixed scale")
	level.call("_update_aim", switch_to_straight_target + Vector2.RIGHT * 10.0)
	_expect(level.get_form_switch_feedback_count() == 1, "AC-01: Updating within STRAIGHT does not repeat switch feedback")
	level.call("_update_aim", near_target)
	_expect(level.get_aim_mode_name() == "ARC", "AC-01/02: Crossing inward updates the preview back to ARC")
	_expect(level.get_form_switch_feedback_count() == 2, "AC-01: STRAIGHT to ARC triggers exactly one additional feedback event")
	_expect(level.get_aim_preview_visual_language() == "WARM_ARC", "AC-06: Returning to ARC restores the warm visual language")
	_expect(player.get_aim_form_threshold_visual_language() == "COOL_STRAIGHT_PREVIEW", "AC-01: Returning to ARC restores the cool next-form preview circle")

	player.aim_cancel_requested.emit()
	_expect(level.get_round_state_name() == "OBSERVING", "AC-02: Right press cancels AIMING")
	_expect(not level.is_attack_committed(), "AC-02: Canceling AIMING preserves the attack")
	_expect(not level.is_aim_preview_visible(), "AC-02: Canceling AIMING hides the preview")

	player.aim_released.emit(near_target)
	_expect(level.get_round_state_name() == "OBSERVING", "AC-02: Left release after cancel is ignored")
	_expect(not level.is_attack_committed(), "AC-02: Left release after cancel cannot consume the attack")

	var boundary_target := player.global_position + Vector2.RIGHT * level.get_slash_form_distance_threshold()
	player.aim_started.emit(boundary_target)
	_expect(level.get_aim_mode_name() == "STRAIGHT", "AC-02: Distance equal to threshold selects STRAIGHT")
	_expect(is_equal_approx(level.get_aim_preview_distance(), 400.0), "AC-01/02: Straight preview uses the slash distance")
	_expect(is_equal_approx(level.get_aim_preview_width(), 80.0), "AC-01/03: Straight preview uses the effective slash width")
	player.aim_cancel_requested.emit()

	var far_target := player.global_position + Vector2.RIGHT * (level.get_slash_form_distance_threshold() + 20.0)
	player.aim_started.emit(far_target)
	player.aim_released.emit(far_target)
	_expect(level.is_attack_committed(), "AC-02: First attack is committed")
	_expect(level.get_aim_mode_name() == "STRAIGHT", "AC-02: Distance above threshold commits STRAIGHT")
	_expect(level.get_round_state_name() == "EXECUTING", "AC-02: Left release enters EXECUTING")
	_expect(not level.is_player_input_enabled(), "AC-03: Player input locks after attack")
	_expect(not level.is_aim_preview_visible(), "AC-03: Attack commit hides the aim preview")
	var straight_active_slash := level.get_node("Effects").get_child(0) as PrototypeSlash
	_expect(straight_active_slash != null and straight_active_slash.get_execution_visual_language() == "COOL_STRAIGHT", "AC-06: Straight execution keeps the cool visual language")

	player.aim_started.emit(far_target)
	player.aim_cancel_requested.emit()
	_expect(level.get_round_state_name() == "EXECUTING", "AC-02: Second attack request cannot change state")

	await create_timer(0.8).timeout
	_expect(level.get_round_state_name() == "RESOLVED", "AC-04/05: Slash resolves exactly once")
	_expect(level.get_alive_enemy_count() > 0, "AC-05: Default layout demonstrates a failed partial hit")
	_expect(
		level.get_state_history() == [
			"INITIALIZING",
			"OBSERVING",
			"AIMING",
			"OBSERVING",
			"AIMING",
			"OBSERVING",
			"AIMING",
			"OBSERVING",
			"AIMING",
			"EXECUTING",
			"RESOLVED",
		],
		"AC-09: State history includes cancel, dual-mode preview checks, commit, and resolution in order"
	)

	level.queue_free()
	await process_frame

	_release_all_inputs()
	var arc_level := packed_scene.instantiate() as PrototypeLevel
	root.add_child(arc_level)
	await process_frame
	await process_frame
	var arc_player := arc_level.get_node("Actors/Player") as PlayerController
	var arc_origin := arc_player.global_position
	var arc_enemies := arc_level.get_node("Actors/Enemies")
	for child: Node in arc_enemies.get_children():
		if child is EnemyController:
			(child as EnemyController).move_speed = 0.0
	var enemy_a := arc_enemies.get_child(0) as EnemyController
	var enemy_b := arc_enemies.get_child(1) as EnemyController
	var enemy_c := arc_enemies.get_child(2) as EnemyController
	enemy_a.global_position = arc_origin + Vector2(40.0, 0.0)
	enemy_b.global_position = arc_origin + Vector2(80.0, 85.0)
	enemy_c.global_position = arc_origin + Vector2(0.0, 120.0)
	await physics_frame

	var deadzone_target := arc_origin + Vector2.RIGHT * maxf(arc_level.get_arc_direction_deadzone_radius() - 1.0, 0.0)
	arc_player.aim_started.emit(deadzone_target)
	_expect(arc_level.get_aim_mode_name() == "ARC", "AC-02: Mouse inside the direction deadzone selects ARC")
	_expect(is_zero_approx(arc_level.get_aim_preview_distance()), "AC-01/02: Mouse inside the deadzone previews a stationary arc slash")
	_expect(not arc_level.is_aim_direction_arrow_visible(), "AC-01/02: Mouse inside the deadzone hides the movement arrow")
	_expect(is_equal_approx(arc_level.get_aim_preview_width(), arc_level.get_arc_radius() * 2.0), "AC-01/03: Arc preview remains circular instead of becoming a path capsule")
	arc_player.aim_cancel_requested.emit()

	var deadzone_boundary_target := arc_origin + Vector2.RIGHT * arc_level.get_arc_direction_deadzone_radius()
	arc_player.aim_started.emit(deadzone_boundary_target)
	_expect(arc_level.is_aim_direction_arrow_visible(), "AC-01/02: Mouse exactly on the deadzone radius enables the movement arrow")
	_expect(is_equal_approx(arc_level.get_aim_preview_distance(), arc_level.get_arc_move_distance()), "AC-01/02: Deadzone boundary uses the moving arc branch")
	arc_player.aim_cancel_requested.emit()

	var arc_target := arc_origin + Vector2.RIGHT * (arc_level.get_arc_direction_deadzone_radius() + 10.0)
	Input.action_press("move_left")
	arc_player.aim_started.emit(arc_target)
	_expect(arc_level.get_aim_mode_name() == "ARC", "AC-02: Mouse outside the direction deadzone selects a moving ARC")
	_expect(arc_level.is_aim_direction_arrow_visible(), "AC-01/02: Mouse outside the deadzone displays the movement arrow")
	_expect(is_equal_approx(arc_level.get_aim_preview_distance(), arc_level.get_arc_move_distance()), "AC-01/02: Arc movement arrow uses the configured distance")
	arc_player.aim_released.emit(arc_target)
	Input.action_release("move_left")
	Input.action_press("move_up")
	await create_timer(0.08).timeout
	Input.action_release("move_up")
	_expect(arc_level.get_round_state_name() == "EXECUTING", "AC-02/03: Arc release enters EXECUTING")
	_expect(arc_level.get_aim_mode_name() == "ARC", "AC-02: Arc mode remains fixed after commit")
	_expect(arc_player.get_last_attack_pose_name() == "ARC", "AC-06: Arc slash uses the dedicated player attack pose")
	var active_slash := arc_level.get_node("Effects").get_child(0) as PrototypeSlash
	_expect(active_slash != null and active_slash.is_arc_visual_active(), "AC-06: Arc slash displays the dedicated arc light")
	if active_slash != null:
		_expect(active_slash.get_execution_visual_language() == "WARM_ARC", "AC-06: Arc execution keeps the warm visual language")
		_expect(is_equal_approx(active_slash.get_arc_visual_radius(), arc_level.get_arc_radius()), "AC-03/06: Arc light and hit query share the configured radius")
		_expect(active_slash.global_position.distance_to(arc_player.global_position) < 1.0, "AC-03/06: Arc light follows the moving player")
	await create_timer(0.72).timeout
	_expect(arc_level.get_round_state_name() == "RESOLVED", "AC-04/05: Arc slash resolves exactly once")
	_expect(arc_player.global_position.distance_to(arc_origin + Vector2.RIGHT * arc_level.get_arc_move_distance()) < 1.0, "AC-02/03: Arc movement uses the committed mouse direction instead of opposing WASD input")
	_expect(not is_instance_valid(enemy_a) and not is_instance_valid(enemy_b), "AC-03: Moving arc circle hits enemies encountered along the short path")
	_expect(is_instance_valid(enemy_c) and enemy_c.is_alive(), "AC-03: Enemy outside the moving arc circle remains alive")
	_expect(arc_level.get_alive_enemy_count() == 1, "AC-05: Arc test resolves with the expected survivor")

	arc_level.queue_free()
	await process_frame
	_release_all_inputs()
	_finish()


func _release_all_inputs() -> void:
	for action: String in ["move_up", "move_down", "move_left", "move_right"]:
		if InputMap.has_action(action):
			Input.action_release(action)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS | %s" % message)
	else:
		_failures.append(message)
		push_error("FAIL | %s" % message)


func _finish() -> void:
	if _failures.is_empty():
		print("RESULT | PASS | Prototype smoke acceptance")
		quit(0)
	else:
		print("RESULT | FAIL | %d checks failed" % _failures.size())
		quit(1)
