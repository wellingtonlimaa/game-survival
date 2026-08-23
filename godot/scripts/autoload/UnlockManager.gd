extends Node

## Conquistas e desbloqueios.
## As conquistas agora também disparam DURANTE a run (com toast na hora).

const P := preload("res://scripts/utils/Theme.gd")

const ACHIEVEMENTS := {
	"first_blood":        {"label": "Primeiro Sangue",  "reward": 25,  "hint": "Derrote 1 inimigo", "icon": "🩸"},
	"hundred_kills":      {"label": "Centurião",        "reward": 80,  "hint": "100 KOs no total", "icon": "💯"},
	"five_hundred_kills": {"label": "Mestre do Mato",   "reward": 160, "hint": "500 KOs no total", "icon": "🌿"},
	"thousand_kills":     {"label": "Ceifador",         "reward": 300, "hint": "1000 KOs no total", "icon": "☠"},
	"boss_down":          {"label": "Caça-Chefes",      "reward": 120, "hint": "Derrote 1 chefe", "icon": "👑"},
	"boss_hunter":        {"label": "Lenda Chefe",      "reward": 240, "hint": "Derrote 5 chefes", "icon": "🏅"},
	"survivor_5":         {"label": "Sobrevivente",     "reward": 100, "hint": "Sobreviva 5 minutos", "icon": "⏱"},
	"survivor_10":        {"label": "Inabalável",       "reward": 220, "hint": "Sobreviva 10 minutos", "icon": "🛡"},
	"evolved":            {"label": "Despertar",        "reward": 150, "hint": "Evolua uma arma", "icon": "⭐"},
	"synergy":            {"label": "Harmonia",         "reward": 150, "hint": "Ative uma sinergia", "icon": "✦"},
	"rich":               {"label": "Próspero",         "reward": 180, "hint": "500 moedas acumuladas", "icon": "🪙"},
	"wealthy":            {"label": "Magnata",          "reward": 320, "hint": "1500 moedas acumuladas", "icon": "💰"},
	"combo_50":           {"label": "Imparável",        "reward": 200, "hint": "Combo de 50 KOs", "icon": "🔥"},
	"victory":            {"label": "Noite Vencida",    "reward": 500, "hint": "Derrote o Ceifador da Noite", "icon": "🌅"},
	"arsenal":            {"label": "Arsenal Completo", "reward": 260, "hint": "Equipe 6 armas numa run", "icon": "⚔"},
	"collector":          {"label": "Colecionador",     "reward": 300, "hint": "Descubra 10 armas no Codex", "icon": "📖"},
}

## Desbloqueios por marco acumulado
const WEAPON_UNLOCKS := {
	"boomerang":  {"stat": "total_kills", "value": 60,   "label": "Bumerangue"},
	"axe":        {"stat": "total_kills", "value": 150,  "label": "Machado Giratório"},
	"scythe":     {"stat": "total_kills", "value": 300,  "label": "Foice Ceifadora"},
	"book":       {"stat": "total_kills", "value": 500,  "label": "Grimório Maldito"},
	"lightning":  {"stat": "boss_kills",  "value": 1,    "label": "Cajado Relâmpago"},
	"frost_nova": {"stat": "boss_kills",  "value": 3,    "label": "Nova Gélida"},
	"holy_shield":{"stat": "boss_kills",  "value": 6,    "label": "Escudo Sagrado"},
	"bomb":       {"stat": "best_time",   "value": 240,  "label": "Bomba de Piche"},
	"drone":      {"stat": "best_time",   "value": 360,  "label": "Sentinela"},
	"comet":      {"stat": "evolved_weapons", "value": 1, "label": "Cometa Cósmico"},
	"flame":      {"stat": "evolved_weapons", "value": 2, "label": "Lança-Chamas"},
}

const CHARACTER_UNLOCKS := {
	"knight":    {"stat": "total_kills", "value": 200, "label": "Guardião"},
	"rogue":     {"stat": "total_kills", "value": 400, "label": "Ladina"},
	"alchemist": {"stat": "boss_kills",  "value": 3,   "label": "Alquimista"},
	"monk":      {"stat": "best_time",   "value": 480, "label": "Monge"},
}

