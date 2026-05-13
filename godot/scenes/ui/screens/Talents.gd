extends Control

signal back_pressed

const ORDER := ["survival", "weaponry", "collector", "fortune", "tempo", "growth", "planning"]

const DESCRIPTIONS := {
	"survival":  "+12 vida e +0.08 regen por nível",
	"weaponry":  "+6% dano por nível (escala com prestige)",
	"collector": "+18 raio de coleta por nível",
	"fortune":   "+8% sorte por nível",
	"tempo":     "-3% cooldown por nível (multiplicativo)",
	"growth":    "+4% XP e moedas por nível",
	"planning":  "+1 banimento a cada 2 níveis",
}


func _ready() -> void:
	%BackButton.pressed.connect(_back)
	_build()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")


func _refresh_points() -> void:
	%PointsLabel.text = "⭐ %d" % int(SaveSystem.get_value("prestige_points", 0))


func _build() -> void:
	_refresh_points()
	for child in %TalentsContainer.get_children():
		child.queue_free()
	for key in ORDER:
		var info: Dictionary = ProgressionManager.TALENTS.get(key, {})
		if info.is_empty():
			continue
		%TalentsContainer.add_child(_make_row(key, info))


func _make_row(key: String, info: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.92)
	style.border_color = Color(0.553, 0.412, 0.886, 1)
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
	lbl.add_theme_color_override("font_color", Color(0.722, 0.553, 1.0))
	lbl.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(lbl)

	var level := ProgressionManager.talent_level(key)
	var max_level: int = int(info["max_level"])
	var status := Label.new()
	status.text = "Lv %d / %d   ·   %s" % [level, max_level, String(DESCRIPTIONS.get(key, ""))]
	status.add_theme_color_override("font_color", Color(0.722, 0.694, 0.808))
	status.add_theme_font_size_override("font_size", 13)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_vbox.add_child(status)

	var buy_btn := Button.new()
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.553, 0.412, 0.886, 1)
	btn_style.border_color = Color(0.275, 0.196, 0.494, 1)
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
	buy_btn.add_theme_color_override("font_color", Color(0.953, 0.929, 0.871))
	buy_btn.add_theme_font_size_override("font_size", 14)

	if level >= max_level:
		buy_btn.text = "MÁX"
		buy_btn.disabled = true
	else:
		var cost := ProgressionManager.talent_cost(key)
		buy_btn.text = "⭐ %d" % cost
		buy_btn.disabled = not ProgressionManager.can_buy_talent(key)
		buy_btn.pressed.connect(func(): _on_buy(key))

	hbox.add_child(buy_btn)
	return panel


func _on_buy(key: String) -> void:
	if ProgressionManager.buy_talent(key):
		_build()
