class_name WeaponRegistry
extends RefCounted

## Catálogo único de armas + regras de evolução.
## Antes existiam dicionários duplicados (WeaponSystem, UpgradeSystem, Unlock).
## Agora tudo passa por aqui.

const DIR := "res://resources/weapons/%s.tres"

## A ordem também é a ordem do Codex.
const KEYS := [
	"wand", "knife", "spear", "arrow_storm", "shotgun", "fire_staff",
	"spirit", "missile", "boomerang", "axe", "lightning", "bomb", "scythe",
	"flame", "frost_nova", "drone", "orbit", "holy_shield", "comet",
	"book", "fury",
]

## Armas liberadas desde o começo (as outras entram via UnlockManager).
## Arsenal disponível desde o primeiro minuto (variedade > escassez).
const STARTER_KEYS := [
	"wand", "knife", "spear", "arrow_storm", "orbit", "fury",
	"shotgun", "fire_staff", "spirit", "missile",
]

## Evolução: arma no nível máximo + passiva exigida no máximo = carta dourada.
const EVOLUTIONS := {
	"wand": {
		"into": "arcane_rain", "name": "Chuva Arcana", "icon": "🌌", "requires": "cooldown",
		"description": "Quatro orbes teleguiados por disparo. O céu inteiro vira arcano.",
		"overrides": {"count_bonus": 3, "damage_mult": 1.35, "cooldown_mult": 0.80, "homing_strength": 3.0},
	},
	"arrow_storm": {
		"into": "artemis_fury", "name": "Fúria de Ártemis", "icon": "🎯", "requires": "velocity",
		"description": "Três setas por disparo que atravessam tudo pela frente.",
		"overrides": {"count_bonus": 2, "pierce_bonus": 2, "damage_mult": 1.30},
	},
	"fire_staff": {
		"into": "inferno_staff", "name": "Cajado do Inferno", "icon": "🌋", "requires": "area",
		"description": "A bola de fogo vira uma cratera. Área enorme e queimadura brutal.",
		"overrides": {"damage_mult": 1.40, "area_mult": 1.80, "status_power_mult": 2.0},
	},
	"missile": {
		"into": "missile_swarm", "name": "Enxame de Mísseis", "icon": "🎆", "requires": "multishot",
		"description": "Três mísseis por salva, cada um com explosão maior.",
		"overrides": {"count_bonus": 2, "damage_mult": 1.35, "area_mult": 1.45, "homing_strength": 9.0},
	},
	"spirit": {
		"into": "soul_swarm", "name": "Enxame de Almas", "icon": "🕊", "requires": "luck",
		"description": "Quatro almas caçadoras que não erram nunca.",
		"overrides": {"count_bonus": 3, "damage_mult": 1.25, "homing_strength": 9.0},
	},
	"knife": {
		"into": "steel_storm", "name": "Tempestade de Aço", "icon": "🌀", "requires": "move",
		"description": "Uma parede de lâminas que corta fileiras inteiras.",
		"overrides": {"count_bonus": 3, "pierce_bonus": 3, "cooldown_mult": 0.75},
	},
	"spear": {
		"into": "thunder_lance", "name": "Lança do Trovão", "icon": "🌩", "requires": "might",
		"description": "Cada estocada solta um trovão que salta entre os alvos.",
		"overrides": {"damage_mult": 1.40, "chain_bonus": 2, "status": "stun", "status_duration": 0.3, "status_chance": 0.35},
	},
	"shotgun": {
		"into": "double_thunder", "name": "Trovão Duplo", "icon": "💥", "requires": "armor",
		"description": "Dez chumbos por disparo. Empurra a horda inteira pra longe.",
		"overrides": {"count_bonus": 5, "damage_mult": 1.30, "knockback_mult": 1.4},
	},
	"boomerang": {
		"into": "storm_wheel", "name": "Roda da Tempestade", "icon": "🌪", "requires": "magnet",
		"description": "Três rodas que voltam sempre e congelam quem tocam.",
		"overrides": {"count_bonus": 2, "damage_mult": 1.35, "status": "slow", "status_power": 0.35, "status_duration": 1.6},
	},
	"axe": {
		"into": "executioner", "name": "Carrasco", "icon": "⚰", "requires": "vitality",
		"description": "Machados gigantes que ceifam qualquer fila.",
		"overrides": {"damage_mult": 1.60, "pierce_bonus": 4, "count_bonus": 1},
	},
	"lightning": {
		"into": "zeus_wrath", "name": "Ira de Zeus", "icon": "🔱", "requires": "crit",
		"description": "Sete saltos por raio e recarga relâmpago.",
		"overrides": {"damage_mult": 1.40, "chain_bonus": 4, "cooldown_mult": 0.70, "status_chance": 0.9},
	},
	"bomb": {
		"into": "meteor_bomb", "name": "Chuva de Meteoros", "icon": "☄", "requires": "greed",
		"description": "Duas bombas por arremesso, cada uma com raio de cratera.",
		"overrides": {"damage_mult": 1.50, "area_mult": 1.50, "count_bonus": 1},
	},
	"scythe": {
		"into": "death_harvest", "name": "Ceifa Final", "icon": "💀", "requires": "regen",
		"description": "O leque vira círculo completo e cada corte te cura o dobro.",
		"overrides": {"damage_mult": 1.40, "area_mult": 1.45, "lifesteal_mult": 2.0},
	},
	"flame": {
		"into": "dragon_breath", "name": "Sopro do Dragão", "icon": "🐉", "requires": "area",
		"description": "Um cone de fogo que cobre metade da tela.",
		"overrides": {"damage_mult": 1.50, "area_mult": 1.55, "status_power_mult": 1.6},
	},
	"frost_nova": {
		"into": "absolute_zero", "name": "Zero Absoluto", "icon": "🧊", "requires": "cooldown",
		"description": "Catorze estilhaços que congelam de vez quem for atingido.",
		"overrides": {"count_bonus": 6, "damage_mult": 1.40, "status": "stun", "status_duration": 0.9, "status_chance": 0.55},
	},
	"drone": {
		"into": "drone_swarm", "name": "Enxame de Sentinelas", "icon": "🛸", "requires": "cooldown",
		"description": "Três sentinelas cobrindo todos os ângulos.",
		"overrides": {"count_bonus": 2, "damage_mult": 1.30, "cooldown_mult": 0.6},
	},
	"orbit": {
		"into": "constellation", "name": "Constelação", "icon": "✨", "requires": "luck",
		"description": "Cinco astros numa órbita larga e imparável.",
		"overrides": {"count_bonus": 3, "damage_mult": 1.35, "orbit_radius_bonus": 34.0},
	},
	"holy_shield": {
		"into": "divine_aegis", "name": "Égide Divina", "icon": "🔰", "requires": "armor",
		"description": "Três escudos sagrados girando — nada passa.",
		"overrides": {"count_bonus": 2, "damage_mult": 1.50, "orbit_radius_bonus": 18.0},
	},
	"comet": {
		"into": "twin_comets", "name": "Cometas Gêmeos", "icon": "🌠", "requires": "velocity",
		"description": "Três cometas numa órbita ainda mais veloz.",
		"overrides": {"count_bonus": 2, "damage_mult": 1.35, "orbit_speed_mult": 1.25},
	},
	"book": {
		"into": "forbidden_tome", "name": "Tomo Proibido", "icon": "📕", "requires": "luck",
		"description": "Seis páginas amaldiçoadas que marcam todo mundo pra morrer.",
		"overrides": {"count_bonus": 3, "damage_mult": 1.40, "status_power_mult": 2.0, "status_chance": 1.0},
	},
	"fury": {
		"into": "eternal_cyclone", "name": "Ciclone Eterno", "icon": "🌀", "requires": "move",
		"description": "Um ciclone gigantesco que tritura tudo ao redor sem parar.",
		"overrides": {"damage_mult": 1.50, "area_mult": 1.55, "cooldown_mult": 0.80},
	},
}

