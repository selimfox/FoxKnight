class_name V03ImpactMark
extends Node2D

var tint := Color.RED
var lifetime := 6.0
var elapsed := 0.0
var on_wall := false

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var color := tint
	color.a *= 1.0 - clampf(elapsed / lifetime, 0.0, 1.0)
	if on_wall:
		draw_line(Vector2(-9, -9), Vector2(8, 5), color, 4.0)
		draw_line(Vector2(-5, -4), Vector2(-5, 12), color, 3.0)
		draw_circle(Vector2(9, 7), 3.0, color)
	else:
		draw_circle(Vector2.ZERO, 6.0, color)
		for index in range(6):
			var arm := Vector2.RIGHT.rotated(TAU * float(index) / 6.0 + 0.32)
			var spread := 9.0 + float(index % 3) * 4.0
			draw_line(arm * 3.0, arm * spread, color, 3.0)
			draw_circle(arm * spread, 2.0 + float(index % 2), color)
