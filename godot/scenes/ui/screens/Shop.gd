extends "res://scenes/ui/screens/ScreenBase.gd"

## Loja permanente: gasta moedas em melhorias que valem pra todas as runs.

const ORDER := ["max_hp", "damage", "xp_gain", "move", "armor", "luck", "magnet", "crit", "greed", "rerolls"]
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")
const GEM_COST := 25

var _coins_label: Label
var _gems_label: Label
var _list: VBoxContainer
var _weapons_list: VBoxContainer


func _init() -> void:
	screen_title = "Loja"
	screen_icon = "🛒"


func _build_content() -> void:
	_coins_label = UI.make_label("🪙 %d" % int(SaveSystem.get_value("coins", 0)), 18, P.ACCENT_GOLD, 3)
	header_extra.add_child(_coins_label)
	EventBus.currency_changed.connect(func(_k, _v): _refresh())

	_gems_label = UI.make_label("🌙 %d" % int(SaveSystem.get_value("gems", 0)), 18, P.ACCENT_CYAN, 3)
	header_extra.add_child(_gems_label)

	content.add_child(section("Melhorias permanentes — valem em toda partida"))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	content.add_child(_list)

	content.add_child(section("🌙 FRAGMENTOS DE LUA — libere armas na marra"))
	var hint := UI.make_label("Ganha 1 por chefe derrotado e 5 por vitória. Cada arma custa %d." % GEM_COST, 11, P.TEXT_MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(hint)
	_weapons_list = VBoxContainer.new()
	_weapons_list.add_theme_constant_override("separation", 6)
	content.add_child(_weapons_list)

	_refresh()


func _refresh() -> void:
	_coins_label.text = "🪙 %d" % int(SaveSystem.get_value("coins", 0))
	_gems_label.text = "🌙 %d" % int(SaveSystem.get_value("gems", 0))
	for child in _list.get_children():
		child.queue_free()
	for key in ORDER:
		var info: Dictionary = ProgressionManager.PERMANENT_UPGRADES.get(key, {})
		if info.is_empty():
			continue
		_list.add_child(_make_row(key, info))
	_refresh_weapons()


func _refresh_weapons() -> void:
	for child in _weapons_list.get_children():
		child.queue_free()
	var unlocked: Array = SaveSystem.get_value("unlocked_weapons", [])
	var gems: int = int(SaveSystem.get_value("gems", 0))
	var locked_any: bool = false
	for key in RegistryScript.KEYS:
		if unlocked.has(key):
			continue
		locked_any = true
		var data: Resource = RegistryScript.get_data(key)
		if data == null:
			continue
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_CYAN, 12, 2, 10))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var icon := UI.make_label(data.icon, 24, data.icon_color)
		icon.custom_minimum_size = Vector2(32, 0)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(texts)
		texts.add_child(UI.make_label(data.display_name, 15, P.TEXT_PRIMARY, 2))
		var desc := UI.make_label(data.description, 10, P.TEXT_SECONDARY)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(desc)
		var buy := UI.make_button("🌙 %d" % GEM_COST, P.ACCENT_CYAN, P.TEXT_DARK, 14)
		buy.custom_minimum_size = Vector2(80, 40)
		buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy.disabled = gems < GEM_COST
		buy.pressed.connect(func(): _buy_weapon(key))
		row.add_child(buy)
		_weapons_list.add_child(panel)
	if not locked_any:
		var done := UI.make_label("Todas as 20 armas liberadas. Monstro. 🏆", 13, P.ACCENT_GOLD)
		done.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_weapons_list.add_child(done)


func _buy_weapon(key: String) -> void:
	var gems: int = int(SaveSystem.get_value("gems", 0))
	if gems < GEM_COST:
		EventBus.sfx("deny", 0.6)
		return
	SaveSystem.add_gems(-GEM_COST)
	UnlockManager.unlock_weapon(key)
	EventBus.sfx("chest", 0.9)
	_refresh()


func _make_row(key: String, info: Dictionary) -> Control:
	var level: int = ProgressionManager.upgrade_level(key)
	var max_level: int = int(info["max_level"])
	var maxed: bool = level >= max_level

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_GOLD if maxed else P.BORDER, 14, 2, 12))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var icon := UI.make_label(String(info.get("icon", "✦")), 26, P.ACCENT_GOLD)
	icon.custom_minimum_size = Vector2(34, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(icon)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 2)
	row.add_child(texts)

	texts.add_child(UI.make_label(String(info["label"]), 17, P.TEXT_PRIMARY, 2))
	texts.add_child(UI.make_label(String(info.get("effect", "")), 11, P.TEXT_SECONDARY))

	# Pontinhos de nível
	var dots := HBoxContainer.new()
	dots.add_theme_constant_override("separation", 3)
	for i in range(max_level):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 5)
		dot.color = P.ACCENT_GOLD if i < level else Color(0.24, 0.20, 0.32)
		dots.add_child(dot)
	texts.add_child(dots)

	var buy := UI.make_button("MÁX" if maxed else "🪙 %d" % ProgressionManager.upgrade_cost(key),
		P.ACCENT_GOLD, P.TEXT_DARK, 15)
	buy.custom_minimum_size = Vector2(92, 44)
	buy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if maxed:
		buy.disabled = true
	else:
		buy.disabled = not ProgressionManager.can_buy_upgrade(key)
		buy.pressed.connect(func():
			if ProgressionManager.buy_upgrade(key):
				_refresh())
	row.add_child(buy)

	return panel
