class_name V02HUD
extends CanvasLayer

signal battle_start_requested
signal undo_requested
signal retry_requested
signal next_requested
signal main_menu_requested

@onready var phase_label: Label = $Root/TopBar/PhaseLabel
@onready var moves_label: Label = $Root/TopBar/MovesLabel
@onready var enemy_label: Label = $Root/TopBar/EnemyLabel
@onready var hint_label: Label = $Root/HintLabel
@onready var start_button: Button = $Root/StartButton
@onready var undo_button: Button = $Root/UndoButton
@onready var result_panel: Control = $Root/ResultPanel
@onready var result_label: Label = $Root/ResultPanel/ResultLabel
@onready var reason_label: Label = $Root/ResultPanel/ReasonLabel
@onready var primary_button: Button = $Root/ResultPanel/PrimaryButton
@onready var menu_button: Button = $Root/ResultPanel/MenuButton

func _ready() -> void:
	start_button.pressed.connect(func() -> void: battle_start_requested.emit())
	undo_button.pressed.connect(func() -> void: undo_requested.emit())
	primary_button.pressed.connect(_on_primary_pressed)
	menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	result_panel.visible = false

func show_preparing(remaining: int) -> void:
	phase_label.text = "战前调整"
	moves_label.text = "调整次数  %d" % remaining
	hint_label.text = "拖动发光地面或敌人到合法目标，然后开始战斗"
	start_button.visible = true
	start_button.disabled = false
	undo_button.visible = true
	undo_button.disabled = true
	hint_label.modulate = Color.WHITE
	result_panel.visible = false

func set_moves(remaining: int) -> void:
	moves_label.text = "调整次数  %d" % remaining


func set_undo_available(available: bool) -> void:
	undo_button.disabled = not available


func set_start_available(available: bool) -> void:
	start_button.disabled = not available


func set_enemy_count(count: int) -> void:
	enemy_label.text = "目标  %d" % count

func show_battle() -> void:
	phase_label.text = "战斗运行"
	moves_label.text = "一刀  1 / 1"
	hint_label.text = "WASD 塑造局面　左键瞄准　近弧 / 远直　右键取消"
	hint_label.modulate = Color.WHITE
	start_button.visible = false
	undo_button.visible = false

func show_aiming() -> void:
	phase_label.text = "瞄准中"
	hint_label.text = "松开提交唯一一刀　右键取消"

func show_executing() -> void:
	phase_label.text = "一刀已提交"
	moves_label.text = "一刀  0 / 1"
	hint_label.text = "伤害结算中"

func show_result(victory: bool, alive_count: int, final_level: bool) -> void:
	result_panel.visible = true
	start_button.visible = false
	undo_button.visible = false
	phase_label.text = "本关完成" if victory else "本关失败"
	result_label.text = "胜 利" if victory else "失 败"
	reason_label.text = "所有目标已斩落" if victory else ("仍有 %d 个目标存活" % alive_count if alive_count > 0 else "狐狸受到致命伤害")
	hint_label.text = "选择下一步"
	hint_label.modulate = Color.WHITE
	primary_button.set_meta("action", "next" if victory else "retry")
	primary_button.text = ("完成旅程" if final_level else "进入下一关") if victory else "重试当前关"
	primary_button.grab_focus()

func set_drag_message(message: String, valid: bool) -> void:
	hint_label.text = message
	hint_label.modulate = Color(0.64, 1.0, 0.72) if valid else Color(1.0, 0.76, 0.62)

func _on_primary_pressed() -> void:
	if primary_button.get_meta("action", "retry") == "next":
		next_requested.emit()
	else:
		retry_requested.emit()
