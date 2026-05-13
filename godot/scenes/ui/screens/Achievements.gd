extends Control

signal back_pressed


func _ready() -> void:
	%BackButton.pressed.connect(_back)
	_build()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")


func _build() -> void:
	for child in %Container.get_children():
		child.queue_free()
	var unlocked: Array = SaveSystem.get_value("achievements", [])
	var done: int = 0
	for key in UnlockManager.ACHIEVEMENTS.keys():
		var info: Dictionary = UnlockManager.ACHIEVEMENTS[key]
		var has: bool = unlocked.has(key)
		if has:
			done += 1
		%Container.add_child(_make_row(key, info, has))
	%CountLabel.text = "%d / %d" % [done, UnlockManager.ACHIEVEMENTS.size()]


func _make_row(key: String, info: Dictionary, has: bool) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.94) if has else Color(0.067, 0.055, 0.118, 0.7)
	style.border_color = Color(1, 0.776, 0.298) if has else Color(0.275, 0.227, 0.412)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var icon := Label.new()
	icon.text = "🏆" if has else "🔒"
	icon.add_theme_font_size_override("font_size", 28)
	hbox.add_child(icon)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = String(info["label"])
	name_lbl.add_theme_color_override("font_color", Color(1, 0.776, 0.298) if has else Color(0.722, 0.694, 0.808))
	name_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_lbl)

	var hint := Label.new()
	hint.text = String(info["hint"])
	hint.add_theme_color_override("font_color", Color(0.722, 0.694, 0.808))
	hint.add_theme_font_size_override("font_size", 12)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(hint)

	var reward_lbl := Label.new()
	reward_lbl.text = "+%d 🪙" % int(info["reward"])
	reward_lbl.add_theme_color_override("font_color", Color(1, 0.776, 0.298))
	reward_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(reward_lbl)

	return panel
