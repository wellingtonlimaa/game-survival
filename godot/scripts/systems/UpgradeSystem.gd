extends Node

## Monta e aplica as cartas de upgrade.
## Pool com pesos, evoluções douradas e bênçãos infinitas (o pool nunca seca).

const RarityScript := preload("res://scripts/utils/Rarity.gd")
const SynergyScript := preload("res://scripts/systems/SynergySystem.gd")
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")
const P := preload("res://scripts/utils/Theme.gd")

const PASSIVE_DIR := "res://resources/passives/%s.tres"
const RELIC_DIR := "res://resources/relics/%s.tres"

const PASSIVE_KEYS := [
	"might", "area", "cooldown", "velocity", "crit", "armor",
	"vitality", "regen", "move", "magnet", "luck", "greed",
	"multishot", "pierce", "vision",
]

const RELIC_KEYS := [
	"blood_crown", "moon_shard", "phoenix_ember", "storm_ring", "giant_belt",
	"hourglass", "dark_mirror", "leech_fang", "winged_boots", "gambler_coin",
	"void_star", "titan_heart", "moon_lens", "twin_barrel",
]

## Bênçãos: sempre disponíveis, garantem que o level-up nunca fique vazio.
const BLESSINGS := [
	{"key": "heal", "title": "Bênção da Lua", "icon": "🌙", "description": "Recupera 45% da vida máxima na hora.", "color": Color(0.439, 0.871, 0.494)},
	{"key": "power", "title": "Sussurro de Poder", "icon": "✨", "description": "+8% de dano permanente.", "color": Color(0.886, 0.275, 0.345)},
	{"key": "gold", "title": "Oferenda Dourada", "icon": "🪙", "description": "+60 moedas na hora.", "color": Color(1.0, 0.776, 0.298)},
	{"key": "xp", "title": "Néctar Astral", "icon": "🔮", "description": "+12% de XP e um empurrão de experiência.", "color": Color(0.553, 0.412, 0.886)},
	{"key": "shield", "title": "Casca de Pedra", "icon": "🪨", "description": "+1.5 de armadura e +12 de vida máxima.", "color": Color(0.722, 0.694, 0.808)},
]

var player: Node2D = null
var weapon_system: Node = null
var passives: Dictionary = {}      # chave → nível
var relics: Array = []             # chaves
var banished: Array = []           # "kind:key"
var rerolls_left: int = 2
var banishes_left: int = 1
var active_synergies: Array = []
var _res_cache: Dictionary = {}
var _fractional: Dictionary = {}   # acumula bônus fracionários (+1 projétil a cada N níveis)


func configure(p_player: Node2D, p_weapon_system: Node) -> void:
	player = p_player
	weapon_system = p_weapon_system
	rerolls_left = 2 + ProgressionManager.upgrade_level("rerolls")
	banishes_left = 1 + int(ProgressionManager.talent_level("planning") / 2)


func _load_res(path: String) -> Resource:
	if _res_cache.has(path):
		return _res_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	_res_cache[path] = res
	return res


func passive_data(key: String) -> Resource:
	return _load_res(PASSIVE_DIR % key)


func relic_data(key: String) -> Resource:
	return _load_res(RELIC_DIR % key)


func passive_level(key: String) -> int:
	return int(passives.get(key, 0))


# --- Montagem das escolhas ---------------------------------------------------

func roll_choices(chest: bool = false) -> Array:
	var pool: Array = _build_pool()
	var luck: float = float(player.luck) if "luck" in player else 0.0
	var wanted: int = 4 if chest else 3
	var choices: Array = []

	# Evolução sempre entra primeiro (é o grande momento da run)
	var evolutions: Array = pool.filter(func(e): return e["kind"] == "weapon_evolve")
	if not evolutions.is_empty():
		var evo: Dictionary = evolutions[randi() % evolutions.size()].duplicate()
		evo["rarity"] = "lendario"
		choices.append(evo)
		pool = pool.filter(func(e): return e["kind"] != "weapon_evolve")

	var picked_keys: Array = []
	for c in choices:
		picked_keys.append("%s:%s" % [c["kind"], c["key"]])

	var guard: int = 0
	while choices.size() < wanted and guard < 60:
		guard += 1
		var entry: Dictionary = _weighted_pick(pool)
		if entry.is_empty():
			break
		var id: String = "%s:%s" % [entry["kind"], entry["key"]]
		if picked_keys.has(id):
			continue
		picked_keys.append(id)
		var choice: Dictionary = entry.duplicate()
		choice["rarity"] = RarityScript.roll(luck, chest)
		choices.append(choice)

	# Se ainda faltou (pool minúsculo), completa com bênçãos
	while choices.size() < wanted:
		var b: Dictionary = _blessing_entry(BLESSINGS[randi() % BLESSINGS.size()])
		b["rarity"] = RarityScript.roll(luck, chest)
		choices.append(b)

	return choices


