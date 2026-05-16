extends Node

signal player_damaged(amount: float)
signal player_died
signal player_level_up(new_level: int)
signal player_xp_gained(amount: float)

signal enemy_spawned(enemy: Node)
signal enemy_killed(enemy: Node, source: String)
signal boss_spawned(boss: Node)
signal boss_killed(boss: Node)

signal weapon_picked(key: String, level: int, rarity: String)
signal weapon_evolved(key: String)
signal synergy_unlocked(key: String)
signal relic_picked(key: String)

signal pickup_collected(kind: String, value: float)
signal chest_opened(chest: Node)
signal altar_used(kind: String)

signal coins_changed(total: int)
signal currency_changed(kind: String, value: int)
signal achievement_unlocked(key: String)

signal event_started(kind: String, label: String)
signal event_completed(kind: String)
signal event_failed(kind: String)
signal narrative_triggered(text: String)

signal screen_shake_requested(intensity: float, duration: float)
signal flash_requested(color: Color, duration: float)
signal damage_number_requested(world_pos: Vector2, value: float, color: Color)
signal floating_text_requested(world_pos: Vector2, text: String, color: Color)

signal scene_change_requested(scene_path: String)
signal game_paused(is_paused: bool)
signal game_over(won: bool, stats: Dictionary)

signal mail_received
signal announcement_received
