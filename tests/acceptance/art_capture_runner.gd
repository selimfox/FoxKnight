extends SceneTree

## Manual visual QA: capture Level 1 at native viewport size in idle and both aim forms.
func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var campaign: Node = load("res://scenes/prototype/campaign.tscn").instantiate()
	root.add_child(campaign)
	for frame in 2:
		await process_frame
	_save("res://output/visual_audit_menu.png")
	campaign.queue_free()
	await process_frame
	var level: Node = load("res://scenes/prototype/levels/level_01.tscn").instantiate()
	root.add_child(level)
	for frame in 5:
		await process_frame
	var player := level.get_node("Actors/Player") as PlayerController
	_save("res://output/level01_runtime_art_capture_v2.png")
	var lighting := level.get_node("Arena/Moonlight") as Node2D
	lighting.set("_time", 4.0)
	lighting.queue_redraw()
	await process_frame
	_save("res://output/level01_art_light_phase_b.png")
	player.update_arc_aim_preview(110.0)
	await process_frame
	_save("res://output/level01_art_arc_preview.png")
	player.update_straight_aim_preview(Vector2.RIGHT, 330.0, 70.0, 110.0)
	await process_frame
	_save("res://output/level01_art_straight_preview.png")
	player.clear_aim_preview()
	var hud := level.get_node("HUD") as PrototypeHUD
	hud.show_result(false, 2, true, false)
	await process_frame
	_save("res://output/visual_audit_failure.png")
	hud.show_result(true, 0, true, false)
	await process_frame
	_save("res://output/visual_audit_victory.png")
	level.queue_free()
	await process_frame
	for index in [2, 3]:
		var other_level: Node = load("res://scenes/prototype/levels/level_0%d.tscn" % index).instantiate()
		root.add_child(other_level)
		for frame in 3:
			await process_frame
		_save("res://output/visual_audit_level_0%d.png" % index)
		other_level.queue_free()
		await process_frame
	quit()


func _save(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	var error := image.save_png(path)
	print("ART CAPTURE | ", path, " | ", image.get_size(), " | ", error)
