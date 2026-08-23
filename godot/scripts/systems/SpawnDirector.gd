extends Node

## Diretor de spawn: controla o ritmo da noite.
## Sobe a pressão com o tempo, solta elites, minichefes e chefes,
## e recicla inimigos que ficaram longe demais.

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")

const ENEMY_DIR := "res://resources/enemies/%s.tres"
const BOSS_VARIANTS := ["boss_base", "boss_warlock", "boss_frost"]
const FINAL_BOSS := "boss_final"
const MAX_ENEMIES := 130

## Pesos por fase da partida (segundos → { chave: peso })
const WAVE_TABLE := [
	{"until": 45.0,  "pool": {"shade": 60, "runner": 40}},
	{"until": 100.0, "pool": {"shade": 40, "runner": 30, "bat": 20, "slime": 10}},
	{"until": 180.0, "pool": {"shade": 25, "runner": 20, "bat": 15, "brute": 15, "archer": 15, "slime": 10}},
	{"until": 300.0, "pool": {"shade": 12, "runner": 15, "bat": 12, "brute": 15, "archer": 15, "exploder": 12, "charger": 10, "slime": 9}},
	{"until": 450.0, "pool": {"runner": 10, "bat": 12, "brute": 15, "archer": 14, "exploder": 14, "charger": 14, "summoner": 10, "slime": 6, "golem": 5}},
	{"until": 99999.0, "pool": {"runner": 10, "bat": 10, "brute": 14, "archer": 12, "exploder": 15, "charger": 15, "summoner": 12, "golem": 12}},
]

var enemy_cache: Dictionary = {}

var player: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null
var pickups_container: Node = null
var effects_container: Node = null
var map: Resource = null
var modifier: Dictionary = {}

var time_alive: float = 0.0
var spawn_timer: float = 2.0
var boss_timer: float = 180.0
var miniboss_timer: float = 90.0
var boss_index: int = 0
var boss_active: bool = false
var goal_seconds: float = 600.0
var final_boss_spawned: bool = false
var paused: bool = false

var _spawn_radius: float = 460.0
var _despawn_radius: float = 1300.0


func configure(
	p_player: Node2D,
	enemies_node: Node,
	projectiles_node: Node,
	pickups_node: Node,
	map_data: Resource,
	effects_node: Node = null,
	modifier_info: Dictionary = {}
) -> void:
	player = p_player
	enemies_container = enemies_node
	projectiles_container = projectiles_node
	pickups_container = pickups_node
	effects_container = effects_node
	map = map_data
	modifier = modifier_info
	time_alive = 0.0
	spawn_timer = 2.0
	boss_timer = 180.0
	miniboss_timer = 90.0
	_update_spawn_radius()
	EventBus.boss_despawned.connect(func(): boss_active = false)


func _update_spawn_radius() -> void:
	var viewport_size: Vector2 = Vector2(1080, 1920)
	if is_inside_tree():
		viewport_size = get_viewport().get_visible_rect().size
	var zoom: float = 1.0
	if player != null and is_instance_valid(player) and player.has_node("Camera"):
		zoom = maxf(0.1, (player.get_node("Camera") as Camera2D).zoom.x)
	var half_diag: float = (viewport_size / zoom).length() * 0.5
	_spawn_radius = half_diag + 90.0
	_despawn_radius = _spawn_radius * 2.6


func tick(delta: float) -> void:
	if paused or player == null or not is_instance_valid(player):
		return
	time_alive += delta

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var amount: int = _spawn_amount()
		for _i in range(amount):
			_spawn_regular_enemy()
		spawn_timer = _spawn_interval()

	miniboss_timer -= delta
	if miniboss_timer <= 0.0:
		spawn_miniboss()
		miniboss_timer = 100.0

	boss_timer -= delta
	if boss_timer <= 0.0 and not final_boss_spawned:
		spawn_boss()
		boss_timer = 180.0

	if int(time_alive * 2.0) % 4 == 0:
		_despawn_far_enemies()


# --- Ritmo -------------------------------------------------------------------

func _spawn_interval() -> float:
	# 2.2s no início → 0.28s aos 8 minutos
	return maxf(0.32, 2.2 - time_alive * 0.0035)


func _spawn_amount() -> int:
	var base: int = 1 + int(time_alive / 75.0)
	if time_alive > 300.0:
		base += 1
	return mini(base, 7)


func hp_mult() -> float:
	var minute_scale: float = 1.0 + time_alive / 150.0
	var diff: Dictionary = GameManager.difficulty_data()
	return minute_scale * float(diff.get("hp_mod", 1.0)) * float(modifier.get("hp_mult", 1.0))


func damage_mult() -> float:
	var diff: Dictionary = GameManager.difficulty_data()
	var scale: float = 1.0 + time_alive / 300.0
	return scale * float(diff.get("damage_mod", diff.get("hp_mod", 1.0))) * float(modifier.get("damage_taken_mult", 1.0))


func coin_mult() -> float:
	var diff: Dictionary = GameManager.difficulty_data()
	return float(diff.get("coin_mod", 1.0)) * float(modifier.get("coin_mult", 1.0))


func elite_chance() -> float:
	var base: float = 0.015 + clampf(time_alive / 600.0, 0.0, 1.0) * 0.09
	return clampf(base + float(modifier.get("elite_bias", 0.0)), 0.0, 0.35)


# --- Spawns ------------------------------------------------------------------

func _pool_for_time() -> Dictionary:
	for entry in WAVE_TABLE:
		if time_alive < float(entry["until"]):
			return entry["pool"]
	return WAVE_TABLE[WAVE_TABLE.size() - 1]["pool"]


