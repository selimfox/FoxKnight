class_name V03FoxAura
extends Node2D

var pulse := 0.0

func _ready() -> void:
	visible = false
	show_behind_parent = true

func _process(delta: float) -> void:
	if visible:
		pulse += delta
		queue_redraw()

func _draw() -> void:
	var radius := 30.0 + sin(pulse * 7.0) * 3.0
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.68, 0.14, 0.13))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(1.0, 0.81, 0.25, 0.85), 3.0)
	draw_arc(Vector2.ZERO, radius + 7.0, 0.0, TAU, 48, Color(1.0, 0.55, 0.15, 0.33), 2.0)
