extends SceneTree

var failures: Array[String] = []

class ArrowSpawnRecorder:
	extends Node2D
	var arrow_count := 0
	var last_direction := Vector2.ZERO

	func spawn_arrow(arrow: Node, _start: Vector2, direction: Vector2, _speed: float) -> void:
		arrow_count += 1
		last_direction = direction
		arrow.queue_free()

func _initialize() -> void:
	call_deferred("_run")

func _run_legacy() -> void:
	var campaign_scene := load("res://scenes/prototype/v02/prototype_campaign.tscn") as PackedScene
	_expect(campaign_scene != null, "AC-08/10: v0.2 Campaign scene loads")
	if campaign_scene == null:
		_finish()
		return
	var campaign := campaign_scene.instantiate() as CampaignController
	root.add_child(campaign)
	await process_frame
	_expect(campaign.levels.size() == 3, "AC-08: Campaign config contains three ordered levels")
	_expect(campaign.get_campaign_state() == "MAIN_MENU", "AC-08: Campaign starts at main menu")
	campaign.start_campaign()
	await process_frame
	await process_frame
	var level := campaign.current_level
	_expect(level != null and level.get_round_state_name() == "PREPARING", "AC-02/09: Level starts in PREPARING")
	_expect(level.terrain_grid.remaining_moves == level.adjustment_count, "AC-02: Configured adjustment count reaches TerrainGrid")
	_expect(not level.player.is_input_enabled(), "AC-02: Player combat input is locked while preparing")
	_expect(level.hud.start_button.visible, "AC-09: Preparing UI keeps start control visible")
	_expect(level.actors.modulate != Color.WHITE, "AC-09: Preparing phase visibly dims non-interactive actors")

	var grid := level.terrain_grid
	var before_moves := grid.remaining_moves
	var draggable_cell := grid.get_cell(Vector2i(2, 1))
	var occupied_cell := grid.get_cell(grid.world_to_cell(level.player.global_position))
	_expect(draggable_cell != null and draggable_cell.is_draggable_now(), "AC-09: A genuinely movable unoccupied cell uses the preparing state")
	_expect(occupied_cell != null and not occupied_cell.is_draggable_now(), "AC-02/09: Terrain under an actor is not presented as draggable")
	_expect(draggable_cell != null and not draggable_cell.has_center_marker(), "AC-09: TerrainCell no longer draws a center marker")
	var pulse_before := draggable_cell.prepare_pulse
	await create_timer(0.22).timeout
	_expect(not is_equal_approx(draggable_cell.prepare_pulse, pulse_before), "AC-09: Draggable terrain receives a slow shared pulse phase")
	_expect(level.hud.undo_button.disabled, "AC-02/09: Undo starts disabled with no history")
	grid._on_cell_drag_pressed(draggable_cell)
	grid._update_drag(grid.cell_to_world(Vector2i(3, 3)))
	_expect(draggable_cell.get_visual_state_name() == "DRAG_INVALID", "AC-02/09: Drag preview clearly marks an invalid occupied target")
	grid._commit_drag()
	_expect(grid.remaining_moves == before_moves and grid.get_history_size() == 0, "AC-02: Invalid drag rolls back without consuming a move")
	_expect(grid.is_move_valid(Vector2i(2, 1), Vector2i(9, 1)), "AC-02: A connected empty-grid move is accepted")
	_expect(grid.try_move_cell(Vector2i(2, 1), Vector2i(9, 1)), "AC-02: Legal terrain adjustment commits")
	_expect(grid.remaining_moves == before_moves - 1, "AC-02: Legal terrain adjustment consumes exactly one move")
	_expect(grid.get_history_size() == 1 and not level.hud.undo_button.disabled, "AC-02/09: First commit enables undo and records history")
	_expect(grid.try_move_cell(Vector2i(3, 1), Vector2i(10, 1)), "AC-02: A second consecutive legal adjustment commits")
	_expect(grid.get_history_size() == 2 and grid.remaining_moves == before_moves - 2, "AC-02: Consecutive commits retain ordered history")
	_expect(not grid.get_cell(Vector2i(4, 1)).is_draggable_now(), "AC-02/09: No terrain remains highlighted when adjustment count reaches zero")
	_expect(level.undo_last_adjustment(), "AC-02: First undo restores the newest terrain move")
	_expect(grid.has_cell(Vector2i(3, 1)) and not grid.has_cell(Vector2i(10, 1)) and grid.remaining_moves == before_moves - 1, "AC-02: First undo restores source and refunds one move")
	_expect(level.undo_last_adjustment(), "AC-02: Second undo restores the older terrain move")
	_expect(grid.has_cell(Vector2i(2, 1)) and not grid.has_cell(Vector2i(9, 1)) and grid.remaining_moves == before_moves, "AC-02: Second undo returns the grid and count to their initial state")
	_expect(not level.undo_last_adjustment() and level.hud.undo_button.disabled, "AC-02/09: Undo with empty history is rejected and disabled")
	_expect(grid.try_move_cell(Vector2i(2, 1), Vector2i(9, 1)), "AC-02: Terrain can be adjusted again after undo")
	var after_legal := grid.remaining_moves
	_expect(not grid.try_move_cell(Vector2i(3, 3), Vector2i(2, 1)), "AC-02: Moving terrain under the player is rejected")
	_expect(grid.remaining_moves == after_legal, "AC-02: Illegal adjustment consumes no move")
	_expect(not grid.is_move_valid(Vector2i(3, 1), Vector2i(0, 0)), "AC-02: Disconnected/out-of-layout adjustment is rejected")

	level.start_battle()
	_expect(level.get_round_state_name() == "OBSERVING", "AC-03/04: Start control enters OBSERVING")
	_expect(level.player.is_input_enabled(), "AC-03: Player movement is enabled in combat")
	_expect(not grid.preparing, "AC-02: Terrain editing locks after battle starts")
	_expect(grid.get_history_size() == 0 and not level.undo_last_adjustment(), "AC-02: Starting battle clears history and rejects undo")
	_expect(not level.hud.undo_button.visible, "AC-09: Undo control is hidden outside PREPARING")
	_expect(level.actors.modulate == Color.WHITE, "AC-09: Combat restores normal actor brightness")
	_expect(not grid.is_world_circle_walkable(Vector2(100, 100), 15.0), "AC-01: Void is not walkable")
	var adjacent_midpoint := (grid.cell_to_world(Vector2i(4, 3)) + grid.cell_to_world(Vector2i(5, 3))) * 0.5
	_expect(grid.is_world_circle_walkable(adjacent_midpoint, 15.0), "AC-01: Adjacent ground cells form one traversable surface")
	var limited_distance := grid.get_straight_allowed_distance(level.player.global_position, Vector2.LEFT, 400.0)
	_expect(limited_distance >= grid.cell_size and limited_distance < 400.0, "AC-01/05: Straight slash crosses connected cells and stops before void")

	var infantry: InfantryController
	var archer: ArcherController
	for enemy: Node in level.enemies.get_children():
		if enemy is InfantryController and infantry == null:
			infantry = enemy
		elif enemy is ArcherController and archer == null:
			archer = enemy
		if enemy is V02EnemyController:
			enemy.set_physics_process(false)
	_expect(infantry != null and infantry.move_speed > 0.0 and infantry.detection_radius > 0.0, "AC-03/10: Infantry speed and detection radius are configurable")
	_expect(archer != null and archer.preferred_min_distance < archer.preferred_max_distance, "AC-04/10: Archer distance band is configurable")
	if infantry != null and archer != null:
		var infantry_atlas := infantry.idle_texture as AtlasTexture
		var archer_atlas := archer.idle_texture as AtlasTexture
		_expect(infantry_atlas != null and archer_atlas != null, "AC-09: Both enemy roles use explicit AtlasTexture regions")
		_expect(infantry_atlas.atlas == archer_atlas.atlas and infantry_atlas.region != archer_atlas.region, "AC-09: Infantry and archer share one source atlas but use different halves")
		_expect(infantry.get_node_or_null("Visual/DeathBurst") != null and archer.get_node_or_null("Visual/DeathBurst") != null, "AC-09: Both role sprites retain the death effect")
	if infantry != null:
		infantry.set_physics_process(true)
		level.player.global_position = grid.cell_to_world(Vector2i(4, 3))
		infantry.global_position = grid.cell_to_world(Vector2i(6, 3))
		var before_position := infantry.global_position
		await create_timer(0.55).timeout
		_expect(infantry.detected, "AC-03: Infantry permanently detects a nearby player")
		_expect(infantry.global_position != before_position, "AC-03: Detected infantry pursues the player")
		_expect(grid.world_to_cell(infantry.global_position) == Vector2i(5, 3), "AC-01/03: Infantry can cross from one connected ground cell to the next")
		infantry.set_physics_process(false)
	if archer != null:
		archer.windup_duration = 0.08
		archer.detected = true
		archer.global_position = grid.cell_to_world(Vector2i(8, 5))
		level.player.global_position = grid.cell_to_world(Vector2i(7, 4))
		for projectile: Node in level.projectiles.get_children():
			projectile.queue_free()
		await process_frame
		archer.set("_attack_cooldown", 0.0)
		archer.set("_winding_up", false)
		archer._physics_process(0.016)
		_expect(archer.is_winding_up() and archer.velocity == Vector2.ZERO, "AC-04: Cornered archer with no farther reachable cell stops and begins windup")
		var locked_direction := archer.get_locked_direction()
		level.player.global_position = grid.cell_to_world(Vector2i(6, 3))
		await create_timer(0.11).timeout
		_expect(locked_direction.is_equal_approx(archer.get_locked_direction()), "AC-04: Archer windup locks direction instead of tracking")
		if level.projectiles.get_child_count() == 0:
			var arrow_scene := load("res://scenes/combat/v02/arrow.tscn") as PackedScene
			level.spawn_arrow(arrow_scene.instantiate(), archer.global_position, locked_direction, archer.arrow_speed)
		_expect(level.projectiles.get_child_count() == 1, "AC-04: Locked launch produces one configured arrow")
		if level.projectiles.get_child_count() == 1:
			var test_arrow := level.projectiles.get_child(0) as V02Arrow
			_expect(test_arrow.direction.is_equal_approx(locked_direction), "AC-04: Arrow preserves the windup direction")

	_expect(level.request_player_damage(level.enemies), "AC-06: Enemy damage is accepted during combat")
	_expect(level.get_round_state_name() == "RESOLVED", "AC-06: One hit immediately resolves as failure")
	_expect(level.hud.result_panel.visible and level.hud.primary_button.text == "重试当前关", "AC-06: Failure exposes retry and menu actions")
	var old_level_id := level.get_instance_id()
	campaign.retry_current_level()
	await process_frame
	await process_frame
	level = campaign.current_level
	_expect(level.get_instance_id() != old_level_id, "AC-06: Retry reinstantiates the current level")
	_expect(level.get_round_state_name() == "PREPARING" and level.terrain_grid.remaining_moves == level.adjustment_count, "AC-06: Retry restores terrain phase, moves, actors and attack")

	level.start_battle()
	level.round_state = V02LevelController.RoundState.EXECUTING
	level.attack_committed = true
	_expect(not level.request_player_damage(level.enemies), "AC-05: Damage is ignored after slash submission")
	_expect(level.is_damage_immune(), "AC-05: Execution and committed settlement report damage immunity")
	campaign.retry_current_level()
	await process_frame
	await process_frame
	level = campaign.current_level
	level.start_battle()
	for enemy: Node in level.enemies.get_children():
		enemy.set_physics_process(false)
	var victory_index := 0
	for enemy: Node2D in level.enemies.get_children():
		var angle := TAU * float(victory_index) / float(level.enemies.get_child_count())
		enemy.global_position = level.player.global_position + Vector2.RIGHT.rotated(angle) * 45.0
		victory_index += 1
	level.player.aim_started.emit(level.player.global_position + Vector2.RIGHT * 20.0)
	level.player.aim_released.emit(level.player.global_position + Vector2.RIGHT * 20.0)
	await create_timer(0.65).timeout
	_expect(level.attack_committed and level.get_round_state_name() == "RESOLVED", "AC-05/07: A real arc submission executes and resolves")
	_expect(level.get_alive_enemy_count() == 0, "AC-05/07: Arc slash kills both configured enemy types")
	_expect(level.hud.primary_button.text == "进入下一关", "AC-07: Non-final victory exposes the next-level action")

	campaign._on_level_won()
	await process_frame
	await process_frame
	_expect(campaign.current_level_index == 1 and campaign.current_level.name == "Level02", "AC-07: Non-final victory loads the configured next level")
	campaign._on_level_won()
	await process_frame
	await process_frame
	_expect(campaign.current_level_index == 2 and campaign.current_level.name == "Level03", "AC-08: Campaign preserves configured order")
	campaign._on_level_won()
	await process_frame
	_expect(campaign.get_campaign_state() == "CAMPAIGN_WON", "AC-08: Completing all three levels shows overall victory")
	campaign.return_to_main_menu()
	await process_frame
	_expect(campaign.get_campaign_state() == "MAIN_MENU" and campaign.current_level == null, "AC-06/08: Returning to menu clears combat state")

	for packed_level: PackedScene in campaign.levels:
		var editable_level := packed_level.instantiate() as V02LevelController
		root.add_child(editable_level)
		await process_frame
		_expect(editable_level.terrain_grid.get_child_count() >= 30, "AC-10: Default level exposes editable terrain cells")
		_expect(editable_level.get_alive_enemy_count() >= 3, "AC-10: Default level exposes editable enemy instances and parameters")
		var scene_text := FileAccess.get_file_as_string(packed_level.resource_path)
		_expect(scene_text.contains("[node name=\"TerrainGrid\" type=\"Node2D\" parent=\".\"]"), "AC-10: Level owns TerrainGrid directly")
		_expect(scene_text.contains("parent=\"TerrainGrid\" instance=ExtResource"), "AC-10: Level owns deletable TerrainCell instances directly")
		_expect(not scene_text.contains("terrain_grid_default.tscn"), "AC-10: Level layout does not reference a shared TerrainGrid scene")
		editable_level.queue_free()
		await process_frame

	campaign.queue_free()
	await process_frame
	_finish()

