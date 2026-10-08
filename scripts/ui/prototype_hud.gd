class_name PrototypeHUD
extends CanvasLayer

signal retry_requested
signal next_requested
signal menu_requested

@onready var _attack_label: Label = $Root/TopBar/AttackCountLabel
@onready var _enemy_label: Label = $Root/TopBar/EnemyCountLabel
@onready var _top_bar: Panel = $Root/TopBar
@onready var _attack_digits: PixelCounter = $Root/TopBar/AttackDigits
@onready var _enemy_digits: PixelCounter = $Root/TopBar/EnemyDigits
@onready var _form_badge: Panel = $Root/FormBadge
@onready var _form_glyph: Control = $Root/FormBadge/FormGlyph
@onready var _form_label: Label = $Root/FormBadge/FormLabel
@onready var _hint_label: Label = $Root/HintLabel
@onready var _hint_ribbon: TextureRect = $Root/HintRibbon
@onready var _rule_ribbon: TextureRect = $Root/RuleRibbon
@onready var _rule_label: Label = $Root/RuleLabel
@onready var _level_notice: Label = $Root/LevelNotice
@onready var _debug_state_label: Label = $Root/DebugStateLabel
@onready var _result_panel: Panel = $Root/ResultPanel
@onready var _result_label: Label = $Root/ResultPanel/ResultLabel
@onready var _result_art: TextureRect = $Root/ResultPanel/ResultTitleArt
@onready var _reason_label: Label = $Root/ResultPanel/ReasonLabel
@onready var _retry_button: Button = $Root/ResultPanel/RetryButton
@onready var _next_button: Button = $Root/ResultPanel/NextButton
@onready var _menu_button: Button = $Root/ResultPanel/MenuButton

var _hint_generation := 0
var _observing_hint_shown := false
var _level_notice_generation := 0
var _result_children_rects: Dictionary = {}
var _split_panels: Array[Panel] = []
var _survivor_rects: Array[Rect2] = []


func _ready() -> void:
	_retry_button.pressed.connect(func() -> void: retry_requested.emit())
	_next_button.pressed.connect(func() -> void: next_requested.emit())
	_menu_button.pressed.connect(func() -> void: menu_requested.emit())
	_result_panel.visible = false
	_result_label.visible = _result_art.texture == null
	for child in _result_panel.get_children():
		if child is Control:
			_result_children_rects[child] = Rect2(child.position, child.size)


func set_attack_count(count: int) -> void:
	_attack_label.text = str(count)
	_attack_digits.value = count


func set_enemy_count(count: int) -> void:
	_enemy_label.text = str(count)
	_enemy_digits.value = count
	# Grow only when necessary; avoid a panel that pulses smaller as enemies die.
	_top_bar.offset_right = maxf(_top_bar.offset_right, 24.0 + 152.0 + str(maxi(count, 0)).length() * 28.0 + 12.0)


func set_round_state(state_name: String, show_debug: bool) -> void:
	_debug_state_label.visible = show_debug
	_debug_state_label.text = "STATE  %s" % state_name


func set_observing_hint() -> void:
	_form_badge.visible = false
	if _observing_hint_shown:
		_hide_hint()
		return
	_observing_hint_shown = true
	_rule_ribbon.visible = true
	_rule_label.visible = true
	_show_hint("WASD 移动  ·  按住左键瞄准", 4.0)


func set_aiming_hint() -> void:
	_rule_ribbon.visible = false
	_rule_label.visible = false
	_show_hint("松开出刀  ·  右键取消", 3.5)


func show_level_notice(number: int) -> void:
	_level_notice_generation += 1
	var generation := _level_notice_generation
	_level_notice.text = "关卡 %d" % number
	_level_notice.modulate = Color.WHITE
	_level_notice.visible = true
	var tween := create_tween()
	tween.tween_interval(0.25)
	tween.tween_property(_level_notice, "modulate:a", 0.0, 0.35)
	await tween.finished
	if is_inside_tree() and generation == _level_notice_generation:
		_level_notice.visible = false


func set_aim_form(arc_mode: bool) -> void:
	_form_badge.visible = true
	_form_glyph.set("arc_mode", arc_mode)
	_form_label.text = "弧形斩 · 原地" if arc_mode else "冲撞斩 · 位移"
	_form_label.add_theme_color_override("font_color", Color(0.90, 0.68, 0.40) if arc_mode else Color(0.50, 0.83, 0.87))


func set_executing_hint() -> void:
	_form_badge.visible = false
	_hide_hint()


func _show_hint(message: String, seconds: float) -> void:
	_hint_generation += 1
	var generation := _hint_generation
	_hint_label.text = message
	_hint_label.visible = true
	_hint_ribbon.visible = true
	await get_tree().create_timer(seconds).timeout
	if is_inside_tree() and generation == _hint_generation and not _result_panel.visible:
		_hide_hint()


func _hide_hint() -> void:
	_hint_generation += 1
	_hint_label.visible = false
	_hint_ribbon.visible = false
	_rule_label.visible = false
	_rule_ribbon.visible = false


