extends Control

signal back_pressed

const UPGRADES_ORDER := ["max_hp", "damage", "xp_gain", "move", "armor", "luck", "magnet", "rerolls"]


func _ready() -> void:
	%BackButton.pressed.connect(_back)
	EventBus.currency_changed.connect(_on_currency_changed)
	_build_list()
	_refresh_currencies()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")


func _on_currency_changed(_k: String, _v: int) -> void:
	_refresh_currencies()


func _refresh_currencies() -> void:
	%CoinsLabel.text = "🪙 %d" % int(SaveSystem.get_value("coins", 0))


func _build_list() -> void:
	for child in %ItemsContainer.get_children():
		child.queue_free()
	for key in UPGRADES_ORDER:
		var info: Dictionary = ProgressionManager.PERMANENT_UPGRADES.get(key, {})
		if info.is_empty():
			continue
		%ItemsContainer.add_child(_make_row(key, info))


func _make_row(key: String, info: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.92)
	style.border_color = Color(0.275, 0.227, 0.412, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var info_vbox := VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var lbl := Label.new()
	lbl.text = String(info["label"])
	lbl.add_theme_color_override("font_color", Color(0.953, 0.929, 0.871))
	lbl.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(lbl)

	var level := ProgressionManager.upgrade_level(key)
	var max_level: int = int(info["max_level"])
	var status := Label.new()
	status.text = "Lv %d / %d" % [level, max_level]
	status.add_theme_color_override("font_color", Color(0.722, 0.694, 0.808))
	status.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(status)

	var buy_btn := Button.new()
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 0.776, 0.298, 1)
	btn_style.border_color = Color(0.435, 0.275, 0.063)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 3
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	btn_style.content_margin_left = 12
	btn_style.content_margin_top = 6
	btn_style.content_margin_right = 12
	btn_style.content_margin_bottom = 8
	buy_btn.add_theme_stylebox_override("normal", btn_style)
	buy_btn.add_theme_stylebox_override("hover", btn_style)
	buy_btn.add_theme_stylebox_override("pressed", btn_style)
	buy_btn.add_theme_color_override("font_color", Color(0.137, 0.094, 0.039))
	buy_btn.add_theme_font_size_override("font_size", 16)

	if level >= max_level:
		buy_btn.text = "MÁX"
		buy_btn.disabled = true
	else:
		var cost: int = ProgressionManager.upgrade_cost(key)
		buy_btn.text = "🪙 %d" % cost
		buy_btn.disabled = not ProgressionManager.can_buy_upgrade(key)
		buy_btn.pressed.connect(func(): _on_buy(key))

	hbox.add_child(buy_btn)
	return panel


func _on_buy(key: String) -> void:
	if ProgressionManager.buy_upgrade(key):
		_build_list()