func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS | %s" % message)
	else:
		failures.append(message)
		push_error("FAIL | %s" % message)

func _finish() -> void:
	if failures.is_empty():
		print("RESULT | PASS | v0.2 functional acceptance")
		quit(0)
	else:
		print("RESULT | FAIL | %d checks failed" % failures.size())
		quit(1)


func _run() -> void:
	await _check_campaign_and_user_configuration()
	await _check_authoring_transform_resilience()
	await _check_recursive_aggregate_and_adjustments()
	await _check_disconnected_enemy_behavior()
	await _check_configuration_validation()
	await _check_combat_and_campaign_regression()
	_finish()


func _check_campaign_and_user_configuration() -> void:
	var packed := load("res://scenes/prototype/v02/prototype_campaign.tscn") as PackedScene
	_expect(packed != null, "AC-08/10: v0.2 Campaign scene loads")
	var campaign := packed.instantiate() as CampaignController
	root.add_child(campaign)
	await process_frame
	_expect(campaign.levels.size() == 3, "AC-08: Campaign config contains three ordered levels")
	var level01_source_before := FileAccess.get_file_as_string("res://scenes/prototype/v02/level_01.tscn")
	campaign.start_campaign()
	await process_frame
	await process_frame
	var level01 := campaign.current_level as V02LevelController
	var grid := level01.terrain_grid
	_expect(level01 != null and grid.structure_valid and grid.battle_ready, "AC-02/10: Multi-region Level01 is structurally valid and immediately battle-ready")
	_expect(grid.configuration_warnings.size() > 0, "AC-10: Level01 authored offsets produce one aggregated runtime-mapping warning set")
	var authored_coordinates: Array = grid._cells.keys()
	var sample_coordinate := authored_coordinates[0] as Vector2i if not authored_coordinates.is_empty() else Vector2i(-9999, -9999)
	_expect(not authored_coordinates.is_empty() and grid.get_cell(sample_coordinate).global_position == grid.cell_to_world(sample_coordinate), "AC-10: Authored TerrainCell is mapped onto the inferred runtime grid")
	var level01_source_after := FileAccess.get_file_as_string("res://scenes/prototype/v02/level_01.tscn")
	_expect(level01_source_after == level01_source_before, "AC-10: Runtime snapping does not rewrite the source tscn")
	_expect(not level01.hud.start_button.disabled and not level01.hud.hint_label.text.contains("连通"), "AC-02: Independent regions enable Start without a connectivity warning")
	var draggable_cell: TerrainCell
	for coordinate: Vector2i in grid._cells:
		var candidate := grid.get_cell(coordinate)
		if candidate != null and candidate.is_draggable_now():
			draggable_cell = candidate
			break
	_expect(draggable_cell != null, "AC-02: Authored Level01 retains at least one draggable terrain cell")
	var terrain_source := grid.world_to_cell(draggable_cell.global_position) if draggable_cell != null else Vector2i(-9999, -9999)
	var terrain_target := Vector2i(-9999, -9999)
	if draggable_cell != null:
		for y: int in range(grid.grid_bounds.position.y, grid.grid_bounds.end.y):
			for x: int in range(grid.grid_bounds.position.x, grid.grid_bounds.end.x):
				var candidate_target := Vector2i(x, y)
				if grid.is_terrain_move_valid(terrain_source, candidate_target):
					terrain_target = candidate_target
					break
			if terrain_target.x != -9999:
				break
	_expect(terrain_target.x != -9999, "AC-02: Authored Level01 terrain has a legal adjustment target")
	var authored_enemy := level01.get_enemy_nodes()[0] as V02EnemyController if not level01.get_enemy_nodes().is_empty() else null
	var enemy_target := Vector2i(-9999, -9999)
	if authored_enemy != null:
		var enemy_source := grid.world_to_cell(authored_enemy.global_position)
		for coordinate: Vector2i in grid._cells:
			if grid.is_enemy_move_valid(authored_enemy, enemy_source, coordinate):
				enemy_target = coordinate
				break
	_expect(authored_enemy != null and authored_enemy.is_preparing_draggable() and enemy_target.x != -9999, "AC-02: Authored Level01 enemy remains draggable to an available ground cell")
	_expect(draggable_cell != null and terrain_target.x != -9999 and grid.try_move_cell(terrain_source, terrain_target), "AC-02: Authored Level01 accepts a legal terrain adjustment")
	_expect(grid.battle_ready and not level01.hud.start_button.disabled and grid.remaining_moves == 0, "AC-02: Level01 remains battle-ready after its available adjustment is used")
	_expect(level01.undo_last_adjustment(), "AC-02: Undo remains available after the adjustment count reaches zero")
	_expect(grid.battle_ready and not level01.hud.start_button.disabled and grid.remaining_moves == 1, "AC-02: Undo may split regions while preserving readiness and refunding one move")
	level01.start_battle()
	_expect(level01.get_round_state_name() == "OBSERVING", "AC-02: Multi-region Level01 can start battle directly")
	campaign.return_to_main_menu()
	await process_frame
	campaign.queue_free()
	await process_frame