const RELIC_UNLOCKS := {
	"storm_ring":   {"stat": "evolved_weapons", "value": 1, "label": "Anel da Tempestade"},
	"giant_belt":   {"stat": "best_time",  "value": 300, "label": "Cinto do Colosso"},
	"hourglass":    {"stat": "total_kills","value": 250, "label": "Ampulheta Rachada"},
	"dark_mirror":  {"stat": "boss_kills", "value": 2,   "label": "Espelho Sombrio"},
	"leech_fang":   {"stat": "total_kills","value": 600, "label": "Presa Sanguessuga"},
	"winged_boots": {"stat": "best_time",  "value": 420, "label": "Botas Aladas"},
	"gambler_coin": {"stat": "total_coins","value": 800, "label": "Moeda do Apostador"},
	"void_star":    {"stat": "victories",  "value": 1,   "label": "Estrela do Vazio"},
	"titan_heart":  {"stat": "boss_kills", "value": 8,   "label": "Coração de Titã"},
	"moon_lens":    {"stat": "best_time",  "value": 180, "label": "Lente Lunar"},
	"twin_barrel":  {"stat": "total_kills","value": 350, "label": "Cano Duplo"},
}

var _run_flags: Dictionary = {}
var _codex_cache: Dictionary = {}


func _ready() -> void:
	EventBus.synergy_unlocked.connect(func(_k): award_achievement("synergy"))
	EventBus.weapon_evolved.connect(func(_k): award_achievement("evolved"))
	EventBus.combo_changed.connect(_on_combo)
	EventBus.loadout_changed.connect(_on_loadout_changed)
	EventBus.codex_entry_seen.connect(_on_codex_entry)
	EventBus.enemy_killed.connect(_on_enemy_killed)


## Todo inimigo derrotado entra no Codex (com cache pra não gravar o save à toa)
func _on_enemy_killed(enemy: Node, _source: String) -> void:
	if enemy == null or not ("data" in enemy) or enemy.data == null:
		return
	var key: String = String(enemy.data.key)
	if _codex_cache.has(key):
		return
	_codex_cache[key] = true
	if not SaveSystem.codex_has("enemies", key):
		SaveSystem.mark_codex("enemies", key)


func has_achievement(key: String) -> bool:
	var list: Array = SaveSystem.get_value("achievements", [])
	return list.has(key)


func award_achievement(key: String) -> void:
	if has_achievement(key):
		return
	var info: Dictionary = ACHIEVEMENTS.get(key, {})
	if info.is_empty():
		return
	var list: Array = (SaveSystem.get_value("achievements", []) as Array).duplicate()
	list.append(key)
	SaveSystem.set_value("achievements", list)
	SaveSystem.add_coins(int(info.get("reward", 0)))
	EventBus.achievement_unlocked.emit(key)
	EventBus.toast("%s +%d🪙" % [String(info["label"]), int(info.get("reward", 0))], P.ACCENT_GOLD, String(info.get("icon", "🏆")))


func _on_combo(count: int, _pct: float) -> void:
	if count >= 50:
		award_achievement("combo_50")


func _on_loadout_changed() -> void:
	pass


func _on_codex_entry(category: String, key: String) -> void:
	SaveSystem.mark_codex(category, key)
	if category == "weapons":
		var codex: Dictionary = SaveSystem.get_value("codex", {})
		if (codex.get("weapons", []) as Array).size() >= 10:
			award_achievement("collector")


## Chamado durante a partida (KOs, tempo e chefes da run atual)
func notify_run_progress(run_kills: int, run_time: int, run_boss_kills: int) -> void:
	var total_kills: int = int(SaveSystem.get_value("total_kills", 0)) + run_kills
	if total_kills >= 1:
		award_achievement("first_blood")
	if total_kills >= 100:
		award_achievement("hundred_kills")
	if total_kills >= 500:
		award_achievement("five_hundred_kills")
	if total_kills >= 1000:
		award_achievement("thousand_kills")
	if run_time >= 300:
		award_achievement("survivor_5")
	if run_time >= 600:
		award_achievement("survivor_10")
	var boss_total: int = int(SaveSystem.get_value("boss_kills", 0)) + run_boss_kills
	if boss_total >= 1:
		award_achievement("boss_down")
	if boss_total >= 5:
		award_achievement("boss_hunter")


func notify_arsenal_full() -> void:
	award_achievement("arsenal")


func unlock_weapon(key: String) -> bool:
	var list: Array = (SaveSystem.get_value("unlocked_weapons", []) as Array).duplicate()
	if list.has(key):
		return false
	list.append(key)
	SaveSystem.set_value("unlocked_weapons", list)
	return true


