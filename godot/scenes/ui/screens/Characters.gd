extends "res://scenes/ui/screens/ScreenBase.gd"

## Seleção de herói: stats comparados, arma inicial e dica de desbloqueio.

const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")

var _list: VBoxContainer


func _init() -> void:
	screen_title = "Heróis"
	screen_icon = "🧙"


func _build_content() -> void:
	content.add_child(section("Cada herói muda o jeito de jogar"))
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	content.add_child(_list)
	_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	for c in CharacterRegistry.all_in_order():
		_list.add_child(_make_card(c))


func _make_card(c: Resource) -> Control:
	var unlocked: bool = CharacterRegistry.is_unlocked(c.key)
	var selected: bool = String(SaveSystem.get_value("selected_character", "hunter")) == c.key

	var panel := PanelContainer.new()
	var border: Color = P.ACCENT_GOLD if selected else (P.BORDER if unlocked else Color(0.18, 0.16, 0.22))
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, border, 14, 3 if selected else 2, 12))

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)

	# Retrato desenhado
	var portrait := _Portrait.new()
	portrait.custom_minimum_size = Vector2(64, 78)
	portrait.body_color = c.body_color if unlocked else Color(0.24, 0.21, 0.30)
	portrait.head_color = c.head_color if unlocked else Color(0.16, 0.14, 0.21)
	portrait.eye_color = c.eye_color if unlocked else Color(0.35, 0.33, 0.42)
	top.add_child(portrait)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 3)
	top.add_child(texts)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	texts.add_child(name_row)
	name_row.add_child(UI.make_label(c.display_name if unlocked else "???", 19, P.TEXT_PRIMARY if unlocked else P.TEXT_MUTED, 2))
	if selected:
		name_row.add_child(UI.make_chip("EQUIPADO", P.ACCENT_GREEN, 10))

	var desc := UI.make_label(c.description if unlocked else "🔒 %s" % c.unlock_hint, 12, P.TEXT_SECONDARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(desc)

	if unlocked:
		var stats := HBoxContainer.new()
		stats.add_theme_constant_override("separation", 4)
		texts.add_child(stats)
		stats.add_child(UI.make_chip("❤ %d%%" % int(c.hp_mult * 100.0), P.ACCENT_RED, 10))
		stats.add_child(UI.make_chip("👟 %d%%" % int(c.speed_mult * 100.0), P.ACCENT_GREEN, 10))
		if c.damage_mult_bonus != 0.0:
			stats.add_child(UI.make_chip("⚔ +%d%%" % int(c.damage_mult_bonus * 100.0), P.ACCENT_ORANGE, 10))
		if c.armor_bonus != 0.0:
			stats.add_child(UI.make_chip("🛡 +%d" % int(c.armor_bonus), P.TEXT_SECONDARY, 10))
		if c.luck_bonus != 0.0:
			stats.add_child(UI.make_chip("🍀 +%d%%" % int(c.luck_bonus * 100.0), P.CRIT, 10))
		if c.regen_bonus != 0.0:
			stats.add_child(UI.make_chip("💗 +%.1f" % c.regen_bonus, P.ACCENT_GREEN, 10))
		if c.xp_mult_bonus != 0.0:
			stats.add_child(UI.make_chip("🔮 +%d%%" % int(c.xp_mult_bonus * 100.0), P.ACCENT_PURPLE, 10))

		var weapon: Resource = RegistryScript.get_data(c.starter_weapon)
		if weapon != null:
			texts.add_child(UI.make_label("Arma inicial: %s %s" % [weapon.icon, weapon.display_name], 11, P.TEXT_MUTED))

	if unlocked and not selected:
		var btn := UI.make_button("SELECIONAR", P.ACCENT_GOLD, P.TEXT_DARK, 15)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(func():
			CharacterRegistry.select(c.key)
			EventBus.sfx("select", 0.7)
			_refresh())
		box.add_child(btn)

	return panel


## Bonequinho do herói desenhado (mesma silhueta do jogo)
class _Portrait extends Control:
	var body_color: Color = Color(0.275, 0.227, 0.412)
	var head_color: Color = Color(0.118, 0.094, 0.18)
	var eye_color: Color = Color(1.0, 0.776, 0.298)
	var _time: float = 0.0

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, size.y * 0.78)
		var bob: float = sin(_time * 2.2) * 2.0
		draw_circle(center + Vector2(0, 6), 16.0, Color(0, 0, 0, 0.35))
		# Capa
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-11, -28 + bob), center + Vector2(11, -28 + bob),
			center + Vector2(15, 2 + bob), center + Vector2(-15, 2 + bob),
		]), body_color.darkened(0.25))
		# Corpo
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-9, -24 + bob), center + Vector2(9, -24 + bob),
			center + Vector2(11, 0 + bob), center + Vector2(-11, 0 + bob),
		]), body_color)
		# Cabeça
		draw_circle(center + Vector2(0, -34 + bob), 11.0, head_color)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-11.5, -34 + bob), center + Vector2(0, -48 + bob), center + Vector2(11.5, -34 + bob),
		]), head_color.lightened(0.05))
		draw_circle(center + Vector2(0, -32 + bob), 8.0, Color(0.05, 0.04, 0.09, 0.9))
		draw_circle(center + Vector2(-3.4, -33 + bob), 2.2, eye_color)
		draw_circle(center + Vector2(3.4, -33 + bob), 2.2, eye_color)
