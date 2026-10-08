class_name PixelCounter
extends Control

@export var digits_atlas: Texture2D
@export var tint: Color = Color.WHITE
@export_range(1, 20, 1) var digit_width := 12
@export_range(1, 30, 1) var digit_height := 18
@export_range(0, 10, 1) var spacing := 2
@export_range(1, 3, 1) var display_scale := 2

var value := 0:
	set(number):
		value = maxi(number, 0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()


func _draw() -> void:
	if digits_atlas == null:
		return
	var number_text := str(value)
	for index in number_text.length():
		var digit := number_text.unicode_at(index) - 48
		if digit < 0 or digit > 9:
			continue
		var source := Rect2(digit * digit_width, 0, digit_width, digit_height)
		var destination := Rect2(index * (digit_width + spacing) * display_scale, 0, digit_width * display_scale, digit_height * display_scale)
		draw_texture_rect_region(digits_atlas, destination, source, tint)