func unlock_character(key: String) -> bool:
	var list: Array = (SaveSystem.get_value("unlocked_characters", []) as Array).duplicate()
	if list.has(key):
		return false
	list.append(key)
	SaveSystem.set_value("unlocked_characters", list)
	return true


func unlock_relic(key: String) -> bool:
	var list: Array = (SaveSystem.get_value("unlocked_relics", []) as Array).duplicate()
	if list.has(key):
		return false
	list.append(key)
	SaveSystem.set_value("unlocked_relics", list)
	return true


func _stat(name: String) -> int:
	return int(SaveSystem.get_value(name, 0))


## Roda no fim da partida e devolve a lista de novidades pra tela de resultado.
func check_unlocks_after_run() -> Array:
	var news: Array = []

	for key in WEAPON_UNLOCKS.keys():
		var req: Dictionary = WEAPON_UNLOCKS[key]
		if _stat(String(req["stat"])) >= int(req["value"]) and unlock_weapon(key):
			news.append({"kind": "arma", "label": String(req["label"]), "icon": "⚔"})

	for key in CHARACTER_UNLOCKS.keys():
		var req_c: Dictionary = CHARACTER_UNLOCKS[key]
		if _stat(String(req_c["stat"])) >= int(req_c["value"]) and unlock_character(key):
			news.append({"kind": "herói", "label": String(req_c["label"]), "icon": "🧙"})

	for key in RELIC_UNLOCKS.keys():
		var req_r: Dictionary = RELIC_UNLOCKS[key]
		if _stat(String(req_r["stat"])) >= int(req_r["value"]) and unlock_relic(key):
			news.append({"kind": "relíquia", "label": String(req_r["label"]), "icon": "💎"})

	# Conquistas acumuladas
	notify_run_progress(0, _stat("best_time"), 0)
	if _stat("evolved_weapons") >= 1:
		award_achievement("evolved")
	if _stat("total_coins") >= 500:
		award_achievement("rich")
	if _stat("total_coins") >= 1500:
		award_achievement("wealthy")
	if _stat("victories") >= 1:
		award_achievement("victory")

	if not news.is_empty():
		SaveSystem.set_value("has_mail", true)
	return news


const STAT_NAMES := {
	"total_kills": "KOs",
	"boss_kills": "chefes",
	"best_time": "s de recorde",
	"evolved_weapons": "armas evoluídas",
	"victories": "vitórias",
	"total_coins": "moedas",
	"player_level": "nível de conta",
}


## O desbloqueio mais próximo — usado no fim da partida e no Codex.
func next_unlock_hint() -> String:
	var best: Dictionary = {}
	var best_gap: float = 1e9
	var sources := [
		[WEAPON_UNLOCKS, "unlocked_weapons", "⚔"],
		[CHARACTER_UNLOCKS, "unlocked_characters", "🧙"],
		[RELIC_UNLOCKS, "unlocked_relics", "💎"],
	]
	for src in sources:
		var table: Dictionary = src[0]
		var owned: Array = SaveSystem.get_value(String(src[1]), [])
		for key in table.keys():
			if owned.has(key):
				continue
			var req: Dictionary = table[key]
			var current: int = _stat(String(req["stat"]))
			var gap: float = float(int(req["value"]) - current)
			if gap > 0.0 and gap < best_gap:
				best_gap = gap
				best = {
					"icon": String(src[2]), "label": String(req["label"]),
					"stat": String(req["stat"]), "value": int(req["value"]), "current": current,
				}
	if best.is_empty():
		return ""
	return "%s %s — %d/%d %s" % [
		best["icon"], best["label"], best["current"], best["value"],
		STAT_NAMES.get(best["stat"], ""),
	]


## Progresso legível pra tela de conquistas
func achievement_progress(key: String) -> String:
	match key:
		"hundred_kills":
			return "%d/100" % _stat("total_kills")
		"five_hundred_kills":
			return "%d/500" % _stat("total_kills")
		"thousand_kills":
			return "%d/1000" % _stat("total_kills")
		"boss_down":
			return "%d/1" % _stat("boss_kills")
		"boss_hunter":
			return "%d/5" % _stat("boss_kills")
		"survivor_5":
			return "%ds/300s" % _stat("best_time")
		"survivor_10":
			return "%ds/600s" % _stat("best_time")
		"rich":
			return "%d/500" % _stat("total_coins")
		"wealthy":
			return "%d/1500" % _stat("total_coins")
		"victory":
			return "%d/1" % _stat("victories")
	return ""