static var _cache: Dictionary = {}


static func path_for(key: String) -> String:
	return DIR % key


static func exists(key: String) -> bool:
	return KEYS.has(key)


static func get_data(key: String) -> Resource:
	if _cache.has(key):
		return _cache[key]
	var path: String = path_for(key)
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	_cache[key] = res
	return res


static func all_data() -> Array:
	var out: Array = []
	for key in KEYS:
		var d: Resource = get_data(key)
		if d != null:
			out.append(d)
	return out


## Chaves liberadas no save (com fallback pras iniciais)
static func unlocked_keys() -> Array:
	var saved: Array = SaveSystem.get_value("unlocked_weapons", STARTER_KEYS)
	var out: Array = []
	for key in KEYS:
		if saved.has(key):
			out.append(key)
	if out.is_empty():
		out = STARTER_KEYS.duplicate()
	return out


static func evolution_for(key: String) -> Dictionary:
	return EVOLUTIONS.get(key, {})


static func has_evolution(key: String) -> bool:
	return EVOLUTIONS.has(key)


## Cria o recurso da arma evoluída aplicando os overrides sobre a base.
static func build_evolution(base: Resource) -> Resource:
	var info: Dictionary = EVOLUTIONS.get(base.key, {})
	if info.is_empty():
		return base
	var data: Resource = base.duplicate()
	var ov: Dictionary = info.get("overrides", {})
	data.key = String(info.get("into", base.key + "_evo"))
	data.display_name = String(info.get("name", base.display_name + " ★"))
	data.description = String(info.get("description", base.description))
	data.icon = String(info.get("icon", base.icon))
	data.is_evolution = true
	data.evolves_into = ""
	data.max_level = base.max_level

	data.damage *= float(ov.get("damage_mult", 1.0))
	data.cooldown *= float(ov.get("cooldown_mult", 1.0))
	data.area *= float(ov.get("area_mult", 1.0))
	data.knockback *= float(ov.get("knockback_mult", 1.0))
	data.projectile_count += int(ov.get("count_bonus", 0))
	data.pierce += int(ov.get("pierce_bonus", 0))
	data.chain_targets += int(ov.get("chain_bonus", 0))
	data.orbit_radius += float(ov.get("orbit_radius_bonus", 0.0))
	data.orbit_speed *= float(ov.get("orbit_speed_mult", 1.0))
	data.lifesteal *= float(ov.get("lifesteal_mult", 1.0))
	data.homing_strength = maxf(data.homing_strength, float(ov.get("homing_strength", 0.0)))
	if ov.has("status"):
		data.status = String(ov["status"])
	if ov.has("status_power"):
		data.status_power = float(ov["status_power"])
	if ov.has("status_power_mult"):
		data.status_power *= float(ov["status_power_mult"])
	if ov.has("status_duration"):
		data.status_duration = maxf(data.status_duration, float(ov["status_duration"]))
	if ov.has("status_chance"):
		data.status_chance = float(ov["status_chance"])
	# Evoluída brilha: cor mais quente e rastro ligado
	data.icon_color = base.icon_color.lerp(Color(1.0, 0.85, 0.45), 0.35)
	data.trail = true
	return data
