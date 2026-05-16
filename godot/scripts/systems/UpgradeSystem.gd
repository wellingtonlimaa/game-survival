extends Node

const RarityScript := preload("res://scripts/utils/Rarity.gd")
const SynergySystemScript := preload("res://scripts/systems/SynergySystem.gd")

const WEAPON_PATHS := {
	"wand":  "res://resources/weapons/wand.tres",
	"knife": "res://resources/weapons/knife.tres",
	"orbit": "res://resources/weapons/orbit.tres",
}

const PASSIVE_PATHS := {
	"move":     "res://resources/passives/move.tres",
	"regen":    "res://resources/passives/regen.tres",
	"magnet":   "res://resources/passives/magnet.tres",
	"armor":    "res://resources/passives/armor.tres",
	"luck":     "res://resources/passives/luck.tres",
	"cooldown": "res://resources/passives/cooldown.tres",
}

const RELIC_PATHS := {
	"blood_crown":   "res://resources/relics/blood_crown.tres",
	"moon_shard":    "res://resources/relics/moon_shard.tres",
	"phoenix_ember": "res://resources/relics/phoenix_ember.tres",
	"storm_ring":    "res://resources/relics/storm_ring.tres",
	"giant_belt":    "res://resources/relics/giant_belt.tres",
}

const MAX_WEAPON_LEVEL := 8

var player: Node2D = null
var weapon_system: Node = null
var passives: Dictionary = {}      # key → level
var relics: Array = []             # keys
var banished: Array = []           # keys
var rerolls_left: int = 2
var banishes_left: int = 1
var active_synergies: Array = []


func configure(p_player: Node2D, p_weapon_system: Node) -> void:
	player = p_player
	weapon_system = p_weapon_system


# Gera 3 escolhas (chest=true dá bônus de raridade)
func roll_choices(chest: bool = false) -> Array:
	var pool: Array = _build_pool()
	if pool.size() == 0:
		return []
	pool.shuffle()
	var luck: float = float(player.get("luck")) if "luck" in player else 0.0
	var choices: Array = []
	for i in range(min(3, pool.size())):
		var entry: Dictionary = pool[i].duplicate()
		entry["rarity"] = RarityScript.roll(luck, chest)
		choices.append(entry)
	# Prioriza evoluções se aparecem em jogo
	_ensure_evolutions_priority(choices, pool, luck)
	return choices


func _ensure_evolutions_priority(choices: Array, pool: Array, luck: float) -> void:
	# Se houver evoluções disponíveis e nenhuma foi sorteada, força 1
	var has_evolve: bool = false
	for c in choices:
		if c["kind"] == "weapon_evolve":
			has_evolve = true
			break
	if has_evolve:
		return
	for p in pool:
		if p["kind"] == "weapon_evolve":
			var forced: Dictionary = p.duplicate()
			forced["rarity"] = "lendario"
			if choices.size() > 0:
				choices[choices.size() - 1] = forced
			else:
				choices.append(forced)
			return


func _build_pool() -> Array:
	var pool: Array = []
	# Armas equipadas: nível up ou evolução
	if weapon_system == null:
		return pool
	for slot in weapon_system.slots:
		var key: String = slot.data.key
		if banished.has("weapon_level:%s" % key):
			continue
		if slot.level >= MAX_WEAPON_LEVEL:
			pool.append({
				"kind": "weapon_evolve",
				"key": key,
				"title": "Evoluir %s" % slot.data.display_name,
				"description": "Liberta o verdadeiro poder da arma.",
				"color": Color(1.0, 0.776, 0.298, 1.0),
			})
		else:
			pool.append({
				"kind": "weapon_level",
				"key": key,
				"title": "+1 %s" % slot.data.display_name,
				"description": "Aumenta dano, projéteis e reduz recarga.",
				"color": slot.data.icon_color,
			})

	# Armas novas (até 3 armas totais por enquanto)
	var equipped_keys: Array = []
	for slot in weapon_system.slots:
		equipped_keys.append(slot.data.key)
	if equipped_keys.size() < 6:
		for key in WEAPON_PATHS.keys():
			if equipped_keys.has(key):
				continue
			if banished.has("weapon_new:%s" % key):
				continue
			var weapon_res: Resource = load(WEAPON_PATHS[key])
			pool.append({
				"kind": "weapon_new",
				"key": key,
				"title": "Nova: %s" % weapon_res.display_name,
				"description": weapon_res.description,
				"color": weapon_res.icon_color,
			})

	# Passivas (até max_level)
	for key in PASSIVE_PATHS.keys():
		if banished.has("passive:%s" % key):
			continue
		var res: Resource = load(PASSIVE_PATHS[key])
		var cur: int = int(passives.get(key, 0))
		if cur >= res.max_level:
			continue
		pool.append({
			"kind": "passive",
			"key": key,
			"title": "%s %d" % [res.display_name, cur + 1],
			"description": res.description,
			"color": res.icon_color,
		})

	# Relíquias (cada uma só uma vez)
	for key in RELIC_PATHS.keys():
		if banished.has("relic:%s" % key) or relics.has(key):
			continue
		var res: Resource = load(RELIC_PATHS[key])
		pool.append({
			"kind": "relic",
			"key": key,
			"title": res.display_name,
			"description": res.description,
			"color": res.icon_color,
		})

	return pool


