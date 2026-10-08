extends SceneTree

var _failures: Array[String] = []
var _shadow_sources: Array[Vector2] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for number in range(1, 4):
		var path := "res://scenes/prototype/levels/level_%02d.tscn" % number
		var level := (load(path) as PackedScene).instantiate() as PrototypeLevel
		var arena := level.get_node("Arena") as TileArena
		var floor := arena.get_node("Floor") as TileMapLayer
		var walls := arena.get_node("Walls") as TileMapLayer
		var decor := arena.get_node("Decoration") as TileMapLayer
		var water := arena.get_node("WaterSurface") as TileMapLayer
		var props := arena.get_node("Props") as TileMapLayer
		var reflections := arena.get_node("WaterReflections")
		_expect(arena.get_node_or_null("CourtyardPlate") == null, "ART-%d no whole-room CourtyardPlate" % number)
		_expect(floor.modulate.a > 0.99 and walls.modulate.a > 0.99, "ART-%d terrain visible directly" % number)
		_expect(floor.tile_set.resource_path.ends_with("courtyard_floor_level_%02d_tileset.tres" % number), "ART-%d floor uses authored atlas" % number)
		_expect(walls.tile_set.resource_path.ends_with("courtyard_wall_20260930_tileset.tres"), "ART-%d wall uses authored atlas" % number)
		_expect(decor.get_used_cells().size() > 0 and props.get_used_cells().size() > 0, "ART-%d independent editable decoration and props" % number)
		_expect(water.get_used_cells().size() == 9, "ART-%d shallow water keeps its nine authored cells" % number)
		var quiet_floor_count := 0
		var slab_count := 0
		for floor_position: Vector2i in floor.get_used_cells():
			if floor.get_cell_source_id(floor_position) == 0 and floor.get_cell_atlas_coords(floor_position) == Vector2i.ZERO:
				quiet_floor_count += 1
			elif floor.get_cell_source_id(floor_position) == 2:
				slab_count += 1
		_expect(quiet_floor_count < int(floor.get_used_cells().size() * 0.48) and slab_count >= 32, "ART-%d floor no longer repeats a single cell over most of the room" % number)
		_expect(water.tile_set.get_physics_layers_count() == 0 and props.tile_set.get_physics_layers_count() == 0, "ART-%d visual layers have no collision" % number)
		var wall_count := walls.get_used_cells().size()
		var floor_cell := Vector2i(10, 8)
		var wall_cell := Vector2i(8, 8)
		var decor_cell := Vector2i(11, 12)
		floor.set_cell(floor_cell, 2, Vector2i(2, 1))
		walls.set_cell(wall_cell, 0, Vector2i(0, 1))
		decor.set_cell(decor_cell, 0, Vector2i(1, 0))
		level.get_node("Actors/Player").global_position = water.to_global(water.map_to_local(water.get_used_cells()[4]))
		root.add_child(level)
		await process_frame
		await physics_frame
		_expect(floor.get_cell_atlas_coords(floor_cell) == Vector2i(2, 1), "EDIT-%d floor edit survives live scene" % number)
		_expect(walls.get_cell_atlas_coords(wall_cell) == Vector2i(0, 1), "EDIT-%d wall visual edit survives live scene" % number)
		_expect(decor.get_cell_atlas_coords(decor_cell) == Vector2i(1, 0), "EDIT-%d decoration edit survives live scene" % number)
		_expect(arena.get_node("TileWallCollisions").get_child_count() == wall_count + 1, "EDIT-%d wall edit adds collision" % number)
		_expect(arena.get_slash_distance(Vector2(176, 272), Vector2.RIGHT, 400.0) < 400.0, "EDIT-%d wall edit clips slash" % number)
		var player := level.get_node("Actors/Player") as PlayerController
		var player_shadow := player.get_node("GroundShadow") as DynamicActorShadow
		_shadow_sources.append(player_shadow.main_light_world_position)
		_expect(player_shadow.main_light_world_position.distance_to(Vector2(-120.0, -120.0)) > 50.0, "LIGHT-%d scene light drives current actor shadow" % number)
		var reflection := reflections.get_reflection_for_actor(player) as Sprite2D
		_expect(reflection != null and reflection.visible, "WATER-%d actor entry enables reflection" % number)
		var ripple := reflections.get_node_or_null("Ripple_" + player.name) as Sprite2D
		_expect(ripple != null and ripple.visible, "WATER-%d actor entry creates a brief surface ripple" % number)
		reflections.call("_process", 0.08)
		_expect(absf(float(player_shadow.get("_water_factor")) - 0.45) < 0.01, "WATER-%d ground shadow attenuates over eighty milliseconds" % number)
		player_shadow.set_shadow_fade(0.6)
		reflections.call("_process", 0.01)
		_expect(absf(float(player_shadow.get("_fade")) - 0.6) < 0.01, "WATER-%d water shading preserves independent death fade" % number)
		player_shadow.set_shadow_fade(1.0)
		if reflection != null:
			var sprite := player.get_node("Visual/Sprite") as CharacterAnimation
			var anchor := sprite.get_frame_foot_anchor()
			var reflected_foot := reflection.to_global(Vector2(anchor.x, reflection.texture.get_height() - anchor.y))
			_expect(reflected_foot.distance_to(player.get_visual_foot_anchor_global()) < 0.01, "WATER-%d flipped frame foot anchor remains aligned" % number)
			if number == 1 and DisplayServer.get_name() != "headless":
				_capture("res://output/environment_v2_water_01_enter.png")
			var front_frame := reflection.texture
			(player.get_node("Visual/Sprite") as CharacterAnimation).play("walk", "side")
			reflections.call("_process", 0.0)
			_expect(reflection.texture != front_frame, "WATER-%d reflection follows current turned frame" % number)
			if number == 1 and DisplayServer.get_name() != "headless":
				await process_frame
				_capture("res://output/environment_v2_water_02_turn.png")
				(player.get_node("Visual/Sprite") as CharacterAnimation).play("arc", "front")
				reflections.call("_process", 0.0)
				await process_frame
				_capture("res://output/environment_v2_water_03_arc.png")
			player.position = Vector2(480, 272)
			reflections.call("_process", 0.0)
			_expect(not reflection.visible, "WATER-%d actor exit hides reflection" % number)
			_expect(not ripple.visible, "WATER-%d actor exit hides water ripple" % number)
			reflections.call("_process", 0.08)
			_expect(absf(float(player_shadow.get("_water_factor")) - 1.0) < 0.01, "WATER-%d leaving water restores land shadow" % number)
			if number == 1 and DisplayServer.get_name() != "headless":
				await process_frame
				_capture("res://output/environment_v2_water_04_exit.png")
		level.queue_free()
		await process_frame
	_expect(_shadow_sources.size() == 3 and _shadow_sources[0].distance_to(_shadow_sources[1]) > 100.0, "LIGHT: different level light layouts produce different shadow sources")
	_finish()


func _expect(condition: bool, label: String) -> void:
	if condition:
		print("PASS | " + label)
	else:
		_failures.append(label)
		push_error("FAIL | " + label)


func _capture(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	_expect(image != null and image.save_png(path) == OK, "CAPTURE | " + path)


func _finish() -> void:
	if _failures.is_empty():
		print("RESULT | PASS | Editable environment and water visual acceptance")
		quit(0)
	else:
		print("RESULT | FAIL | %d environment checks" % _failures.size())
		quit(1)
