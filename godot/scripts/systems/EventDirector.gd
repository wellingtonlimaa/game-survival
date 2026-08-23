extends Node

## Eventos de arena: quebram a rotina da partida a cada ~30s.

const PICKUP_SCENE := preload("res://scenes/pickups/Pickup.tscn")
const AREA_EFFECT_SCENE := preload("res://scenes/effects/AreaEffect.tscn")
const P := preload("res://scripts/utils/Theme.gd")

const EVENT_INFO := {
	"meteor_rain": {"label": "Chuva de Meteoros", "icon": "☄", "duration": 10.0, "min_time": 70.0, "color": Color(1.0, 0.561, 0.243)},
	"mist":        {"label": "Neblina Espessa",  "icon": "🌫", "duration": 12.0, "min_time": 120.0, "color": Color(0.722, 0.694, 0.808)},
	"elite_horde": {"label": "Horda Elite",      "icon": "☠", "duration": 14.0, "min_time": 100.0, "color": Color(0.886, 0.275, 0.345)},
	"gem_rain":    {"label": "Chuva de Gemas",   "icon": "💎", "duration": 6.0,  "min_time": 25.0, "color": Color(0.553, 0.412, 0.886)},
	"coin_rain":   {"label": "Chuva de Moedas",  "icon": "🪙", "duration": 6.0,  "min_time": 45.0, "color": Color(1.0, 0.776, 0.298)},
	"frenzy":      {"label": "Fúria Sangrenta",  "icon": "🔥", "duration": 12.0, "min_time": 60.0, "color": Color(1.0, 0.35, 0.35)},
	"treasure":    {"label": "Tesouro Perdido",  "icon": "📦", "duration": 4.0,  "min_time": 90.0, "color": Color(1.0, 0.776, 0.298)},
}

var player: Node2D = null
var pickups_container: Node = null
var spawn_director: Node = null
var effects_container: Node = null
var screen_effects: Node = null
var enemies_container: Node = null

var time_alive: float = 0.0
var event_timer: float = 28.0
var current_event: String = ""
var event_remaining: float = 0.0

var meteor_strike_timer: float = 0.0
var meteor_count_left: int = 0
var _frenzy_applied: bool = false


func configure(p_player: Node2D, p_pickups: Node, p_spawner: Node, p_effects: Node, p_screen_effects: Node = null, p_enemies: Node = null) -> void:
	player = p_player
	pickups_container = p_pickups
	spawn_director = p_spawner
	effects_container = p_effects
	screen_effects = p_screen_effects
	enemies_container = p_enemies


