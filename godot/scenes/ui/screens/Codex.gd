extends "res://scenes/ui/screens/ScreenBase.gd"

## Codex: catálogo de armas, inimigos e relíquias com os números reais.

const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")

const ENEMY_KEYS := [
	"shade", "runner", "bat", "brute", "archer", "exploder", "charger",
	"slime", "slime_small", "summoner", "golem", "miniboss",
	"boss_base", "boss_frost", "boss_warlock", "boss_final",
]

const RELIC_KEYS := [
	"blood_crown", "moon_shard", "phoenix_ember", "storm_ring", "giant_belt",
	"hourglass", "dark_mirror", "leech_fang", "winged_boots", "gambler_coin",
	"void_star", "titan_heart", "moon_lens", "twin_barrel",
]

const BEHAVIOR_NAMES := [
	"tiro automático", "tiro na mira", "órbita", "aura", "arremesso em arco",
	"bumerangue", "raio em cadeia", "bomba", "golpe em leque", "explosão radial",
	"jato de fogo", "sentinela", "teleguiado",
]

var _tab: String = "weapons"
var _tabs_row: HBoxContainer
var _list: VBoxContainer


func _init() -> void:
	screen_title = "Codex"
	screen_icon = "📚"


func _build_content() -> void:
	_tabs_row = HBoxContainer.new()
	_tabs_row.add_theme_constant_override("separation", 6)
	content.add_child(_tabs_row)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	content.add_child(_list)

	_refresh()


func _refresh() -> void:
	for child in _tabs_row.get_children():
		child.queue_free()
	for tab in [["weapons", "⚔ Armas"], ["enemies", "👹 Inimigos"], ["relics", "💎 Relíquias"]]:
		var key: String = String(tab[0])
		var selected: bool = key == _tab
		var btn := UI.make_button(String(tab[1]), P.ACCENT_GOLD if selected else P.BG_HIGH,
			P.TEXT_DARK if selected else P.TEXT_SECONDARY, 13)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			_tab = key
			EventBus.sfx("click", 0.5)
			_refresh())
		_tabs_row.add_child(btn)

	for child in _list.get_children():
		child.queue_free()

	match _tab:
		"weapons":
			_build_weapons()
		"enemies":
			_build_enemies()
		"relics":
			_build_relics()


func _build_weapons() -> void:
	var unlocked: Array = SaveSystem.get_value("unlocked_weapons", [])
	_list.add_child(section("%d / %d armas liberadas" % [unlocked.size(), RegistryScript.KEYS.size()]))
	for key in RegistryScript.KEYS:
		var data: Resource = RegistryScript.get_data(key)
		if data == null:
			continue
		var has: bool = unlocked.has(key)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UI.panel_style(
			P.BG_MID if has else Color(0.067, 0.055, 0.118, 0.7),
			data.icon_color if has else P.BORDER_SOFT, 12, 2, 10))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)

		var icon := UI.make_label(data.icon if has else "🔒", 24, data.icon_color if has else P.TEXT_MUTED)
		icon.custom_minimum_size = Vector2(32, 0)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)

		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 1)
		row.add_child(texts)
		texts.add_child(UI.make_label(data.display_name if has else "???", 16, P.TEXT_PRIMARY if has else P.TEXT_MUTED, 2))
		if has:
			var desc := UI.make_label(data.description, 11, P.TEXT_SECONDARY)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			texts.add_child(desc)
			var stats := HBoxContainer.new()
			stats.add_theme_constant_override("separation", 4)
			stats.add_child(UI.make_chip("⚔ %d" % int(data.damage), P.ACCENT_RED, 10))
			stats.add_child(UI.make_chip("⏱ %.2fs" % data.cooldown, P.ACCENT_CYAN, 10))
			stats.add_child(UI.make_chip(BEHAVIOR_NAMES[int(data.behavior)], P.TEXT_SECONDARY, 10))
			if data.status != "":
				stats.add_child(UI.make_chip(_status_name(data.status), P.BURN, 10))
			texts.add_child(stats)
			var evo: Dictionary = RegistryScript.evolution_for(key)
			if not evo.is_empty():
				texts.add_child(UI.make_label("⭐ Evolui em %s (%s no máximo)" % [String(evo.get("name", "")), _passive_name(String(evo.get("requires", "")))], 10, P.ACCENT_GOLD))
		else:
			texts.add_child(UI.make_label(_weapon_hint(key), 11, P.TEXT_MUTED))
		_list.add_child(panel)


