class_name TerrainCell
extends Area2D

signal drag_pressed(cell: TerrainCell)

enum TargetHighlight { NONE, LEGAL, INVALID }

@export var cell_color := Color(0.20, 0.26, 0.34, 1.0)
@export var border_color := Color(0.44, 0.72, 0.78, 1.0)
@export var preparing_color := Color(0.12, 0.48, 0.42, 1.0)

var cell_size := 64.0
var preparing := true
var draggable := false
var dragging := false
var drag_valid := false
var prepare_pulse := 0.0
var target_highlight := TargetHighlight.NONE
var hovered := false


func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	queue_redraw()


func configure_size(value: float) -> void:
	cell_size = value
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node != null:
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2.ONE * (cell_size - 4.0)
		shape_node.shape = rectangle
	queue_redraw()


func set_preparing(value: bool) -> void:
	preparing = value
	if not value:
		draggable = false
		dragging = false
	input_pickable = value and draggable
	queue_redraw()


func set_draggable(value: bool) -> void:
	draggable = preparing and value
	input_pickable = draggable
	queue_redraw()


func set_prepare_pulse(value: float) -> void:
	prepare_pulse = clampf(value, 0.0, 1.0)
	if preparing and draggable and not dragging:
		queue_redraw()


func set_drag_feedback(is_dragging: bool, is_valid: bool) -> void:
	dragging = is_dragging
	drag_valid = is_valid
	queue_redraw()


func set_target_highlight(value: TargetHighlight) -> void:
	target_highlight = value
	queue_redraw()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not preparing or not draggable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		drag_pressed.emit(self)
		get_viewport().set_input_as_handled()


func _on_mouse_entered() -> void:
	hovered = true
	queue_redraw()


func _on_mouse_exited() -> void:
	hovered = false
	queue_redraw()


func _draw() -> void:
	var half := cell_size * 0.5 - 2.0
	var fill := cell_color
	var outline := border_color
	var outline_width := 2.0
	if dragging:
		fill = Color(0.18, 0.64, 0.36, 1.0) if drag_valid else Color(0.66, 0.16, 0.18, 1.0)
		outline = Color(0.68, 1.0, 0.72, 1.0) if drag_valid else Color(1.0, 0.46, 0.42, 1.0)
		outline_width = 4.0
	elif preparing and target_highlight == TargetHighlight.LEGAL:
		fill = Color(0.16, 0.42, 0.31, 1.0)
		outline = Color(0.58, 1.0, 0.68, 1.0)
		outline_width = 4.0
	elif preparing and target_highlight == TargetHighlight.INVALID:
		fill = Color(0.48, 0.13, 0.15, 1.0)
		outline = Color(1.0, 0.42, 0.38, 1.0)
		outline_width = 4.0
	elif preparing and draggable:
		var brightness := lerpf(0.82, 1.18, prepare_pulse)
		fill = preparing_color * brightness
		fill.a = 1.0
		outline = Color(0.62, 1.0, 0.70, 1.0) if hovered else Color(0.52, 1.0, 0.82, lerpf(0.58, 1.0, prepare_pulse))
		outline_width = 4.5 if hovered else lerpf(2.0, 3.5, prepare_pulse)
	draw_rect(Rect2(Vector2(-half, -half), Vector2.ONE * half * 2.0), fill, true)
	draw_rect(Rect2(Vector2(-half, -half), Vector2.ONE * half * 2.0), outline, false, outline_width)


func is_draggable_now() -> bool:
	return preparing and draggable


func has_center_marker() -> bool:
	return false


func get_visual_state_name() -> String:
	if dragging:
		return "DRAG_VALID" if drag_valid else "DRAG_INVALID"
	if preparing and draggable:
		return "PREPARING_DRAGGABLE"
	return "NORMAL"
