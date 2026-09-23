extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS | ", label)
	else:
		failures += 1
		push_error("FAIL | " + label)

func _new_level() -> V03Level:
	var level := load("res://scenes/prototype/v03/level_01.tscn").instantiate() as V03Level
	root.add_child(level)
	for statue in level.statues():
		statue.shot_clock = 1000.0
	return level

func _remove(level: V03Level) -> void:
	root.remove_child(level)
	level.free()
	Engine.time_scale = 1.0

func _run() -> void:
	var level := _new_level()
	await process_frame
	_check(level.floor_layer.get_used_cells().size() > 200, "AC-10 scene contains paintable native TileMapLayer floor")
	_check(level.wall_layer.get_used_cells().size() > 50, "AC-10 scene contains paintable native TileMapLayer walls")
	_check(level.is_world_circle_walkable(Vector2(208, 272), 14.0), "AC-01 fox can stand on floor")
	_check(not level.is_world_circle_walkable(Vector2(80, 272), 14.0), "AC-01 wall blocks fox")
	_check(level.allowed_dash_distance(Vector2(208, 272), Vector2.LEFT, 400) < 150.0, "AC-01 straight slash ends at wall")
	var tile := Vector2i(10, 8)
	var tile_position := level.floor_layer.to_global(level.floor_layer.map_to_local(tile))
	level.floor_layer.erase_cell(tile)
	_check(not level.is_world_circle_walkable(tile_position, 0.0), "AC-10 erased floor becomes void without registry edit")
	level.floor_layer.set_cell(tile, 0, Vector2i(0, 0))
	level.wall_layer.set_cell(tile, 0, Vector2i(1, 0))
	_check(level.is_wall(tile_position), "AC-10 painted wall takes effect without registry edit")
	level.wall_layer.erase_cell(tile)
	var group := level.get_node("Actors/Statues") as Node2D
	var before := level.alive_count()
	var added := load("res://scenes/actors/v03/statue.tscn").instantiate() as V03Statue
	group.add_child(added)
	added.position = Vector2(350, 260)
	_check(level.alive_count() == before + 1, "AC-10 added statue counted automatically")
	group.position += Vector2(20, 0)
	_check(added.global_position.distance_to(Vector2(370, 260)) < 0.1, "AC-10 parent re-layout changes world position")
	added.queue_free()
	await process_frame
	_check(level.alive_count() == before, "AC-10 removed statue no longer counted")
	_remove(level)

	level = _new_level()
	await process_frame
	var statues := level.statues()
	var first := statues[0]
	var second := statues[1]
	var lock := level._spawn_projectile(V03Projectile.Kind.LOCK, level.fox.global_position, (first.global_position - level.fox.global_position).normalized(), 500, 0, 6, 3)
	level.advance_projectile(lock, level.fox.global_position, first.global_position)
	_check(first.bound_remaining > 1.9 and not lock.active, "AC-02 lock binds first live target and vanishes")
	first.bind_for(0.3)
	first.bind_for(2.0)
	_check(is_equal_approx(first.bound_remaining, 2.0), "AC-02 repeat lock refreshes without stacking")
	var cooldown_before := level.lock_cooldown_remaining
	level.lock_cooldown_remaining = 4.0
	_check(not level.fire_lock() and level.lock_cooldown_remaining == 4.0, "AC-02 cooldown rejects early repeat")
	level.lock_cooldown_remaining = cooldown_before
	first.shot_clock = 0.2
	first._physics_process(0.1)
	_check(is_equal_approx(first.shot_clock, 0.2), "AC-02 bind pauses shooting timer")
	first.bound_remaining = 0.0
	first._physics_process(0.1)
	_check(first.shot_clock < 0.2, "AC-02 release resumes remainder without burst")
	var aimed := StatueAttackConfig.new()
	aimed.fire_mode = StatueAttackConfig.FireMode.AIM_AT_FOX
	aimed.aimed_speed = 333.0
	first.attack = aimed
	first.shot_clock = 0.0
	var count_before := level.effects.get_child_count()
	first._physics_process(0.016)
	_check(level.effects.get_child_count() == count_before + 1, "AC-03 aimed statue fires configured bullet")
	var enemy_bullet := level.effects.get_child(level.effects.get_child_count() - 1) as V03Projectile
	var fixed_direction := enemy_bullet.direction
	level.fox.global_position += Vector2(0, 100)
	_check(enemy_bullet.direction == fixed_direction and is_equal_approx(enemy_bullet.speed, 333.0), "AC-03 launched aim does not track")
	var volley := StatueAttackConfig.new()
	volley.fire_mode = StatueAttackConfig.FireMode.CONFIGURED_VOLLEY
	volley.attack_interval = 1.3
	var entry := StatueShotEntry.new()
	entry.angle_degrees = 90.0
	entry.speed = 200.0
	entry.acceleration = -50.0
	volley.volley = [entry]
	first.attack = volley
	first.shot_clock = 0.0
	first._physics_process(0.016)
	var volley_bullet := level.effects.get_child(level.effects.get_child_count() - 1) as V03Projectile
	_check(volley_bullet.direction.distance_to(Vector2.DOWN.rotated(first.rotation)) < 0.01 and volley_bullet.acceleration == -50.0, "AC-03 typed volley angle and acceleration")
	_check(absf(first.shot_clock - (1.3 - 0.016)) < 0.01, "AC-03 attack interval configured")
	level._slash_origin = level.fox.global_position
	level._slash_direction = Vector2.RIGHT
	level._slash_distance = 100.0
	level._slash_arc = false
	level.phase = V03Level.Phase.EXECUTING
	var reflect := level._spawn_projectile(V03Projectile.Kind.ENEMY, level.fox.global_position + Vector2(50, 0), Vector2.LEFT, 500, 100, 5, 4)
	level._reflect_in_slash()
	_check(not reflect.active, "AC-04 reflected enemy bullet immediately invalid")
	var friendly: V03Projectile
	for node in level.effects.get_children():
		if node is V03Projectile and node.active and node.kind == V03Projectile.Kind.FRIENDLY:
			friendly = node
	_check(friendly != null and friendly.direction == Vector2.RIGHT and friendly.speed == 500.0 and friendly.acceleration == 0.0, "AC-04 friendly bullet reverses and removes acceleration")
	level.phase = V03Level.Phase.OBSERVING
	level.fox_hit()
	_check(level.result == "failure", "AC-09 normal phase vulnerable")
	level._resolve(true)
	_check(level.result == "failure", "AC-08 resolved death cannot be overwritten")
	_remove(level)

	level = _new_level()
	await process_frame
	statues = level.statues()
	first = statues[0]
	second = statues[1]
	level.chain_config.direct_kills_required = 1
	level.phase = V03Level.Phase.AIMING
	level._start_slash(false, (first.global_position - level.fox.global_position).normalized())
	_check(level.slash_count == 1 and level.direct_kills_this_slash >= 1, "AC-05 first slash counts direct kills")
	level.fox_hit()
	_check(level.phase == V03Level.Phase.EXECUTING, "AC-09 execution immunity")
	level._end_slash()
	_check(level.phase == V03Level.Phase.CHOOSING and level._slash_arc, "AC-05 follow-up forces alternating arc form")
	_check(Engine.time_scale < 1.0 and level.choice_end_usec > Time.get_ticks_usec(), "AC-06 choice uses slow scale and real deadline")
	level.fox_hit()
	_check(level.phase == V03Level.Phase.CHOOSING and not level.fox.is_input_enabled(), "AC-09 choice immune and movement disabled")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	level._unhandled_input(click)
	_check(level.slash_count == 2 and level.phase == V03Level.Phase.EXECUTING, "AC-05 new press launches second slash")
	level._end_slash()
	_remove(level)

	level = _new_level()
	await process_frame
	statues = level.statues()
	statues[0].kill()
	statues[1].kill()
	level.phase = V03Level.Phase.WAITING
	var last_target := statues[2]
	var late_friendly := level._spawn_projectile(V03Projectile.Kind.FRIENDLY, last_target.global_position - Vector2(70, 0), Vector2.RIGHT, 400, 0, 6, 2)
	level._check_outcome()
	_check(level.phase == V03Level.Phase.WAITING, "AC-08 late friendly bullet delays failure")
	level.advance_projectile(late_friendly, late_friendly.global_position, last_target.global_position + Vector2(20, 0))
	await process_frame
	_check(level.result == "victory" and not last_target.alive, "AC-08 late friendly bullet can finish all targets")
	_remove(level)

	level = _new_level()
	await process_frame
	statues = level.statues()
	statues[0].kill()
	statues[1].kill()
	level.phase = V03Level.Phase.WAITING
	last_target = statues[2]
	var late_corpse := level._spawn_projectile(V03Projectile.Kind.CORPSE, last_target.global_position - Vector2(70, 0), Vector2.RIGHT, 400, 0, 12, 2)
	level._check_outcome()
	level.advance_projectile(late_corpse, late_corpse.global_position, last_target.global_position + Vector2(20, 0))
	await process_frame
	_check(level.result == "victory" and not last_target.alive and level.direct_kills_this_slash == 0, "AC-08 late corpse can finish all targets without direct credit")
	_remove(level)

	level = _new_level()
	await process_frame
	level._add_mark(Vector2(200, 200))
	level._spawn_projectile(V03Projectile.Kind.ENEMY, Vector2(300, 300), Vector2.RIGHT, 100, 0, 6, 2)
	level._resolve(false)
	current_scene = level
	level.retry()
	await process_frame
	var reloaded := current_scene as V03Level
	_check(reloaded != null and reloaded != level and reloaded._marks.is_empty() and reloaded.effects.get_child_count() == 0 and is_equal_approx(Engine.time_scale, 1.0), "AC-10 retry reloads clean scene and time scale")
	current_scene = null
	if reloaded != null:
		_remove(reloaded)
	current_scene = null
	if reloaded != null:
		_remove(reloaded)

	level = _new_level()
	await process_frame
	statues = level.statues()
	first = statues[0]
	second = statues[1]
	level.phase = V03Level.Phase.WAITING
	var corpse := level._spawn_projectile(V03Projectile.Kind.CORPSE, first.global_position - Vector2(60, 0), Vector2.RIGHT, 400, 0, 12, 2)
	level.advance_projectile(corpse, corpse.global_position, first.global_position + Vector2(20, 0))
	_check(not first.alive and not corpse.active and level.friendly_attack_count() >= 1, "AC-07 corpse transfers atomically to successor")
	_check(level.direct_kills_this_slash == 0, "AC-05 indirect death does not count for chain")
	level._check_outcome()
	_check(level.phase == V03Level.Phase.WAITING, "AC-08 pending friendly attack delays failure")
	for node in level.effects.get_children():
		if node is V03Projectile:
			node.consume()
	level._check_outcome()
	_check(level.result == "failure", "AC-08 no friendly attack and survivors means failure")
	_remove(level)

	level = _new_level()
	await process_frame
	first = level.statues()[0]
	second = level.statues()[1]
	_check(second.attack.fire_mode == StatueAttackConfig.FireMode.CONFIGURED_VOLLEY and second.attack.volley.size() == 2, "AC-03 sample board authors typed volley in Inspector")
	var wall_point := level.wall_layer.to_global(level.wall_layer.map_to_local(Vector2i(2, 8)))
	lock = level._spawn_projectile(V03Projectile.Kind.LOCK, Vector2(208, 272), Vector2.LEFT, 500, 0, 6, 3, 400)
	level.advance_projectile(lock, lock.global_position, wall_point - Vector2(15, 0))
	_check(not lock.active and first.bound_remaining == 0.0, "AC-02 wall absorbs lock before target")
	lock = level._spawn_projectile(V03Projectile.Kind.LOCK, Vector2(208, 272), Vector2.RIGHT, 500, 0, 6, 3, 40)
	lock._physics_process(0.2)
	_check(not lock.active and first.bound_remaining == 0.0, "AC-02 lock expires at configured range")
	var near := load("res://scenes/actors/v03/statue.tscn").instantiate() as V03Statue
	level.get_node("Actors/Statues").add_child(near)
	near.global_position = Vector2(290, 272)
	lock = level._spawn_projectile(V03Projectile.Kind.LOCK, Vector2(208, 272), Vector2.RIGHT, 1500, 0, 6, 3, 500)
	level.advance_projectile(lock, lock.global_position, Vector2(700, 272))
	_check(near.bound_remaining > 0.0 and second.bound_remaining == 0.0, "AC-02 swept lock binds first target only")
	var fast := level._spawn_projectile(V03Projectile.Kind.ENEMY, Vector2(110, 272), Vector2.LEFT, 2000, 0, 5, 2)
	level.advance_projectile(fast, fast.global_position, Vector2(10, 272))
	_check(not fast.active, "AC-04 high-speed enemy bullet swept against wall")
	level.phase = V03Level.Phase.EXECUTING
	level._slash_origin = Vector2(208, 272)
	level._slash_direction = Vector2.RIGHT
	level._slash_distance = 200.0
	level._slash_arc = false
	fast = level._spawn_projectile(V03Projectile.Kind.ENEMY, Vector2(420, 272), Vector2.LEFT, 2000, 0, 5, 2)
	var count_friendly := level.friendly_attack_count()
	level.advance_projectile(fast, fast.global_position, Vector2(200, 272))
	_check(not fast.active and level.friendly_attack_count() == count_friendly + 1, "AC-04 high-speed slash crossing reflects once")
	level.phase = V03Level.Phase.WAITING
	var corpse_wall := level._spawn_projectile(V03Projectile.Kind.CORPSE, Vector2(110, 272), Vector2.LEFT, 600, 0, 10, 2)
	level.advance_projectile(corpse_wall, corpse_wall.global_position, Vector2(10, 272))
	_check(not corpse_wall.active and level._marks.size() > 0, "AC-07 corpse stops at wall and leaves debris")
	_remove(level)

	level = _new_level()
	await process_frame
	statues = level.statues()
	first = statues[0]
	second = statues[1]
	var third := statues[2]
	first.global_position = Vector2(340, 272)
	second.global_position = Vector2(538, 340)
	third.global_position = Vector2(680, 272)
	level.chain_config.direct_kills_required = 1
	level.phase = V03Level.Phase.AIMING
	level._start_slash(false, Vector2.RIGHT)
	level._end_slash()
	_check(level.phase == V03Level.Phase.CHOOSING and first.alive == false and second.alive, "AC-05 first direct kill opens one choice")
	level._finish_choice(true)
	_check(level.slash_count == 2 and level.phase == V03Level.Phase.EXECUTING and second.alive == false, "AC-05 second opposite-form slash directly kills")
	_check(Engine.time_scale < 1.0 and level._scale_restore_start > 0, "AC-06 accepted chain retains gradual scale recovery")
	level._end_slash()
	_check(level.phase == V03Level.Phase.CHOOSING and third.alive, "AC-05 second qualifying slash opens another choice")
	level._slash_direction = Vector2.RIGHT
	level._finish_choice(true)
	_check(level.slash_count == 3 and not third.alive and level.last_slash_arc == false, "AC-05 third slash alternates again without stored credit")
	level._end_slash()
	_check(level.result == "victory", "AC-08 all dead resolves victory after executing slash")
	_check(not second.is_physics_processing(), "AC-08 resolved world stops statue updates")
	var frozen := true
	for node in level.effects.get_children():
		if node is V03Projectile and node.is_physics_processing():
			frozen = false
	_check(frozen, "AC-08 resolved world stops in-flight projectiles")
	_remove(level)

	level = _new_level()
	await process_frame
	first = level.statues()[0]
	level.chain_config.direct_kills_required = 2
	level.phase = V03Level.Phase.AIMING
	level._start_slash(false, (first.global_position - level.fox.global_position).normalized())
	level._end_slash()
	_check(level.phase != V03Level.Phase.CHOOSING and level.direct_kills_this_slash == 1, "AC-05 below N direct kills cannot chain")
	_remove(level)

	level = _new_level()
	await process_frame
	first = level.statues()[0]
	level.chain_config.selection_duration_real_seconds = 0.02
	level.chain_config.restore_duration_real_seconds = 0.0
	level.phase = V03Level.Phase.AIMING
	level._start_slash(false, (first.global_position - level.fox.global_position).normalized())
	level._end_slash()
	var slash_before_timeout := level.slash_count
	await create_timer(0.04, true, false, true).timeout
	level._process(0.0)
	_check(level.phase != V03Level.Phase.CHOOSING and level.slash_count == slash_before_timeout and is_equal_approx(Engine.time_scale, 1.0), "AC-06 real-time choice timeout exits without auto-chain and restores scale")
	_remove(level)

	level = _new_level()
	await process_frame
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	var effects_before := level.effects.get_child_count()
	level._unhandled_input(key)
	_check(level.effects.get_child_count() == effects_before + 1 and level.lock_cooldown_remaining > 0.0, "AC-02 E input action launches lock and starts cooldown")
	level._on_aim_started(Vector2(450, 208))
	_check(level.phase == V03Level.Phase.AIMING and level.fox.is_input_enabled(), "AC-01 simulated hold enters aiming while fox moves")
	level._on_aim_released(Vector2(450, 208))
	_check(level.phase == V03Level.Phase.EXECUTING and level.slash_count == 1, "AC-01 simulated release executes first slash")
	level._end_slash()
	_check(level.phase == V03Level.Phase.CHOOSING, "AC-05 simulated direct hit offers continuation")
	effects_before = level.effects.get_child_count()
	level._unhandled_input(key)
	_check(level.effects.get_child_count() == effects_before, "AC-09 E is disabled during continuation choice")
	click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	level._unhandled_input(click)
	_check(level.phase == V03Level.Phase.EXECUTING and level.slash_count == 2, "AC-06 simulated fresh click accepts continuation")
	level._end_slash()
	_remove(level)

	print("RESULT | %s | v0.3 acceptance | %d checks, %d failures" % ["PASS" if failures == 0 else "FAIL", checks, failures])
	quit(0 if failures == 0 else 1)
