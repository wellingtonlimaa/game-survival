extends Node

## Meta-progressão: loja permanente, talentos de prestígio, nível de conta
## e o baú diário.

const P := preload("res://scripts/utils/Theme.gd")

const PERMANENT_UPGRADES := {
	"max_hp":  {"label": "Vida Máxima",  "icon": "❤", "base_cost": 70,  "max_level": 10, "effect": "+8 de vida por nível"},
	"damage":  {"label": "Dano",         "icon": "⚔", "base_cost": 90,  "max_level": 10, "effect": "+4% de dano por nível"},
	"xp_gain": {"label": "Ganho de XP",  "icon": "🔮", "base_cost": 80,  "max_level": 10, "effect": "+5% de XP por nível"},
	"move":    {"label": "Velocidade",   "icon": "👟", "base_cost": 65,  "max_level": 10, "effect": "+6 de velocidade por nível"},
	"armor":   {"label": "Armadura",     "icon": "🛡", "base_cost": 85,  "max_level": 10, "effect": "+0.4 de armadura por nível"},
	"luck":    {"label": "Sorte",        "icon": "🍀", "base_cost": 100, "max_level": 10, "effect": "+4% de sorte por nível"},
	"magnet":  {"label": "Ímã de XP",    "icon": "🧲", "base_cost": 75,  "max_level": 10, "effect": "+10 de coleta por nível"},
	"crit":    {"label": "Crítico",      "icon": "👁", "base_cost": 120, "max_level": 8,  "effect": "+1.5% de crítico por nível"},
	"greed":   {"label": "Ganância",     "icon": "💰", "base_cost": 110, "max_level": 8,  "effect": "+5% de moedas por nível"},
	"rerolls": {"label": "Re-rolls",     "icon": "🎲", "base_cost": 130, "max_level": 6,  "effect": "+1 re-roll por nível"},
}

const TALENTS := {
	"survival":  {"label": "Sobrevivência", "icon": "💗", "max_level": 6, "base_cost": 1, "effect": "+14 de vida e +0.1 de regeneração por nível"},
	"weaponry":  {"label": "Armaria",       "icon": "⚔", "max_level": 6, "base_cost": 2, "effect": "+6% de dano por nível (escala com prestígio)"},
	"collector": {"label": "Coletor",       "icon": "🧲", "max_level": 6, "base_cost": 1, "effect": "+18 de coleta e +3% de XP por nível"},
	"fortune":   {"label": "Fortuna",       "icon": "🍀", "max_level": 6, "base_cost": 2, "effect": "+8% de sorte e +6% de moedas por nível"},
	"tempo":     {"label": "Tempo",         "icon": "⚡", "max_level": 6, "base_cost": 3, "effect": "-3% de recarga por nível"},
	"growth":    {"label": "Crescimento",   "icon": "🌱", "max_level": 6, "base_cost": 1, "effect": "+4% de XP por nível"},
	"planning":  {"label": "Planejamento",  "icon": "📋", "max_level": 6, "base_cost": 2, "effect": "+1 banimento a cada 2 níveis"},
}

const META_UNLOCKS := {
	2: "Loja",
	4: "Dificuldade Difícil",
	5: "Talentos",
	8: "Dificuldade Infernal",
	10: "Salão dos Recordes",
}

const DAILY_REWARDS := [
	{"coins": 80,  "energy": 20},
	{"coins": 120, "energy": 20},
	{"coins": 160, "energy": 25},
	{"coins": 220, "energy": 25},
	{"coins": 300, "energy": 30},
	{"coins": 400, "energy": 35},
	{"coins": 600, "energy": 60},
]


func meta_xp_to_next(level: int) -> int:
	return 100 + (level - 1) * 80


func add_meta_xp(amount: int) -> Dictionary:
	var xp: int = int(SaveSystem.get_value("player_xp", 0)) + maxi(0, amount)
	var level: int = int(SaveSystem.get_value("player_level", 1))
	var start_level: int = level
	var coin_bonus: int = 0
	var unlocks: Array = []
	while xp >= meta_xp_to_next(level):
		xp -= meta_xp_to_next(level)
		level += 1
		coin_bonus += 25 * level
		if META_UNLOCKS.has(level):
			unlocks.append(String(META_UNLOCKS[level]))
	SaveSystem.set_value("player_xp", xp)
	SaveSystem.set_value("player_level", level)
	if coin_bonus > 0:
		SaveSystem.add_coins(coin_bonus)
	var leveled: bool = level > start_level
	if leveled:
		SaveSystem.set_value("pending_level_announce", level)
		if not unlocks.is_empty():
			SaveSystem.set_value("pending_unlocks_announce", unlocks)
	return {
		"gained_xp": maxi(0, amount),
		"new_level": level,
		"start_level": start_level,
		"leveled_up": leveled,
		"coin_bonus": coin_bonus,
		"unlocks": unlocks,
	}


