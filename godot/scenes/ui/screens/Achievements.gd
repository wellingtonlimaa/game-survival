extends "res://scenes/ui/screens/ScreenBase.gd"

## Conquistas com progresso visível (o que falta pra cada uma).


func _init() -> void:
	screen_title = "Conquistas"
	screen_icon = "🏆"


func _build_content() -> void:
	var unlocked: Array = SaveSystem.get_value("achievements", [])
	var total: int = UnlockManager.ACHIEVEMENTS.size()
	var done: int = 0
	for key in UnlockManager.ACHIEVEMENTS.keys():
		if unlocked.has(key):
			done += 1

	header_extra.add_child(UI.make_label("%d/%d" % [done, total], 18, P.ACCENT_GOLD, 3))

	var bar := UI.make_progress(P.ACCENT_GOLD, Color(0.10, 0.09, 0.15, 0.9), 12)
	bar.max_value = float(total)
	bar.value = float(done)
	content.add_child(bar)

	for key in UnlockManager.ACHIEVEMENTS.keys():
		var info: Dictionary = UnlockManager.ACHIEVEMENTS[key]
		content.add_child(_make_row(key, info, unlocked.has(key)))

	content.add_child(section("Desbloqueios da coleção"))
	content.add_child(_collection_panel())


func _make_row(key: String, info: Dictionary, has: bool) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(
		P.BG_MID if has else Color(0.067, 0.055, 0.118, 0.75),
		P.ACCENT_GOLD if has else P.BORDER_SOFT, 12, 2, 10))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon := UI.make_label(String(info.get("icon", "🏆")) if has else "🔒", 24, P.ACCENT_GOLD if has else P.TEXT_MUTED)
	icon.custom_minimum_size = Vector2(32, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 1)
	row.add_child(texts)
	texts.add_child(UI.make_label(String(info["label"]), 16, P.TEXT_PRIMARY if has else P.TEXT_SECONDARY, 2))
	var hint_text: String = String(info["hint"])
	var progress: String = UnlockManager.achievement_progress(key)
	if not has and progress != "":
		hint_text += "  (%s)" % progress
	var hint := UI.make_label(hint_text, 11, P.TEXT_MUTED)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(hint)

	row.add_child(UI.make_label("+%d 🪙" % int(info["reward"]), 15, P.ACCENT_GOLD if not has else P.TEXT_MUTED, 2))
	return panel


func _collection_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_CYAN, 12, 2, 10))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var weapons: Array = SaveSystem.get_value("unlocked_weapons", [])
	var chars: Array = SaveSystem.get_value("unlocked_characters", [])
	var relics: Array = SaveSystem.get_value("unlocked_relics", [])
	box.add_child(UI.make_label("⚔ Armas: %d/20" % weapons.size(), 14, P.TEXT_PRIMARY))
	box.add_child(UI.make_label("🧙 Heróis: %d/6" % chars.size(), 14, P.TEXT_PRIMARY))
	box.add_child(UI.make_label("💎 Relíquias: %d/12" % relics.size(), 14, P.TEXT_PRIMARY))

	var next_hint := UnlockManager.next_unlock_hint()
	if next_hint != "":
		box.add_child(UI.make_label("Próximo: %s" % next_hint, 11, P.ACCENT_CYAN))
	return panel