func show_result(victory: bool, alive_count: int, in_campaign: bool = false, final_level: bool = false, survivor_positions: Array[Vector2] = [], survivor_rects: Array[Rect2] = []) -> void:
	_restore_result_blocks()
	_survivor_rects = survivor_rects.duplicate()
	if _survivor_rects.is_empty():
		for foot in survivor_positions:
			_survivor_rects.append(Rect2(foot - Vector2(40, 80), Vector2(80, 88)).grow(8.0))
	_form_badge.visible = false
	_result_panel.visible = true
	_result_label.text = "胜 利" if victory else "失 败"
	_result_label.modulate = Color(1.0, 0.86, 0.35) if victory else Color(1.0, 0.42, 0.35)
	_result_art.texture = preload("res://assets/art/production/ui/r3_20260930/export/victory_lettering.png") if victory else preload("res://assets/art/production/ui/r3_20260930/export/failure_lettering.png")
	_result_art.visible = _result_art.texture != null
	_result_label.visible = not _result_art.visible
	_reason_label.text = "所有目标已斩落" if victory else "仍有 %d 个目标存活" % alive_count
	_next_button.visible = victory and in_campaign
	_next_button.text = "返回主界面" if final_level else "下一关"
	_menu_button.visible = in_campaign and not (victory and final_level)
	_layout_result_buttons(victory and in_campaign, final_level)
	_place_result_away_from(survivor_positions)
	_hide_hint()
	if _next_button.visible:
		_next_button.grab_focus()
	else:
		_retry_button.grab_focus()


func _place_result_away_from(_survivors: Array[Vector2]) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var left := (viewport_size.x - 660.0) * 0.5
	var bottom := Rect2(left, viewport_size.y - 156.0, 660.0, 146.0)
	var top := Rect2(left, 10.0, 660.0, 146.0)
	var bottom_hits := 0
	var top_hits := 0
	for actor_rect in _survivor_rects:
		bottom_hits += int(bottom.intersects(actor_rect))
		top_hits += int(top.intersects(actor_rect))
	var chosen := top if top_hits < bottom_hits else bottom
	if mini(top_hits, bottom_hits) > 0:
		_split_result_blocks(viewport_size)
		return
	_result_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_result_panel.position = chosen.position.round()
	_result_panel.size = chosen.size


func _restore_result_blocks() -> void:
	for child in _result_children_rects:
		if child.get_parent() != _result_panel:
			child.reparent(_result_panel, false)
		var rect: Rect2 = _result_children_rects[child]
		child.position = rect.position
		child.size = rect.size
	for panel in _split_panels:
		panel.queue_free()
	_split_panels.clear()
	_result_panel.self_modulate = Color.WHITE
	_result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_panel.get_node("ResultDivider").visible = true


func _split_result_blocks(viewport_size: Vector2) -> void:
	_result_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_result_panel.position = Vector2.ZERO
	_result_panel.size = viewport_size
	_result_panel.self_modulate.a = 0.0
	_result_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var actions: Array[Button] = []
	for button in [_retry_button, _next_button, _menu_button]:
		if button.visible:
			actions.append(button)
	var sizes := [Vector2(224, 146), Vector2(194, 12 + actions.size() * 62)]
	var occupied := _survivor_rects.duplicate()
	occupied.append(_top_bar.get_global_rect().grow(8.0))
	for index in range(2):
		var location := _find_clear_block(sizes[index], occupied, viewport_size, index == 1)
		var panel := Panel.new()
		panel.name = "ResultOutcomeBlock" if index == 0 else "ResultActionsBlock"
		panel.add_theme_stylebox_override("panel", _result_panel.get_theme_stylebox("panel"))
		_result_panel.add_child(panel)
		panel.position = location
		panel.size = sizes[index]
		_split_panels.append(panel)
		occupied.append(Rect2(location, sizes[index]).grow(8.0))
		if index == 0:
			for child in [_result_label, _result_art, _reason_label, _result_panel.get_node("ResultDivider")]:
				child.reparent(panel, false)
			panel.get_node("ResultDivider").visible = false
			_result_art.position.x = 24.0
			_reason_label.position.x = 10.0
			_reason_label.size.x = 204.0
		else:
			for action_index in actions.size():
				var button := actions[action_index]
				button.reparent(panel, false)
				button.position = Vector2(10, 8 + action_index * 62)
				button.size = Vector2(174, 54)
	_result_panel.get_node_or_null("ResultMotion").visible = false


func _find_clear_block(block_size: Vector2, occupied: Array, viewport_size: Vector2, prefer_right: bool) -> Vector2:
	# Search edge corners first, then all legal cells. Never choose an overlap.
	var x_values: Array = [viewport_size.x - block_size.x - 10.0, 10.0] if prefer_right else [10.0, viewport_size.x - block_size.x - 10.0]
	var y_values: Array = [viewport_size.y - block_size.y - 10.0, 10.0]
	for x in range(10, int(viewport_size.x - block_size.x - 9), 2):
		x_values.append(float(x))
	for y in range(10, int(viewport_size.y - block_size.y - 9), 2):
		y_values.append(float(y))
	for y in y_values:
		for x in x_values:
			var candidate := Rect2(Vector2(x, y), block_size)
			var clear := true
			for rect in occupied:
				if candidate.intersects(rect):
					clear = false
					break
			if clear:
				return candidate.position
	# Authored three-level counts leave room. Report unsupported overcrowding.
	push_error("No clear result block placement for this authored scene")
	return Vector2(-block_size.x, -block_size.y)


func _layout_result_buttons(has_next: bool, final_level: bool) -> void:
	# Keep each existing branch and focus target; reflow only the visible controls.
	var actions: Array[Button] = [_retry_button]
	var widths: Array[float] = [166.0]
	if has_next:
		actions.append(_next_button)
		widths.append(140.0 if final_level else 114.0)
	if _menu_button.visible:
		actions.append(_menu_button)
		widths.append(92.0)
	var total_width := 8.0 * (actions.size() - 1)
	for width in widths:
		total_width += width
	# Keep the middle of the battlefield clear: actions occupy the right side of
	# the shallow bottom result strip, while outcome and cause remain on the left.
	var left := 230.0 + roundf((420.0 - total_width) / 2.0)
	for index in actions.size():
		actions[index].offset_left = left
		actions[index].offset_right = left + widths[index]
		actions[index].offset_top = 50.0
		actions[index].offset_bottom = 105.0
		left += widths[index] + 8.0