# --- Loja --------------------------------------------------------------------

func upgrade_level(key: String) -> int:
	var dict: Dictionary = SaveSystem.get_value("permanent_upgrades", {})
	return int(dict.get(key, 0))


func upgrade_cost(key: String) -> int:
	var info: Dictionary = PERMANENT_UPGRADES.get(key, {})
	if info.is_empty():
		return 0
	var lvl := upgrade_level(key)
	return int(info["base_cost"]) + int(float(info["base_cost"]) * 0.6 * float(lvl))


func can_buy_upgrade(key: String) -> bool:
	var info: Dictionary = PERMANENT_UPGRADES.get(key, {})
	if info.is_empty():
		return false
	if upgrade_level(key) >= int(info["max_level"]):
		return false
	return int(SaveSystem.get_value("coins", 0)) >= upgrade_cost(key)


func buy_upgrade(key: String) -> bool:
	if not can_buy_upgrade(key):
		EventBus.sfx("deny", 0.6)
		return false
	var cost := upgrade_cost(key)
	SaveSystem.add_coins(-cost)
	var dict: Dictionary = (SaveSystem.get_value("permanent_upgrades", {}) as Dictionary).duplicate()
	dict[key] = upgrade_level(key) + 1
	SaveSystem.set_value("permanent_upgrades", dict)
	EventBus.sfx("coin", 0.8)
	return true


# --- Talentos ----------------------------------------------------------------

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
		EventBus.sfx("deny", 0.6)
		return false
	var cost := talent_cost(key)
	SaveSystem.set_value("prestige_points", int(SaveSystem.get_value("prestige_points", 0)) - cost)
	var dict: Dictionary = (SaveSystem.get_value("talents", {}) as Dictionary).duplicate()
	dict[key] = talent_level(key) + 1
	SaveSystem.set_value("talents", dict)
	EventBus.sfx("select", 0.8)
	return true


# --- Prestígio ---------------------------------------------------------------

func can_prestige() -> bool:
	var best := int(SaveSystem.get_value("best_time", 0))
	var total_kills := int(SaveSystem.get_value("total_kills", 0))
	return best >= 600 or total_kills >= 1000


func prestige_gain() -> int:
	var best := int(SaveSystem.get_value("best_time", 0))
	var total_kills := int(SaveSystem.get_value("total_kills", 0))
	return maxi(1, best / 300 + total_kills / 500)


func do_prestige() -> bool:
	if not can_prestige():
		return false
	var gained: int = prestige_gain()
	SaveSystem.set_value("prestige", int(SaveSystem.get_value("prestige", 0)) + 1)
	SaveSystem.set_value("prestige_points", int(SaveSystem.get_value("prestige_points", 0)) + gained)
	SaveSystem.set_value("coins", 0)
	SaveSystem.set_value("permanent_upgrades", {})
	# Armas/heróis/relíquias continuam desbloqueados: prestígio não apaga coleção
	EventBus.sfx("evolve", 1.0)
	EventBus.toast("PRESTÍGIO! +%d ponto(s)" % gained, P.ACCENT_PURPLE, "⭐")
	return true


# --- Baú diário --------------------------------------------------------------

func daily_available() -> bool:
	var last: int = int(SaveSystem.get_value("daily_chest_at", 0))
	if last <= 0:
		return true
	return int(Time.get_unix_time_from_system()) - last >= 82800  # 23h


func seconds_to_daily() -> int:
	var last: int = int(SaveSystem.get_value("daily_chest_at", 0))
	var elapsed: int = int(Time.get_unix_time_from_system()) - last
	return maxi(0, 82800 - elapsed)


func claim_daily() -> Dictionary:
	if not daily_available():
		return {}
	var now: int = int(Time.get_unix_time_from_system())
	var last: int = int(SaveSystem.get_value("daily_chest_at", 0))
	var streak: int = int(SaveSystem.get_value("daily_streak", 0))
	# Perdeu mais de 48h? recomeça a sequência
	if last > 0 and now - last > 172800:
		streak = 0
	streak = mini(streak + 1, DAILY_REWARDS.size())
	var reward: Dictionary = DAILY_REWARDS[streak - 1]
	SaveSystem.set_value("daily_chest_at", now)
	SaveSystem.set_value("daily_streak", streak)
	SaveSystem.add_coins(int(reward["coins"]))
	SaveSystem.add_energy(int(reward["energy"]))
	EventBus.sfx("chest", 1.0)
	return {"coins": int(reward["coins"]), "energy": int(reward["energy"]), "streak": streak}
