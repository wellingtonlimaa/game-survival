extends Area2D

## Inimigo genérico dirigido por EnemyData.
## Cuida de IA, status (queimadura/lentidão/atordoamento/marca), separação
## entre inimigos, dano de contato contínuo e drops.

const EnemyDataScript := preload("res://scripts/data/EnemyData.gd")
const PROJECTILE_SCENE := preload("res://scenes/projectiles/Projectile.tscn")
const ENEMY_SCENE_PATH := "res://scenes/enemies/Enemy.tscn"
const MAX_PICKUPS := 120
const P := preload("res://scripts/utils/Theme.gd")

signal died(enemy: Node)

var data: Resource = null
var hp: float = 0.0
var max_hp: float = 0.0
var target: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null
var pickups_container: Node = null
var effects_container: Node = null

var hp_mult: float = 1.0
var damage_mult: float = 1.0
var coin_mult: float = 1.0
var is_elite: bool = false
var dead: bool = false

var knock_velocity: Vector2 = Vector2.ZERO
var hit_flash: float = 0.0
var attack_timer: float = 0.0
var windup_timer: float = 0.0
var windup_active: bool = false
var contact_cd: float = 0.0
var spawn_anim: float = 0.0
var _time: float = 0.0
var _facing: float = 1.0
var _separation: Vector2 = Vector2.ZERO
var _sep_tick: int = 0
var _charge_dir: Vector2 = Vector2.ZERO
var _charge_time: float = 0.0
var _spiral_angle: float = 0.0
var _damage_taken_total: float = 0.0
var _last_facing: float = 1.0
var _last_hp_bucket: int = -1
var _flash_drawn: bool = false
var _behavior: int = 0
var _radius: float = 14.0
var _base_speed: float = 90.0
var _contact_damage: float = 10.0
var _target_radius: float = 16.0
var _can_hurt_player: bool = false
var _speed_cache: float = 90.0
var _status_drawn: int = 0
var _drawn_once: bool = false

# status → { "power": float, "time": float, "tick": float }
var statuses: Dictionary = {}

@onready var collision_shape: CollisionShape2D = $Collision


func setup(
	enemy_data: Resource,
	player_ref: Node2D,
	enemies_node: Node,
	projectiles_node: Node,
	pickups_node: Node,
	p_hp_mult: float = 1.0,
	p_damage_mult: float = 1.0,
	p_coin_mult: float = 1.0,
	p_elite: bool = false,
	effects_node: Node = null
) -> void:
	data = enemy_data
	target = player_ref
	enemies_container = enemies_node
	projectiles_container = projectiles_node
	pickups_container = pickups_node
	effects_container = effects_node
	hp_mult = p_hp_mult
	damage_mult = p_damage_mult
	coin_mult = p_coin_mult
	is_elite = p_elite

	max_hp = data.hp * hp_mult * (2.6 if is_elite else 1.0)
	hp = max_hp

	var shape: CircleShape2D = collision_shape.shape
	if shape != null:
		shape = shape.duplicate()
		shape.radius = current_radius()
		collision_shape.shape = shape

	_behavior = int(data.behavior)
	_radius = current_radius()
	_base_speed = data.speed * (1.08 if is_elite else 1.0)
	_speed_cache = _base_speed
	_contact_damage = data.contact_damage * damage_mult * (1.25 if is_elite else 1.0)
	_can_hurt_player = player_ref != null and player_ref.has_method("apply_damage_to_player")
	_target_radius = float(player_ref.get("radius")) if (player_ref != null and "radius" in player_ref) else 16.0

	attack_timer = data.attack_cooldown * randf_range(0.6, 1.1)
	spawn_anim = 1.0
	z_index = 3 if data.is_boss() else 1
	add_to_group("enemies")
	if data.is_boss():
		EventBus.boss_hp_changed.emit(hp, max_hp, data.display_name)
	if data.tier == EnemyDataScript.Tier.BOSS:
		EventBus.boss_spawned.emit(self)
	EventBus.enemy_spawned.emit(self)
	queue_redraw()


func current_radius() -> float:
	if data == null:
		return 14.0
	return data.radius * (1.25 if is_elite else 1.0)


