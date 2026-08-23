class_name RunFinalizer
extends RefCounted

## Ponte entre a meta-progressão e a partida:
## aplica tudo que foi comprado antes da run e guarda o resultado depois.

# --- Antes da run ------------------------------------------------------------

static func apply_pre_run(player: Node2D) -> void:
	var character: Resource = CharacterRegistry.selected()
	if character != null:
		player.max_hp *= character.hp_mult
		player.hp = player.max_hp
		player.speed *= character.speed_mult
		player.damage_mult += character.damage_mult_bonus
		player.armor += character.armor_bonus
		player.luck += character.luck_bonus
		player.regen += character.regen_bonus
		player.pickup_radius += character.pickup_bonus
		player.xp_mult += character.xp_mult_bonus
		if player.has_node("Sprite"):
			var sprite: Node = player.get_node("Sprite")
			sprite.color_body = character.body_color
			sprite.color_head = character.head_color
			sprite.color_eyes = character.eye_color
			sprite.color_cape = character.body_color.darkened(0.28)

	# Loja permanente
	var upgrades: Dictionary = SaveSystem.get_value("permanent_upgrades", {})
	player.max_hp += 8.0 * int(upgrades.get("max_hp", 0))
	player.hp = player.max_hp
	player.damage_mult += 0.04 * int(upgrades.get("damage", 0))
	player.xp_mult += 0.05 * int(upgrades.get("xp_gain", 0))
	player.speed += 6.0 * int(upgrades.get("move", 0))
	player.luck += 0.04 * int(upgrades.get("luck", 0))
	player.armor += 0.4 * int(upgrades.get("armor", 0))
	player.pickup_radius += 10.0 * int(upgrades.get("magnet", 0))
	player.crit_chance += 0.015 * int(upgrades.get("crit", 0))
	player.coin_mult += 0.05 * int(upgrades.get("greed", 0))

	# Talentos de prestígio
	var talents: Dictionary = SaveSystem.get_value("talents", {})
	var prestige: int = int(SaveSystem.get_value("prestige", 0))
	var prestige_bonus: float = 1.0 + prestige * 0.03

	var survival_lvl: int = int(talents.get("survival", 0))
	var weaponry_lvl: int = int(talents.get("weaponry", 0))
	var collector_lvl: int = int(talents.get("collector", 0))
	var fortune_lvl: int = int(talents.get("fortune", 0))
	var tempo_lvl: int = int(talents.get("tempo", 0))
	var growth_lvl: int = int(talents.get("growth", 0))

	player.max_hp += 14.0 * survival_lvl
	player.hp = player.max_hp
	player.regen += 0.1 * survival_lvl
	player.damage_mult += 0.06 * weaponry_lvl * prestige_bonus
	player.pickup_radius += 18.0 * collector_lvl
	player.xp_mult += 0.03 * collector_lvl + 0.04 * growth_lvl
	player.luck += 0.08 * fortune_lvl
	player.coin_mult += 0.06 * fortune_lvl
	if tempo_lvl > 0:
		player.cooldown_mult *= pow(0.97, float(tempo_lvl))

	# Bônus global de prestígio
	player.damage_mult *= prestige_bonus
	player.max_hp *= prestige_bonus
	player.hp = player.max_hp

	player.hp_changed.emit(player.hp, player.max_hp)
	player.xp_changed.emit(player.xp, player.xp_to_next, player.level)


# --- Depois da run -----------------------------------------------------------

