extends Node

const PERMANENT_UPGRADES := {
	"max_hp":    { "label": "Vida Máxima",   "base_cost": 70,  "max_level": 10 },
	"damage":    { "label": "Dano",          "base_cost": 90,  "max_level": 10 },
	"xp_gain":   { "label": "Ganho de XP",   "base_cost": 80,  "max_level": 10 },
	"move":      { "label": "Velocidade",    "base_cost": 65,  "max_level": 10 },
	"luck":      { "label": "Sorte",         "base_cost": 100, "max_level": 10 },
	"armor":     { "label": "Armadura",      "base_cost": 85,  "max_level": 10 },
	"magnet":    { "label": "Imã de XP",     "base_cost": 75,  "max_level": 10 },
	"rerolls":   { "label": "Re-rolls extra", "base_cost": 110, "max_level": 6 },
}

const TALENTS := {
	"survival":  { "label": "Sobrevivência", "max_level": 6, "base_cost": 1 },
	"weaponry":  { "label": "Armaria",       "max_level": 6, "base_cost": 2 },
	"collector": { "label": "Coletor",       "max_level": 6, "base_cost": 1 },
	"fortune":   { "label": "Fortuna",       "max_level": 6, "base_cost": 2 },
	"tempo":     { "label": "Tempo",         "max_level": 6, "base_cost": 3 },
	"growth":    { "label": "Crescimento",   "max_level": 6, "base_cost": 1 },
	"planning":  { "label": "Planejamento",  "max_level": 6, "base_cost": 2 },
}


func upgrade_level(key: String) -> int:
	var dict: Dictionary = SaveSystem.get_value("permanent_upgrades", {})
	return int(dict.get(key, 0))


func upgrade_cost(key: String) -> int:
	var info: Dictionary = PERMANENT_UPGRADES.get(key, {})
	if info.is_empty():
		return 0
	var lvl := upgrade_level(key)
	return int(info["base_cost"]) + lvl * int(info["base_cost"]) / 2


func can_buy_upgrade(key: String) -> bool:
	var info: Dictionary = PERMANENT_UPGRADES.get(key, {})
	if info.is_empty():
		return false
	if upgrade_level(key) >= int(info["max_level"]):
		return false
	return int(SaveSystem.get_value("coins", 0)) >= upgrade_cost(key)


func buy_upgrade(key: String) -> bool:
	if not can_buy_upgrade(key):
		return false
	var cost := upgrade_cost(key)
	SaveSystem.add_coins(-cost)
	var dict: Dictionary = SaveSystem.get_value("permanent_upgrades", {}).duplicate()
	dict[key] = upgrade_level(key) + 1
	SaveSystem.set_value("permanent_upgrades", dict)
	return true


func talent_level(key: String) -> int:
	var dict: Dictionary = SaveSystem.get_value("talents", {})
	return int(dict.get(key, 0))


func talent_cost(key: String) -> int:
	var info: Dictionary = TALENTS.get(key, {})
	if info.is_empty():
		return 0
	return int(info["base_cost"]) + talent_level(key)


func can_buy_talent(key: String) -> bool:
	var info: Dictionary = TALENTS.get(key, {})
	if info.is_empty():
		return false
	if talent_level(key) >= int(info["max_level"]):
		return false
	return int(SaveSystem.get_value("prestige_points", 0)) >= talent_cost(key)


func buy_talent(key: String) -> bool:
	if not can_buy_talent(key):
		return false
	var cost := talent_cost(key)
	SaveSystem.set_value("prestige_points", int(SaveSystem.get_value("prestige_points", 0)) - cost)
	var dict: Dictionary = SaveSystem.get_value("talents", {}).duplicate()
	dict[key] = talent_level(key) + 1
	SaveSystem.set_value("talents", dict)
	return true


func can_prestige() -> bool:
	var best := int(SaveSystem.get_value("best_time", 0))
	var total_kills := int(SaveSystem.get_value("total_kills", 0))
	return best >= 600 or total_kills >= 1000


func do_prestige() -> bool:
	if not can_prestige():
		return false
	var best := int(SaveSystem.get_value("best_time", 0))
	var total_kills := int(SaveSystem.get_value("total_kills", 0))
	var gained: int = maxi(1, best / 300 + total_kills / 500)
	SaveSystem.set_value("prestige", int(SaveSystem.get_value("prestige", 0)) + 1)
	SaveSystem.set_value("prestige_points", int(SaveSystem.get_value("prestige_points", 0)) + gained)
	SaveSystem.set_value("coins", 0)
	SaveSystem.set_value("permanent_upgrades", {})
	SaveSystem.set_value("unlocked_weapons", ["wand", "orbit", "knife", "spear", "boomerang"])
	SaveSystem.set_value("unlocked_characters", ["hunter"])
	SaveSystem.set_value("unlocked_relics", ["blood_crown", "moon_shard"])
	return true
