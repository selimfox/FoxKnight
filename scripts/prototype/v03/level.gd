class_name V03Level
extends Node2D

enum Phase { OBSERVING, AIMING, EXECUTING, CHOOSING, WAITING, RESOLVED }

@export var lock_config: ChainLockConfig
@export var chain_config: SlashChainConfig
@export var corpse_config: CorpseImpactConfig
@export_range(30.0, 250.0, 1.0) var arc_radius := 90.0
@export_range(40.0, 700.0, 1.0) var straight_distance := 330.0
@export_range(10.0, 180.0, 1.0) var straight_width := 70.0
@export_range(0.05, 1.0, 0.01) var slash_duration := 0.22

var phase := Phase.OBSERVING
var result := ""
var slash_count := 0
var direct_kills_this_slash := 0
var last_slash_arc := false
var last_direction := Vector2.RIGHT
var lock_cooldown_remaining := 0.0
var choice_end_usec := 0
var _slash_end := 0.0
var _slash_origin := Vector2.ZERO
var _slash_direction := Vector2.RIGHT
var _slash_distance := 0.0
var _slash_arc := false
var _reflect_ids: Dictionary = {}
var _marks: Array[Dictionary] = []
var _scale_restore_start := 0
var _scale_restore_from := 1.0
var _startup_complete := false
var _victory_pending := false

@onready var fox: PlayerController = $Actors/Player
@onready var effects: Node2D = $Effects
@onready var floor_layer: TileMapLayer = $Terrain/Floor
@onready var wall_layer: TileMapLayer = $Terrain/Walls
@onready var status: Label = $HUD/Status
@onready var result_label: Label = $HUD/Result

func _enter_tree() -> void:
	_ensure_action(&"heaven_chain", KEY_E)
	_ensure_action(&"retry", KEY_R)
	_ensure_action(&"move_left", KEY_A)
	_ensure_action(&"move_right", KEY_D)
	_ensure_action(&"move_up", KEY_W)
	_ensure_action(&"move_down", KEY_S)

func _ready() -> void:
	if lock_config == null:
		lock_config = ChainLockConfig.new()
	if chain_config == null:
		chain_config = SlashChainConfig.new()
	if corpse_config == null:
		corpse_config = CorpseImpactConfig.new()
	Engine.time_scale = 1.0
	fox.aim_started.connect(_on_aim_started)
	fox.aim_released.connect(_on_aim_released)
	fox.aim_cancel_requested.connect(_on_cancel)
	for statue in statues():
		_wire_statue(statue)
	fox.set_terrain_grid(self, 14.0)
	_startup_complete = true
	_update_hud()

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _process(_delta: float) -> void:
	if not _startup_complete:
		return
	if phase == Phase.AIMING or phase == Phase.CHOOSING:
		_update_aim(get_global_mouse_position())
	if phase == Phase.CHOOSING and Time.get_ticks_usec() >= choice_end_usec:
		_finish_choice(false)
	if _scale_restore_start > 0:
		var elapsed := float(Time.get_ticks_usec() - _scale_restore_start) / 1000000.0
		var duration := chain_config.restore_duration_real_seconds
		Engine.time_scale = 1.0 if duration <= 0.0 else lerpf(_scale_restore_from, 1.0, clampf(elapsed / duration, 0.0, 1.0))
		if Engine.time_scale >= 0.999:
			Engine.time_scale = 1.0
			_scale_restore_start = 0
	_update_hud()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if phase == Phase.RESOLVED:
		return
	lock_cooldown_remaining = maxf(0.0, lock_cooldown_remaining - delta)
	if phase == Phase.EXECUTING:
		_reflect_in_slash()
		_slash_end -= delta
		if _slash_end <= 0.0:
			_end_slash()
	if phase == Phase.WAITING:
		_check_outcome()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("retry") and phase == Phase.RESOLVED:
		retry()
	elif event.is_action_pressed(lock_config.input_action) and phase in [Phase.OBSERVING, Phase.AIMING]:
		fire_lock()
	elif phase == Phase.CHOOSING and event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
			_finish_choice(true)

func _on_aim_started(target: Vector2) -> void:
	if phase != Phase.OBSERVING:
		return
	phase = Phase.AIMING
	_update_aim(target)

func _on_aim_released(target: Vector2) -> void:
	if phase != Phase.AIMING:
		return
	_update_aim(target)
	_start_slash(_slash_arc, _slash_direction)