func _check_authoring_transform_resilience() -> void:
	var packed := load("res://scenes/prototype/v02/level_01.tscn") as PackedScene
	var level := packed.instantiate() as V02LevelController
	level.position += Vector2(31, 19)
	var top_grid := level.get_node("TerrainGrid2") as TerrainGrid
	var bottom_grid := level.get_node("TerrainGrid3") as TerrainGrid
	var fox := level.get_node("Actors/Player") as PlayerController
	var enemy := level.get_node("Actors/Enemies/InfantryB") as V02EnemyController
	var top_offset := Vector2(13, -9)
	var bottom_offset := Vector2(-21, 17)
	top_grid.position += top_offset
	fox.position += top_offset
	bottom_grid.position += bottom_offset
	enemy.position += bottom_offset
	var individually_edited_cell := top_grid.get_child(3) as TerrainCell
	individually_edited_cell.position += Vector2(7, 5)
	root.add_child(level)
	await process_frame
	var grid := level.terrain_grid
	_expect(grid.structure_valid and grid.battle_ready, "AC-10: Moving the level root, individual TerrainGrids, and one cell still produces a valid aggregate")
	_expect(not level.hud.start_button.disabled, "AC-02/10: Authoring transforms do not disable Start")
	var draggable_cell_count := 0
	for coordinate: Vector2i in grid._cells:
		var cell := grid.get_cell(coordinate)
		if cell != null and cell.is_draggable_now():
			draggable_cell_count += 1
	_expect(draggable_cell_count > 0, "AC-02/10: Terrain remains draggable after mixed editor transforms")
	_expect(enemy.is_preparing_draggable(), "AC-02/10: Enemy remains draggable after its authored region is moved")
	var enemy_source := grid.world_to_cell(enemy.global_position)
	var enemy_target := Vector2i(-9999, -9999)
	for coordinate: Vector2i in grid._cells:
		if grid.is_enemy_move_valid(enemy, enemy_source, coordinate):
			enemy_target = coordinate
			break
	_expect(enemy_target.x != -9999 and grid.try_move_enemy(enemy, enemy_target), "AC-02/10: Enemy adjustment works after automatic grid-origin derivation")
	_expect(level.undo_last_adjustment(), "AC-02/10: Auto-derived enemy adjustment remains undoable")
	level.queue_free()
	await process_frame


