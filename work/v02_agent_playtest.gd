extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var level01_packed := load("res://scenes/prototype/v02/level_01.tscn") as PackedScene
	var level01 := level01_packed.instantiate() as V02LevelController
	root.add_child(level01)
	await process_frame
	var level01_grid := level01.terrain_grid
	_check(level01_grid.structure_valid and level01_grid.battle_ready and not level01.hud.start_button.disabled, "Multi-region Level01 is immediately editable and battle-ready")
	_check(not level01.hud.hint_label.text.contains("连通"), "Independent regions show no connectivity warning")
	await _save_frame("res://output/v02_independent_regions.png")
	var first_cell := _find_draggable_cell(level01_grid)
	var terrain_source := level01_grid.world_to_cell(first_cell.global_position) if first_cell != null else Vector2i(-9999, -9999)
	var terrain_target := _find_terrain_target(level01_grid, terrain_source) if first_cell != null else Vector2i(-9999, -9999)
	_check(first_cell != null and terrain_target.x != -9999, "Current Level01 exposes a draggable terrain cell and legal target")
	if first_cell != null and terrain_target.x != -9999:
		level01_grid._on_cell_drag_pressed(first_cell)
		level01_grid._update_drag(level01_grid.cell_to_world(terrain_target))
		_check(first_cell.get_visual_state_name() == "DRAG_VALID", "Current Level01 terrain drag reports a legal target")
		await _save_frame("res://output/v02_level01_terrain_drag.png")
		level01_grid._commit_drag()
	_check(level01_grid.battle_ready and not level01.hud.start_button.disabled and level01_grid.get_history_size() == 1, "A real Level01 terrain drag commits and restores battle readiness")
	_check(level01.undo_last_adjustment() and level01_grid.battle_ready and not level01.hud.start_button.disabled, "Undo restores the authored Level01 terrain")
	var level01_enemy := level01.get_enemy_nodes()[0] as V02EnemyController if not level01.get_enemy_nodes().is_empty() else null
	var level01_enemy_target := _find_enemy_target(level01_grid, level01_enemy)
	_check(level01_enemy != null and level01_enemy_target.x != -9999, "Current Level01 exposes a draggable enemy and legal target")
	if level01_enemy != null and level01_enemy_target.x != -9999:
		level01_grid._on_enemy_drag_pressed(level01_enemy)
		level01_grid._update_drag(level01_grid.cell_to_world(level01_enemy_target))
		_check(level01_enemy.get_preparing_visual_state() == "DRAG_VALID", "Current Level01 enemy drag reports a legal target")
		await _save_frame("res://output/v02_level01_enemy_drag.png")
		level01_grid._commit_drag()
	_check(level01_grid.battle_ready and not level01.hud.start_button.disabled and level01_grid.get_history_size() == 1, "A real Level01 enemy drag commits and restores battle readiness")
	_check(level01.undo_last_adjustment() and level01_grid.battle_ready and not level01.hud.start_button.disabled, "Undo restores the authored Level01 enemy")
	level01.queue_free()
	await process_frame
	var packed := load("res://scenes/prototype/v02/level_02.tscn") as PackedScene
	var level := packed.instantiate() as V02LevelController
	level.adjustment_count = 3
	root.add_child(level)
	await process_frame
	_check(level.get_round_state_name() == "PREPARING", "Preparing phase is visible and interactive")
	var grid := level.terrain_grid
	var infantry: V02EnemyController
	for enemy: V02EnemyController in level.get_enemy_nodes():
		if enemy is InfantryController:
			infantry = enemy
			break
	var enemy_source := grid.world_to_cell(infantry.global_position)
	var enemy_target := Vector2i(8, 5)
	grid._on_enemy_drag_pressed(infantry)
	grid._update_drag(grid.cell_to_world(enemy_target))
	_check(infantry.get_preparing_visual_state() == "DRAG_VALID", "Enemy mouse drag reports a legal distant highlighted ground target")
	await _save_frame("res://output/v02_enemy_drag.png")
	grid._commit_drag()
	_check(grid.world_to_cell(infantry.global_position) == enemy_target and grid.get_last_history_type() == "enemy", "Enemy drag commits into the shared history")
	var dragged_cell := grid.get_cell(Vector2i(2, 1))
	grid._on_cell_drag_pressed(dragged_cell)
	grid._update_drag(grid.cell_to_world(Vector2i(9, 1)))
	_check(dragged_cell.get_visual_state_name() == "DRAG_VALID", "Actual drag preview reports a legal target")
	await _save_frame("res://output/v02_terrain_drag.png")
	grid._commit_drag()
	_check(grid.get_history_size() == 2 and grid.remaining_moves == level.adjustment_count - 2, "Terrain drag shares count and history with enemy drag")
	_check(level.undo_last_adjustment() and grid.has_cell(Vector2i(2, 1)), "Undo restores the latest terrain move before the older enemy move")
	_check(grid.world_to_cell(infantry.global_position) == enemy_target and not level.hud.undo_button.disabled, "Older enemy adjustment remains active and undoable")
	await _save_frame("res://output/v02_prepare.png")
	level.start_battle()
	for enemy: Node in level.get_enemy_nodes():
		enemy.set_physics_process(false)
	var start_cell := level.terrain_grid.world_to_cell(level.player.global_position)
	Input.action_press("move_right")
	await create_timer(0.4).timeout
	Input.action_release("move_right")
	_check(level.terrain_grid.world_to_cell(level.player.global_position) != start_cell, "Player input crosses connected terrain cells")
	for enemy: Node in level.get_enemy_nodes():
		enemy.set_physics_process(true)
	await create_timer(0.25).timeout
	_check(level.get_round_state_name() == "OBSERVING", "Combat phase runs infantry and archer behavior")
	await _save_frame("res://output/v02_battle.png")
	for enemy: Node in level.get_enemy_nodes():
		enemy.set_physics_process(false)
	var index := 0
	for enemy: Node2D in level.get_enemy_nodes():
		var angle := TAU * float(index) / float(level.get_enemy_nodes().size())
		enemy.global_position = level.player.global_position + Vector2.RIGHT.rotated(angle) * 48.0
		index += 1
	level.player.aim_started.emit(level.player.global_position + Vector2.RIGHT * 20.0)
	level.player.aim_released.emit(level.player.global_position + Vector2.RIGHT * 20.0)
	await create_timer(0.7).timeout
	_check(level.get_round_state_name() == "RESOLVED" and level.get_alive_enemy_count() == 0, "The single arc slash resolves a valid all-target win")
	await _save_frame("res://output/v02_result.png")
	if failures.is_empty():
		print("RESULT | PASS | v0.2 agent playtest")
		quit(0)
	else:
		print("RESULT | FAIL | %d agent checks failed" % failures.size())
		quit(1)

