class_name V03Projectile
extends Node2D

enum Kind { ENEMY, FRIENDLY, LOCK, CORPSE }

var kind := Kind.ENEMY
var direction := Vector2.RIGHT
var speed := 300.0
var acceleration := 0.0
var radius := 8.0
var lifetime := 4.0
var travel_remaining := INF
var last_direction := Vector2.RIGHT
var owner_level: Node
var active := true

func _physics_process(delta: float) -> void:
	if not active or owner_level == null:
		return
	lifetime -= delta
	if lifetime <= 0.0 or travel_remaining <= 0.0:
		consume()
		return
	var from := global_position
	var step := minf(speed * delta, travel_remaining)
	var target := from + direction * step
	travel_remaining -= step
	owner_level.advance_projectile(self, from, target)
	if not active:
		return
	if travel_remaining <= 0.0:
		consume()
		return
	speed = maxf(0.0, speed + acceleration * delta)
	queue_redraw()

func consume() -> void:
	if not active:
		return
	active = false
	queue_free()

func _draw() -> void:
	var color := Color(1.0, 0.36, 0.22) if kind == Kind.ENEMY else Color(0.26, 0.86, 1.0)
	if kind == Kind.LOCK:
		color = Color(0.94, 0.88, 0.27)
	elif kind == Kind.CORPSE:
		color = Color(0.66, 0.62, 0.55)
	if kind == Kind.LOCK:
		var angle := direction.angle()
		draw_set_transform(Vector2.ZERO, angle)
		draw_line(Vector2(-22, 0), Vector2(9, 0), color, 3.0)
		for x in [-18.0, -10.0, -2.0]:
			draw_polyline(PackedVector2Array([Vector2(x - 3, 0), Vector2(x, -4), Vector2(x + 3, 0), Vector2(x, 4), Vector2(x - 3, 0)]), Color(0.45, 0.96, 1.0), 1.8)
		draw_colored_polygon(PackedVector2Array([Vector2(7, -7), Vector2(19, 0), Vector2(7, 7)]), color)
		draw_set_transform(Vector2.ZERO)
	elif kind == Kind.FRIENDLY:
		draw_colored_polygon(PackedVector2Array([Vector2(0, -radius - 3), Vector2(radius + 3, 0), Vector2(0, radius + 3), Vector2(-radius - 3, 0)]), color)
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 16, Color(0.7, 1.0, 1.0, 0.7), 1.5)
	elif kind == Kind.CORPSE:
		draw_circle(Vector2.ZERO, radius, color)
		draw_line(Vector2(-radius, -4), Vector2(radius, 5), Color(0.30, 0.29, 0.27), 2.0)
		draw_line(Vector2(-2, radius), Vector2(4, -radius), Color(0.30, 0.29, 0.27), 2.0)
	else:
		draw_circle(Vector2.ZERO, radius, color)
		draw_circle(Vector2(-2, -2), radius * 0.35, Color(1.0, 0.75, 0.55))
