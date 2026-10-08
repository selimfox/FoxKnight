extends Control

const WARM := Color(0.90, 0.68, 0.40)
const COOL := Color(0.50, 0.83, 0.87)

var arc_mode := true:
	set(value):
		arc_mode = value
		queue_redraw()


func _draw() -> void:
	var color := WARM if arc_mode else COOL
	if arc_mode:
		for y in range(2, 15):
			for x in range(2, 15):
				var squared := Vector2(x - 8, y - 8).length_squared()
				if squared >= 25.0 and squared <= 36.0:
					draw_rect(Rect2(x * 2, y * 2, 2, 2), color)
	else:
		for x in range(2, 14):
			draw_rect(Rect2(x * 2, 16, 2, 2), color)
		for step in 4:
			draw_rect(Rect2((10 + step) * 2, (5 + step) * 2, 2, 2), color)
			draw_rect(Rect2((10 + step) * 2, (11 - step) * 2, 2, 2), color)
