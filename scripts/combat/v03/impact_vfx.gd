class_name V03ImpactVfx
extends Node2D

var tint := Color(0.2, 0.9, 1.0)
var duration := 0.25
var elapsed := 0.0
var splatter := false

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress := clampf(elapsed / duration, 0.0, 1.0)
	var color := tint
	color.a *= 1.0 - progress
	if splatter:
		for index in range(7):
			var angle := TAU * float(index) / 7.0 + 0.21
			var spread := (10.0 + float(index % 3) * 5.0) * (0.4 + progress)
			var arm := Vector2.RIGHT.rotated(angle)
			draw_line(arm * 3.0, arm * spread, color, 2.5)
			draw_circle(arm * spread, 2.0 + float(index % 2), color)
	else:
		draw_arc(Vector2.ZERO, 7.0 + progress * 20.0, 0.0, TAU, 24, color, 3.0)
		for index in range(6):
			var arm := Vector2.RIGHT.rotated(TAU * float(index) / 6.0)
			draw_line(arm * 5.0, arm * (12.0 + progress * 17.0), color, 2.5)
