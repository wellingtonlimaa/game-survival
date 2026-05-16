extends Control

signal back_pressed


func _ready() -> void:
	%BackButton.pressed.connect(_back)
	_build()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")


func _build() -> void:
	for child in %CharsGrid.get_children():
		child.queue_free()
	for c in CharacterRegistry.all_in_order():
		%CharsGrid.add_child(_make_card(c))


func _make_card(c: Resource) -> Control:
	var unlocked: bool = CharacterRegistry.is_unlocked(c.key)
	var selected: bool = String(SaveSystem.get_value("selected_character", "hunter")) == c.key

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.94)
	style.border_color = Color(1.0, 0.776, 0.298) if selected else Color(0.275, 0.227, 0.412)
	style.border_width_left = 3 if selected else 2
	style.border_width_top = 3 if selected else 2
	style.border_width_right = 3 if selected else 2
	style.border_width_bottom = 5 if selected else 3
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	# Avatar (cor do char como ColorRect)
	var avatar := ColorRect.new()
	avatar.color = c.body_color if unlocked else Color(0.275, 0.227, 0.412)
	avatar.custom_minimum_size = Vector2(80, 100)
	avatar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(avatar)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = c.display_name if unlocked else "???"
	name_lbl.add_theme_color_override("font_color", Color(0.953, 0.929, 0.871) if unlocked else Color(0.514, 0.486, 0.616))
	name_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_lbl)

	var desc := Label.new()
	desc.text = c.description if unlocked else c.unlock_hint
	desc.add_theme_color_override("font_color", Color(0.722, 0.694, 0.808))
	desc.add_theme_font_size_override("font_size", 13)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var action_btn := Button.new()
	action_btn.add_theme_font_size_override("font_size", 14)
	var btn_style := StyleBoxFlat.new()
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.content_margin_left = 10
	btn_style.content_margin_top = 4
	btn_style.content_margin_right = 10
	btn_style.content_margin_bottom = 6
	if unlocked:
		if selected:
			action_btn.text = "EQUIPADO"
			btn_style.bg_color = Color(0.439, 0.871, 0.494, 1)
			action_btn.disabled = true
			action_btn.add_theme_color_override("font_color", Color(0.043, 0.137, 0.063))
		else:
			action_btn.text = "Selecionar"
			btn_style.bg_color = Color(1, 0.776, 0.298, 1)
			action_btn.add_theme_color_override("font_color", Color(0.137, 0.094, 0.039))
			action_btn.pressed.connect(func(): _select(c.key))
	else:
		action_btn.text = "🔒 Bloqueado"
		btn_style.bg_color = Color(0.196, 0.165, 0.235, 1)
		action_btn.disabled = true
		action_btn.add_theme_color_override("font_color", Color(0.514, 0.486, 0.616))
	action_btn.add_theme_stylebox_override("normal", btn_style)
	action_btn.add_theme_stylebox_override("hover", btn_style)
	action_btn.add_theme_stylebox_override("pressed", btn_style)
	action_btn.add_theme_stylebox_override("disabled", btn_style)
	vbox.add_child(action_btn)

	return panel


func _select(key: String) -> void:
	CharacterRegistry.select(key)
	_build()