func _save_frame(path: String) -> void:
	await process_frame
	await process_frame
	var error := root.get_texture().get_image().save_png(path)
	_check(error == OK, "Captured %s" % path)

func _find_draggable_cell(grid: AggregateTerrainMap) -> TerrainCell:
	for coordinate: Vector2i in grid._cells:
		var cell := grid.get_cell(coordinate)
		if cell != null and cell.is_draggable_now():
			return cell
	return null

func _find_terrain_target(grid: AggregateTerrainMap, source: Vector2i) -> Vector2i:
	for y: int in range(grid.grid_bounds.position.y, grid.grid_bounds.end.y):
		for x: int in range(grid.grid_bounds.position.x, grid.grid_bounds.end.x):
			var target := Vector2i(x, y)
			if grid.is_terrain_move_valid(source, target):
				return target
	return Vector2i(-9999, -9999)

func _find_enemy_target(grid: AggregateTerrainMap, enemy: V02EnemyController) -> Vector2i:
	if enemy == null:
		return Vector2i(-9999, -9999)
	var source := grid.world_to_cell(enemy.global_position)
	for coordinate: Vector2i in grid._cells:
		if grid.is_enemy_move_valid(enemy, source, coordinate):
			return coordinate
	return Vector2i(-9999, -9999)

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS | %s" % message)
	else:
		failures.append(message)
		push_error("FAIL | %s" % message)
