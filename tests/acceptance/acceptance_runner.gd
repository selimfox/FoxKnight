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
	var configured_enemies := _get_target_enemies(level)
	_expect(not configured_enemies.is_empty(), "AC-01: At least one target enemy is configured")
	_expect(
		level.get_alive_enemy_count() == configured_enemies.size(),
		"AC-01: All configured target enemies are registered without a fixed count"
	)
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

	var effective_arc_radius := level.get_effective_arc_radius()
	var near_target := player.global_position + Vector2.RIGHT * (effective_arc_radius - 1.0)
	player.aim_started.emit(near_target)
	_expect(level.get_round_state_name() == "AIMING", "AC-02: Left press enters AIMING")
	_expect(not level.is_attack_committed(), "AC-02: Entering AIMING does not consume the attack")
	_expect(level.is_player_input_enabled(), "AC-01: Player movement remains enabled while aiming")
	_expect(level.is_aim_preview_visible(), "AC-01/02: Near aim displays the arc preview")
	_expect(level.get_aim_mode_name() == "ARC", "AC-01/02: Distance inside the effective arc radius selects ARC")
	_expect(not level.is_aim_arc_boundary_visible(), "AC-01: ARC uses its attack-circle edge as the switch boundary without a second circle")
	_expect(is_equal_approx(level.get_aim_arc_boundary_radius(), effective_arc_radius), "AC-01: ARC attack radius and slash-form boundary share one effective value")
	_expect(level.get_aim_preview_visual_language() == "WARM_ARC", "AC-06: Arc preview uses the warm visual language")
	_expect(player.get_aim_arc_boundary_visual_language() == "MERGED_WITH_ARC_RANGE", "AC-01: ARC does not present a separate next-form circle")
	_expect(level.has_form_switch_audio_stream(), "AC-01: Slash-form switch feedback has an assigned audio stream")
	_expect(level.get_form_switch_feedback_count() == 0, "AC-01: Initial aim selection does not count as a form switch")
	_expect(is_equal_approx(level.get_aim_preview_radius(), effective_arc_radius), "AC-01/03: Arc preview uses the effective hit radius")
	_expect(is_equal_approx(level.get_aim_preview_width(), effective_arc_radius * 2.0), "AC-01/03: Arc preview remains one circular attack range")
	_expect(is_zero_approx(level.get_aim_preview_distance()), "AC-01/02: Arc preview has no movement component")
	_expect(not (player.get_node("AimPreview/CenterLine") as Line2D).visible, "AC-01/02: Arc preview has no direction arrow")

	level.call("_update_aim", near_target + Vector2.UP)
	_expect(level.get_form_switch_feedback_count() == 0, "AC-01: Updating within ARC does not repeat switch feedback")
	var switch_to_straight_target := player.global_position + Vector2.RIGHT * effective_arc_radius
	level.call("_update_aim", switch_to_straight_target)
	_expect(level.get_aim_mode_name() == "STRAIGHT", "AC-01/02: Reaching the arc boundary updates the preview to STRAIGHT")
	_expect(level.get_form_switch_feedback_count() == 1, "AC-01: ARC to STRAIGHT triggers one switch feedback event")
	_expect(level.is_form_switch_flash_visible(), "AC-01: A real form switch displays the boundary-circle flash")
	_expect(level.get_aim_preview_visual_language() == "COOL_STRAIGHT", "AC-06: Straight preview uses the cool visual language")
	_expect(level.is_aim_arc_boundary_visible(), "AC-01: STRAIGHT keeps one weak arc-radius circle to show where ARC returns")
	_expect(player.get_aim_arc_boundary_visual_language() == "WARM_ARC_PREVIEW", "AC-01: STRAIGHT uses a weak warm circle to preview the ARC zone")
	var straight_boundary_radius := player.get_aim_arc_boundary_radius()
	var straight_boundary_scale := player.get_aim_arc_boundary_scale()
	var straight_boundary_line_width := player.get_aim_arc_boundary_line_width()
	var straight_boundary_alpha_before := player.get_aim_arc_boundary_alpha()
	level.set_process(false)
	await create_timer(0.4).timeout
	level.set_process(true)
	_expect(absf(player.get_aim_arc_boundary_alpha() - straight_boundary_alpha_before) > 0.01, "AC-01: The weak ARC-zone circle breathes through alpha in STRAIGHT")
	_expect(is_equal_approx(player.get_aim_arc_boundary_radius(), straight_boundary_radius), "AC-01: Breathing does not change the ARC-zone radius")
	_expect(player.get_aim_arc_boundary_scale().is_equal_approx(straight_boundary_scale), "AC-01: Breathing does not change the ARC-zone scale")
	_expect(is_equal_approx(player.get_aim_arc_boundary_line_width(), straight_boundary_line_width), "AC-01: Breathing does not change the ARC-zone line width")
	level.call("_update_aim", switch_to_straight_target + Vector2.RIGHT * 10.0)
	_expect(level.get_form_switch_feedback_count() == 1, "AC-01: Updating within STRAIGHT does not repeat switch feedback")
	level.call("_update_aim", near_target)
	_expect(level.get_aim_mode_name() == "ARC", "AC-01/02: Crossing inward updates the preview back to ARC")
	_expect(level.get_form_switch_feedback_count() == 2, "AC-01: STRAIGHT to ARC triggers exactly one additional feedback event")
	_expect(level.get_aim_preview_visual_language() == "WARM_ARC", "AC-06: Returning to ARC restores the warm visual language")
	_expect(not level.is_aim_arc_boundary_visible(), "AC-01: Returning to ARC removes the duplicate outer circle")

	player.aim_cancel_requested.emit()
	_expect(level.get_round_state_name() == "OBSERVING", "AC-02: Right press cancels AIMING")
	_expect(not level.is_attack_committed(), "AC-02: Canceling AIMING preserves the attack")
	_expect(not level.is_aim_preview_visible(), "AC-02: Canceling AIMING hides the preview")

	player.aim_released.emit(near_target)
	_expect(level.get_round_state_name() == "OBSERVING", "AC-02: Left release after cancel is ignored")
	_expect(not level.is_attack_committed(), "AC-02: Left release after cancel cannot consume the attack")

	var boundary_target := player.global_position + Vector2.RIGHT * effective_arc_radius
	player.aim_started.emit(boundary_target)
	_expect(level.get_aim_mode_name() == "STRAIGHT", "AC-02: Distance equal to threshold selects STRAIGHT")
	_expect(is_equal_approx(level.get_aim_preview_distance(), 400.0), "AC-01/02: Straight preview uses the slash distance")
	_expect(is_equal_approx(level.get_aim_preview_width(), 80.0), "AC-01/03: Straight preview uses the effective slash width")
	player.aim_cancel_requested.emit()

	if not configured_enemies.is_empty():
		var guaranteed_survivor := configured_enemies[configured_enemies.size() - 1]
		guaranteed_survivor.move_speed = 0.0
		guaranteed_survivor.global_position = player.global_position + Vector2.LEFT * 200.0

	var far_target := player.global_position + Vector2.RIGHT * (effective_arc_radius + 20.0)
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
	_expect(level.get_alive_enemy_count() > 0, "AC-05: Any surviving configured target produces failure")
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
	var arc_enemies := _get_target_enemies(arc_level)
	_expect(arc_enemies.size() >= 3, "AC-03/05: Arc isolation has enough targets for inside/outside coverage")
	if arc_enemies.size() < 3:
		arc_level.queue_free()
		await process_frame
		_release_all_inputs()
		_finish()
		return
	for enemy: EnemyController in arc_enemies:
		enemy.move_speed = 0.0
	var enemy_a := arc_enemies[0]
	var enemy_b := arc_enemies[1]
	var initial_arc_target := arc_origin + Vector2.RIGHT * 20.0
	arc_player.aim_started.emit(initial_arc_target)
	var prepared_arc := arc_level.get("_prepared_slash") as PrototypeSlash
	prepared_arc.hitbox_tolerance_multiplier = 1.25
	var arc_effective_radius := arc_level.get_effective_arc_radius()
	_expect(is_equal_approx(arc_effective_radius, arc_level.get_arc_radius() * 1.25), "AC-03: Effective arc radius applies the hitbox tolerance exactly once")
	enemy_a.global_position = arc_origin + Vector2(40.0, 0.0)
	enemy_b.global_position = arc_origin + Vector2(0.0, arc_effective_radius - 18.0)
	for index: int in range(2, arc_enemies.size()):
		arc_enemies[index].global_position = arc_origin + Vector2(0.0, arc_effective_radius + 45.0 + index * 4.0)
	await physics_frame

	var arc_target := arc_origin + Vector2.RIGHT * (arc_effective_radius - 10.0)
	arc_level.call("_update_aim", arc_target)
	_expect(arc_level.get_aim_mode_name() == "ARC", "AC-02: Mouse inside the effective radius selects stationary ARC")
	_expect(is_zero_approx(arc_level.get_aim_preview_distance()), "AC-01/02: ARC has no previewed movement distance")
	_expect(not arc_level.is_aim_arc_boundary_visible(), "AC-01: ARC presents only its one attack circle")
	arc_player.aim_released.emit(arc_target)
	await create_timer(0.08).timeout
	_expect(arc_level.get_round_state_name() == "EXECUTING", "AC-02/03: Arc release enters EXECUTING")
	_expect(arc_level.get_aim_mode_name() == "ARC", "AC-02: Arc mode remains fixed after commit")
	_expect(arc_player.global_position.distance_to(arc_origin) < 1.0, "AC-02/03: Arc execution keeps the player at the committed origin")
	_expect(arc_player.get_last_attack_pose_name() == "ARC", "AC-06: Arc slash uses the dedicated player attack pose")
	var active_slash := arc_level.get_node("Effects").get_child(0) as PrototypeSlash
	_expect(active_slash != null and active_slash.is_arc_visual_active(), "AC-06: Arc slash displays the dedicated arc light")
	if active_slash != null:
		_expect(active_slash.get_execution_visual_language() == "WARM_ARC", "AC-06: Arc execution keeps the warm visual language")
		_expect(is_equal_approx(active_slash.get_arc_visual_radius(), arc_effective_radius), "AC-03/06: Arc light, selection boundary, preview, and hit query share one effective radius")
		_expect(active_slash.global_position.distance_to(arc_origin) < 1.0, "AC-03/06: Arc light remains centered on the stationary player")
	await create_timer(0.72).timeout
	_expect(arc_level.get_round_state_name() == "RESOLVED", "AC-04/05: Arc slash resolves exactly once")
	_expect(arc_player.global_position.distance_to(arc_origin) < 1.0, "AC-02/03: Arc slash finishes without moving the player")
	_expect(not is_instance_valid(enemy_a) and not is_instance_valid(enemy_b), "AC-03: Stationary arc circle hits enemies inside its radius")
	var all_outside_enemies_survived := true
	for index: int in range(2, arc_enemies.size()):
		if not is_instance_valid(arc_enemies[index]) or not arc_enemies[index].is_alive():
			all_outside_enemies_survived = false
	_expect(all_outside_enemies_survived, "AC-03: Every enemy outside the stationary arc circle remains alive")
	_expect(
		arc_level.get_alive_enemy_count() == arc_enemies.size() - 2,
		"AC-05: Any number of surviving targets produces failure"
	)

	arc_level.queue_free()
	await process_frame

	_release_all_inputs()
	var victory_level := packed_scene.instantiate() as PrototypeLevel
	root.add_child(victory_level)
	await process_frame
	await process_frame
	var victory_player := victory_level.get_node("Actors/Player") as PlayerController
	var victory_origin := victory_player.global_position
	var victory_enemies := _get_target_enemies(victory_level)
	_expect(
		victory_enemies.size() == configured_enemies.size(),
		"AC-04: Victory isolation uses every target configured by the current scene"
	)
	for enemy: EnemyController in victory_enemies:
		enemy.move_speed = 0.0
	var victory_initial_target := victory_origin + Vector2.RIGHT * 20.0
	victory_player.aim_started.emit(victory_initial_target)
	var victory_radius := victory_level.get_effective_arc_radius()
	for index: int in range(victory_enemies.size()):
		var angle := TAU * float(index) / float(maxi(victory_enemies.size(), 1))
		victory_enemies[index].global_position = victory_origin + Vector2.RIGHT.rotated(angle) * (victory_radius * 0.5)
	await physics_frame
	var victory_target := victory_origin + Vector2.RIGHT * (victory_radius - 10.0)
	victory_player.aim_released.emit(victory_target)
	await create_timer(0.8).timeout
	_expect(victory_level.get_round_state_name() == "RESOLVED", "AC-04: All-target slash resolves exactly once")
	_expect(victory_level.get_alive_enemy_count() == 0, "AC-04: Killing every configured target leaves zero survivors")
	var victory_label := victory_level.get_node("HUD/Root/ResultPanel/ResultLabel") as Label
	_expect(victory_label.text == "胜 利", "AC-04: Zero surviving targets produces the victory result")
	victory_level.queue_free()
	await process_frame
	_release_all_inputs()
	_finish()


func _get_target_enemies(level: PrototypeLevel) -> Array[EnemyController]:
	var result: Array[EnemyController] = []
	var enemy_container := level.get_node_or_null("Actors/Enemies")
	if enemy_container == null:
		return result
	for child: Node in enemy_container.get_children():
		if child is EnemyController:
			result.append(child as EnemyController)
	return result


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
