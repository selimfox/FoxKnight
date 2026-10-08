class_name CampaignController
extends Node2D

const LEVEL_SCENES = [
	preload("res://scenes/prototype/levels/level_01.tscn"),
	preload("res://scenes/prototype/levels/level_02.tscn"),
	preload("res://scenes/prototype/levels/level_03.tscn"),
]

var _current_level: PrototypeLevel
var _current_index := -1

@onready var _level_host: Node2D = $LevelHost
@onready var _menu: Control = $MenuLayer/Menu
@onready var _title_art: TextureRect = $MenuLayer/Menu/TitleArt
@onready var _title_text: Label = $MenuLayer/Menu/Title
@onready var _menu_motion: TitleMotion = $MenuLayer/Menu/TitleMotion


func _ready() -> void:
	_title_art.visible = _title_art.texture != null
	_title_text.visible = not _title_art.visible
	$MenuLayer/Menu/StartButton.pressed.connect(func() -> void: _load_level.call_deferred(0))
	$MenuLayer/Menu/Level1Button.pressed.connect(func() -> void: _load_level.call_deferred(0))
	$MenuLayer/Menu/Level2Button.pressed.connect(func() -> void: _load_level.call_deferred(1))
	$MenuLayer/Menu/Level3Button.pressed.connect(func() -> void: _load_level.call_deferred(2))
	_show_menu()


func _load_level(index: int) -> void:
	if index < 0 or index >= LEVEL_SCENES.size():
		return
	_clear_level()
	_current_index = index
	_current_level = LEVEL_SCENES[index].instantiate() as PrototypeLevel
	_current_level.campaign_mode = true
	_current_level.is_final_level = index == LEVEL_SCENES.size() - 1
	_current_level.retry_requested.connect(func() -> void: _load_level.call_deferred(index))
	_current_level.next_requested.connect(func() -> void: _next_level.call_deferred())
	_current_level.menu_requested.connect(func() -> void: _show_menu.call_deferred())
	_level_host.add_child(_current_level)
	_menu.visible = false
	(_current_level.get_node("HUD") as PrototypeHUD).show_level_notice(index + 1)


func _next_level() -> void:
	if _current_index + 1 >= LEVEL_SCENES.size():
		_show_menu()
	else:
		_load_level(_current_index + 1)


func _show_menu() -> void:
	_clear_level()
	_current_index = -1
	_menu.visible = true
	_menu_motion.play_open_glint()
	$MenuLayer/Menu/StartButton.grab_focus()


func _clear_level() -> void:
	if is_instance_valid(_current_level):
		_level_host.remove_child(_current_level)
		_current_level.queue_free()
	_current_level = null
