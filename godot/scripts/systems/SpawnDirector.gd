extends Node

const ENEMY_SCENE := preload("res://scenes/enemies/Enemy.tscn")

const ENEMY_PATHS := {
	"shade":        "res://resources/enemies/shade.tres",
	"runner":       "res://resources/enemies/runner.tres",
	"brute":        "res://resources/enemies/brute.tres",
	"archer":       "res://resources/enemies/archer.tres",
	"exploder":     "res://resources/enemies/exploder.tres",
	"summoner":     "res://resources/enemies/summoner.tres",
	"miniboss":     "res://resources/enemies/miniboss.tres",
	"boss_base":    "res://resources/enemies/boss_base.tres",
	"boss_warlock": "res://resources/enemies/boss_warlock.tres",
	"boss_frost":   "res://resources/enemies/boss_frost.tres",
}

const BOSS_VARIANTS := ["boss_base", "boss_warlock", "boss_frost"]

const MAX_ENEMIES := 220

var enemy_cache: Dictionary = {}

var player: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null
var pickups_container: Node = null
var map: Resource = null

var time_alive: float = 0.0
var spawn_timer: float = 1.0
var boss_timer: float = 120.0
var miniboss_timer: float = 75.0
var boss_index: int = 0


func configure(p_player: Node2D, enemies_node: Node, projectiles_node: Node, pickups_node: Node, map_data: Resource) -> void:
	player = p_player
	enemies_container = enemies_node
	projectiles_container = projectiles_node
	pickups_container = pickups_node
	map = map_data
	time_alive = 0.0
	spawn_timer = 1.0
	boss_timer = 120.0
	miniboss_timer = 75.0


func tick(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	time_alive += delta

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		var amount: int = _spawn_amount()
		for _i in range(amount):
			_spawn_regular_enemy()
		spawn_timer = _spawn_interval()

	miniboss_timer -= delta
	if miniboss_timer <= 0.0 and time_alive > 60.0:
		_spawn_miniboss()
		miniboss_timer = 75.0

	boss_timer -= delta
	if boss_timer <= 0.0:
		_spawn_boss()
		boss_timer = 120.0


func _spawn_interval() -> float:
	return max(0.12, 0.74 - time_alive * 0.0022)


func _spawn_amount() -> int:
	var base: int = 1 + int(time_alive / 30.0) / 4
	if time_alive > 180.0:
		base += 1
	return base


func _choose_enemy_key() -> String:
	# Probabilidades evoluem por tempo
	var t: float = time_alive
	var roll: float = randf()

	if t < 30.0:
		# Só shade e runner no começo
		return "shade" if roll < 0.7 else "runner"
	elif t < 90.0:
		if roll < 0.5: return "shade"
		elif roll < 0.85: return "runner"
		else: return "brute"
	elif t < 180.0:
		if roll < 0.30: return "shade"
		elif roll < 0.55: return "runner"
		elif roll < 0.75: return "brute"
		elif roll < 0.88: return "archer"
		else: return "exploder"
	else:
		if roll < 0.15: return "shade"
		elif roll < 0.35: return "runner"
		elif roll < 0.55: return "brute"
		elif roll < 0.72: return "archer"
		elif roll < 0.88: return "exploder"
		else: return "summoner"


func _spawn_regular_enemy() -> void:
	if enemies_container.get_child_count() >= MAX_ENEMIES:
		return
	var key: String = _choose_enemy_key()
	_spawn_enemy(key, _random_offscreen_position())


func _spawn_miniboss() -> void:
	_spawn_enemy("miniboss", _random_offscreen_position(360.0))


func _spawn_boss() -> void:
	var key: String = BOSS_VARIANTS[boss_index % BOSS_VARIANTS.size()]
	boss_index += 1
	_spawn_enemy(key, _random_offscreen_position(420.0))
	var data: Resource = _load_enemy_data(key)
	if data != null:
		EventBus.narrative_triggered.emit("⚠ %s surgiu!" % data.display_name)


func _spawn_enemy(key: String, spawn_pos: Vector2) -> void:
	var data: Resource = _load_enemy_data(key)
	if data == null:
		return
	var enemy := ENEMY_SCENE.instantiate()
	enemies_container.add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.setup(
		data,
		player,
		enemies_container,
		projectiles_container,
		pickups_container,
		_hp_mult(),
		_damage_mult(),
		_coin_mult()
	)


func _load_enemy_data(key: String) -> Resource:
	if enemy_cache.has(key):
		return enemy_cache[key]
	var path: String = ENEMY_PATHS.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var res := load(path)
	enemy_cache[key] = res
	return res


func _hp_mult() -> float:
	var minute_scale: float = 1.0 + time_alive / 120.0
	var diff: Dictionary = GameManager.difficulty_data()
	return minute_scale * float(diff.get("hp_mod", 1.0))


func _damage_mult() -> float:
	var diff: Dictionary = GameManager.difficulty_data()
	return 1.0 + time_alive / 240.0 * float(diff.get("hp_mod", 1.0))


func _coin_mult() -> float:
	var diff: Dictionary = GameManager.difficulty_data()
	return float(diff.get("coin_mod", 1.0))


func _random_offscreen_position(distance: float = 380.0) -> Vector2:
	var angle: float = randf() * TAU
	var pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * distance
	if map != null:
		pos.x = clamp(pos.x, 40.0, float(map.world_width - 40))
		pos.y = clamp(pos.y, 40.0, float(map.world_height - 40))
	return pos
