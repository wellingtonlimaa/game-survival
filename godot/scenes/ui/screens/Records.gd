extends "res://scenes/ui/screens/ScreenBase.gd"

## Salão dos recordes: melhores runs, histórico e estatísticas gerais.

const MEDALS := ["🥇", "🥈", "🥉"]


func _init() -> void:
	screen_title = "Recordes"
	screen_icon = "🏅"


func _build_content() -> void:
	# Estatísticas gerais
	content.add_child(section("SEUS NÚMEROS"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)
	grid.add_child(_stat("⏱ Melhor tempo", GameManager.format_time(int(SaveSystem.get_value("best_time", 0))), P.ACCENT_CYAN))
	grid.add_child(_stat("☠ KOs totais", str(int(SaveSystem.get_value("total_kills", 0))), P.ACCENT_RED))
	grid.add_child(_stat("👑 Chefes", str(int(SaveSystem.get_value("boss_kills", 0))), P.ACCENT_GOLD))
	grid.add_child(_stat("⭐ Evoluções", str(int(SaveSystem.get_value("evolved_weapons", 0))), P.ACCENT_PURPLE))
	grid.add_child(_stat("🌅 Vitórias", str(int(SaveSystem.get_value("victories", 0))), P.ACCENT_GREEN))
	grid.add_child(_stat("🎮 Partidas", str(int(SaveSystem.get_value("total_runs", 0))), P.TEXT_SECONDARY))

	content.add_child(section("TOP 10 — MAIOR SOBREVIVÊNCIA"))
	var ranking: Array = SaveSystem.get_value("ranking", [])
	if ranking.is_empty():
		content.add_child(_empty("Nenhum registro ainda. Bora sobreviver!"))
	else:
		var pos: int = 1
		for run in ranking:
			content.add_child(_make_row(pos, run, true))
			pos += 1

	content.add_child(section("PARTIDAS RECENTES"))
	var history: Array = SaveSystem.get_value("history", [])
	if history.is_empty():
		content.add_child(_empty("Sem histórico ainda."))
	else:
		var i: int = 1
		for run in history:
			content.add_child(_make_row(i, run, false))
			i += 1


func _stat(label: String, value: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.BORDER, 12, 2, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var l := UI.make_label(label, 11, P.TEXT_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	var v := UI.make_label(value, 20, color, 3)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(v)
	return panel


func _empty(text: String) -> Control:
	var l := UI.make_label(text, 12, P.TEXT_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _make_row(pos: int, run: Dictionary, is_ranking: bool) -> Control:
	var panel := PanelContainer.new()
	var accent: Color = P.ACCENT_GOLD if (is_ranking and pos <= 3) else P.BORDER
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, accent, 12, 2, 8))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var badge: String = MEDALS[pos - 1] if (is_ranking and pos <= 3) else "#%d" % pos
	var pos_label := UI.make_label(badge, 16, P.ACCENT_GOLD if pos <= 3 else P.TEXT_MUTED, 2)
	pos_label.custom_minimum_size = Vector2(34, 0)
	pos_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(pos_label)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 1)
	row.add_child(texts)

	var line1 := "%s  ·  ☠ %d  ·  Lv %d" % [
		GameManager.format_time(int(run.get("time", 0))),
		int(run.get("kills", 0)),
		int(run.get("level", 1)),
	]
	texts.add_child(UI.make_label(line1, 15, P.TEXT_PRIMARY, 2))

	var char_key: String = String(run.get("character", "hunter"))
	var char_res: Resource = CharacterRegistry.get_character(char_key)
	var map_key: String = String(run.get("map", "forest"))
	var map_res: Resource = MapRegistry.get_map(map_key)
	var line2 := "%s · %s · %s" % [
		char_res.display_name if char_res != null else char_key,
		map_res.display_name if map_res != null else map_key,
		String(run.get("difficulty", "normal")).capitalize(),
	]
	texts.add_child(UI.make_label(line2, 10, P.TEXT_MUTED))

	if bool(run.get("won", false)):
		row.add_child(UI.make_chip("VITÓRIA", P.ACCENT_GREEN, 10))
	row.add_child(UI.make_label("🪙%d" % int(run.get("coins", 0)), 13, P.ACCENT_GOLD, 2))
	return panel