static func finalize(stats: Dictionary) -> Dictionary:
	var won: bool = bool(stats.get("won", false))
	var time_alive: int = int(stats.get("time", 0))
	var kills: int = int(stats.get("kills", 0))
	var run_coins: int = int(stats.get("coins", 0))
	var boss_kills: int = int(stats.get("boss_kills", 0))
	var evolved_weapons: int = int(stats.get("evolved", 0))
	var level: int = int(stats.get("level", 1))

	# Moedas: as coletadas na run + bônus por tempo/chefes + vitória
	var time_bonus: int = int(time_alive / 6)
	var boss_bonus: int = boss_kills * 40
	var victory_bonus: int = 250 if won else 0
	var coin_total: int = run_coins + time_bonus + boss_bonus + victory_bonus
	if GameManager.energy_bonus:
		coin_total = int(round(float(coin_total) * 1.2))
	SaveSystem.add_coins(coin_total)

	var previous_best: int = int(SaveSystem.get_value("best_time", 0))
	var is_record: bool = time_alive > previous_best

	SaveSystem.set_value("total_kills", int(SaveSystem.get_value("total_kills", 0)) + kills)
	SaveSystem.set_value("total_runs", int(SaveSystem.get_value("total_runs", 0)) + 1)
	SaveSystem.set_value("boss_kills", int(SaveSystem.get_value("boss_kills", 0)) + boss_kills)
	SaveSystem.set_value("evolved_weapons", int(SaveSystem.get_value("evolved_weapons", 0)) + evolved_weapons)
	if is_record:
		SaveSystem.set_value("best_time", time_alive)
	if kills > int(SaveSystem.get_value("best_kills", 0)):
		SaveSystem.set_value("best_kills", kills)
	if level > int(SaveSystem.get_value("best_level", 1)):
		SaveSystem.set_value("best_level", level)
	if won:
		SaveSystem.set_value("victories", int(SaveSystem.get_value("victories", 0)) + 1)

	var run_record := {
		"time": time_alive,
		"kills": kills,
		"coins": coin_total,
		"level": level,
		"character": GameManager.selected_character,
		"difficulty": GameManager.selected_difficulty,
		"map": String(stats.get("map", MapRegistry.selected_key)),
		"modifier": String(stats.get("modifier", "calm")),
		"won": won,
		"date": Time.get_datetime_string_from_system(false, true),
	}
	var history: Array = (SaveSystem.get_value("history", []) as Array).duplicate()
	history.push_front(run_record)
	if history.size() > 12:
		history.resize(12)
	SaveSystem.set_value("history", history)

	var ranking: Array = (SaveSystem.get_value("ranking", []) as Array).duplicate()
	ranking.append(run_record)
	ranking.sort_custom(func(a, b): return int(a.get("time", 0)) > int(b.get("time", 0)))
	if ranking.size() > 10:
		ranking.resize(10)
	SaveSystem.set_value("ranking", ranking)

	# Fragmentos de Lua: 1 por chefe + 5 pela vitória (compram armas na loja)
	var gems: int = boss_kills + (5 if won else 0)
	if gems > 0:
		SaveSystem.add_gems(gems)

	var unlocked: Array = UnlockManager.check_unlocks_after_run()

	var meta_xp: int = _compute_meta_xp(kills, time_alive, boss_kills, evolved_weapons, won)
	var level_result: Dictionary = ProgressionManager.add_meta_xp(meta_xp)
	SaveSystem.save_now()

	return {
		"coin_total": coin_total,
		"bonus": victory_bonus,
		"time_bonus": time_bonus,
		"boss_bonus": boss_bonus,
		"meta_xp": meta_xp,
		"new_meta_level": int(level_result.get("new_level", 1)),
		"start_meta_level": int(level_result.get("start_level", 1)),
		"leveled_up": bool(level_result.get("leveled_up", false)),
		"level_coin_bonus": int(level_result.get("coin_bonus", 0)),
		"unlocks": unlocked,
		"best_time": int(SaveSystem.get_value("best_time", 0)),
		"is_record": is_record,
		"gems": gems,
	}


static func _compute_meta_xp(kills: int, time_alive: int, boss_kills: int, evolved: int, won: bool) -> int:
	var xp: int = 0
	xp += kills
	xp += int(time_alive / 2)
	xp += boss_kills * 25
	xp += evolved * 50
	if won:
		xp += 150
	return xp