func tick(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	time_alive += delta

	if current_event == "":
		event_timer -= delta
		if event_timer <= 0.0:
			_start_random_event()
	else:
		event_remaining -= delta
		_tick_active_event(delta)
		if event_remaining <= 0.0:
			_end_event()


func event_progress() -> float:
	if current_event == "":
		return 0.0
	var total: float = float(EVENT_INFO[current_event]["duration"])
	return clampf(event_remaining / total, 0.0, 1.0)


func event_label() -> String:
	if current_event == "":
		return ""
	var info: Dictionary = EVENT_INFO[current_event]
	return "%s %s" % [String(info["icon"]), String(info["label"])]


func _start_random_event() -> void:
	var candidates: Array = []
	for key in EVENT_INFO.keys():
		if time_alive >= float(EVENT_INFO[key]["min_time"]):
			candidates.append(key)
	if candidates.is_empty():
		event_timer = 15.0
		return

	current_event = String(candidates[randi() % candidates.size()])
	var info: Dictionary = EVENT_INFO[current_event]
	event_remaining = float(info["duration"])

	EventBus.event_started.emit(current_event, String(info["label"]))
	EventBus.toast(String(info["label"]), info["color"], String(info["icon"]))
	EventBus.sfx("chest", 0.6)

	match current_event:
		"meteor_rain":
			meteor_count_left = 16
			meteor_strike_timer = 0.0
		"mist":
			if screen_effects != null and screen_effects.has_method("set_darkness"):
				screen_effects.set_darkness(0.5)
		"elite_horde":
			_spawn_elite_wave()
		"gem_rain":
			_spawn_rain("xp", 14, 10)
		"coin_rain":
			_spawn_rain("coin", 12, 4)
		"frenzy":
			_apply_frenzy(true)
		"treasure":
			_spawn_treasure()


func _tick_active_event(delta: float) -> void:
	match current_event:
		"meteor_rain":
			meteor_strike_timer -= delta
			if meteor_strike_timer <= 0.0 and meteor_count_left > 0:
				_strike_meteor()
				meteor_strike_timer = randf_range(0.35, 0.75)
				meteor_count_left -= 1


func _end_event() -> void:
	var ended: String = current_event
	current_event = ""
	event_remaining = 0.0
	event_timer = randf_range(26.0, 40.0)

	if ended == "mist" and screen_effects != null and screen_effects.has_method("set_darkness"):
		screen_effects.set_darkness(0.0)
	if ended == "frenzy":
		_apply_frenzy(false)

	EventBus.event_completed.emit(ended)


func _apply_frenzy(on: bool) -> void:
	if player == null or not is_instance_valid(player):
		return
	if on and not _frenzy_applied:
		_frenzy_applied = true
		player.cooldown_mult *= 0.6
		player.speed *= 1.12
		EventBus.flash_requested.emit(Color(1.0, 0.35, 0.35, 0.2), 0.3)
	elif not on and _frenzy_applied:
		_frenzy_applied = false
		player.cooldown_mult /= 0.6
		player.speed /= 1.12


func _strike_meteor() -> void:
	if effects_container == null or player == null:
		return
	var offset: Vector2 = Vector2(randf_range(-320.0, 320.0), randf_range(-320.0, 320.0))
	var pos: Vector2 = player.global_position + offset

	var marker := _MeteorMarker.new()
	marker.global_position = pos
	effects_container.add_child(marker)
	marker.start(player, enemies_container)


class _MeteorMarker extends Node2D:
	const WARN_TIME := 0.75
	const RADIUS := 95.0
	var elapsed: float = 0.0
	var target_player: Node2D
	var enemies: Node

	func start(p: Node2D, e: Node) -> void:
		target_player = p
		enemies = e
		z_index = 5

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= WARN_TIME + 0.18:
			queue_free()
		elif elapsed >= WARN_TIME and not is_queued_for_deletion():
			_strike()

	func _strike() -> void:
		set_process(false)
		EventBus.screen_shake_requested.emit(0.5, 0.22)
		EventBus.sfx("explosion", 0.45)
		EventBus.explosion_requested.emit(global_position, RADIUS, Color(1.0, 0.561, 0.243))
		var dmg: float = 34.0
		if is_instance_valid(target_player):
			var dist: float = global_position.distance_to(target_player.global_position)
			if dist < RADIUS and target_player.has_method("apply_damage_to_player"):
				target_player.apply_damage_to_player(dmg * 0.6)
		if enemies != null and is_instance_valid(enemies):
			for e in enemies.get_children():
				if not e.has_method("take_damage"):
					continue
				var d: float = global_position.distance_to(e.global_position)
				if d < RADIUS:
					e.take_damage(dmg * 2.4, 160.0, (e.global_position - global_position).normalized(), "meteor", false)
					if e.has_method("apply_status"):
						e.apply_status("burn", 6.0, 3.0)
		queue_free()

	func _draw() -> void:
		var t: float = clampf(elapsed / WARN_TIME, 0.0, 1.0)
		if elapsed < WARN_TIME:
			draw_circle(Vector2.ZERO, RADIUS, Color(1, 0.561, 0.243, 0.16))
			draw_arc(Vector2.ZERO, RADIUS - 4.0, -PI / 2.0, -PI / 2.0 + t * TAU, 32, Color(1, 0.776, 0.298, 0.9), 3.0)
			# Meteoro caindo
			var fall: Vector2 = Vector2(0, -420.0 * (1.0 - t))
			draw_circle(fall, 10.0, Color(1.0, 0.6, 0.25))
			draw_circle(fall + Vector2(0, -14), 6.0, Color(1.0, 0.85, 0.4, 0.6))


func _spawn_elite_wave() -> void:
	if spawn_director == null or player == null:
		return
	spawn_director.spawn_wave("brute", 4, true, 380.0)
	spawn_director.spawn_wave("charger", 3, true, 420.0)
	EventBus.screen_shake_requested.emit(0.4, 0.3)


func _spawn_rain(kind: String, count: int, value: int) -> void:
	if pickups_container == null or player == null:
		return
	for i in range(count):
		var angle: float = randf() * TAU
		var dist: float = randf_range(70.0, 260.0)
		var item := PICKUP_SCENE.instantiate()
		pickups_container.add_child(item)
		item.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		item.setup(kind, value, player)


func _spawn_treasure() -> void:
	if pickups_container == null or player == null:
		return
	var angle: float = randf() * TAU
	var chest := PICKUP_SCENE.instantiate()
	pickups_container.add_child(chest)
	chest.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(280.0, 420.0)
	chest.setup("chest", 1, player)
	# Item de apoio junto do baú
	var extra := PICKUP_SCENE.instantiate()
	pickups_container.add_child(extra)
	extra.global_position = chest.global_position + Vector2(40, 0)
	extra.setup("magnet" if randf() < 0.5 else "bomb", 1, player)