func _physics_process(delta: float) -> void:
	if data == null or dead:
		return
	if not is_instance_valid(target):
		return

	_time += delta
	if spawn_anim > 0.0:
		spawn_anim = maxf(0.0, spawn_anim - delta * 3.0)

	knock_velocity = knock_velocity.lerp(Vector2.ZERO, clampf(delta * 6.0, 0.0, 1.0))
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - delta * 4.5)
	if contact_cd > 0.0:
		contact_cd = maxf(0.0, contact_cd - delta)

	_tick_statuses(delta)
	_update_separation()

	var stunned: bool = statuses.has("stun")
	if not stunned:
		attack_timer = maxf(0.0, attack_timer - delta)
		match _behavior:
			EnemyDataScript.Behavior.CHASE:
				_behavior_chase(delta)
			EnemyDataScript.Behavior.KITE_AND_SHOOT:
				_behavior_kite(delta)
			EnemyDataScript.Behavior.EXPLODE_CLOSE:
				_behavior_explode(delta)
			EnemyDataScript.Behavior.SUMMONER:
				_behavior_summoner(delta)
			EnemyDataScript.Behavior.BOSS_RADIAL:
				_behavior_boss(delta)
			EnemyDataScript.Behavior.CHARGER:
				_behavior_charger(delta)
			EnemyDataScript.Behavior.SPIRAL:
				_behavior_spiral(delta)
			EnemyDataScript.Behavior.SPLITTER:
				_behavior_chase(delta)
	else:
		global_position += knock_velocity * delta

	_check_contact_damage()
	_maybe_redraw()


## Redesenhar 180 inimigos por quadro derruba o FPS.
## O nó já se move sozinho: só refazemos o desenho quando o visual muda.
func _maybe_redraw() -> void:
	var hp_bucket: int = int(hp / maxf(1.0, max_hp) * 12.0)
	var flash_on: bool = hit_flash > 0.3
	var status_count: int = statuses.size()
	var dirty: bool = (
		not _drawn_once
		or windup_active
		or spawn_anim > 0.0
		or is_elite
		or flash_on != _flash_drawn
		or status_count != _status_drawn
		or hp_bucket != _last_hp_bucket
	)
	if dirty:
		_drawn_once = true
		_flash_drawn = flash_on
		_status_drawn = status_count
		_last_hp_bucket = hp_bucket
		queue_redraw()


# --- Movimento ---------------------------------------------------------------

func move_speed() -> float:
	return _speed_cache


func _refresh_speed_cache() -> void:
	_speed_cache = _base_speed
	if statuses.has("slow"):
		_speed_cache *= maxf(0.15, 1.0 - float(statuses["slow"]["power"]))


func _step(dir: Vector2, delta: float, scale: float = 1.0) -> void:
	var vel: Vector2 = dir * _speed_cache * scale + knock_velocity + _separation
	global_position += vel * delta
	if absf(dir.x) > 0.05:
		_facing = signf(dir.x)


## Empurrão suave entre inimigos pra não virar uma pilha só.
func _update_separation() -> void:
	_sep_tick += 1
	if _sep_tick % 10 != 0:
		return
	_separation = Vector2.ZERO
	var count: int = 0
	for other in get_overlapping_areas():
		if count >= 5:
			break
		if other == self or not (other is Node2D):
			continue
		if not other.is_in_group("enemies"):
			continue
		var diff: Vector2 = global_position - other.global_position
		var d: float = diff.length()
		if d < 0.01:
			diff = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
			d = 1.0
		var min_d: float = current_radius() + 6.0
		if d < min_d * 2.0:
			_separation += diff.normalized() * (1.0 - d / (min_d * 2.0)) * 90.0
			count += 1


func _behavior_chase(delta: float) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	_step(dir, delta)


