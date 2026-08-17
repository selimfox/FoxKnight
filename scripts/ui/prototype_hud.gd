class_name PrototypeHUD
extends CanvasLayer

signal retry_requested

@onready var _attack_label: Label = $Root/TopBar/AttackCountLabel
@onready var _enemy_label: Label = $Root/TopBar/EnemyCountLabel
@onready var _hint_label: Label = $Root/HintLabel
@onready var _debug_state_label: Label = $Root/DebugStateLabel
@onready var _result_panel: Panel = $Root/ResultPanel
@onready var _result_label: Label = $Root/ResultPanel/ResultLabel
@onready var _reason_label: Label = $Root/ResultPanel/ReasonLabel
@onready var _retry_button: Button = $Root/ResultPanel/RetryButton


func _ready() -> void:
	_retry_button.pressed.connect(func() -> void: retry_requested.emit())
	_result_panel.visible = false


func set_attack_count(count: int) -> void:
	_attack_label.text = "一刀  %d / 1" % count


func set_enemy_count(count: int) -> void:
	_enemy_label.text = "目标  %d" % count


func set_round_state(state_name: String, show_debug: bool) -> void:
	_debug_state_label.visible = show_debug
	_debug_state_label.text = "STATE  %s" % state_name


func set_observing_hint() -> void:
	_hint_label.text = "WASD 移动    左键瞄准    近弧 / 远直"


func set_aiming_hint() -> void:
	_hint_label.text = "近距弧斩    远距直斩    松开出刀    右键取消"


func set_executing_hint() -> void:
	_hint_label.text = "选择已锁定——见证这一刀"


func show_result(victory: bool, alive_count: int) -> void:
	_result_panel.visible = true
	_result_label.text = "胜 利" if victory else "失 败"
	_result_label.modulate = Color(1.0, 0.86, 0.35) if victory else Color(1.0, 0.42, 0.35)
	_reason_label.text = "所有目标已斩落" if victory else "仍有 %d 个目标存活" % alive_count
	_hint_label.text = "R 或按钮立即重试"
	_retry_button.grab_focus()