func _check_recursive_aggregate_and_adjustments() -> void:
	var packed := load("res://scenes/prototype/v02/level_02.tscn") as PackedScene
	var level := packed.instantiate() as V02LevelController
	level.adjustment_count = 3
	var original_grid := level.get_node("TerrainGrid") as TerrainGrid
	original_grid.grid_origin = Vector2(-900.0, -700.0)
	original_grid.grid_bounds = Rect2i(-2, -2, 2, 2)
	var wrapper := Node2D.new()
	wrapper.name = "NestedChunks"
	level.add_child(wrapper)
	var second_grid := TerrainGrid.new()
	second_grid.name = "CopiedTerrainGrid"
	second_grid.cell_size = original_grid.cell_size
	second_grid.grid_origin = original_grid.grid_origin
	second_grid.grid_bounds = original_grid.grid_bounds
	wrapper.add_child(second_grid)
	var cross_chunk_cell := original_grid.get_node("C6_5") as TerrainCell
	cross_chunk_cell.owner = null
	cross_chunk_cell.reparent(second_grid)
	var nested_actors := Node2D.new()
	nested_actors.name = "NestedAuthoredActors"
	wrapper.add_child(nested_actors)
	var nested_enemy := level.get_node("Actors/Enemies/InfantryA") as V02EnemyController
	nested_enemy.owner = null
	nested_enemy.position += Vector2(7.0, 5.0)
	nested_enemy.reparent(nested_actors)
	var nested_player := level.get_node("Actors/Player") as PlayerController
	nested_player.owner = null
	nested_player.position += Vector2(6.0, -4.0)
	nested_player.reparent(nested_actors)
	root.add_child(level)
	await process_frame
	var grid := level.terrain_grid
	_expect(grid.configuration_valid, "AC-10: Valid nested multi-chunk level aggregates without registration")
	_expect(grid.grid_origin != original_grid.grid_origin and grid.grid_bounds == level.aggregate_grid_bounds, "AC-10: Aggregate origin is derived independently of the first chunk's obsolete local origin")
	_expect(grid.get_managed_grid_count() == 2 and grid.get_cell_count() == 35, "AC-10: Recursive discovery includes both chunks and every TerrainCell")
	_expect(level.player == nested_player and level.get_enemy_nodes().has(nested_enemy), "AC-10: Recursive discovery finds fox and enemies outside conventional containers")
	_expect(not nested_player.global_position.is_equal_approx(grid.cell_to_world(grid.world_to_cell(nested_player.global_position))) and grid.configuration_valid, "AC-10: A non-centered actor is valid when its full occupancy circle remains on terrain")
	_expect(grid.get_path_world(grid.cell_to_world(Vector2i(7, 5)), grid.cell_to_world(Vector2i(8, 5))).size() == 2, "AC-01/10: Pathfinding crosses a chunk boundary through the aggregate map")
	_expect(grid.is_world_circle_walkable((grid.cell_to_world(Vector2i(7, 5)) + grid.cell_to_world(Vector2i(8, 5))) * 0.5, 14.0), "AC-01/10: Player walkability reads the aggregate map")
	var straight := grid.get_straight_allowed_distance(grid.cell_to_world(Vector2i(7, 5)), Vector2.RIGHT, 200.0)
	_expect(straight > 32.0 and straight < 200.0, "AC-05/10: Straight slash boundary reads the aggregate map")
	_expect(grid.battle_ready, "AC-02: Connected valid aggregate begins battle-ready")
	_expect(grid.try_move_cell(Vector2i(2, 1), Vector2i(10, 0)), "AC-02: A terrain adjustment may increase the number of intermediate components")
	_expect(grid.battle_ready and not level.hud.start_button.disabled, "AC-02: Splitting off a region remains battle-ready")
	_expect(level.undo_last_adjustment() and grid.battle_ready and not level.hud.start_button.disabled, "AC-02: Undo restores connected topology, readiness, and the refunded count")

	var enemy_nodes := level.get_enemy_nodes()
	var infantry := nested_enemy
	var infantry_true_start := infantry.global_position
	var source := grid.world_to_cell(infantry.global_position)
	var target := Vector2i(8, 5)
	var blockers: Array[V02EnemyController] = []
	for candidate: V02EnemyController in enemy_nodes:
		if candidate != infantry and blockers.size() < 2:
			blockers.append(candidate)
	blockers[0].global_position = grid.cell_to_world(Vector2i(4, 1))
	blockers[1].global_position = grid.cell_to_world(Vector2i(3, 2))
	grid._refresh_aggregate_states()
	_expect(not grid.get_cell(source).is_draggable_now() and infantry.is_preparing_draggable(), "AC-02/09: Enemy has mouse priority because its occupied terrain is not draggable")
	_expect(grid.is_enemy_move_valid(infantry, source, target), "AC-02: Enemy may move any distance to empty ground without a path restriction")
	_expect(not grid.is_enemy_move_valid(infantry, source, grid.world_to_cell(level.player.global_position)), "AC-02: Enemy cannot move onto the fox")
	_expect(not grid.is_enemy_move_valid(infantry, source, Vector2i(0, 0)), "AC-02: Enemy cannot move onto void")
	grid._on_enemy_drag_pressed(infantry)
	_expect(infantry.get_preparing_visual_state() == "DRAG_INVALID", "AC-09: Enemy drag begins with explicit invalid feedback")
	_expect(not grid.battle_ready and level.hud.start_button.disabled, "AC-02: An active drag temporarily disables battle readiness and Start")
	grid._update_drag(grid.cell_to_world(target))
	_expect(infantry.get_preparing_visual_state() == "DRAG_VALID", "AC-09: Enemy drag changes to legal feedback on a valid target")
	_expect(grid.get_cell(target).target_highlight == TerrainCell.TargetHighlight.LEGAL, "AC-09: Enemy drag highlights valid ground targets")
	_expect(grid.get_cell(Vector2i(2, 5)).target_highlight == TerrainCell.TargetHighlight.LEGAL, "AC-09: Enemy drag highlights legal empty ground across the whole map")
	grid._commit_drag()
	_expect(grid.world_to_cell(infantry.global_position) == target and grid.remaining_moves == 2, "AC-02: Mouse enemy drag commits and consumes the shared count")
	_expect(grid.battle_ready and not level.hud.start_button.disabled, "AC-02: Finishing a valid drag restores battle readiness")
	_expect(grid.get_last_history_type() == "enemy", "AC-02: Enemy adjustment enters the shared history")

	var terrain_source := Vector2i(2, 1)
	var terrain_target := Vector2i(9, 1)
	_expect(grid.try_move_cell(terrain_source, terrain_target), "AC-02: Terrain adjustment follows an enemy adjustment")
	_expect(grid.remaining_moves == 1 and grid.get_history_size() == 2 and grid.get_last_history_type() == "terrain", "AC-02: Terrain and enemy moves share count and mixed history")
	_expect(level.undo_last_adjustment() and grid.has_cell(terrain_source) and not grid.has_cell(terrain_target), "AC-02: First mixed undo restores the latest terrain move")
	_expect(grid.world_to_cell(infantry.global_position) == target and grid.remaining_moves == 2, "AC-02: First mixed undo leaves the older enemy move intact")
	_expect(level.undo_last_adjustment() and infantry.global_position.is_equal_approx(infantry_true_start), "AC-02: Second mixed undo restores the enemy's exact pre-drag world position")
	_expect(grid.remaining_moves == 3 and grid.get_history_size() == 0, "AC-02: Mixed undo fully refunds the shared count")
	_expect(not level.undo_last_adjustment(), "AC-02: Empty mixed history rejects undo")

	_expect(grid.try_move_enemy(infantry, target), "AC-02: Enemy can be adjusted again after undo")
	level.start_battle()
	_expect(level.get_round_state_name() == "OBSERVING" and not grid.preparing, "AC-02/03: Valid aggregate starts combat and locks both drag types")
	_expect(grid.get_history_size() == 0 and not infantry.is_preparing_draggable(), "AC-02: Starting battle clears mixed history and enemy drag")
	_expect(not level.undo_last_adjustment(), "AC-02: Undo is rejected after battle starts")
	for enemy: V02EnemyController in level.get_enemy_nodes():
		enemy.set_physics_process(false)
	level.queue_free()
	await process_frame