func _on_cancel() -> void:
	if phase == Phase.AIMING:
		phase = Phase.OBSERVING
		fox.clear_aim_preview()

func _update_aim(target: Vector2) -> void:
	if phase not in [Phase.AIMING, Phase.CHOOSING]:
		return
	var delta := target - fox.global_position
	if delta.length_squared() > 0.001:
		last_direction = delta.normalized()
	_slash_direction = last_direction
	_slash_arc = delta.length() < arc_radius if phase == Phase.AIMING else not last_slash_arc
	_slash_distance = 0.0 if _slash_arc else allowed_dash_distance(fox.global_position, _slash_direction, straight_distance)
	if _slash_arc:
		fox.update_arc_aim_preview(arc_radius)
	else:
		fox.update_straight_aim_preview(_slash_direction, _slash_distance, straight_width, arc_radius)

func _start_slash(arc: bool, direction: Vector2) -> void:
	if phase not in [Phase.AIMING, Phase.CHOOSING]:
		return
	if phase == Phase.AIMING:
		Engine.time_scale = 1.0
		_scale_restore_start = 0
	phase = Phase.EXECUTING
	fox.set_input_enabled(false)
	fox.clear_aim_preview()
	_slash_origin = fox.global_position
	_slash_direction = direction.normalized() if direction != Vector2.ZERO else last_direction
	_slash_arc = arc
	_slash_distance = 0.0 if arc else allowed_dash_distance(_slash_origin, _slash_direction, straight_distance)
	last_slash_arc = arc
	last_direction = _slash_direction
	slash_count += 1
	direct_kills_this_slash = 0
	_slash_end = slash_duration
	_reflect_ids.clear()
	if arc:
		fox.play_arc_attack_pose(slash_duration)
	else:
		fox.play_straight_attack_pose()
		var dash := create_tween()
		dash.tween_property(fox, "global_position", _slash_origin + _slash_direction * _slash_distance, slash_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	# Direct deaths are recorded before any new derived attack can advance.
	for statue in statues():
		if statue.alive and _point_in_slash(statue.global_position, 18.0):
			_kill_statue(statue, true, _direct_corpse_direction(statue.global_position))
	_reflect_in_slash()
	_update_hud()

func _end_slash() -> void:
	if phase != Phase.EXECUTING:
		return
	if not _slash_arc:
		fox.global_position = _slash_origin + _slash_direction * _slash_distance
	if alive_count() == 0:
		_resolve(true)
	elif direct_kills_this_slash >= maxi(1, chain_config.direct_kills_required):
		phase = Phase.CHOOSING
		choice_end_usec = Time.get_ticks_usec() + int(chain_config.selection_duration_real_seconds * 1000000.0)
		_scale_restore_start = 0
		Engine.time_scale = chain_config.selection_time_scale
		_update_aim(get_global_mouse_position())
	else:
		_enter_waiting()

func _finish_choice(accept: bool) -> void:
	if phase != Phase.CHOOSING:
		return
	if alive_count() == 0:
		_resolve(true)
		return
	var direction := _slash_direction
	var arc := _slash_arc
	_restore_scale()
	if accept:
		_start_slash(arc, direction)
	else:
		fox.clear_aim_preview()
		_enter_waiting()

func _enter_waiting() -> void:
	phase = Phase.WAITING
	fox.set_input_enabled(true)
	_check_outcome()

func _restore_scale() -> void:
	_scale_restore_from = Engine.time_scale
	_scale_restore_start = Time.get_ticks_usec()
	if chain_config.restore_duration_real_seconds <= 0.0:
		Engine.time_scale = 1.0
		_scale_restore_start = 0

func _check_outcome() -> void:
	if phase == Phase.RESOLVED:
		return
	if alive_count() == 0:
		if phase == Phase.EXECUTING:
			_victory_pending = true
		else:
			_resolve(true)
	elif phase == Phase.WAITING and friendly_attack_count() == 0:
		_resolve(false)

func _resolve(victory: bool) -> void:
	if phase == Phase.RESOLVED:
		return
	phase = Phase.RESOLVED
	result = "victory" if victory else "failure"
	fox.set_input_enabled(false)
	fox.clear_aim_preview()
	Engine.time_scale = 1.0
	_scale_restore_start = 0
	for statue in statues():
		statue.set_physics_process(false)
	for node in effects.get_children():
		node.set_physics_process(false)
	result_label.text = "胜利 · R 重试" if victory else "失败 · R 重试"
	_update_hud()
	set_process(false)

func fox_hit() -> void:
	if phase in [Phase.OBSERVING, Phase.AIMING, Phase.WAITING]:
		_resolve(false)

func retry() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func fire_lock() -> bool:
	if phase not in [Phase.OBSERVING, Phase.AIMING] or lock_cooldown_remaining > 0.0:
		return false
	var direction := (get_global_mouse_position() - fox.global_position).normalized()
	if direction == Vector2.ZERO:
		direction = last_direction
	_spawn_projectile(V03Projectile.Kind.LOCK, fox.global_position, direction, lock_config.projectile_speed, 0.0, lock_config.projectile_radius, 3.0, lock_config.maximum_range)
	lock_cooldown_remaining = lock_config.cooldown
	return true

func _wire_statue(statue: V03Statue) -> void:
	statue.set_fox(fox)
	if not statue.fired.is_connected(_on_statue_fired):
		statue.fired.connect(_on_statue_fired)

func _on_statue_fired(origin: Vector2, direction: Vector2, speed: float, acceleration: float) -> void:
	_spawn_projectile(V03Projectile.Kind.ENEMY, origin, direction, speed, acceleration, 7.0, 5.0)

func _spawn_projectile(kind: V03Projectile.Kind, origin: Vector2, direction: Vector2, speed: float, acceleration: float, radius: float, lifetime: float, range_limit: float = INF) -> V03Projectile:
	var bullet := V03Projectile.new()
	bullet.kind = kind
	bullet.direction = direction.normalized()
	bullet.last_direction = bullet.direction
	bullet.speed = speed
	bullet.acceleration = acceleration
	bullet.radius = radius
	bullet.lifetime = lifetime
	bullet.travel_remaining = range_limit
	bullet.owner_level = self
	effects.add_child(bullet)
	bullet.global_position = origin
	return bullet

func advance_projectile(bullet: V03Projectile, origin: Vector2, target: Vector2) -> void:
	var length := origin.distance_to(target)
	var steps := maxi(1, ceili(length / maxf(3.0, bullet.radius * 0.5)))
	for step in range(1, steps + 1):
		var point := origin.lerp(target, float(step) / float(steps))
		if is_wall(point, bullet.radius):
			if bullet.kind == V03Projectile.Kind.CORPSE:
				_add_mark(point)
			bullet.consume()
			return
		if bullet.kind == V03Projectile.Kind.ENEMY:
			if phase == Phase.EXECUTING and _point_in_slash(point, bullet.radius):
				_reflect(bullet, point)
				return
			if point.distance_to(fox.global_position) <= bullet.radius + 12.0:
				bullet.consume()
				fox_hit()
				return
		else:
			for statue in statues():
				if not statue.alive or point.distance_to(statue.global_position) > bullet.radius + 18.0:
					continue
				if bullet.kind == V03Projectile.Kind.LOCK:
					statue.bind_for(lock_config.bind_duration)
				elif bullet.kind == V03Projectile.Kind.CORPSE:
					# Create successor before consuming predecessor; outcome check sees the full batch.
					_kill_statue(statue, false, bullet.direction)
				else:
					_kill_statue(statue, false, bullet.direction)
				bullet.consume()
				call_deferred("_check_outcome")
				return
	bullet.global_position = target

func _reflect_in_slash() -> void:
	for node in effects.get_children():
		if node is V03Projectile:
			var bullet := node as V03Projectile
			if bullet.active and bullet.kind == V03Projectile.Kind.ENEMY and _point_in_slash(bullet.global_position, bullet.radius):
				_reflect(bullet, bullet.global_position)

func _reflect(bullet: V03Projectile, at: Vector2) -> void:
	if not bullet.active or bullet.kind != V03Projectile.Kind.ENEMY:
		return
	var reverse := -bullet.direction if bullet.direction != Vector2.ZERO else -bullet.last_direction
	_spawn_projectile(V03Projectile.Kind.FRIENDLY, at, reverse, bullet.speed, 0.0, bullet.radius, bullet.lifetime)
	bullet.consume()

func _kill_statue(statue: V03Statue, direct: bool, direction: Vector2) -> void:
	if not statue.kill():
		return
	if direct:
		direct_kills_this_slash += 1
	_add_mark(statue.global_position)
	_spawn_projectile(V03Projectile.Kind.CORPSE, statue.global_position, direction, corpse_config.speed, 0.0, corpse_config.radius, corpse_config.lifetime)
	if phase not in [Phase.EXECUTING, Phase.CHOOSING]:
		call_deferred("_check_outcome")

func _direct_corpse_direction(at: Vector2) -> Vector2:
	if not _slash_arc:
		return _slash_direction.rotated(deg_to_rad(corpse_config.straight_angle_offset_degrees))
	var radial := (at - fox.global_position).normalized()
	return radial if radial != Vector2.ZERO else last_direction

func _point_in_slash(at: Vector2, radius: float = 0.0) -> bool:
	if _slash_arc:
		return at.distance_to(_slash_origin) <= arc_radius + radius
	var relative := at - _slash_origin
	var along := relative.dot(_slash_direction)
	var across := absf(relative.cross(_slash_direction))
	return along >= -radius and along <= _slash_distance + radius and across <= straight_width * 0.5 + radius

func allowed_dash_distance(origin: Vector2, direction: Vector2, maximum: float) -> float:
	if direction == Vector2.ZERO:
		return 0.0
	var distance := 0.0
	while distance < maximum:
		var next := minf(maximum, distance + 3.0)
		if not is_world_circle_walkable(origin + direction * next, 14.0):
			break
		distance = next
	return distance

func is_world_circle_walkable(point: Vector2, radius: float) -> bool:
	for offset in [Vector2.ZERO, Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
		var cell := floor_layer.local_to_map(floor_layer.to_local(point + offset))
		if floor_layer.get_cell_source_id(cell) < 0 or wall_layer.get_cell_source_id(wall_layer.local_to_map(wall_layer.to_local(point + offset))) >= 0:
			return false
	return true

func is_wall(point: Vector2, radius: float = 0.0) -> bool:
	for offset in [Vector2.ZERO, Vector2(radius, 0), Vector2(-radius, 0), Vector2(0, radius), Vector2(0, -radius)]:
		if wall_layer.get_cell_source_id(wall_layer.local_to_map(wall_layer.to_local(point + offset))) >= 0:
			return true
	return false

func statues() -> Array[V03Statue]:
	var found: Array[V03Statue] = []
	for node in get_tree().get_nodes_in_group("v03_statue"):
		if node is V03Statue and is_ancestor_of(node):
			found.append(node)
	return found

func alive_count() -> int:
	var count := 0
	for statue in statues():
		if statue.alive:
			count += 1
	return count

func friendly_attack_count() -> int:
	var count := 0
	for node in effects.get_children():
		if node is V03Projectile and node.active and node.kind in [V03Projectile.Kind.FRIENDLY, V03Projectile.Kind.CORPSE]:
			count += 1
	return count

func _add_mark(at: Vector2) -> void:
	_marks.append({"position": at, "end": Time.get_ticks_usec() + int(corpse_config.mark_lifetime * 1000000.0)})
	while _marks.size() > corpse_config.maximum_marks:
		_marks.pop_front()
	queue_redraw()

func _draw() -> void:
	var now := Time.get_ticks_usec()
	for index in range(_marks.size() - 1, -1, -1):
		var mark := _marks[index]
		if now >= mark.end:
			_marks.remove_at(index)
		else:
			var center: Vector2 = to_local(mark.position)
			draw_line(center + Vector2(-8, -5), center + Vector2(9, 4), corpse_config.mark_color, 2.0)
			draw_line(center + Vector2(-4, 6), center + Vector2(3, -8), corpse_config.mark_color, 2.0)
	if phase == Phase.EXECUTING:
		if _slash_arc:
			draw_arc(to_local(_slash_origin), arc_radius, 0.0, TAU, 48, Color(1.0, 0.64, 0.22, 0.85), 12.0)
		else:
			draw_line(to_local(_slash_origin), to_local(_slash_origin + _slash_direction * _slash_distance), Color(0.38, 0.88, 1.0, 0.75), straight_width)

func _update_hud() -> void:
	if phase == Phase.RESOLVED:
		status.text = "目标 %d · %s" % [alive_count(), result]
	elif phase == Phase.CHOOSING:
		var remaining := maxf(0.0, float(choice_end_usec - Time.get_ticks_usec()) / 1000000.0)
		status.text = "续斩 %s · %.1f 秒 · 新点击确认" % ["圆" if _slash_arc else "直", remaining]
	else:
		status.text = "目标 %d · 第 %d 刀 · 锁 %.1f · %s" % [alive_count(), slash_count + 1, lock_cooldown_remaining, Phase.keys()[phase]]

func _ensure_action(action: StringName, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action, event)