func _behavior_kite(delta: float) -> void:
	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	var dir: Vector2 = to_target.normalized() if dist > 0.001 else Vector2.RIGHT
	var move_dir: Vector2
	if dist < data.prefered_distance * 0.85:
		move_dir = -dir * 0.85
	elif dist > data.prefered_distance * 1.15:
		move_dir = dir * 0.6
	else:
		move_dir = dir.rotated(PI * 0.5) * 0.35
	_step(move_dir, delta)

	if attack_timer <= 0.0 and not windup_active and dist < data.prefered_distance * 2.0:
		windup_active = true
		windup_timer = data.windup_time
	if windup_active:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_fire_at_player()
			windup_active = false
			attack_timer = data.attack_cooldown


func _behavior_explode(delta: float) -> void:
	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	var dir: Vector2 = to_target.normalized() if dist > 0.001 else Vector2.RIGHT

	if dist > data.trigger_distance and not windup_active:
		_step(dir, delta, 1.15)
	else:
		if not windup_active:
			windup_active = true
			windup_timer = data.windup_time
			EventBus.sfx("burn", 0.5)
		windup_timer -= delta
		if windup_timer <= 0.0:
			_explode()


func _behavior_summoner(delta: float) -> void:
	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	var dir: Vector2 = to_target.normalized() if dist > 0.001 else Vector2.RIGHT
	if dist < data.prefered_distance:
		_step(-dir, delta, 0.7)
	else:
		_step(dir, delta, 0.3)

	if attack_timer <= 0.0 and not windup_active:
		windup_active = true
		windup_timer = data.windup_time
	if windup_active:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_summon_minions()
			windup_active = false
			attack_timer = data.attack_cooldown


func _behavior_boss(delta: float) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	_step(dir, delta, 0.7)

	if attack_timer <= 0.0 and not windup_active:
		windup_active = true
		windup_timer = data.windup_time
	if windup_active:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_fire_radial()
			windup_active = false
			# Enfurecido abaixo de 40% de vida: ataca mais rápido
			attack_timer = data.attack_cooldown * (0.6 if hp < max_hp * 0.4 else 1.0)


func _behavior_charger(delta: float) -> void:
	if _charge_time > 0.0:
		_charge_time -= delta
		global_position += (_charge_dir * data.charge_speed + knock_velocity) * delta
		return

	var to_target: Vector2 = target.global_position - global_position
	var dist: float = to_target.length()
	var dir: Vector2 = to_target.normalized() if dist > 0.001 else Vector2.RIGHT

	if windup_active:
		windup_timer -= delta
		_charge_dir = dir
		if windup_timer <= 0.0:
			windup_active = false
			_charge_time = data.charge_duration
			attack_timer = data.attack_cooldown
			EventBus.sfx("dash", 0.5)
		return

	if attack_timer <= 0.0 and dist < 420.0:
		windup_active = true
		windup_timer = data.windup_time
		return
	_step(dir, delta, 0.55)


func _behavior_spiral(delta: float) -> void:
	var dir: Vector2 = (target.global_position - global_position).normalized()
	_step(dir, delta, 0.45)
	attack_timer -= delta * 0.0
	if attack_timer <= 0.0:
		_spiral_angle += 0.62
		var count: int = maxi(1, int(data.projectile_count / 4))
		for i in range(count):
			var angle: float = _spiral_angle + float(i) / float(count) * TAU
			_spawn_enemy_projectile(Vector2(cos(angle), sin(angle)))
		attack_timer = maxf(0.12, data.attack_cooldown * 0.18)


# --- Combate -----------------------------------------------------------------

func _check_contact_damage() -> void:
	if contact_cd > 0.0 or not _can_hurt_player:
		return
	var reach: float = _radius + _target_radius
	var diff: Vector2 = global_position - target.global_position
	if diff.length_squared() <= reach * reach:
		target.apply_damage_to_player(_contact_damage)
		contact_cd = 0.7
		knock_velocity += diff.normalized() * 90.0


func _fire_at_player() -> void:
	if projectiles_container == null or not is_instance_valid(target):
		return
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var count: int = maxi(1, data.projectile_count)
	for i in range(count):
		var offset: float = (float(i) - float(count - 1) * 0.5) * 0.16
		_spawn_enemy_projectile(dir.rotated(offset))
	EventBus.sfx("shoot", 0.35)