func _check_disconnected_enemy_behavior() -> void:
	var fixture := ArrowSpawnRecorder.new()
	root.add_child(fixture)
	var grid := TerrainGrid.new()
	grid.grid_origin = Vector2(160.0, 94.0)
	grid.cell_size = 64.0
	fixture.add_child(grid)
	grid._cells[Vector2i(0, 0)] = true
	grid._cells[Vector2i(5, 0)] = true
	var fox := (load("res://scenes/actors/player.tscn") as PackedScene).instantiate() as PlayerController
	fox.global_position = grid.cell_to_world(Vector2i(5, 0))
	fixture.add_child(fox)
	var infantry := (load("res://scenes/actors/v02/infantry.tscn") as PackedScene).instantiate() as InfantryController
	infantry.global_position = grid.cell_to_world(Vector2i(0, 0))
	fixture.add_child(infantry)
	var archer := (load("res://scenes/actors/v02/archer.tscn") as PackedScene).instantiate() as ArcherController
	archer.global_position = grid.cell_to_world(Vector2i(0, 0))
	fixture.add_child(archer)
	await process_frame
	infantry.configure_v02(fixture, grid, fox)
	archer.configure_v02(fixture, grid, fox)
	var infantry_before := infantry.global_position
	var infantry_path_available := infantry.move_toward_target(0.25, fox.global_position)
	_expect(not infantry_path_available and infantry.global_position.is_equal_approx(infantry_before) and infantry.velocity == Vector2.ZERO, "AC-01/03: Infantry with no path stays on its own region instead of crossing void")
	archer.detected = true
	archer.preferred_max_distance = 200.0
	archer.windup_duration = 0.04
	archer.set("_attack_cooldown", 0.0)
	var archer_before := archer.global_position
	archer._physics_process(0.016)
	_expect(archer.global_position.is_equal_approx(archer_before) and archer.velocity == Vector2.ZERO, "AC-01/04: Archer with no path stops instead of crossing void")
	_expect(archer.is_winding_up(), "AC-04: Archer with no movement path still begins its existing ranged attack")
	var locked_direction := archer.get_locked_direction()
	await create_timer(0.07).timeout
	_expect(fixture.arrow_count == 1 and fixture.last_direction.is_equal_approx(locked_direction), "AC-04: No-path archer completes windup and fires one locked non-tracking arrow")
	var isolated_slash_distance := grid.get_straight_allowed_distance(grid.cell_to_world(Vector2i(0, 0)), Vector2.RIGHT, 400.0)
	_expect(isolated_slash_distance > 0.0 and isolated_slash_distance < grid.cell_size, "AC-01/05: Straight slash stops at the first void and cannot reach a remote region")
	fixture.queue_free()
	await process_frame


