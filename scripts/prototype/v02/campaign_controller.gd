class_name CampaignController
extends Node

@export var levels: Array[PackedScene] = []

var current_level_index := 0
var current_level: V02LevelController

@onready var level_host: Node = $LevelHost
@onready var main_menu: Control = $UI/MainMenu
@onready var campaign_result: Control = $UI/CampaignResult

func _ready() -> void:
	$UI/MainMenu/StartButton.pressed.connect(start_campaign)
	$UI/CampaignResult/MenuButton.pressed.connect(return_to_main_menu)
	show_main_menu()

func start_campaign() -> void:
	if levels.is_empty():
		push_error("Campaign has no configured levels")
		return
	current_level_index = 0
	main_menu.visible = false
	campaign_result.visible = false
	_load_current_level()

func _load_current_level() -> void:
	_clear_level()
	current_level = levels[current_level_index].instantiate() as V02LevelController
	level_host.add_child(current_level)
	current_level.set_campaign_context(current_level_index, levels.size())
	current_level.level_won.connect(_on_level_won)
	current_level.retry_requested.connect(retry_current_level)
	current_level.main_menu_requested.connect(return_to_main_menu)

func retry_current_level() -> void:
	if current_level != null:
		_load_current_level()

func _on_level_won() -> void:
	if current_level_index + 1 < levels.size():
		current_level_index += 1
		_load_current_level()
	else:
		_clear_level()
		campaign_result.visible = true

func return_to_main_menu() -> void:
	_clear_level()
	current_level_index = 0
	show_main_menu()

func show_main_menu() -> void:
	main_menu.visible = true
	campaign_result.visible = false

func _clear_level() -> void:
	if is_instance_valid(current_level):
		current_level.queue_free()
	current_level = null
	for child: Node in level_host.get_children():
		child.queue_free()

func get_campaign_state() -> String:
	if main_menu.visible:
		return "MAIN_MENU"
	if campaign_result.visible:
		return "CAMPAIGN_WON"
	return "PLAYING"
