extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var level := load("res://scenes/prototype/levels/level_01.tscn").instantiate() as PrototypeLevel
	root.add_child(level)
	for frame in 3:
		await process_frame
	var player := level.get_node("Actors/Player") as PlayerController
	var feedback := level.get_node("FeedbackController") as FeedbackController
	var enemy := level.get_node("Actors/Enemies").get_child(0) as EnemyController
	var fx_atlas := load("res://assets/art/production/fx/fx_world2x.png") as Texture2D
	_check(fx_atlas != null and fx_atlas.get_size() == Vector2(256, 128), "28-frame FX atlas imports at 2x size")
	player.update_arc_aim_preview(90.0)
	player.update_straight_aim_preview(Vector2.RIGHT, 250.0, 70.0, 90.0)
	var switch_fx := player.get_node("FormSwitchFX") as PixelFXPlayer
	_check(player.get_form_switch_feedback_count() == 1, "Form change still emits one event")
	_check(switch_fx.get_sequence_name() == "switch_cool" and switch_fx.get_sprite_count() == 8, "Cool switch pixel FX matches target form")
	player.update_arc_aim_preview(90.0)
	_check(player.get_form_switch_feedback_count() == 2 and switch_fx.get_sequence_name() == "switch_warm", "Warm switch pixel FX matches target form")
	player.clear_aim_preview()
	_check(switch_fx.get_sequence_name() == "", "Cancel clears switch FX without consuming attack")

	feedback.play_hit(enemy)
	var hit_count := 0
	var death_count := 0
	for child in level.get_children():
		if child is PixelFXPlayer:
			if child.get_sequence_name() == "hit":
				hit_count += 1
			elif child.get_sequence_name() == "death":
				death_count += 1
	_check(hit_count == 1 and death_count == 0, "True hit feedback starts impact without premature death residue")
	await create_timer(0.12).timeout
	for child in level.get_children():
		if child is PixelFXPlayer and child.get_sequence_name() == "death":
			death_count += 1
	_check(death_count == 1, "Death residue follows the hit pose, independent of death eligibility/count truth")

	var slash := load("res://scenes/combat/prototype_slash.tscn").instantiate() as PrototypeSlash
	level.get_node("Effects").add_child(slash)
	var initial_width := slash.width
	var initial_distance := slash.distance
	var slash_state := {"finished": false}
	slash.finished.connect(func(_n: int) -> void: slash_state["finished"] = true)
	slash.execute(player, player.global_position, PrototypeSlash.SlashMode.STRAIGHT, Vector2.RIGHT, 180.0, 90.0)
	await create_timer(0.06).timeout
	_check(slash.has_execution_coverage() and slash.get_execution_visual_language() == "COOL_STRAIGHT", "Straight query onset reveals full truthful coverage with segmented authored blade")
	_check(is_equal_approx(slash.width, initial_width) and is_equal_approx(slash.distance, initial_distance), "FX does not modify slash geometry")
	_capture("res://output/fx_straight_960x540.png")
	await create_timer(0.28).timeout
	_check(slash_state["finished"], "Straight slash finishes at existing timing")

	var arc := load("res://scenes/combat/prototype_slash.tscn").instantiate() as PrototypeSlash
	level.get_node("Effects").add_child(arc)
	var start := player.global_position
	var arc_state := {"finished": false}
	arc.finished.connect(func(_n: int) -> void: arc_state["finished"] = true)
	arc.execute(player, start, PrototypeSlash.SlashMode.ARC, Vector2.ZERO, -1.0, 110.0)
	await create_timer(0.06).timeout
	_check(arc.has_execution_coverage() and arc.ARC_BLADE.get_size() == Vector2(1440, 240), "Arc uses six authored 240px frames with full active-area coverage")
	_check(arc.is_arc_visual_active() and is_equal_approx(arc.get_arc_visual_radius(), 110.0), "Arc FX preserves actual 110 query radius")
	_capture("res://output/fx_arc_960x540.png")
	await create_timer(0.28).timeout
	_check(arc_state["finished"] and player.global_position.distance_to(start) < 0.01, "Arc slash finishes stationary")
	print("RESULT | ", "FAIL" if _failed else "PASS", " | FX visual acceptance")
	quit(1 if _failed else 0)


func _capture(path: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var image := root.get_viewport().get_texture().get_image()
	_check(image.get_size() == Vector2i(960, 540) and image.save_png(path) == OK, "Captured " + path)


func _check(condition: bool, label: String) -> void:
	if not condition:
		_failed = true
	print("PASS" if condition else "FAIL", " | ", label)