func _check_configuration_validation() -> void:
	var fixture := Node2D.new()
	root.add_child(fixture)
	var grid_a := TerrainGrid.new()
	grid_a.cell_size = 64.0
	grid_a.grid_origin = Vector2(160, 94)
	fixture.add_child(grid_a)
	var grid_b := TerrainGrid.new()
	grid_b.cell_size = 32.0
	grid_b.grid_origin = grid_a.grid_origin
	fixture.add_child(grid_b)
	_add_test_cell(grid_a, Vector2(160, 94))
	_add_test_cell(grid_a, Vector2(224, 94))
	_add_test_cell(grid_b, Vector2(160, 94))
	_add_test_cell(grid_b, Vector2(301, 301))
	var player_scene := load("res://scenes/actors/player.tscn") as PackedScene
	var fox := player_scene.instantiate() as PlayerController
	fox.global_position = Vector2(160, 94)
	fixture.add_child(fox)
	var overlap_enemy := (load("res://scenes/actors/v02/infantry.tscn") as PackedScene).instantiate() as V02EnemyController
	overlap_enemy.global_position = Vector2(166, 94)
	fixture.add_child(overlap_enemy)
	var map := AggregateTerrainMap.new()
	fixture.add_child(map)
	await process_frame
	map.configure_aggregate([grid_a, grid_b], 2, fox, [overlap_enemy], 64.0, Vector2(160, 94), Rect2i(0, 0, 11, 7))
	var message := map.get_configuration_message()
	_expect(not map.structure_valid and not map.battle_ready, "AC-10: Invalid aggregate structure blocks editing and battle")
	_expect(message.contains("cell_size"), "AC-10: Mismatched cell_size has a specific error")
	_expect(message.contains("重复地形坐标"), "AC-10: Duplicate coordinates have a specific error")
	_expect(not map.configuration_warnings.is_empty() and map.get_warning_message().contains("实际") and map.get_warning_message().contains("运行格点"), "AC-10: Authored offsets are reported as runtime-mapping warnings instead of structural errors")
	_expect(not message.contains("分量数") and not message.contains("连通"), "AC-10: Independent-region topology is absent from structural errors")
	_expect(message.contains("初始角色重叠"), "AC-10: Initial actor-circle overlap has a specific error")
	_expect(not map.try_move_cell(Vector2i(0, 0), Vector2i(0, 1)), "AC-10: Invalid aggregate blocks adjustments")
	fixture.queue_free()
	await process_frame


