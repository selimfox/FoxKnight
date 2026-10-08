class_name TitleMotion
extends Control

# Compatibility: approved focus corners are supplied by the shared Theme.
@export var focus_buttons: Array[NodePath] = []
@export var show_open_glint := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func play_open_glint() -> void:
	pass