func _choose_enemy_key() -> String:
	var pool: Dictionary = _pool_for_time()
	var total: int = 0
	for key in pool.keys():
		total += int(pool[key])
	var roll: int = randi() % maxi(1, total)
	var acc: int = 0
	for key in pool.keys():
		acc += int(pool[key])
		if roll < acc:
			return String(key)
	return "shade"


func _spawn_regular_enemy() -> void:
	if enemies_container == null or enemies_container.get_child_count() >= MAX_ENEMIES:
		return
	var key: String = _choose_enemy_key()
	var elite: bool = randf() < elite_chance()
	spawn_enemy(key, _random_offscreen_position(), elite)


func spawn_miniboss() -> void:
	spawn_enemy("miniboss", _random_offscreen_position(_spawn_radius * 1.1), false)
	var data: Resource = _load_enemy_data("miniboss")
	if data != null:
		EventBus.narrative_triggered.emit("⚔ %s apareceu!" % data.display_name)
		EventBus.sfx("boss", 0.6)


func spawn_boss() -> void:
	var key: String = BOSS_VARIANTS[boss_index % BOSS_VARIANTS.size()]
	boss_index += 1
	_announce_boss(key)


func spawn_final_boss() -> void:
	if final_boss_spawned:
		return
	final_boss_spawned = true
	_announce_boss(FINAL_BOSS)


func _announce_boss(key: String) -> void:
	spawn_enemy(key, _random_offscreen_position(_spawn_radius * 1.15), false)
	boss_active = true
	var data: Resource = _load_enemy_data(key)
	if data != null:
		EventBus.narrative_triggered.emit("⚠ %s surgiu!" % data.display_name)
		EventBus.toast(data.display_name, Color(0.949, 0.282, 0.420), "☠")
	EventBus.sfx("boss", 0.9)
	EventBus.screen_shake_requested.emit(0.7, 0.6)
	AudioManager.duck(2.0, -6.0)


## Chefe de arena: mais vida e dano que o chefe do relógio
func spawn_arena_boss(key: String, pos: Vector2) -> Node:
	var data: Resource = _load_enemy_data(key)
	if data == null or enemies_container == null:
		return null
	var enemy := ENEMY_SCENE.instantiate()
	enemies_container.add_child(enemy)
	enemy.global_position = pos
	enemy.setup(
		data, player, enemies_container, projectiles_container, pickups_container,
		hp_mult() * 1.6, damage_mult() * 1.15, coin_mult() * 2.0, false, effects_container
	)
	boss_active = true
	EventBus.sfx("boss", 1.0)
	AudioManager.duck(2.5, -7.0)
	return enemy


## Usado por eventos (horda elite, altares, etc.)
func spawn_wave(key: String, count: int, elite: bool = false, distance: float = -1.0) -> void:
	var dist: float = distance if distance > 0.0 else _spawn_radius
	for i in range(count):
		var angle: float = float(i) / float(maxi(1, count)) * TAU + randf() * 0.4
		var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist
		spawn_enemy(key, _clamp_to_map(pos), elite)


func spawn_enemy(key: String, spawn_pos: Vector2, elite: bool = false) -> Node:
	var data: Resource = _load_enemy_data(key)
	if data == null or enemies_container == null:
		return null
	var enemy := ENEMY_SCENE.instantiate()
	enemies_container.add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.setup(
		data, player, enemies_container, projectiles_container, pickups_container,
		hp_mult(), damage_mult(), coin_mult(), elite, effects_container
	)
	return enemy


func _load_enemy_data(key: String) -> Resource:
	if enemy_cache.has(key):
		return enemy_cache[key]
	var path: String = ENEMY_DIR % key
	if not ResourceLoader.exists(path):
		push_warning("Inimigo inexistente: %s" % key)
		return null
	var res: Resource = load(path)
	enemy_cache[key] = res
	return res


func _random_offscreen_position(distance: float = -1.0) -> Vector2:
	var dist: float = distance if distance > 0.0 else _spawn_radius
	var angle: float = randf() * TAU
	return _clamp_to_map(player.global_position + Vector2(cos(angle), sin(angle)) * dist)


func _clamp_to_map(pos: Vector2) -> Vector2:
	if map == null:
		return pos
	return Vector2(
		clampf(pos.x, 40.0, float(map.world_width - 40)),
		clampf(pos.y, 40.0, float(map.world_height - 40))
	)


## Inimigos muito longe são removidos (economiza CPU e evita "caudas" infinitas).
func _despawn_far_enemies() -> void:
	if enemies_container == null:
		return
	var limit_sq: float = _despawn_radius * _despawn_radius
	for e in enemies_container.get_children():
		if not (e is Node2D):
			continue
		if "data" in e and e.data != null and e.data.is_boss():
			continue
		if player.global_position.distance_squared_to(e.global_position) > limit_sq:
			e.queue_free()


func enemy_count() -> int:
	return enemies_container.get_child_count() if enemies_container != null else 0


## Mata tudo na tela (item bomba)
func nuke_screen(damage: float = 99999.0) -> int:
	var killed: int = 0
	if enemies_container == null:
		return 0
	for e in enemies_container.get_children():
		if not e.has_method("take_damage"):
			continue
		if "data" in e and e.data != null and e.data.is_boss():
			e.take_damage(damage * 0.05, 0.0, Vector2.UP, "bomb", false)
			continue
		e.take_damage(damage, 300.0, (e.global_position - player.global_position).normalized(), "bomb", false)
		killed += 1
	EventBus.screen_shake_requested.emit(1.0, 0.4)
	EventBus.flash_requested.emit(Color(1.0, 0.8, 0.4, 0.4), 0.3)
	return killed