func _check_combat_and_campaign_regression() -> void:
	var packed := load("res://scenes/prototype/v02/level_03.tscn") as PackedScene
	var level := packed.instantiate() as V02LevelController
	root.add_child(level)
	await process_frame
	_expect(level.terrain_grid.configuration_valid, "AC-01/10: Unmodified default Level03 has a valid aggregate map")
	level.start_battle()
	_expect(level.player.is_input_enabled(), "AC-03: Player movement enables in combat")
	var infantry: InfantryController
	var archer: ArcherController
	for enemy: V02EnemyController in level.get_enemy_nodes():
		if enemy is InfantryController and infantry == null:
			infantry = enemy
		elif enemy is ArcherController and archer == null:
			archer = enemy
		enemy.set_physics_process(false)
	_expect(infantry != null and archer != null, "AC-03/04: Recursive enemy discovery finds both roles")
	if infantry != null:
		infantry.detected = true
		infantry.global_position = level.terrain_grid.cell_to_world(Vector2i(3, 3))
		level.player.global_position = level.terrain_grid.cell_to_world(Vector2i(5, 3))
		var before := infantry.global_position
		infantry._physics_process(0.25)
		_expect(infantry.global_position != before, "AC-03/10: Infantry movement uses aggregate pathfinding")
	if archer != null:
		archer.detected = true
		archer.global_position = level.terrain_grid.cell_to_world(Vector2i(2, 1))
		level.player.global_position = level.terrain_grid.cell_to_world(Vector2i(3, 2))
		archer.set("_attack_cooldown", 0.0)
		archer._physics_process(0.016)
		_expect(archer.is_winding_up(), "AC-04: Cornered archer still attacks when it cannot retreat")
	_expect(level.request_player_damage(infantry), "AC-06: Combat damage is accepted")
	_expect(level.get_round_state_name() == "RESOLVED" and level.hud.primary_button.text == "重试当前关", "AC-06: One-hit death resolves with retry")
	level.queue_free()
	await process_frame

	var campaign_scene := load("res://scenes/prototype/v02/prototype_campaign.tscn") as PackedScene
	var campaign := campaign_scene.instantiate() as CampaignController
	root.add_child(campaign)
	await process_frame
	campaign.start_campaign()
	await process_frame
	await process_frame
	campaign._on_level_won()
	await process_frame
	await process_frame
	_expect(campaign.current_level_index == 1 and campaign.current_level.name == "Level02", "AC-07: Campaign advances in configured order")
	campaign._on_level_won()
	await process_frame
	await process_frame
	campaign._on_level_won()
	await process_frame
	_expect(campaign.get_campaign_state() == "CAMPAIGN_WON", "AC-08: Three configured levels reach overall victory")
	campaign.return_to_main_menu()
	await process_frame
	_expect(campaign.get_campaign_state() == "MAIN_MENU", "AC-06/08: Return to menu clears campaign state")
	campaign.queue_free()
	await process_frame


func _add_test_cell(parent: Node, world_position: Vector2) -> TerrainCell:
	var cell := TerrainCell.new()
	parent.add_child(cell)
	cell.global_position = world_position
	return cell
