extends PanelContainer

@onready var row: HBoxContainer = %Row

var weapon_system: Node = null


func _ready() -> void:
	EventBus.weapon_picked.connect(_refresh)
	EventBus.weapon_evolved.connect(_refresh)


func bind_weapons(p_weapon_system: Node) -> void:
	weapon_system = p_weapon_system
	_refresh("", 0, "")


func _refresh(_a = "", _b = 0, _c = "") -> void:
	if weapon_system == null:
		return
	for child in row.get_children():
		child.queue_free()
	for slot in weapon_system.slots:
		var chip := _make_chip(slot)
		row.add_child(chip)


func _make_chip(slot) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(56, 56)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.9)
	style.border_color = slot.data.icon_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var color_box := ColorRect.new()
	color_box.color = slot.data.icon_color
	color_box.custom_minimum_size = Vector2(0, 22)
	vbox.add_child(color_box)

	var lvl_label := Label.new()
	var max_level: int = 8
	var is_evolved: bool = slot.level > max_level
	lvl_label.text = "★" if is_evolved else "Lv %d" % slot.level
	lvl_label.add_theme_font_size_override("font_size", 12)
	var col: Color = Color(1.0, 0.776, 0.298, 1.0) if is_evolved else Color(0.953, 0.929, 0.871, 1.0)
	lvl_label.add_theme_color_override("font_color", col)
	lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lvl_label)

	return panel