func pick(choice: Dictionary) -> void:
	var kind: String = choice["kind"]
	var key: String = choice["key"]
	var rarity: String = choice.get("rarity", "comum")
	var rarity_mult: float = RarityScript.mult(rarity)

	match kind:
		"weapon_new":
			weapon_system.equip(key)
			EventBus.weapon_picked.emit(key, 1, rarity)
		"weapon_level":
			# WeaponSystem.equip já incrementa nível se já existir
			weapon_system.equip(key)
			var lvl: int = _weapon_level_of(key)
			EventBus.weapon_picked.emit(key, lvl, rarity)
		"weapon_evolve":
			_evolve_weapon(key)
			EventBus.weapon_evolved.emit(key)
			EventBus.flash_requested.emit(Color(1.0, 0.776, 0.298, 0.5), 0.4)
			EventBus.screen_shake_requested.emit(0.5, 0.4)
		"passive":
			_apply_passive(key, rarity_mult)
		"relic":
			_apply_relic(key, rarity_mult)
			relics.append(key)
			EventBus.relic_picked.emit(key)

	_refresh_synergies()


func reroll() -> Array:
	if rerolls_left <= 0:
		return []
	rerolls_left -= 1
	return roll_choices(false)


func banish(choice: Dictionary) -> Array:
	if banishes_left <= 0:
		return []
	banishes_left -= 1
	banished.append("%s:%s" % [choice["kind"], choice["key"]])
	return roll_choices(false)


func _weapon_level_of(key: String) -> int:
	for slot in weapon_system.slots:
		if slot.data.key == key:
			return slot.level
	return 0


func _evolve_weapon(key: String) -> void:
	for slot in weapon_system.slots:
		if slot.data.key == key:
			slot.level = MAX_WEAPON_LEVEL + 1
			# Boost final: -25% cd, +30% dano
			slot.data = slot.data.duplicate()
			slot.data.cooldown *= 0.75
			slot.data.damage *= 1.3
			slot.data.display_name = slot.data.display_name + " ★"
			return


func _apply_passive(key: String, mult: float) -> void:
	if player == null:
		return
	var res: Resource = load(PASSIVE_PATHS[key])
	passives[key] = int(passives.get(key, 0)) + 1
	# Aplica os bônus do nível atual escalonados pela raridade
	player.speed += res.move_speed_per_level * mult
	player.regen += res.regen_per_level * mult
	player.max_hp += res.max_hp_bonus_per_level * mult
	player.hp = min(player.hp + res.max_hp_bonus_per_level * mult, player.max_hp)
	player.armor += res.armor_per_level * mult
	if "luck" in player:
		player.luck += res.luck_per_level * mult
	if "pickup_radius" in player:
		player.pickup_radius += res.magnet_per_level * mult
	if res.cooldown_mult_per_level != 0.0 and weapon_system != null:
		for slot in weapon_system.slots:
			slot.timer *= (1.0 + res.cooldown_mult_per_level * mult)
	player.emit_signal("hp_changed", player.hp, player.max_hp)


func _apply_relic(key: String, mult: float) -> void:
	if player == null:
		return
	var res: Resource = load(RELIC_PATHS[key])
	player.max_hp += res.max_hp_bonus * mult
	player.max_hp -= res.max_hp_loss
	player.max_hp = max(20.0, player.max_hp)
	player.armor += res.armor_bonus * mult
	player.regen += res.regen_bonus
	if "luck" in player:
		player.luck += res.luck_bonus
	if "damage_mult" in player:
		player.damage_mult += res.damage_mult_bonus * mult
	if "xp_mult" in player:
		player.xp_mult += res.xp_mult_bonus * mult
	if res.heal_on_pickup > 0.0:
		player.hp = min(player.hp + res.heal_on_pickup, player.max_hp)
	if res.grants_weapon != "" and weapon_system != null:
		weapon_system.equip(res.grants_weapon)
	player.emit_signal("hp_changed", player.hp, player.max_hp)


func _refresh_synergies() -> void:
	if weapon_system == null:
		return
	var keys: Array = []
	for slot in weapon_system.slots:
		keys.append(slot.data.key)
	var found: Array = SynergySystemScript.check(keys)
	for s in found:
		if not active_synergies.has(s):
			active_synergies.append(s)
			var info: Dictionary = SynergySystemScript.SYNERGIES[s]
			# Aplica bônus
			if "damage_mult" in player:
				player.damage_mult += float(info.get("damage_bonus", 0.0))
			player.speed *= (1.0 + float(info.get("speed_bonus", 0.0)))
			EventBus.synergy_unlocked.emit(s)
			EventBus.narrative_triggered.emit("✦ %s" % String(info["label"]))
