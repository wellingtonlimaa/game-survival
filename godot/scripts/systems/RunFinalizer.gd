class_name RunFinalizer
extends RefCounted

# Aplica todos os bônus persistentes ao Player no início da run
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
			var sprite = player.get_node("Sprite")
			sprite.color_body = character.body_color
			sprite.color_head = character.head_color
			sprite.color_eyes = character.eye_color

	# Permanent shop upgrades
	var upgrades: Dictionary = SaveSystem.get_value("permanent_upgrades", {})
	var max_hp_lvl: int = int(upgrades.get("max_hp", 0))
	var dmg_lvl: int = int(upgrades.get("damage", 0))
	var xp_lvl: int = int(upgrades.get("xp_gain", 0))
	var move_lvl: int = int(upgrades.get("move", 0))
	var luck_lvl: int = int(upgrades.get("luck", 0))
	var armor_lvl: int = int(upgrades.get("armor", 0))
	var magnet_lvl: int = int(upgrades.get("magnet", 0))
	player.max_hp += 8.0 * max_hp_lvl
	player.hp = player.max_hp
	player.damage_mult += 0.04 * dmg_lvl
	player.xp_mult += 0.05 * xp_lvl
	player.speed += 6.0 * move_lvl
	player.luck += 0.04 * luck_lvl
	player.armor += 0.4 * armor_lvl
	player.pickup_radius += 10.0 * magnet_lvl

	# Talents (prestige tree)
	var talents: Dictionary = SaveSystem.get_value("talents", {})
	var prestige: int = int(SaveSystem.get_value("prestige", 0))
	var prestige_bonus: float = 1.0 + prestige * 0.03

	var survival_lvl: int = int(talents.get("survival", 0))
	var weaponry_lvl: int = int(talents.get("weaponry", 0))
	var collector_lvl: int = int(talents.get("collector", 0))
	var fortune_lvl: int = int(talents.get("fortune", 0))
	var growth_lvl: int = int(talents.get("growth", 0))

	player.max_hp += 12.0 * survival_lvl
	player.hp = player.max_hp
	player.regen += 0.08 * survival_lvl
	player.damage_mult += 0.06 * weaponry_lvl * prestige_bonus
	player.pickup_radius += 18.0 * collector_lvl
	player.luck += 0.08 * fortune_lvl
	player.xp_mult += 0.04 * growth_lvl

	player.hp_changed.emit(player.hp, player.max_hp)
	player.xp_changed.emit(player.xp, player.xp_to_next, player.level)


# Salva resultado da run no save
static func finalize(stats: Dictionary) -> Dictionary:
	var won: bool = bool(stats.get("won", false))
	var time_alive: int = int(stats.get("time", 0))
	var kills: int = int(stats.get("kills", 0))
	var coins: int = int(stats.get("coins", 0))
	var boss_kills: int = int(stats.get("boss_kills", 0))
	var evolved_weapons: int = int(stats.get("evolved", 0))
	var level: int = int(stats.get("level", 1))

	# Vitória dá bônus de moedas
	var coin_total: int = coins + (120 if won else 0)
	SaveSystem.add_coins(coin_total)

	# Stats acumulados
	var total_kills: int = int(SaveSystem.get_value("total_kills", 0)) + kills
	SaveSystem.set_value("total_kills", total_kills)

	if time_alive > int(SaveSystem.get_value("best_time", 0)):
		SaveSystem.set_value("best_time", time_alive)

	var total_boss: int = int(SaveSystem.get_value("boss_kills", 0)) + boss_kills
	SaveSystem.set_value("boss_kills", total_boss)

	var total_evolved: int = int(SaveSystem.get_value("evolved_weapons", 0)) + evolved_weapons
	SaveSystem.set_value("evolved_weapons", total_evolved)

	# Ranking + histórico
	var run_record := {
		"time": time_alive,
		"kills": kills,
		"coins": coin_total,
		"level": level,
		"character": GameManager.selected_character,
		"difficulty": GameManager.selected_difficulty,
		"map": MapRegistry.selected_key,
		"won": won,
	}
	var history: Array = SaveSystem.get_value("history", []).duplicate()
	history.push_front(run_record)
	if history.size() > 10:
		history.resize(10)
	SaveSystem.set_value("history", history)

	var ranking: Array = SaveSystem.get_value("ranking", []).duplicate()
	ranking.append(run_record)
	ranking.sort_custom(func(a, b): return int(a.get("time", 0)) > int(b.get("time", 0)))
	if ranking.size() > 10:
		ranking.resize(10)
	SaveSystem.set_value("ranking", ranking)

	# Energia regenera pouco entre runs (regen via tempo seria ideal)
	var energy: int = int(SaveSystem.get_value("energy", 0))
	SaveSystem.set_value("energy", min(int(SaveSystem.get_value("max_energy", 60)), energy + 5))

	UnlockManager.check_unlocks_after_run()

	return {
		"coin_total": coin_total,
		"bonus": 120 if won else 0,
	}
