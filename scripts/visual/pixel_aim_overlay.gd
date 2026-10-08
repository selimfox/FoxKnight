extends Node2D

# Draws the approved range marks on the same two-world-pixel grid as the art.
# Geometry comes from the game and this node has no gameplay input.
const PIXEL := 2.0
const ARC_EDGE := Color(0.90, 0.68, 0.40, 0.96)
const STRAIGHT_EDGE := Color(0.50, 0.83, 0.87, 0.92)
const AXIS := Color(0.40, 0.70, 0.76, 0.34)

var _mode := "NONE"
var _radius := 0.0
var _distance := 0.0
var _width := 0.0
var _direction := Vector2.RIGHT
var _boundary_radius := 0.0
var _boundary_alpha := 0.0
var _flash_alpha := 0.0
var _flash_color := ARC_EDGE


func set_boundary(radius: float, alpha: float, flash_alpha: float, flash_color: Color) -> void:
	_boundary_radius = radius
	_boundary_alpha = alpha
	_flash_alpha = flash_alpha
	_flash_color = flash_color
	queue_redraw()


func show_arc(radius: float) -> void:
	_mode = "ARC"
	_radius = maxf(radius, 0.0)
	visible = true
	queue_redraw()


func show_straight(direction: Vector2, distance: float, width: float) -> void:
	_mode = "STRAIGHT"
	_direction = direction.normalized()
	_distance = maxf(distance, 0.0)
	_width = maxf(width, 0.0)
	visible = true
	queue_redraw()


func clear() -> void:
	_mode = "NONE"
	visible = false
	queue_redraw()


func _draw() -> void:
	if _mode == "ARC":
		_draw_arc_pixels()
	elif _mode == "STRAIGHT" and _direction != Vector2.ZERO:
		_draw_straight_pixels()
		_draw_circle_pixels(_boundary_radius, Color(ARC_EDGE, _boundary_alpha))
	if _mode != "NONE" and _flash_alpha > 0.0:
		_draw_circle_pixels(_boundary_radius, Color(_flash_color, _flash_alpha))


func _grid_offset() -> Vector2:
	return Vector2(roundf(global_position.x / PIXEL) * PIXEL - global_position.x, roundf(global_position.y / PIXEL) * PIXEL - global_position.y)


func _pixel(center: Vector2, color: Color) -> void:
	draw_rect(Rect2(center - Vector2.ONE, Vector2.ONE * PIXEL), color)


func _draw_arc_pixels() -> void:
	_draw_circle_pixels(_radius, ARC_EDGE)


func _draw_circle_pixels(radius: float, color: Color) -> void:
	var offset := _grid_offset()
	var cells := ceili(radius / PIXEL)
	var outer_squared := maxf(radius - PIXEL, 0.0) ** 2
	var inner_squared := maxf(radius - PIXEL * 2.0, 0.0) ** 2
	for cy in range(-cells, cells + 1):
		for cx in range(-cells, cells + 1):
			var center := offset + Vector2(float(cx) * PIXEL, float(cy) * PIXEL)
			var squared := center.length_squared()
			if squared <= outer_squared and squared >= inner_squared:
				_pixel(center, color)


func _draw_straight_pixels() -> void:
	var offset := _grid_offset()
	var half_width := _width * 0.5
	var side := _direction.orthogonal() * half_width
	var end := _direction * _distance
	var corners := [side, -side, end + side, end - side]
	var min_x := 0.0
	var max_x := 0.0
	var min_y := 0.0
	var max_y := 0.0
	for corner in corners:
		min_x = minf(min_x, corner.x)
		max_x = maxf(max_x, corner.x)
		min_y = minf(min_y, corner.y)
		max_y = maxf(max_y, corner.y)
	for cy in range(floori(min_y / PIXEL) - 1, ceili(max_y / PIXEL) + 2):
		for cx in range(floori(min_x / PIXEL) - 1, ceili(max_x / PIXEL) + 2):
			var center := offset + Vector2(float(cx) * PIXEL, float(cy) * PIXEL)
			var along := center.dot(_direction)
			var across := center.dot(_direction.orthogonal())
			# Inset one cell so each colored square stays inside the queried shape.
			if along < PIXEL or along > _distance - PIXEL or absf(across) > half_width - PIXEL:
				continue
			var edge := absf(across) >= half_width - PIXEL * 2.0 or along >= _distance - PIXEL * 2.0 or along <= PIXEL * 2.0
			if edge:
				_pixel(center, STRAIGHT_EDGE)
			elif absf(across) < PIXEL:
				_pixel(center, AXIS)
	# A small in-range chevron gives direction without a second endpoint.
	var mark := minf(28.0, _distance * 0.5)
	if mark >= 8.0:
		for step in range(4):
			for sign in [-1.0, 1.0]:
				var point: Vector2 = _direction * (mark - float(step) * PIXEL) + _direction.orthogonal() * float(sign) * float(step) * PIXEL
				var snapped := Vector2(roundf((point.x - offset.x) / PIXEL), roundf((point.y - offset.y) / PIXEL)) * PIXEL + offset
				if snapped.dot(_direction) <= _distance - PIXEL and absf(snapped.dot(_direction.orthogonal())) <= half_width - PIXEL:
					_pixel(snapped, STRAIGHT_EDGE)
