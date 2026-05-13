extends Node

const ACHIEVEMENTS := {
	"first_blood":       { "label": "Primeiro Sangue",    "reward": 25,  "hint": "Derrote 1 inimigo" },
	"hundred_kills":     { "label": "Centurião",          "reward": 80,  "hint": "100 KOs totais" },
	"five_hundred_kills":{ "label": "Mestre do Mato",     "reward": 160, "hint": "500 KOs totais" },
	"boss_down":         { "label": "Caça-Chefes",        "reward": 120, "hint": "Derrote 1 chefe" },
	"boss_hunter":       { "label": "Lenda Chefe",        "reward": 240, "hint": "Derrote 5 chefes" },
	"survivor_5":        { "label": "Sobrevivente",       "reward": 100, "hint": "Sobreviva 5 min" },
	"survivor_10":       { "label": "Inabalável",         "reward": 220, "hint": "Sobreviva 10 min" },
	"evolved":           { "label": "Despertar",          "reward": 150, "hint": "Evolua uma arma" },
	"synergy":           { "label": "Harmonia",           "reward": 150, "hint": "Ative uma sinergia" },
	"rich":              { "label": "Próspero",           "reward": 180, "hint": "500 moedas totais" },
	"wealthy":           { "label": "Magnata",            "reward": 320, "hint": "1500 moedas totais" },
}


func has_achievement(key: String) -> bool:
	var list: Array = SaveSystem.get_value("achievements", [])
	return list.has(key)


func award_achievement(key: String) -> void:
	if has_achievement(key):
		return
	var info: Dictionary = ACHIEVEMENTS.get(key, {})
	if info.is_empty():
		return
	var list: Array = SaveSystem.get_value("achievements", []).duplicate()
	list.append(key)
	SaveSystem.set_value("achievements", list)
	SaveSystem.add_coins(int(info.get("reward", 0)))
	EventBus.achievement_unlocked.emit(key)


func unlock_weapon(key: String) -> void:
	var list: Array = SaveSystem.get_value("unlocked_weapons", []).duplicate()
	if not list.has(key):
		list.append(key)
		SaveSystem.set_value("unlocked_weapons", list)


func unlock_character(key: String) -> void:
	var list: Array = SaveSystem.get_value("unlocked_characters", []).duplicate()
	if not list.has(key):
		list.append(key)
		SaveSystem.set_value("unlocked_characters", list)


func unlock_relic(key: String) -> void:
	var list: Array = SaveSystem.get_value("unlocked_relics", []).duplicate()
	if not list.has(key):
		list.append(key)
		SaveSystem.set_value("unlocked_relics", list)


func check_unlocks_after_run() -> void:
	var total_kills := int(SaveSystem.get_value("total_kills", 0))
	var boss_kills := int(SaveSystem.get_value("boss_kills", 0))
	var best_time := int(SaveSystem.get_value("best_time", 0))
	var evolved := int(SaveSystem.get_value("evolved_weapons", 0))

	if total_kills >= 1: award_achievement("first_blood")
	if total_kills >= 100: award_achievement("hundred_kills")
	if total_kills >= 500: award_achievement("five_hundred_kills")
	if boss_kills >= 1: award_achievement("boss_down")
	if boss_kills >= 5: award_achievement("boss_hunter")
	if best_time >= 300: award_achievement("survivor_5")
	if best_time >= 600: award_achievement("survivor_10")
	if evolved >= 1: award_achievement("evolved")

	if total_kills >= 100: unlock_weapon("axe")
	if boss_kills >= 1: unlock_weapon("bomb")
	if best_time >= 300: unlock_weapon("drone")
	if evolved >= 1: unlock_weapon("lightning")
	if total_kills >= 250: unlock_weapon("scythe")
	if total_kills >= 400: unlock_weapon("chain")
	if boss_kills >= 3: unlock_weapon("flame")
	if best_time >= 600: unlock_weapon("book")

	if total_kills >= 250: unlock_character("knight")
	if total_kills >= 400: unlock_character("rogue")
	if boss_kills >= 3: unlock_character("alchemist")
	if best_time >= 600: unlock_character("monk")

	if evolved >= 1: unlock_relic("storm_ring")
	if boss_kills >= 3: unlock_relic("phoenix_ember")
	if best_time >= 600: unlock_relic("giant_belt")
