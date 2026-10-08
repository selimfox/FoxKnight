extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(960, 540)
	await process_frame
	var level: PrototypeLevel = load("res://scenes/prototype/levels/level_01.tscn").instantiate()
	root.add_child(level)
	await process_frame
	var player := level.get_node("Actors/Player") as PlayerController
	var sprite := player.get_node("Visual/Sprite") as CharacterAnimation
	var hud := level.get_node("HUD") as PrototypeHUD
	for state in ["idle", "walk", "stop", "ready", "ready_walk", "cancel", "straight", "arc", "post"]:
		for direction in ["front", "left", "back", "side"]:
			_check(sprite.get_frame_count(state, direction) > 0, "FOX | " + state + "/" + direction)
	_check(sprite.frame_manifest.contains("e_20260930"), "FOX | formal E frame manifest")
	_check(player.get_node("Visual").z_index > level.get_node("Arena/Walls").z_index, "ACTOR | upper body draws above wall tiles")
	level.call("_on_aim_started", player.position + Vector2(300, 100))
	var before := player.position
	Input.action_press("move_down")
	await create_timer(0.12).timeout
	_check(player.position.distance_to(before) > 1.0, "AIM | moving aim keeps existing movement")
	_check(sprite.get_animation_name() == "ready_walk", "AIM | moving aim maps to ready_walk")
	Input.action_release("move_down")
	level.call("_on_aim_cancel_requested")
	_check(sprite.get_animation_name() == "cancel", "AIM | cancellation triggers authored cancel frame")
	_check(not level.attack_committed, "AIM | cancel leaves attack unspent")
	var empty_points: Array[Vector2] = []
	for protected_rects in [
		[Rect2(300, 380, 96, 96)],
		[Rect2(300, 380, 96, 96), Rect2(550, 40, 96, 96)],
		[Rect2(15, 20, 96, 96), Rect2(800, 20, 96, 96), Rect2(15, 400, 96, 96), Rect2(800, 400, 96, 96), Rect2(300, 380, 96, 96), Rect2(500, 40, 96, 96)]
	]:
		var typed_rects: Array[Rect2] = []
		for rect in protected_rects:
			typed_rects.append(rect.grow(8))
		hud.show_result(false, typed_rects.size(), true, false, empty_points, typed_rects)
		var blocks: Array = hud.get("_split_panels")
		if blocks.is_empty():
			blocks = [hud.get_node("Root/ResultPanel")]
		for block: Panel in blocks:
			var block_rect := block.get_global_rect()
			_check(block_rect.position.x >= 0 and block_rect.position.y >= 0, "RESULT | blocks are on screen")
			for protected_rect: Rect2 in typed_rects:
				_check(not block_rect.intersects(protected_rect), "RESULT | survivor sprite and eight-pixel margin remain clear")
		_check(hud.get("_retry_button").visible, "RESULT | retry remains available after reflow")
		await process_frame
	hud.show_result(true, 0, true, true)
	_check(hud.get_node("Root/ResultPanel/NextButton").text == "返回主界面", "RESULT | restoration retains final-level branch")
	level.queue_free()
	await process_frame
	print("RESULT | ", "PASS" if _failures.is_empty() else "FAIL", " | Art revision integration")
	quit(0 if _failures.is_empty() else 1)


func _check(ok: bool, label: String) -> void:
	if not ok:
		_failures.append(label)
	print("PASS" if ok else "FAIL", " | ", label)