func _fire_radial() -> void:
	if projectiles_container == null:
		return
	var count: int = maxi(1, data.projectile_count)
	var base_angle: float = randf() * TAU
	for i in range(count):
		var angle: float = base_angle + float(i) / float(count) * TAU
		_spawn_enemy_projectile(Vector2(cos(angle), sin(angle)))
	EventBus.sfx("shoot_heavy", 0.5)
	EventBus.screen_shake_requested.emit(0.25, 0.18)


func _spawn_enemy_projectile(dir: Vector2) -> void:
	_spawn_enemy_projectile_deferred.call_deferred(global_position, dir.normalized(), damage_mult)


func _spawn_enemy_projectile_deferred(origin: Vector2, dir: Vector2, dmg_mult: float) -> void:
	if projectiles_container == null or not is_instance_valid(projectiles_container):
		return
	var proj := PROJECTILE_SCENE.instantiate()
	projectiles_container.add_child(proj)
	proj.collision_layer = 16
	proj.collision_mask = 2
	proj.hostile = true
	proj.global_position = origin
	proj.velocity = dir * data.projectile_speed
	proj.damage = data.projectile_damage * dmg_mult
	proj.pierce_remaining = 0
	proj.lifetime = data.projectile_lifetime
	proj.knockback = 80.0
	proj.source_key = "enemy:%s" % data.key
	proj.setup_projectile(data.projectile_color, "bolt", data.projectile_radius)


func _explode() -> void:
	var radius: float = data.explode_radius
	if is_instance_valid(target):
		var dist: float = target.global_position.distance_to(global_position)
		if dist < radius and target.has_method("apply_damage_to_player"):
			var falloff: float = clampf(1.0 - dist / radius, 0.35, 1.0)
			target.apply_damage_to_player(data.contact_damage * damage_mult * falloff)
	EventBus.explosion_requested.emit(global_position, radius, P.ACCENT_ORANGE)
	EventBus.screen_shake_requested.emit(0.5, 0.28)
	EventBus.sfx("explosion", 0.7)
	dead = true
	_drop_loot()
	queue_free()


func _summon_minions() -> void:
	if enemies_container == null or data.summon_pool.size() == 0:
		return
	_summon_minions_deferred.call_deferred(global_position)


func _summon_minions_deferred(origin: Vector2) -> void:
	if enemies_container == null or not is_instance_valid(enemies_container):
		return
	if enemies_container.get_child_count() > 240:
		return
	var enemy_scene: PackedScene = load(ENEMY_SCENE_PATH)
	for i in range(data.summon_count):
		var key: String = String(data.summon_pool[i % data.summon_pool.size()])
		var path: String = "res://resources/enemies/%s.tres" % key
		if not ResourceLoader.exists(path):
			continue
		var minion_data: Resource = load(path)
		var minion := enemy_scene.instantiate()
		enemies_container.add_child(minion)
		var angle: float = randf() * TAU
		minion.global_position = origin + Vector2(cos(angle), sin(angle)) * 60.0
		minion.setup(minion_data, target, enemies_container, projectiles_container, pickups_container, hp_mult, damage_mult, coin_mult, false, effects_container)
	EventBus.sfx("shoot_magic", 0.5)


# --- Status ------------------------------------------------------------------

func apply_status(kind: String, power: float, duration: float) -> void:
	if kind == "" or duration <= 0.0 or dead:
		return
	var existing: Dictionary = statuses.get(kind, {})
	var new_time: float = maxf(float(existing.get("time", 0.0)), duration)
	var new_power: float = maxf(float(existing.get("power", 0.0)), power)
	statuses[kind] = {"power": new_power, "time": new_time, "tick": float(existing.get("tick", 0.0))}
	if kind == "slow":
		_refresh_speed_cache()


func _tick_statuses(delta: float) -> void:
	if statuses.is_empty():
		return
	var expired: Array = []
	for kind in statuses.keys():
		var st: Dictionary = statuses[kind]
		st["time"] = float(st["time"]) - delta
		match kind:
			"burn", "poison":
				st["tick"] = float(st["tick"]) - delta
				if float(st["tick"]) <= 0.0:
					st["tick"] = 0.5
					var dmg: float = float(st["power"]) * 0.5
					_apply_raw_damage(dmg, Color(1.0, 0.478, 0.18) if kind == "burn" else P.POISON, false, true)
		if float(st["time"]) <= 0.0:
			expired.append(kind)
		else:
			statuses[kind] = st
	for kind in expired:
		statuses.erase(kind)
		if kind == "slow":
			_refresh_speed_cache()


