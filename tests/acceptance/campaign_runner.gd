extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/prototype/campaign.tscn") as PackedScene
	_expect(packed != null, "CAMPAIGN-01: Main menu scene loads")
	if packed == null:
		_finish()
		return
	var campaign := packed.instantiate() as CampaignController
	root.add_child(campaign)
	await process_frame
	_expect(campaign.get_node("MenuLayer/Menu").visible, "CAMPAIGN-01: Main menu is initially visible")
	_expect(campaign.get_node("LevelHost").get_child_count() == 0, "CAMPAIGN-01: No level runs behind the menu")

	for index: int in range(3):
		campaign.call("_load_level", index)
		await process_frame
		await physics_frame
		var level := campaign.get_node("LevelHost").get_child(0) as PrototypeLevel
		_expect(level != null, "CAMPAIGN-02: Level %d loads" % (index + 1))
		_expect(not campaign.get_node("MenuLayer/Menu").visible, "CAMPAIGN-02: Menu hides during level %d" % (index + 1))
		_expect(level.campaign_mode, "CAMPAIGN-02: Level %d has campaign flow" % (index + 1))
		var arena := level.get_node("Arena") as TileArena
		_expect(arena.floor_layer.get_used_cells().size() > 0, "MAP-02: Level %d has editable floor" % (index + 1))
		_expect(arena.wall_layer.get_used_cells().size() > 0, "MAP-02: Level %d has editable walls" % (index + 1))
		_expect(arena.get_node_or_null("CourtyardPlate") == null, "ART-01: Level %d has no whole-room visual plate" % (index + 1))
		var decoration := arena.get_node("Decoration") as TileMapLayer
		_expect(decoration.get_used_cells().size() > 0, "ART-01: Level %d has editable decoration" % (index + 1))
		_expect(arena.get_node("TileWallCollisions").get_child_count() == arena.wall_layer.get_used_cells().size(), "MAP-02: Level %d walls produce collisions" % (index + 1))
		_expect(level.get_alive_enemy_count() >= 3, "ENEMY-02: Level %d has chase soldiers" % (index + 1))
		for enemy: EnemyController in level.get_node("Actors/Enemies").get_children():
			_expect(enemy.move_speed > 0.0, "ENEMY-02: Level %d soldier can chase" % (index + 1))
		if index == 0:
			level.retry_requested.emit()
			await process_frame
			await process_frame
			_expect(campaign.get_node("LevelHost").get_child_count() == 1, "CAMPAIGN-03: Retry replaces rather than stacks the level")
		if index < 2:
			level = campaign.get_node("LevelHost").get_child(0) as PrototypeLevel
			level.next_requested.emit()
			await process_frame
			await process_frame
			_expect(campaign.get_node("LevelHost").get_child_count() == 1, "CAMPAIGN-03: Next replaces rather than stacks the level")
			_expect(campaign.get_node("LevelHost").get_child(0) != level, "CAMPAIGN-03: Next opens a new scene")

	var final_level := campaign.get_node("LevelHost").get_child(0) as PrototypeLevel
	_expect(final_level.is_final_level, "CAMPAIGN-04: Third level is final")
	final_level.next_requested.emit()
	await process_frame
	await process_frame
	_expect(campaign.get_node("MenuLayer/Menu").visible, "CAMPAIGN-04: Final victory returns to menu")
	_expect(campaign.get_node("LevelHost").get_child_count() == 0, "CAMPAIGN-04: Final level is cleared")

	var editable := load("res://scenes/prototype/levels/level_01.tscn").instantiate() as PrototypeLevel
	var editable_arena := editable.get_node("Arena") as TileArena
	var editable_walls := editable_arena.get_node("Walls") as TileMapLayer
	editable_walls.set_cell(Vector2i(8, 8), 0, Vector2i(0, 1))
	root.add_child(editable)
	await physics_frame
	await physics_frame
	_expect(editable_arena.get_node_or_null("CourtyardPlate") == null, "ART-02: Fixed painted plate is absent")
	_expect(editable_arena.floor_layer.modulate.a > 0.99, "ART-02: Editable TileMap stays visible")
	_expect(editable_arena.get_node("TileWallCollisions").get_child_count() == editable_arena.wall_layer.get_used_cells().size(), "MAP-03: Added wall tile gets collision at runtime")
	var clipped_distance := editable_arena.get_slash_distance(Vector2(176, 272), Vector2.RIGHT, 400.0)
	_expect(clipped_distance < 400.0, "MAP-03: Added wall clips straight slash")
	var path_point := editable_arena.get_next_path_point(Vector2(240, 272), Vector2(304, 272))
	_expect(not is_equal_approx(path_point.y, 272.0), "MAP-03: Soldier path routes around an added wall")
	editable.queue_free()
	campaign.queue_free()
	await process_frame
	_finish()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS | %s" % label)
	else:
		_failures.append(label)
		push_error("FAIL | %s" % label)


func _finish() -> void:
	if _failures.is_empty():
		print("RESULT | PASS | Campaign and TileMap acceptance")
		quit(0)
	else:
		print("RESULT | FAIL | %d checks failed" % _failures.size())
		quit(1)
