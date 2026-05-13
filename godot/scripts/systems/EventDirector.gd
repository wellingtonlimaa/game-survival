extends Node

# Eventos especiais que rolam durante a partida
# Tipos: meteor_rain, mist, elite_horde, gem_rain

const EVENT_INFO := {
	"meteor_rain":  { "label": "Chuva de Meteoros", "duration": 10.0, "min_time": 75.0 },
	"mist":         { "label": "Neblina Espessa",   "duration": 12.0, "min_time": 120.0 },
	"elite_horde":  { "label": "Horda Elite",       "duration": 14.0, "min_time": 90.0 },
	"gem_rain":     { "label": "Chuva de Gemas",    "duration": 7.0,  "min_time": 30.0 },
}

const GEM_SCENE := preload("res://scenes/pickups/Gem.tscn")

var player: Node2D = null
var pickups_container: Node = null
var spawn_director: Node = null  # pra elite_horde
var effects_container: Node = null
var hud_layer: CanvasLayer = null

var time_alive: float = 0.0
var event_timer: float = 32.0  # primeiro evento após 32s
var current_event: String = ""
var event_remaining: float = 0.0

# Estado dos efeitos persistentes
var meteor_strike_timer: float = 0.0
var meteor_count_left: int = 0
var fog_overlay: ColorRect = null


func configure(p_player: Node2D, p_pickups: Node, p_spawner: Node, p_effects: Node, p_hud_layer: CanvasLayer) -> void:
	player = p_player
	pickups_container = p_pickups
	spawn_director = p_spawner
	effects_container = p_effects
	hud_layer = p_hud_layer


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


func _start_random_event() -> void:
	var candidates: Array = []
	for key in EVENT_INFO.keys():
		var info: Dictionary = EVENT_INFO[key]
		if time_alive < float(info["min_time"]):
			continue
		candidates.append(key)
	if candidates.is_empty():
		event_timer = 18.0
		return

	current_event = String(candidates[randi() % candidates.size()])
	var info: Dictionary = EVENT_INFO[current_event]
	event_remaining = float(info["duration"])

	EventBus.event_started.emit(current_event, String(info["label"]))
	EventBus.narrative_triggered.emit("✦ %s" % String(info["label"]))

	match current_event:
		"meteor_rain":
			meteor_count_left = 14
			meteor_strike_timer = 0.0
		"mist":
			_spawn_fog()
		"elite_horde":
			_spawn_elite_wave()
		"gem_rain":
			_spawn_gem_rain()


func _tick_active_event(delta: float) -> void:
	match current_event:
		"meteor_rain":
			meteor_strike_timer -= delta
			if meteor_strike_timer <= 0.0 and meteor_count_left > 0:
				_strike_meteor()
				meteor_strike_timer = randf_range(0.5, 1.0)
				meteor_count_left -= 1


func _end_event() -> void:
	var ended: String = current_event
	current_event = ""
	event_remaining = 0.0
	event_timer = randf_range(28.0, 42.0)

	if fog_overlay != null:
		var tween: Tween = fog_overlay.create_tween()
		tween.tween_property(fog_overlay, "modulate:a", 0.0, 0.6)
		tween.tween_callback(fog_overlay.queue_free)
		fog_overlay = null

	EventBus.event_completed.emit(ended)


func _strike_meteor() -> void:
	if effects_container == null or player == null:
		return
	# Aleatoriza posição em torno do player
	var offset: Vector2 = Vector2(randf_range(-280.0, 280.0), randf_range(-280.0, 280.0))
	var pos: Vector2 = player.global_position + offset

	# Marca visual no chão (warning), depois explosão
	var marker := _MeteorMarker.new()
	marker.global_position = pos
	effects_container.add_child(marker)
	marker.start(player)


class _MeteorMarker extends Node2D:
	var elapsed: float = 0.0
	const WARN_TIME := 0.6
	const RADIUS := 90.0
	var target_player: Node2D

	func start(p: Node2D) -> void:
		target_player = p
		z_index = 5

	func _process(delta: float) -> void:
		elapsed += delta
		queue_redraw()
		if elapsed >= WARN_TIME:
			_strike()
			queue_free()

	func _strike() -> void:
		EventBus.screen_shake_requested.emit(0.55, 0.25)
		EventBus.flash_requested.emit(Color(1, 0.561, 0.243, 0.35), 0.2)
		# Dano em área
		var dmg: float = 28.0
		if is_instance_valid(target_player):
			var dist: float = global_position.distance_to(target_player.global_position)
			if dist < RADIUS:
				if target_player.has_method("apply_damage_to_player"):
					target_player.apply_damage_to_player(dmg * 0.7)
		# Dano em inimigos próximos
		var world := get_tree().current_scene
		if world == null:
			return
		var enemies := world.find_child("Enemies", true, false)
		if enemies == null:
			return
		for e in enemies.get_children():
			if not (e is Node2D):
				continue
			var d: float = global_position.distance_to(e.global_position)
			if d < RADIUS and e.has_method("take_damage"):
				var dir: Vector2 = (e.global_position - global_position).normalized()
				e.take_damage(dmg, 120.0, dir, "meteor")

	func _draw() -> void:
		var t: float = clamp(elapsed / WARN_TIME, 0.0, 1.0)
		if elapsed < WARN_TIME:
			draw_circle(Vector2.ZERO, RADIUS, Color(1, 0.561, 0.243, 0.18))
			draw_arc(Vector2.ZERO, RADIUS - 4.0, 0.0, t * TAU, 32, Color(1, 0.776, 0.298, 0.85), 3.0)
		else:
			draw_circle(Vector2.ZERO, RADIUS * 1.1, Color(1, 0.776, 0.298, 0.55))


func _spawn_fog() -> void:
	if hud_layer == null:
		return
	fog_overlay = ColorRect.new()
	fog_overlay.color = Color(0.071, 0.063, 0.118, 0.55)
	fog_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fog_overlay.modulate.a = 0.0
	hud_layer.add_child(fog_overlay)
	var tween := fog_overlay.create_tween()
	tween.tween_property(fog_overlay, "modulate:a", 1.0, 0.6)


func _spawn_elite_wave() -> void:
	if spawn_director == null or player == null:
		return
	# Spawna ~5 inimigos elites em volta
	var enemy_path: String = "res://resources/enemies/brute.tres"
	if not ResourceLoader.exists(enemy_path):
		return
	var enemy_scene: PackedScene = preload("res://scenes/enemies/Enemy.tscn")
	var enemies_container: Node = spawn_director.enemies_container
	if enemies_container == null:
		return
	var data: Resource = load(enemy_path)
	for i in range(5):
		var angle: float = float(i) / 5.0 * TAU
		var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * 360.0
		var minion := enemy_scene.instantiate()
		enemies_container.add_child(minion)
		minion.global_position = pos
		minion.setup(data, player, enemies_container, spawn_director.projectiles_container, spawn_director.pickups_container, spawn_director._hp_mult() * 1.5, spawn_director._damage_mult() * 1.3, spawn_director._coin_mult() * 1.5)


func _spawn_gem_rain() -> void:
	if pickups_container == null or player == null:
		return
	for i in range(10):
		var angle: float = randf() * TAU
		var dist: float = randf_range(60.0, 220.0)
		var gem := GEM_SCENE.instantiate()
		pickups_container.add_child(gem)
		gem.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		gem.setup(3, player)
