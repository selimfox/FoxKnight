extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Character motion capture requires a graphical renderer")
		quit(1)
		return
	var level: Node = load("res://scenes/prototype/levels/level_01.tscn").instantiate()
	root.add_child(level)
	for index in 3:
		await process_frame
	var player := level.get_node("Actors/Player") as PlayerController
	var sprite := player.get_node("Visual/Sprite") as CharacterAnimation
	player.global_position = Vector2(320.0, 270.0)
	var contact := Image.create(4 * 96, 96, false, Image.FORMAT_RGBA8)
	var seen_frames := {}
	var seen_cels := {}
	Input.action_press("move_right")
	for index in 4:
		await create_timer(0.105).timeout
		var frame := root.get_viewport().get_texture().get_image()
		frame.convert(Image.FORMAT_RGBA8)
		var center := player.global_position.round()
		var source := Rect2i(Vector2i(center) - Vector2i(48, 64), Vector2i(96, 96))
		contact.blit_rect(frame, source, Vector2i(index * 96, 0))
		seen_frames[sprite.get_frame_index()] = true
		var cel := sprite.get_current_frame_texture().get_image()
		seen_cels[hash(cel.get_data())] = true
		print("MOTION FRAME | ", index, " | ", sprite.get_animation_name(), " / ", sprite.get_frame_index(), " | x=", player.global_position.x)
	Input.action_release("move_right")
	var path := "res://output/character_motion_walk_contact.png"
	var saved := contact.save_png(path) == OK
	print("PASS" if saved else "FAIL", " | Fox actual WASD walk contact sheet: ", path)
	print("PASS" if seen_frames.size() >= 3 else "FAIL", " | Fox reaches at least three distinct walk cels while moving")
	print("PASS" if seen_cels.size() >= 3 else "FAIL", " | Walk cels differ in actual source pixels")
	var passed := saved and seen_frames.size() >= 3 and seen_cels.size() >= 3
	print("RESULT | ", "PASS" if passed else "FAIL", " | Character motion capture")
	quit(0 if passed else 1)
