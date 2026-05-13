extends Control

signal back_pressed


func _ready() -> void:
	%BackButton.pressed.connect(_back)
	_build()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")


func _format_time(seconds: int) -> String:
	var m: int = seconds / 60
	var s: int = seconds % 60
	return "%02d:%02d" % [m, s]


func _build() -> void:
	for child in %RankingContainer.get_children():
		child.queue_free()
	for child in %HistoryContainer.get_children():
		child.queue_free()

	var ranking: Array = SaveSystem.get_value("ranking", [])
	if ranking.is_empty():
		var empty := Label.new()
		empty.text = "Sem registros ainda."
		empty.add_theme_color_override("font_color", Color(0.514, 0.486, 0.616))
		empty.add_theme_font_size_override("font_size", 14)
		%RankingContainer.add_child(empty)
	else:
		var pos: int = 1
		for run in ranking:
			%RankingContainer.add_child(_make_row(pos, run, true))
			pos += 1

	var history: Array = SaveSystem.get_value("history", [])
	if history.is_empty():
		var empty := Label.new()
		empty.text = "Sem histórico ainda."
		empty.add_theme_color_override("font_color", Color(0.514, 0.486, 0.616))
		empty.add_theme_font_size_override("font_size", 14)
		%HistoryContainer.add_child(empty)
	else:
		var pos: int = 1
		for run in history:
			%HistoryContainer.add_child(_make_row(pos, run, false))
			pos += 1


func _make_row(pos: int, run: Dictionary, is_ranking: bool) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.85)
	style.border_color = Color(1, 0.776, 0.298) if (is_ranking and pos == 1) else Color(0.275, 0.227, 0.412)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	panel.add_child(hbox)

	var pos_lbl := Label.new()
	pos_lbl.text = "#%d" % pos
	pos_lbl.custom_minimum_size = Vector2(40, 0)
	pos_lbl.add_theme_color_override("font_color", Color(1, 0.776, 0.298) if pos <= 3 else Color(0.722, 0.694, 0.808))
	pos_lbl.add_theme_font_size_override("font_size", 16)
	hbox.add_child(pos_lbl)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var top := Label.new()
	var won: bool = bool(run.get("won", false))
	var marker := "🏆 " if won else ""
	top.text = "%s%s · Lv %d · %d KOs" % [marker, _format_time(int(run.get("time", 0))), int(run.get("level", 1)), int(run.get("kills", 0))]
	top.add_theme_color_override("font_color", Color(0.953, 0.929, 0.871))
	top.add_theme_font_size_override("font_size", 14)
	vbox.add_child(top)

	var bottom := Label.new()
	bottom.text = "%s · %s · %s" % [
		String(run.get("character", "?")).capitalize(),
		String(run.get("difficulty", "?")),
		String(run.get("map", "?")),
	]
	bottom.add_theme_color_override("font_color", Color(0.514, 0.486, 0.616))
	bottom.add_theme_font_size_override("font_size", 11)
	vbox.add_child(bottom)

	var coin := Label.new()
	coin.text = "+%d 🪙" % int(run.get("coins", 0))
	coin.add_theme_color_override("font_color", Color(1, 0.776, 0.298))
	coin.add_theme_font_size_override("font_size", 14)
	hbox.add_child(coin)

	return panel