func _weighted_pick(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	var total: float = 0.0
	for e in pool:
		total += float(e.get("weight", 1.0))
	var roll: float = randf() * total
	var acc: float = 0.0
	for e in pool:
		acc += float(e.get("weight", 1.0))
		if roll <= acc:
			return e
	return pool[pool.size() - 1]


func _build_pool() -> Array:
	var pool: Array = []
	if weapon_system == null:
		return pool

	var equipped_keys: Array = []
	for slot in weapon_system.slots:
		equipped_keys.append(slot.data.key)

	# 1) Subir nível das armas equipadas + evoluções
	for slot in weapon_system.slots:
		var key: String = slot.data.key
		if slot.level < slot.data.max_level:
			if not banished.has("weapon_level:%s" % key):
				pool.append({
					"kind": "weapon_level",
					"key": key,
					"icon": slot.data.icon,
					"title": "%s Nv %d" % [slot.data.display_name, slot.level + 1],
					"description": slot.data.next_level_summary(slot.level),
					"color": slot.data.icon_color,
					"weight": 26.0,
				})
		elif _can_evolve(slot):
			var evo: Dictionary = RegistryScript.evolution_for(slot.data.key)
			pool.append({
				"kind": "weapon_evolve",
				"key": slot.data.key,
				"icon": String(evo.get("icon", "⭐")),
				"title": "EVOLUÇÃO: %s" % String(evo.get("name", "")),
				"description": String(evo.get("description", "")),
				"color": P.ACCENT_GOLD,
				"weight": 100.0,
			})

	# 2) Armas novas (respeitando desbloqueios e slots livres)
	if not weapon_system.is_full():
		for key in RegistryScript.unlocked_keys():
			if equipped_keys.has(key) or banished.has("weapon_new:%s" % key):
				continue
			var data: Resource = RegistryScript.get_data(key)
			if data == null:
				continue
			pool.append({
				"kind": "weapon_new",
				"key": key,
				"icon": data.icon,
				"title": data.display_name,
				"description": data.description,
				"color": data.icon_color,
				"weight": 30.0 if weapon_system.slots.size() < 4 else 16.0,
			})

	# 3) Passivas
	for key in PASSIVE_KEYS:
		if banished.has("passive:%s" % key):
			continue
		var res: Resource = passive_data(key)
		if res == null:
			continue
		var cur: int = passive_level(key)
		if cur >= res.max_level:
			continue
		pool.append({
			"kind": "passive",
			"key": key,
			"icon": res.icon,
			"title": "%s Nv %d" % [res.display_name, cur + 1],
			"description": res.description,
			"color": res.icon_color,
			"weight": 22.0,
		})

	# 4) Relíquias (uma vez cada)
	for key in RELIC_KEYS:
		if banished.has("relic:%s" % key) or relics.has(key):
			continue
		if not _relic_unlocked(key):
			continue
		var res: Resource = relic_data(key)
		if res == null:
			continue
		pool.append({
			"kind": "relic",
			"key": key,
			"icon": res.icon,
			"title": res.display_name,
			"description": res.description,
			"color": res.icon_color,
			"weight": 10.0,
		})

	# 5) Bênçãos (peso baixo, mas infinitas)
	for b in BLESSINGS:
		pool.append(_blessing_entry(b))

	return pool


func _blessing_entry(b: Dictionary) -> Dictionary:
	return {
		"kind": "blessing",
		"key": String(b["key"]),
		"icon": String(b["icon"]),
		"title": String(b["title"]),
		"description": String(b["description"]),
		"color": b["color"],
		"weight": 7.0,
	}


func _relic_unlocked(key: String) -> bool:
	var unlocked: Array = SaveSystem.get_value("unlocked_relics", ["blood_crown", "moon_shard"])
	return unlocked.has(key)


func _can_evolve(slot) -> bool:
	if slot.data.is_evolution or slot.data.evolves_into == "":
		return false
	if slot.level < slot.data.max_level:
		return false
	var info: Dictionary = RegistryScript.evolution_for(slot.data.key)
	var required: String = String(info.get("requires", ""))
	if required == "":
		return true
	var res: Resource = passive_data(required)
	if res == null:
		return true
	return passive_level(required) >= evolution_passive_requirement(res)


## Nível de passiva necessário pra liberar a evolução (max - 1, mínimo 1)
static func evolution_passive_requirement(res: Resource) -> int:
	return maxi(1, res.max_level - 1)


## Texto de "o que falta" pra evoluir (mostrado na carta de nível máximo)
func evolution_requirement_text(weapon_key: String) -> String:
	var info: Dictionary = RegistryScript.evolution_for(weapon_key)
	if info.is_empty():
		return ""
	var required: String = String(info.get("requires", ""))
	var res: Resource = passive_data(required)
	if res == null:
		return ""
	return "Evolui com %s nível %d+" % [res.display_name, evolution_passive_requirement(res)]


# --- Aplicação ---------------------------------------------------------------

func pick(choice: Dictionary) -> void:
	var kind: String = String(choice["kind"])
	var key: String = String(choice["key"])
	var rarity: String = String(choice.get("rarity", "comum"))
	var rarity_mult: float = RarityScript.mult(rarity)

	match kind:
		"weapon_new":
			weapon_system.equip(key)
			EventBus.weapon_picked.emit(key, 1, rarity)
			_codex_seen("weapons", key)
		"weapon_level":
			weapon_system.equip(key)
			var new_level: int = weapon_system.level_of(key)
			EventBus.weapon_picked.emit(key, new_level, rarity)
			_hint_evolution(key, new_level)
		"weapon_evolve":
			if weapon_system.evolve(key):
				EventBus.flash_requested.emit(Color(1.0, 0.776, 0.298, 0.45), 0.5)
				EventBus.screen_shake_requested.emit(0.6, 0.45)
				EventBus.sfx("evolve", 1.0)
				var evo: Dictionary = RegistryScript.evolution_for(key)
				EventBus.toast("EVOLUIU: %s" % String(evo.get("name", "")), P.ACCENT_GOLD, "⭐")
		"passive":
			_apply_passive(key, rarity_mult)
			EventBus.passive_picked.emit(key, passive_level(key))
		"relic":
			_apply_relic(key, rarity_mult)
			relics.append(key)
			EventBus.relic_picked.emit(key)
			_codex_seen("relics", key)
		"blessing":
			_apply_blessing(key, rarity_mult)

	if kind != "weapon_evolve":
		EventBus.sfx("select", 0.7)
	_refresh_synergies()
	EventBus.player_stats_changed.emit()


func reroll() -> Array:
	if rerolls_left <= 0:
		return []
	rerolls_left -= 1
	EventBus.sfx("click", 0.6)
	return roll_choices(false)


func banish(choice: Dictionary) -> Array:
	if banishes_left <= 0:
		return []
	banishes_left -= 1
	banished.append("%s:%s" % [choice["kind"], choice["key"]])
	EventBus.sfx("deny", 0.5)
	return roll_choices(false)


func _apply_passive(key: String, mult: float) -> void:
	if player == null:
		return
	var res: Resource = passive_data(key)
	if res == null:
		return
	passives[key] = passive_level(key) + 1

	player.speed += res.move_speed_per_level * mult
	player.regen += res.regen_per_level * mult
	if res.max_hp_bonus_per_level > 0.0:
		player.add_max_hp(res.max_hp_bonus_per_level * mult)
	player.armor += res.armor_per_level * mult
	player.luck += res.luck_per_level * mult
	player.pickup_radius += res.magnet_per_level * mult
	player.damage_mult += res.damage_mult_per_level * mult
	player.area_mult += res.area_mult_per_level * mult
	player.projectile_speed_mult += res.projectile_speed_per_level * mult
	player.duration_mult += res.duration_per_level * mult
	player.crit_chance += res.crit_chance_per_level * mult
	player.crit_mult += res.crit_mult_per_level * mult
	player.coin_mult += res.coin_mult_per_level * mult
	player.dodge_chance = minf(0.6, player.dodge_chance + res.dodge_per_level * mult)
	player.xp_mult += res.xp_mult_per_level * mult
	if res.extra_projectiles_per_level > 0.0:
		_fractional[key + ":proj"] = float(_fractional.get(key + ":proj", 0.0)) + res.extra_projectiles_per_level
		var whole_proj: int = int(floor(float(_fractional[key + ":proj"]) + 0.001))
		player.extra_projectiles = maxi(player.extra_projectiles, whole_proj)
	if res.extra_pierce_per_level > 0.0:
		_fractional[key + ":pierce"] = float(_fractional.get(key + ":pierce", 0.0)) + res.extra_pierce_per_level
		var whole_pierce: int = int(floor(float(_fractional[key + ":pierce"]) + 0.001))
		player.extra_pierce = maxi(player.extra_pierce, whole_pierce)
	if res.vision_per_level > 0.0:
		player.vision_mult += res.vision_per_level
		player.apply_vision()
	if res.cooldown_mult_per_level != 0.0:
		player.cooldown_mult = maxf(0.25, player.cooldown_mult * (1.0 + res.cooldown_mult_per_level * mult))


func _apply_relic(key: String, mult: float) -> void:
	if player == null:
		return
	var res: Resource = relic_data(key)
	if res == null:
		return
	if res.max_hp_bonus > 0.0:
		player.add_max_hp(res.max_hp_bonus * mult)
	if res.max_hp_pct_bonus > 0.0:
		player.add_max_hp(player.max_hp * res.max_hp_pct_bonus)
	if res.max_hp_loss > 0.0:
		player.add_max_hp(-res.max_hp_loss, false)
	player.armor += res.armor_bonus * mult
	player.regen += res.regen_bonus
	player.luck += res.luck_bonus
	player.damage_mult += res.damage_mult_bonus * mult
	player.xp_mult += res.xp_mult_bonus * mult
	player.coin_mult += res.coin_mult_bonus
	player.speed *= res.speed_mult
	player.cooldown_mult *= res.cooldown_mult
	player.area_mult *= res.area_mult
	player.duration_mult *= res.duration_mult
	player.dodge_chance = minf(0.6, player.dodge_chance + res.dodge_bonus)
	player.crit_chance += res.crit_chance_bonus
	player.crit_mult += res.crit_mult_bonus
	player.lifesteal_on_hit += res.lifesteal_bonus
	player.pickup_radius += res.pickup_bonus
	player.extra_projectiles += res.extra_projectiles
	player.extra_pierce += res.extra_pierce
	if res.vision_bonus > 0.0:
		player.vision_mult += res.vision_bonus
		player.apply_vision()
	player.revives += res.revives
	player.dash_cooldown *= res.dash_cooldown_mult
	rerolls_left += res.extra_rerolls
	if res.heal_on_pickup > 0.0:
		player.heal(res.heal_on_pickup)
	if res.grants_weapon != "" and weapon_system != null:
		weapon_system.equip(res.grants_weapon)


func _apply_blessing(key: String, mult: float) -> void:
	match key:
		"heal":
			player.heal(player.max_hp * 0.45 * mult)
		"power":
			player.damage_mult += 0.08 * mult
		"gold":
			EventBus.pickup_collected.emit("coin", 60.0 * mult)
		"xp":
			player.xp_mult += 0.12 * mult
			EventBus.player_xp_gained.emit(player.xp_to_next * 0.35)
		"shield":
			player.armor += 1.5 * mult
			player.add_max_hp(12.0 * mult)


## Ao chegar no nível máximo, conta o que falta pra evoluir
func _hint_evolution(key: String, level: int) -> void:
	var slot = weapon_system.slot_for(key)
	if slot == null or slot.data.is_evolution or level < slot.data.max_level:
		return
	if _can_evolve(slot):
		return
	var text: String = evolution_requirement_text(key)
	if text != "":
		EventBus.toast("%s no máximo — %s" % [slot.data.display_name, text], P.ACCENT_GOLD, "⭐")


func _codex_seen(category: String, key: String) -> void:
	EventBus.codex_entry_seen.emit(category, key)


func _refresh_synergies() -> void:
	if weapon_system == null:
		return
	var keys: Array = []
	for slot in weapon_system.slots:
		keys.append(slot.data.key)
	var found: Array = SynergyScript.check(keys)
	for s in found:
		if active_synergies.has(s):
			continue
		active_synergies.append(s)
		var info: Dictionary = SynergyScript.SYNERGIES[s]
		player.damage_mult += float(info.get("damage_bonus", 0.0))
		player.speed *= (1.0 + float(info.get("speed_bonus", 0.0)))
		player.area_mult += float(info.get("area_bonus", 0.0))
		player.armor += float(info.get("armor_bonus", 0.0))
		player.crit_chance += float(info.get("crit_bonus", 0.0))
		if info.has("cooldown_bonus"):
			player.cooldown_mult = maxf(0.25, player.cooldown_mult * (1.0 + float(info["cooldown_bonus"])))
		EventBus.synergy_unlocked.emit(s)
		EventBus.toast("SINERGIA: %s" % String(info["label"]), P.ACCENT_CYAN, String(info.get("icon", "✦")))
		EventBus.sfx("chest", 0.8)


## Lista de status atuais pra HUD/pausa
func summary() -> Dictionary:
	var passive_list: Array = []
	for key in passives.keys():
		var res: Resource = passive_data(key)
		if res == null:
			continue
		passive_list.append({"icon": res.icon, "name": res.display_name, "level": passives[key], "color": res.icon_color})
	var relic_list: Array = []
	for key in relics:
		var res: Resource = relic_data(key)
		if res == null:
			continue
		relic_list.append({"icon": res.icon, "name": res.display_name, "color": res.icon_color})
	var synergy_list: Array = []
	for s in active_synergies:
		var info: Dictionary = SynergyScript.SYNERGIES[s]
		synergy_list.append({"icon": String(info.get("icon", "✦")), "name": String(info["label"])})
	return {"passives": passive_list, "relics": relic_list, "synergies": synergy_list}
