extends Node

const SAVE_VERSION := 1
const SLOT_PATH_FORMAT := "user://savegame_slot%d.json"

var data: Dictionary = {}


func _ready() -> void:
	load_slot(GameManager.current_save_slot)


func slot_path(slot: int) -> String:
	return SLOT_PATH_FORMAT % slot


func default_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 0,
		"total_coins": 0,
		"gems": 0,
		"energy": 60,
		"max_energy": 60,
		"player_name": "Sobrevivente",
		"player_level": 1,
		"player_xp": 0,
		"total_kills": 0,
		"best_time": 0,
		"prestige": 0,
		"prestige_points": 0,
		"boss_kills": 0,
		"evolved_weapons": 0,
		"selected_character": "hunter",
		"difficulty": "normal",
		"music_volume": 0.5,
		"sfx_volume": 0.8,
		"muted": false,
		"tutorial_seen": false,
		"unlocked_characters": ["hunter"],
		"unlocked_weapons": ["wand", "orbit", "knife", "spear", "boomerang"],
		"unlocked_relics": ["blood_crown", "moon_shard"],
		"permanent_upgrades": {},
		"talents": {},
		"achievements": [],
		"goal_rewards": [],
		"character_rewards": [],
		"ranking": [],
		"history": [],
		"codex_seen": { "enemies": [], "weapons": [], "relics": [] },
		"has_mail": false,
		"has_announcement": false,
	}


func load_slot(slot: int) -> Dictionary:
	GameManager.current_save_slot = slot
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		data = default_data()
		save()
		return data

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Save corrompido em slot %d, recriando." % slot)
		data = default_data()
		save()
		return data

	var raw := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save inválido em slot %d, recriando." % slot)
		data = default_data()
		save()
		return data

	data = _merge_with_defaults(parsed)
	GameManager.selected_character = data.get("selected_character", "hunter")
	GameManager.selected_difficulty = data.get("difficulty", "normal")
	return data


func save() -> void:
	var path := slot_path(GameManager.current_save_slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Falha ao escrever save em %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func _merge_with_defaults(loaded: Dictionary) -> Dictionary:
	var merged := default_data()
	for key in loaded.keys():
		merged[key] = loaded[key]
	merged["version"] = SAVE_VERSION
	return merged


func get_value(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)


func set_value(key: String, value: Variant) -> void:
	data[key] = value
	save()


func add_coins(amount: int) -> void:
	data["coins"] = int(data.get("coins", 0)) + amount
	data["total_coins"] = int(data.get("total_coins", 0)) + max(0, amount)
	save()
	EventBus.currency_changed.emit("coins", data["coins"])


func add_gems(amount: int) -> void:
	data["gems"] = int(data.get("gems", 0)) + amount
	save()
	EventBus.currency_changed.emit("gems", data["gems"])


func spend_energy(amount: int) -> bool:
	var current := int(data.get("energy", 0))
	if current < amount:
		return false
	data["energy"] = current - amount
	save()
	EventBus.currency_changed.emit("energy", data["energy"])
	return true