func damage_taken_mult() -> float:
	if statuses.has("mark"):
		return 1.0 + float(statuses["mark"]["power"])
	return 1.0


# --- Dano / morte ------------------------------------------------------------

func take_damage(damage: float, knockback: float, dir: Vector2, source: String = "", is_crit: bool = false) -> void:
	if dead or data == null:
		return
	var final_damage: float = maxf(1.0, damage - data.armor) * damage_taken_mult()
	_apply_raw_damage(final_damage, Color.WHITE, is_crit, false)
	if not dead:
		var resist: float = clampf(1.0 - data.knockback_resist, 0.0, 1.0)
		knock_velocity += dir * knockback * resist
	if source != "":
		pass


## Dano puro (usado por status também): não sofre armadura nem knockback.
func _apply_raw_damage(amount: float, color: Color, is_crit: bool, silent: bool) -> void:
	if dead:
		return
	hp -= amount
	_damage_taken_total += amount
	hit_flash = 1.0
	var pos: Vector2 = global_position + Vector2(0, -current_radius() - 6.0)
	if is_crit:
		EventBus.crit_number_requested.emit(pos, amount, P.CRIT)
	elif not silent:
		# Dano de status (queimadura/veneno) não polui a tela com números
		EventBus.damage_number_requested.emit(pos, amount, color)
	EventBus.enemy_damaged.emit(self, amount, is_crit)
	if data.tier == EnemyDataScript.Tier.BOSS or data.tier == EnemyDataScript.Tier.MINIBOSS:
		EventBus.boss_hp_changed.emit(hp, max_hp, data.display_name)
	if hp <= 0.0:
		_die()


func _die() -> void:
	if dead:
		return
	dead = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	EventBus.enemy_killed.emit(self, data.key)
	if data.tier == EnemyDataScript.Tier.BOSS:
		EventBus.boss_killed.emit(self)
		EventBus.boss_despawned.emit()
		EventBus.screen_shake_requested.emit(1.0, 0.5)
		EventBus.flash_requested.emit(Color(1, 1, 1, 0.35), 0.3)
		EventBus.sfx("explosion", 0.9)
	elif data.tier == EnemyDataScript.Tier.MINIBOSS:
		EventBus.boss_despawned.emit()
		EventBus.sfx("explosion", 0.6)
	else:
		EventBus.sfx("kill", 0.35)

	EventBus.impact_requested.emit(global_position, data.body_color, 1.4 if data.is_boss() else 0.7)
	_drop_loot()
	_maybe_split()
	died.emit(self)
	queue_free()


func _maybe_split() -> void:
	if data.behavior != EnemyDataScript.Behavior.SPLITTER or data.split_into == "":
		return
	var path: String = "res://resources/enemies/%s.tres" % data.split_into
	if not ResourceLoader.exists(path) or enemies_container == null:
		return
	_spawn_splits_deferred.call_deferred(global_position, path)


func _spawn_splits_deferred(origin: Vector2, path: String) -> void:
	if enemies_container == null or not is_instance_valid(enemies_container):
		return
	var child_data: Resource = load(path)
	var enemy_scene: PackedScene = load(ENEMY_SCENE_PATH)
	for i in range(data.split_count):
		var e := enemy_scene.instantiate()
		enemies_container.add_child(e)
		var angle: float = randf() * TAU
		e.global_position = origin + Vector2(cos(angle), sin(angle)) * 26.0
		e.setup(child_data, target, enemies_container, projectiles_container, pickups_container, hp_mult, damage_mult, coin_mult, false, effects_container)


