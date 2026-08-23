extends Node

## Barramento global de eventos.
## Nenhum sistema conhece o outro: todos conversam por aqui.

# --- Jogador ---
signal player_damaged(amount: float)
signal player_healed(amount: float)
signal player_died
signal player_revived
signal player_level_up(new_level: int)
signal player_xp_gained(amount: float)
signal player_dashed
signal player_stats_changed

# --- Inimigos ---
signal enemy_spawned(enemy: Node)
signal enemy_damaged(enemy: Node, amount: float, is_crit: bool)
signal enemy_killed(enemy: Node, source: String)
signal boss_spawned(boss: Node)
signal boss_killed(boss: Node)
signal boss_hp_changed(current: float, maximum: float, name: String)
signal boss_despawned

# --- Armas / build ---
signal weapon_picked(key: String, level: int, rarity: String)
signal weapon_evolved(key: String)
signal weapon_fired(key: String)
signal synergy_unlocked(key: String)
signal relic_picked(key: String)
signal passive_picked(key: String, level: int)
signal loadout_changed

# --- Pickups / economia da run ---
signal pickup_collected(kind: String, value: float)
signal run_coins_changed(total: int)
signal chest_opened(chest: Node)
signal altar_used(kind: String)
signal combo_changed(count: int, timer_pct: float)

# --- Meta ---
signal coins_changed(total: int)
signal currency_changed(kind: String, value: int)
signal achievement_unlocked(key: String)
signal codex_entry_seen(category: String, key: String)

# --- Diretor de eventos ---
signal event_started(kind: String, label: String)
signal event_completed(kind: String)
signal event_failed(kind: String)
signal narrative_triggered(text: String)
signal toast_requested(text: String, color: Color, icon: String)

# --- Feedback audiovisual ---
signal screen_shake_requested(intensity: float, duration: float)
signal flash_requested(color: Color, duration: float)
signal hitstop_requested(duration: float)
signal damage_number_requested(world_pos: Vector2, value: float, color: Color)
signal crit_number_requested(world_pos: Vector2, value: float, color: Color)
signal floating_text_requested(world_pos: Vector2, text: String, color: Color)
signal impact_requested(world_pos: Vector2, color: Color, power: float)
signal explosion_requested(world_pos: Vector2, radius: float, color: Color)
signal sfx_requested(key: String, volume: float)

# --- Fluxo de cena ---
signal scene_change_requested(scene_path: String)
signal game_paused(is_paused: bool)
signal game_over(won: bool, stats: Dictionary)

# --- Menu ---
signal mail_received
signal announcement_received


## Atalho usado por todo mundo: EventBus.sfx("hit")
func sfx(key: String, volume: float = 1.0) -> void:
	sfx_requested.emit(key, volume)


## Atalho de feedback de impacto (spark + som + shake curto)
func punch(world_pos: Vector2, color: Color, power: float = 1.0) -> void:
	impact_requested.emit(world_pos, color, power)


func toast(text: String, color: Color = Color(1.0, 0.776, 0.298), icon: String = "") -> void:
	toast_requested.emit(text, color, icon)
