extends "res://scenes/ui/screens/ScreenBase.gd"

## Árvore de talentos, comprada com pontos de prestígio.

const ORDER := ["survival", "weaponry", "collector", "fortune", "tempo", "growth", "planning"]

var _points_label: Label
var _list: VBoxContainer
var _prestige_panel: PanelContainer


func _init() -> void:
	screen_title = "Talentos"
	screen_icon = "🌳"


func _build_content() -> void:
	_points_label = UI.make_label("⭐ %d" % int(SaveSystem.get_value("prestige_points", 0)), 18, P.ACCENT_PURPLE, 3)
	header_extra.add_child(_points_label)

	content.add_child(section("Talentos são permanentes e escalam com o prestígio"))

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	content.add_child(_list)

	_prestige_panel = PanelContainer.new()
	content.add_child(_prestige_panel)

	_refresh()


func _refresh() -> void:
	_points_label.text = "⭐ %d" % int(SaveSystem.get_value("prestige_points", 0))
	for child in _list.get_children():
		child.queue_free()
	for key in ORDER:
		var info: Dictionary = ProgressionManager.TALENTS.get(key, {})
		if info.is_empty():
			continue
		_list.add_child(_make_row(key, info))
	_refresh_prestige()


func _make_row(key: String, info: Dictionary) -> Control:
	var level: int = ProgressionManager.talent_level(key)
	var max_level: int = int(info["max_level"])
	var maxed: bool = level >= max_level

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_PURPLE if level > 0 else P.BORDER, 14, 2, 12))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon := UI.make_label(String(info.get("icon", "✦")), 26, P.ACCENT_PURPLE)
	icon.custom_minimum_size = Vector2(34, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)
	texts.add_child(UI.make_label("%s  ·  %d/%d" % [String(info["label"]), level, max_level], 17, P.TEXT_PRIMARY, 2))
	var effect := UI.make_label(String(info.get("effect", "")), 11, P.TEXT_SECONDARY)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(effect)

	var buy := UI.make_button("MÁX" if maxed else "⭐ %d" % ProgressionManager.talent_cost(key),
		P.ACCENT_PURPLE, P.TEXT_PRIMARY, 15)
	buy.custom_minimum_size = Vector2(86, 44)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if maxed:
		buy.disabled = true
	else:
		buy.disabled = not ProgressionManager.can_buy_talent(key)
		buy.pressed.connect(func():
			if ProgressionManager.buy_talent(key):
				_refresh())
	row.add_child(buy)
	return panel


func _refresh_prestige() -> void:
	for child in _prestige_panel.get_children():
		child.queue_free()
	_prestige_panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_GOLD, 14, 2, 12))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_prestige_panel.add_child(box)

	var prestige: int = int(SaveSystem.get_value("prestige", 0))
	var title := UI.make_label("PRESTÍGIO %d" % prestige, 18, P.ACCENT_GOLD, 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var desc := UI.make_label(
		"Zera moedas e melhorias da loja, mas dá pontos de talento e +3%% de dano/vida por prestígio.\nRequisito: 10 min de sobrevivência OU 1000 KOs.",
		11, P.TEXT_SECONDARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(desc)

	var stats := UI.make_label("Recorde: %s  ·  KOs: %d" % [
		GameManager.format_time(int(SaveSystem.get_value("best_time", 0))),
		int(SaveSystem.get_value("total_kills", 0)),
	], 12, P.TEXT_MUTED)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(stats)

	var can: bool = ProgressionManager.can_prestige()
	var btn := UI.make_button("FAZER PRESTÍGIO (+%d ⭐)" % ProgressionManager.prestige_gain() if can else "🔒 Ainda não disponível",
		P.ACCENT_GOLD, P.TEXT_DARK, 16)
	btn.custom_minimum_size = Vector2(0, 46)
	btn.disabled = not can
	btn.pressed.connect(func():
		if ProgressionManager.do_prestige():
			_refresh())
	box.add_child(btn)