func _drop_loot() -> void:
	if pickups_container == null:
		return
	var xp: int = data.xp_value * (3 if is_elite else 1)
	var coins: int = 0
	var chance: float = data.coin_chance * (2.0 if is_elite else 1.0)
	if data.is_boss() or randf() < chance:
		coins = maxi(1, int(round(data.coin_value * coin_mult * (2.0 if is_elite else 1.0))))
	var heart: bool = randf() < (data.heart_chance + (0.04 if is_elite else 0.0))
	var chest: bool = data.chest_chance > 0.0 and randf() < data.chest_chance
	_spawn_loot_deferred.call_deferred(global_position, xp, coins, heart, chest)


func _spawn_loot_deferred(pos: Vector2, xp: int, coins: int, heart: bool, chest: bool) -> void:
	if pickups_container == null or not is_instance_valid(pickups_container):
		return
	var pickup_scene: PackedScene = load("res://scenes/pickups/Pickup.tscn")
	var crowded: bool = pickups_container.get_child_count() >= MAX_PICKUPS
	if xp > 0:
		if crowded and _merge_into_nearby("xp", pos, xp):
			pass
		else:
			var gem := pickup_scene.instantiate()
			pickups_container.add_child(gem)
			gem.global_position = pos
			gem.setup("xp", xp, target)
	if coins > 0:
		if crowded and _merge_into_nearby("coin", pos, coins):
			pass
		else:
			var coin := pickup_scene.instantiate()
			pickups_container.add_child(coin)
			coin.global_position = pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
			coin.setup("coin", coins, target)
	if heart:
		var h := pickup_scene.instantiate()
		pickups_container.add_child(h)
		h.global_position = pos + Vector2(randf_range(-12, 12), randf_range(-12, 12))
		h.setup("heart", 22, target)
	if chest:
		var c := pickup_scene.instantiate()
		pickups_container.add_child(c)
		c.global_position = pos
		c.setup("chest", 1, target)


## Com o chão cheio, o drop novo entra no item igual mais próximo.
func _merge_into_nearby(kind: String, pos: Vector2, amount: int) -> bool:
	var best: Node = null
	var best_d: float = 400.0 * 400.0
	for p in pickups_container.get_children():
		if not p.has_method("merge_value") or String(p.kind) != kind:
			continue
		var d: float = pos.distance_squared_to(p.global_position)
		if d < best_d:
			best_d = d
			best = p
	if best == null:
		return false
	best.merge_value(amount)
	return true


# --- Desenho -----------------------------------------------------------------

func _draw() -> void:
	if data == null:
		return
	# Desenho enxuto: cada primitiva a mais custa caro com 100+ inimigos na tela
	var r: float = _radius
	var scale_in: float = 1.0 - spawn_anim * 0.4

	# Sombra só nos maiores
	if r >= 12.0:
		draw_circle(Vector2(2, r * 0.42), r * 0.88 * scale_in, Color(0, 0, 0, 0.32))

	# Aura de elite
	if is_elite:
		var pulse: float = 0.5 + 0.5 * sin(_time * 4.0)
		draw_circle(Vector2.ZERO, r * (1.45 + pulse * 0.12), Color(0.624, 0.388, 0.937, 0.22))

	# Telegrafia de ataque
	if windup_active:
		var pct: float = clampf(1.0 - windup_timer / maxf(0.05, data.windup_time), 0.0, 1.0)
		var warn: Color = Color(1.0, 0.35, 0.35, 0.9) if _behavior == EnemyDataScript.Behavior.EXPLODE_CLOSE else P.ACCENT_GOLD
		draw_arc(Vector2.ZERO, r + 7.0, -PI / 2.0, -PI / 2.0 + pct * TAU, 20, warn, 3.0)
		if _behavior == EnemyDataScript.Behavior.CHARGER and _charge_dir != Vector2.ZERO:
			draw_line(Vector2.ZERO, _charge_dir * 150.0, Color(1.0, 0.35, 0.35, 0.35), 4.0)
		elif _behavior == EnemyDataScript.Behavior.EXPLODE_CLOSE:
			draw_arc(Vector2.ZERO, data.explode_radius * pct, 0.0, TAU, 26, Color(1.0, 0.45, 0.2, 0.28), 2.0)

	# Corpo
	var col: Color = data.body_color
	if statuses.has("burn"):
		col = col.lerp(P.BURN, 0.45)
	if statuses.has("slow"):
		col = col.lerp(P.FROST, 0.35)
	if statuses.has("mark"):
		col = col.lerp(Color(0.9, 0.4, 0.9), 0.2)
	if _flash_drawn:
		col = col.lerp(Color.WHITE, 0.75)

	var body_r: float = data.radius * scale_in * (1.25 if is_elite else 1.0)
	_draw_silhouette(col, body_r)
	# Olhos (a alma do bicho)
	var eye_r: float = body_r * 0.18
	draw_circle(Vector2(-body_r * 0.35, -body_r * 0.18), eye_r, data.eye_color)
	draw_circle(Vector2(body_r * 0.35, -body_r * 0.18), eye_r, data.eye_color)

	# Atordoado
	if statuses.has("stun"):
		draw_arc(Vector2(0, -r - 10.0), 6.0, 0.0, TAU, 10, P.CRIT, 2.0)

	# Barra de vida: só quando importa (lixo que morre em 2 tiros não precisa)
	if hp < max_hp * 0.98 and not data.is_boss() and (max_hp > 45.0 or hp < max_hp * 0.55):
		var bar_w: float = r * 1.9
		var pct: float = clampf(hp / max_hp, 0.0, 1.0)
		var bar_y: float = -r - 11.0
		draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w, 4.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w * pct, 4.0), P.hp_color(pct))

	# Coroa
	if data.tier == EnemyDataScript.Tier.BOSS:
		_draw_crown(P.ACCENT_GOLD, -r * 1.15)
	elif data.tier == EnemyDataScript.Tier.MINIBOSS:
		_draw_crown(Color(1.0, 0.776, 0.298, 0.75), -r * 1.05)


