extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var campaign: Node = load("res://scenes/prototype/campaign.tscn").instantiate()
	root.add_child(campaign)
	for frame in 3:
		await process_frame
	var menu := campaign.get_node("MenuLayer/Menu") as Control
	var base := menu.get_node("MenuBase") as TextureRect
	var ornaments := menu.get_node("MenuOrnaments") as TextureRect
	var wordmark := menu.get_node("TitleArt") as TextureRect
	var crest := menu.get_node("FoxCrest") as TextureRect
	var menu_motion := menu.get_node("TitleMotion") as TitleMotion
	_check(base.texture.get_size() == Vector2(960, 540), "UI-MENU: background keeps native 960x540 size")
	_check(base.size == Vector2(960, 540) and ornaments.size == Vector2(960, 540), "UI-MENU: textures stay fixed rather than stretching on wider displays")
	_check(menu.get_node("Background").size == menu.size, "UI-MENU: backdrop fills the expanded viewport")
	_check(base.mouse_filter == Control.MOUSE_FILTER_IGNORE and ornaments.mouse_filter == Control.MOUSE_FILTER_IGNORE, "UI-MENU: art does not intercept buttons")
	_check(base.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "UI-MENU: nearest-neighbor background")
	_check(wordmark.texture != null and wordmark.size == Vector2(368, 80), "UI-TITLE: original-size title lettering is present")
	_check(crest.texture != null and crest.size == Vector2(96, 96), "UI-TITLE: fox crest uses original-size asset")
	_check(not (menu.get_node("Title") as Label).visible, "UI-TITLE: plain title label is hidden while art is available")
	_check(menu_motion.mouse_filter == Control.MOUSE_FILTER_IGNORE, "UI-TITLE: focus and glint never intercept menu input")
	for button_name in ["StartButton", "Level1Button", "Level2Button", "Level3Button"]:
		_check_button(menu.get_node(button_name) as Button, button_name)
	_capture("res://output/ui_production_menu.png")
	DisplayServer.window_set_size(Vector2i(1280, 540))
	for frame in 5:
		await process_frame
	_check(base.size == Vector2(960, 540), "UI-MENU: wide display retains 1:1 art")
	_check(menu.get_node("Background").size == menu.size, "UI-MENU: wide display fills sidebars")
	_check(wordmark.global_position.x == base.global_position.x + 296.0, "UI-TITLE: wide display keeps title centered on the fixed art")
	_capture("res://output/ui_production_menu_wide.png")
	DisplayServer.window_set_size(Vector2i(960, 540))
	for frame in 3:
		await process_frame
	(menu.get_node("StartButton") as Button).grab_focus()
	for frame in 5:
		await process_frame
	_capture("res://output/ui_production_menu_focus.png")

	campaign.queue_free()
	await process_frame
	for index in [1, 2, 3]:
		var level: Node = load("res://scenes/prototype/levels/level_0%d.tscn" % index).instantiate()
		root.add_child(level)
		for frame in 3:
			await process_frame
		var hud := level.get_node("HUD") as PrototypeHUD
		var top := hud.get_node("Root/TopBar") as Panel
		var result := hud.get_node("Root/ResultPanel") as Panel
		_check(top.get_theme_stylebox("panel") is StyleBoxTexture, "UI-HUD: level %d uses nine-slice top panel" % index)
		_check(result.get_theme_stylebox("panel") is StyleBoxTexture, "UI-HUD: level %d uses nine-slice result panel" % index)
		_check(hud.get_node("Root/HintRibbon").texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "UI-HUD: level %d hint uses nearest filtering" % index)
		hud.set_attack_count(0)
		hud.set_enemy_count(2)
		_check(hud.get_node("Root/TopBar/AttackCountLabel").text == "0", "UI-HUD: attack count remains live without debug-like copy")
		_check(hud.get_node("Root/TopBar/EnemyCountLabel").text == "2", "UI-HUD: target count remains live without debug-like copy")
		hud.set_enemy_count(123)
		_check(hud.get_node("Root/TopBar/EnemyDigits").value == 123 and top.size.x >= 248.0, "UI-HUD: pixel counter stays readable for three-digit target counts")
		hud.set_enemy_count(2)
		hud.set_observing_hint()
		_check("左键瞄准" in hud.get_node("Root/HintLabel").text, "UI-HUD: first observing hint remains")
		hud.set_aiming_hint()
		_check("右键取消" in hud.get_node("Root/HintLabel").text, "UI-HUD: aiming hint remains")
		hud.set_executing_hint()
		_check(not hud.get_node("Root/HintLabel").visible, "UI-HUD: committed action clears instruction copy")
		hud.set_observing_hint()
		await process_frame
		_capture("res://output/ui_production_level_0%d.png" % index)
		hud.show_result(false, 2, true, false)
		await process_frame
		_check(hud.get_node("Root/ResultPanel/ReasonLabel").text == "仍有 2 个目标存活", "UI-RESULT: failure reason remains truthful")
		_check((hud.get_node("Root/ResultPanel/ResultTitleArt") as TextureRect).texture.resource_path.ends_with("failure_lettering.png"), "UI-TITLE: failure lettering matches result truth")
		_check(not (hud.get_node("Root/ResultPanel/ResultLabel") as Label).visible, "UI-TITLE: result label remains an unobscured text fallback")
		_check(result.global_position.y >= 360.0, "UI-RESULT: failure leaves the battlefield center visible")
		_check(not hud.get_node("Root/HintRibbon").visible, "UI-RESULT: result hides the overlapping hint ribbon")
		_check(not hud.get_node("Root/ResultPanel/NextButton").visible, "UI-RESULT: failure hides next action")
		_capture("res://output/ui_production_failure_0%d.png" % index)
		hud.show_result(true, 0, true, index == 3)
		await process_frame
		_check(hud.get_node("Root/ResultPanel/NextButton").visible, "UI-RESULT: victory shows campaign action")
		_check(hud.get_node("Root/ResultPanel/NextButton").text == ("返回主界面" if index == 3 else "下一关"), "UI-RESULT: correct campaign branch")
		_check((hud.get_node("Root/ResultPanel/ResultTitleArt") as TextureRect).texture.resource_path.ends_with("victory_lettering.png"), "UI-TITLE: victory lettering matches result truth")
		for button_name in ["RetryButton", "NextButton", "MenuButton"]:
			_check_button(hud.get_node("Root/ResultPanel/%s" % button_name) as Button, button_name)
		_capture("res://output/ui_production_victory_0%d.png" % index)
		level.queue_free()
		await process_frame
	if _failures.is_empty():
		print("RESULT | PASS | Production UI visual and truth checks")
		quit(0)
	else:
		print("RESULT | FAIL | %d production UI checks" % _failures.size())
		quit(1)


func _check_button(button: Button, label: String) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := button.get_theme_stylebox(state) as StyleBoxTexture
		_check(style != null and style.texture is AtlasTexture, "UI-BUTTON: %s has %s art" % [label, state])
		if style != null:
			_check(style.texture_margin_left == 6.0 and style.texture_margin_top == 6.0, "UI-BUTTON: %s %s uses integer 6px border" % [label, state])


func _capture(path: String) -> void:
	var image := root.get_viewport().get_texture().get_image()
	if image == null:
		_check(false, "UI-CAPTURE: renderer did not provide image for %s" % path)
		return
	var error := image.save_png(path)
	_check(error == OK, "UI-CAPTURE: %s" % path)


func _check(ok: bool, label: String) -> void:
	if ok:
		print("PASS | ", label)
	else:
		_failures.append(label)
		push_error("FAIL | " + label)
