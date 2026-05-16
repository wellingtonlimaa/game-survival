extends Node

const CHARACTER_PATHS := {
	"hunter":    "res://resources/characters/hunter.tres",
	"knight":    "res://resources/characters/knight.tres",
	"mage":      "res://resources/characters/mage.tres",
	"rogue":     "res://resources/characters/rogue.tres",
	"alchemist": "res://resources/characters/alchemist.tres",
	"monk":      "res://resources/characters/monk.tres",
}

const ORDER := ["hunter", "mage", "knight", "rogue", "alchemist", "monk"]

var cache: Dictionary = {}


func get_character(key: String) -> Resource:
	if cache.has(key):
		return cache[key]
	var path: String = CHARACTER_PATHS.get(key, CHARACTER_PATHS["hunter"])
	var res := load(path)
	cache[key] = res
	return res


func selected() -> Resource:
	var key: String = String(SaveSystem.get_value("selected_character", "hunter"))
	if not is_unlocked(key):
		key = "hunter"
	return get_character(key)


func is_unlocked(key: String) -> bool:
	var unlocked: Array = SaveSystem.get_value("unlocked_characters", ["hunter"])
	return unlocked.has(key)


func select(key: String) -> void:
	if not is_unlocked(key):
		return
	SaveSystem.set_value("selected_character", key)
	GameManager.selected_character = key


func all_in_order() -> Array:
	var result: Array = []
	for key in ORDER:
		result.append(get_character(key))
	return result