func _draw_silhouette(col: Color, r: float) -> void:
	match data.silhouette:
		"tall":
			draw_rect(Rect2(-r * 0.55, -r, r * 1.1, r * 1.8), col)
			draw_circle(Vector2(0, -r * 0.9), r * 0.6, col)
		"wide":
			draw_rect(Rect2(-r * 0.9, -r * 0.6, r * 1.8, r * 1.2), col)
			draw_circle(Vector2(0, -r * 0.55), r * 0.7, col)
		"crown":
			draw_circle(Vector2.ZERO, r, col)
			for i in range(3):
				var angle: float = -PI / 2.0 + (float(i) - 1.0) * 0.7
				var tip: Vector2 = Vector2(cos(angle), sin(angle)) * r * 1.45
				var base_l: Vector2 = Vector2(cos(angle - 0.22), sin(angle - 0.22)) * r * 0.95
				var base_r: Vector2 = Vector2(cos(angle + 0.22), sin(angle + 0.22)) * r * 0.95
				draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), col.darkened(0.15))
		"mask":
			draw_circle(Vector2.ZERO, r, col)
			draw_rect(Rect2(-r * 0.8, -r * 0.25, r * 1.6, r * 0.5), col.darkened(0.25))
		"skull":
			draw_circle(Vector2.ZERO, r, col)
			draw_rect(Rect2(-r * 0.35, r * 0.05, r * 0.7, r * 0.5), col.darkened(0.3))
		"horned":
			draw_circle(Vector2.ZERO, r, col)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-r * 0.9, -r * 0.35), Vector2(-r * 1.5, -r * 1.25), Vector2(-r * 0.35, -r * 0.8),
			]), col.darkened(0.2))
			draw_colored_polygon(PackedVector2Array([
				Vector2(r * 0.9, -r * 0.35), Vector2(r * 1.5, -r * 1.25), Vector2(r * 0.35, -r * 0.8),
			]), col.darkened(0.2))
		_:
			draw_circle(Vector2.ZERO, r, col)


func _draw_crown(col: Color, y: float) -> void:
	var pts := PackedVector2Array([
		Vector2(-12, y), Vector2(-8, y - 8), Vector2(-4, y), Vector2(0, y - 10),
		Vector2(4, y), Vector2(8, y - 8), Vector2(12, y), Vector2(12, y + 4), Vector2(-12, y + 4),
	])
	draw_colored_polygon(pts, col)
