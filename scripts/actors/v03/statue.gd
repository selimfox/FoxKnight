class_name V03Statue
extends StaticBody2D

signal fired(origin: Vector2, direction: Vector2, speed: float, acceleration: float)
signal died(statue: V03Statue)

@export var attack: StatueAttackConfig
var alive := true
var bound_remaining := 0.0
var bind_total := 2.0
var shot_clock := 0.0
var _fox: Node2D

func _ready() -> void:
	add_to_group("v03_statue")
	if attack == null:
		attack = StatueAttackConfig.new()
	shot_clock = attack.first_shot_delay
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not alive:
		return
	if bound_remaining > 0.0:
		bound_remaining = maxf(0.0, bound_remaining - delta)
		queue_redraw()
		return
	shot_clock -= delta
	if shot_clock > 0.0:
		return
	shot_clock += maxf(attack.attack_interval, 0.1)
	if attack.fire_mode == StatueAttackConfig.FireMode.AIM_AT_FOX:
		if is_instance_valid(_fox):
			var direction := (_fox.global_position - global_position).normalized()
			if direction != Vector2.ZERO:
				fired.emit(global_position, direction, attack.aimed_speed, attack.aimed_acceleration)
	else:
		for entry in attack.volley:
			if entry != null:
				fired.emit(global_position, Vector2.RIGHT.rotated(rotation + deg_to_rad(entry.angle_degrees)), entry.speed, entry.acceleration)
	queue_redraw()

func set_fox(fox: Node2D) -> void:
	_fox = fox

func bind_for(seconds: float) -> void:
	bound_remaining = maxf(seconds, 0.0)
	bind_total = maxf(seconds, 0.01)
	queue_redraw()

func kill() -> bool:
	if not alive:
		return false
	alive = false
	$CollisionShape2D.set_deferred("disabled", true)
	queue_redraw()
	died.emit(self)
	return true

func _draw() -> void:
	if not alive:
		return
	draw_circle(Vector2.ZERO, 20.0, Color(0.28, 0.29, 0.35))
	draw_circle(Vector2.ZERO, 13.0, Color(0.64, 0.60, 0.51))
	draw_line(Vector2(-8, -7), Vector2(9, 7), Color(0.18, 0.17, 0.20), 3.0)
	if bound_remaining > 0.0:
		draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 30, Color(0.35, 0.90, 1.0), 4.0)
		for index in range(12):
			var angle := TAU * float(index) / 12.0
			var center := Vector2.RIGHT.rotated(angle) * 27.0
			var tangent := Vector2.RIGHT.rotated(angle + PI * 0.5)
			var radial := Vector2.RIGHT.rotated(angle)
			draw_polyline(PackedVector2Array([center - tangent * 5.0, center - radial * 3.0, center + tangent * 5.0, center + radial * 3.0, center - tangent * 5.0]), Color(1.0, 0.95, 0.48), 2.0)
		draw_line(Vector2(-19, -16), Vector2(19, 16), Color(0.45, 0.93, 1.0), 2.0)
		draw_line(Vector2(-19, 16), Vector2(19, -16), Color(0.45, 0.93, 1.0), 2.0)
		draw_arc(Vector2.ZERO, 32.0, -PI/2.0, -PI/2.0 + TAU * bound_remaining / bind_total, 32, Color(1.0, 0.91, 0.35), 2.0)