func _build_enemies() -> void:
	var seen: Array = (SaveSystem.get_value("codex", {}) as Dictionary).get("enemies", [])
	_list.add_child(section("%d / %d inimigos catalogados" % [seen.size(), ENEMY_KEYS.size()]))
	for key in ENEMY_KEYS:
		var path: String = "res://resources/enemies/%s.tres" % key
		if not ResourceLoader.exists(path):
			continue
		var data: Resource = load(path)
		var has: bool = seen.has(key)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UI.panel_style(
			P.BG_MID if has else Color(0.067, 0.055, 0.118, 0.7),
			data.body_color if has else P.BORDER_SOFT, 12, 2, 10))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var icon := UI.make_label(data.icon if has else "❔", 24, data.body_color.lightened(0.3) if has else P.TEXT_MUTED)
		icon.custom_minimum_size = Vector2(32, 0)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.add_theme_constant_override("separation", 1)
		row.add_child(texts)
		texts.add_child(UI.make_label(data.display_name if has else "??? ", 16, P.TEXT_PRIMARY if has else P.TEXT_MUTED, 2))
		if has:
			var desc := UI.make_label(data.description, 11, P.TEXT_SECONDARY)
			desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			texts.add_child(desc)
			var stats := HBoxContainer.new()
			stats.add_theme_constant_override("separation", 4)
			stats.add_child(UI.make_chip("❤ %d" % int(data.hp), P.ACCENT_RED, 10))
			stats.add_child(UI.make_chip("👟 %d" % int(data.speed), P.ACCENT_GREEN, 10))
			stats.add_child(UI.make_chip("💥 %d" % int(data.contact_damage), P.ACCENT_ORANGE, 10))
			stats.add_child(UI.make_chip("🔮 %d xp" % data.xp_value, P.ACCENT_PURPLE, 10))
			texts.add_child(stats)
		else:
			texts.add_child(UI.make_label("Derrote um pra catalogar", 11, P.TEXT_MUTED))
		_list.add_child(panel)


func _build_relics() -> void:
	var unlocked: Array = SaveSystem.get_value("unlocked_relics", [])
	_list.add_child(section("%d / %d relíquias liberadas" % [unlocked.size(), RELIC_KEYS.size()]))
	for key in RELIC_KEYS:
		var path: String = "res://resources/relics/%s.tres" % key
		if not ResourceLoader.exists(path):
			continue
		var data: Resource = load(path)
		var has: bool = unlocked.has(key)
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", UI.panel_style(
			P.BG_MID if has else Color(0.067, 0.055, 0.118, 0.7),
			data.icon_color if has else P.BORDER_SOFT, 12, 2, 10))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		panel.add_child(row)
		var icon := UI.make_label(data.icon if has else "🔒", 24, data.icon_color if has else P.TEXT_MUTED)
		icon.custom_minimum_size = Vector2(32, 0)
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(texts)
		texts.add_child(UI.make_label(data.display_name if has else "???", 16, P.TEXT_PRIMARY if has else P.TEXT_MUTED, 2))
		var desc := UI.make_label(data.description if has else _relic_hint(key), 11, P.TEXT_SECONDARY if has else P.TEXT_MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(desc)
		_list.add_child(panel)


func _status_name(status: String) -> String:
	match status:
		"burn": return "🔥 queima"
		"slow": return "❄ lentidão"
		"stun": return "⚡ atordoa"
		"poison": return "☠ veneno"
		"mark": return "🎯 marca"
	return status


func _passive_name(key: String) -> String:
	var path: String = "res://resources/passives/%s.tres" % key
	if not ResourceLoader.exists(path):
		return key
	return (load(path) as Resource).display_name


func _passive_requirement(key: String) -> String:
	var path: String = "res://resources/passives/%s.tres" % key
	if not ResourceLoader.exists(path):
		return key
	var res: Resource = load(path)
	return "%s nível %d+" % [res.display_name, maxi(1, res.max_level - 1)]


func _weapon_hint(key: String) -> String:
	var req: Dictionary = UnlockManager.WEAPON_UNLOCKS.get(key, {})
	if req.is_empty():
		return "Disponível desde o início"
	var stat_names := {
		"total_kills": "KOs totais",
		"boss_kills": "chefes derrotados",
		"best_time": "segundos de recorde",
		"evolved_weapons": "armas evoluídas",
		"victories": "vitórias",
		"player_level": "nível de conta",
	}
	var current: int = int(SaveSystem.get_value(String(req["stat"]), 0))
	return "🔒 %d/%d %s" % [current, int(req["value"]), stat_names.get(String(req["stat"]), "")]


func _relic_hint(key: String) -> String:
	var req: Dictionary = UnlockManager.RELIC_UNLOCKS.get(key, {})
	if req.is_empty():
		return "Disponível desde o início"
	var current: int = int(SaveSystem.get_value(String(req["stat"]), 0))
	return "🔒 %d/%d" % [current, int(req["value"])]
