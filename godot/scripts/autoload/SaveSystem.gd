extends Node

## Save em JSON com 3 slots, migração de versão e energia que regenera
## em tempo real (antes dava pra ficar preso sem energia pra sempre).

const SAVE_VERSION := 2
const SLOT_PATH_FORMAT := "user://savegame_slot%d.json"
const ENERGY_REGEN_SECONDS := 90.0

var data: Dictionary = {}
var _dirty: bool = false
var _save_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_slot(GameManager.current_save_slot)


func _notification(what: int) -> void:
	# Fechar o jogo nunca deve perder progresso pendente
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH or what == NOTIFICATION_PREDELETE:
		if _dirty:
			_write()


func _process(delta: float) -> void:
	# Escrita agrupada: evita gravar o arquivo dezenas de vezes por segundo
	if not _dirty:
		return
	_save_timer -= delta
	if _save_timer <= 0.0:
		_write()


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
		"energy_stamp": 0,
		"player_name": "Sobrevivente",
		"player_level": 1,
		"player_xp": 0,
		"total_kills": 0,
		"total_runs": 0,
		"best_time": 0,
		"best_kills": 0,
		"best_level": 1,
		"victories": 0,
		"prestige": 0,
		"prestige_points": 0,
		"boss_kills": 0,
		"evolved_weapons": 0,
		"selected_character": "hunter",
		"selected_map": "forest",
		"difficulty": "normal",
		"goal_seconds": 600,
		"music_volume": 0.5,
		"sfx_volume": 0.8,
		"muted": false,
		"fullscreen": false,
		"tutorial_seen": false,
		"unlocked_characters": ["hunter", "mage"],
		"unlocked_weapons": ["wand", "knife", "spear", "arrow_storm", "orbit", "fury",
			"shotgun", "fire_staff", "spirit", "missile"],
		"selected_weapon": "",
		"unlocked_relics": ["blood_crown", "moon_shard", "phoenix_ember"],
		"unlocked_maps": ["forest", "graveyard", "ermos"],
		"permanent_upgrades": {},
		"talents": {},
		"achievements": [],
		"ranking": [],
		"history": [],
		"codex": {"enemies": [], "weapons": [], "relics": []},
		"daily_chest_at": 0,
		"daily_streak": 0,
		"has_mail": true,
		"has_announcement": true,
	}


func load_slot(slot: int) -> Dictionary:
	GameManager.current_save_slot = slot
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		data = default_data()
		_write()
		return data

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Save corrompido no slot %d, recriando." % slot)
		data = default_data()
		_write()
		return data

	var raw := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save inválido no slot %d, recriando." % slot)
		data = default_data()
		_write()
		return data

	data = _migrate(_merge_with_defaults(parsed))
	_regen_energy()
	GameManager.selected_character = String(data.get("selected_character", "hunter"))
	GameManager.selected_difficulty = String(data.get("difficulty", "normal"))
	GameManager.selected_goal_seconds = int(data.get("goal_seconds", 600))
	return data


## Migra saves antigos: chaves de armas que não existem mais são descartadas.
func _migrate(loaded: Dictionary) -> Dictionary:
	var version: int = int(loaded.get("version", 1))
	if version < 2:
		var valid_weapons := ["wand", "knife", "spear", "orbit", "arrow_storm", "fury",
			"shotgun", "fire_staff", "spirit", "boomerang", "axe", "lightning",
			"bomb", "scythe", "flame", "frost_nova", "drone", "holy_shield", "comet", "book", "missile"]
		var cleaned: Array = []
		for w in loaded.get("unlocked_weapons", []):
			if valid_weapons.has(String(w)):
				cleaned.append(String(w))
		for w in ["wand", "knife", "spear", "orbit", "arrow_storm", "fury"]:
			if not cleaned.has(w):
				cleaned.append(w)
		loaded["unlocked_weapons"] = cleaned
		# "codex_seen" virou "codex"
		if loaded.has("codex_seen"):
			loaded["codex"] = loaded["codex_seen"]
			loaded.erase("codex_seen")
		# Arcanista sempre disponível
		var chars: Array = loaded.get("unlocked_characters", ["hunter"])
		if not chars.has("mage"):
			chars.append("mage")
		loaded["unlocked_characters"] = chars
	loaded["version"] = SAVE_VERSION
	return loaded


func save() -> void:
	_dirty = true
	_save_timer = 0.35


func save_now() -> void:
	_write()


func _write() -> void:
	_dirty = false
	_save_timer = 0.0
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
	return merged


func get_value(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)


func set_value(key: String, value: Variant) -> void:
	data[key] = value
	save()


func add_coins(amount: int) -> void:
	data["coins"] = maxi(0, int(data.get("coins", 0)) + amount)
	if amount > 0:
		data["total_coins"] = int(data.get("total_coins", 0)) + amount
	save()
	EventBus.currency_changed.emit("coins", data["coins"])
	EventBus.coins_changed.emit(data["coins"])


func add_gems(amount: int) -> void:
	data["gems"] = maxi(0, int(data.get("gems", 0)) + amount)
	save()
	EventBus.currency_changed.emit("gems", data["gems"])


# --- Energia -----------------------------------------------------------------

## Energia volta sozinha com o tempo real (1 a cada 90s).
func _regen_energy() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var stamp: int = int(data.get("energy_stamp", 0))
	if stamp <= 0:
		data["energy_stamp"] = now
		save()
		return
	var elapsed: int = maxi(0, now - stamp)
	var gained: int = int(float(elapsed) / ENERGY_REGEN_SECONDS)
	if gained <= 0:
		return
	var max_energy: int = int(data.get("max_energy", 60))
	var energy: int = int(data.get("energy", 0))
	data["energy"] = mini(max_energy, energy + gained)
	data["energy_stamp"] = now
	save()


func energy() -> int:
	_regen_energy()
	return int(data.get("energy", 0))


func seconds_to_next_energy() -> int:
	var now: int = int(Time.get_unix_time_from_system())
	var stamp: int = int(data.get("energy_stamp", now))
	var elapsed: float = float(maxi(0, now - stamp))
	return int(maxf(0.0, ENERGY_REGEN_SECONDS - fmod(elapsed, ENERGY_REGEN_SECONDS)))


func spend_energy(amount: int) -> bool:
	var current := energy()
	if current < amount:
		return false
	data["energy"] = current - amount
	data["energy_stamp"] = int(Time.get_unix_time_from_system())
	save()
	EventBus.currency_changed.emit("energy", data["energy"])
	return true


func add_energy(amount: int) -> void:
	var max_energy: int = int(data.get("max_energy", 60))
	data["energy"] = clampi(energy() + amount, 0, max_energy)
	save()
	EventBus.currency_changed.emit("energy", data["energy"])


# --- Codex -------------------------------------------------------------------

func mark_codex(category: String, key: String) -> void:
	var codex: Dictionary = data.get("codex", {}).duplicate(true)
	var list: Array = codex.get(category, [])
	if list.has(key):
		return
	list.append(key)
	codex[category] = list
	data["codex"] = codex
	save()


func codex_has(category: String, key: String) -> bool:
	var codex: Dictionary = data.get("codex", {})
	return (codex.get(category, []) as Array).has(key)
