class_name V03Projectile
extends Node2D

enum Kind { ENEMY, LOCK, CORPSE }

const STATUE_SCENE = preload("res://scenes/actors/v03/statue.tscn")

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
var trail: Array[Vector2] = []
var visual_age := 0.0
var _corpse_sculpture: Node2D

func _ready() -> void:
	if kind == Kind.CORPSE:
		var statue := STATUE_SCENE.instantiate()
		_corpse_sculpture = statue.get_node("Sculpture").duplicate() as Node2D
		statue.free()
		_corpse_sculpture.scale = Vector2.ONE * 0.6
		add_child(_corpse_sculpture)

func _physics_process(delta: float) -> void:
	if not active or owner_level == null:
		return
	lifetime -= delta
	if lifetime <= 0.0 or travel_remaining <= 0.0:
		consume()
		return
	var from := global_position
	visual_age += delta
	if kind == Kind.ENEMY and speed > 0.0:
		trail.push_front(from)
		if trail.size() > 7:
			trail.pop_back()
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
	elif kind == Kind.CORPSE:
		pass # The duplicated Sculpture scene is drawn by its Polygon2D children.
	else:
		_draw_trail(Color(1.0, 0.28, 0.09, 0.72))
		draw_circle(Vector2.ZERO, radius + 7.0, Color(1.0, 0.16, 0.04, 0.22))
		draw_circle(Vector2.ZERO, radius, color)
		draw_circle(Vector2(-2, -2), radius * 0.35, Color(1.0, 0.75, 0.55))

func _draw_trail(tint: Color) -> void:
	for index in range(trail.size() - 1, -1, -1):
		var local := to_local(trail[index])
		var fade := 1.0 - float(index + 1) / float(trail.size() + 1)
		var bead := tint
		bead.a *= fade * 0.6
		draw_circle(local, maxf(1.0, radius * fade * 0.75), bead)
	if trail.size() > 0:
		var line_color := tint
		line_color.a *= 0.62
		draw_line(to_local(trail[trail.size() - 1]), Vector2.ZERO, line_color, 3.0)
