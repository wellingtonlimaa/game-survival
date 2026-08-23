extends Node

## Gerencia as armas equipadas: cooldown, disparo e evolução.
## Ao contrário da versão antiga, o herói carrega VÁRIAS armas (estilo survivor).

const PROJECTILE_SCENE := preload("res://scenes/projectiles/Projectile.tscn")
const AREA_EFFECT_SCENE := preload("res://scenes/effects/AreaEffect.tscn")
const DRONE_SCENE := preload("res://scenes/world/Drone.tscn")
const WeaponDataScript := preload("res://scripts/data/WeaponData.gd")
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")
const ProjectileScript := preload("res://scenes/projectiles/Projectile.gd")

const MAX_SLOTS := 6

class WeaponSlot:
	var data: Resource
	var level: int = 1
	var timer: float = 0.0
	var orbit_projectiles: Array = []
	var drones: Array = []
	var shots_fired: int = 0

	func is_max_level() -> bool:
		return level >= data.max_level

var player: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null
var effects_container: Node = null

var slots: Array = []


func configure(player_node: Node2D, enemies_node: Node, projectiles_node: Node, effects_node: Node = null) -> void:
	player = player_node
	enemies_container = enemies_node
	projectiles_container = projectiles_node
	effects_container = effects_node if effects_node != null else projectiles_node


# --- Equipar / evoluir -------------------------------------------------------

func has_weapon(key: String) -> bool:
	for slot in slots:
		if slot.data.key == key:
			return true
	return false


func slot_for(key: String) -> WeaponSlot:
	for slot in slots:
		if slot.data.key == key:
			return slot
	return null


func level_of(key: String) -> int:
	var slot: WeaponSlot = slot_for(key)
	return slot.level if slot != null else 0


func is_full() -> bool:
	return slots.size() >= MAX_SLOTS


## Equipa uma arma nova ou sobe o nível se já tiver.
func equip(key: String) -> bool:
	var existing: WeaponSlot = slot_for(key)
	if existing != null:
		if existing.level < existing.data.max_level:
			existing.level += 1
			_refresh_persistent(existing)
			EventBus.loadout_changed.emit()
		return true

	if is_full():
		return false
	var data: Resource = RegistryScript.get_data(key)
	if data == null:
		return false
	var slot := WeaponSlot.new()
	slot.data = data
	slot.level = 1
	slot.timer = randf() * 0.25
	slots.append(slot)
	_refresh_persistent(slot)
	EventBus.loadout_changed.emit()
	return true


## Troca a arma pela versão evoluída (mantém o nível máximo).
func evolve(key: String) -> bool:
	var slot: WeaponSlot = slot_for(key)
	if slot == null or slot.data.evolves_into == "":
		return false
	_clear_persistent(slot)
	slot.data = RegistryScript.build_evolution(slot.data)
	slot.level = slot.data.max_level
	_refresh_persistent(slot)
	EventBus.weapon_evolved.emit(slot.data.key)
	EventBus.loadout_changed.emit()
	return true


func _clear_persistent(slot: WeaponSlot) -> void:
	for orb in slot.orbit_projectiles:
		if is_instance_valid(orb):
			orb.queue_free()
	slot.orbit_projectiles.clear()
	for d in slot.drones:
		if is_instance_valid(d):
			d.queue_free()
	slot.drones.clear()


func _refresh_persistent(slot: WeaponSlot) -> void:
	match slot.data.behavior:
		WeaponDataScript.Behavior.ORBIT_PLAYER:
			_spawn_orbit_projectiles(slot)
		WeaponDataScript.Behavior.SUMMON_DRONE:
			_refresh_drones(slot)


# --- Loop --------------------------------------------------------------------

func tick(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var cd_mult: float = _stat("cooldown_mult", 1.0)
	for slot in slots:
		slot.timer -= delta
		if slot.timer > 0.0:
			continue
		_fire_weapon(slot)
		slot.timer = slot.data.cooldown_at_level(slot.level) * cd_mult


func _fire_weapon(slot: WeaponSlot) -> void:
	slot.shots_fired += 1
	match slot.data.behavior:
		WeaponDataScript.Behavior.PROJECTILE_AIM_CLOSEST:
			_fire_aim_closest(slot)
		WeaponDataScript.Behavior.PROJECTILE_AIM_DIRECTION:
			_fire_aim_direction(slot)
		WeaponDataScript.Behavior.HOMING_SHOT:
			_fire_aim_closest(slot, true)
		WeaponDataScript.Behavior.ORBIT_PLAYER:
			_spawn_orbit_projectiles(slot)
		WeaponDataScript.Behavior.AURA_PULSE:
			_fire_aura_pulse(slot)
		WeaponDataScript.Behavior.ARC_THROW:
			_fire_arc_throw(slot)
		WeaponDataScript.Behavior.BOOMERANG:
			_fire_boomerang(slot)
		WeaponDataScript.Behavior.CHAIN_LIGHTNING:
			_fire_chain_lightning(slot)
		WeaponDataScript.Behavior.GROUND_BOMB:
			_fire_bomb(slot)
		WeaponDataScript.Behavior.SLASH_ARC:
			_fire_slash(slot)
		WeaponDataScript.Behavior.NOVA_BURST:
			_fire_nova(slot)
		WeaponDataScript.Behavior.CONE_FLAME:
			_fire_flame(slot)
		WeaponDataScript.Behavior.SUMMON_DRONE:
			_refresh_drones(slot)


# --- Stats do jogador --------------------------------------------------------

func _stat(name: String, fallback: float) -> float:
	if player == null or not is_instance_valid(player):
		return fallback
	if name in player:
		return float(player.get(name))
	return fallback


func _damage_of(slot: WeaponSlot) -> float:
	return slot.data.damage_at_level(slot.level) * _stat("damage_mult", 1.0) * _stat("combo_mult", 1.0)


func _count_of(slot: WeaponSlot) -> int:
	var extra: int = int(_stat("extra_projectiles", 0.0))
	return maxi(1, slot.data.projectile_count_at_level(slot.level) + extra)


func _area_of(slot: WeaponSlot) -> float:
	return slot.data.area_at_level(slot.level) * _stat("area_mult", 1.0)


func _speed_of(slot: WeaponSlot) -> float:
	return slot.data.projectile_speed * _stat("projectile_speed_mult", 1.0)


func _lifetime_of(slot: WeaponSlot) -> float:
	return slot.data.projectile_lifetime * _stat("duration_mult", 1.0)


# --- Disparos ----------------------------------------------------------------

func _fire_aim_closest(slot: WeaponSlot, homing: bool = false) -> void:
	var target: Node2D = _find_closest_enemy()
	var direction: Vector2 = player.aim_dir
	if target != null:
		direction = (target.global_position - player.global_position).normalized()
	var count: int = _count_of(slot)
	var spread: float = slot.data.spread_radians if slot.data.spread_radians > 0.0 else 0.16
	for i in range(count):
		var offset: float = (float(i) - float(count - 1) * 0.5) * spread
		var proj: Node = _spawn_projectile(slot, direction.rotated(offset))
		if proj != null and (homing or slot.data.homing_strength > 0.0):
			proj.mode = ProjectileScript.Mode.HOMING
			proj.homing_strength = maxf(slot.data.homing_strength, 4.0)
	_play_shot(slot)


func _fire_aim_direction(slot: WeaponSlot) -> void:
	var aim: Vector2 = player.aim_dir
	if aim.length_squared() < 0.01:
		aim = Vector2.RIGHT
	var count: int = _count_of(slot)
	var spread: float = slot.data.spread_radians
	for i in range(count):
		var offset: float = (float(i) - float(count - 1) * 0.5) * spread
		_spawn_projectile(slot, aim.rotated(offset))
	_play_shot(slot)


func _fire_arc_throw(slot: WeaponSlot) -> void:
	var count: int = _count_of(slot)
	var base: Vector2 = player.aim_dir
	for i in range(count):
		var offset: float = (float(i) - float(count - 1) * 0.5) * slot.data.spread_radians
		var dir: Vector2 = base.rotated(offset)
		var proj: Node = _spawn_projectile(slot, dir)
		if proj != null:
			proj.mode = ProjectileScript.Mode.ARC
			proj.spin = 14.0
	_play_shot(slot)


func _fire_boomerang(slot: WeaponSlot) -> void:
	var count: int = _count_of(slot)
	var target: Node2D = _find_closest_enemy()
	var base: Vector2 = player.aim_dir
	if target != null:
		base = (target.global_position - player.global_position).normalized()
	for i in range(count):
		var offset: float = (float(i) - float(count - 1) * 0.5) * slot.data.spread_radians
		var proj: Node = _spawn_projectile(slot, base.rotated(offset))
		if proj != null:
			proj.mode = ProjectileScript.Mode.BOOMERANG
			proj.spin = 12.0
			proj.player = player
	_play_shot(slot)


func _fire_nova(slot: WeaponSlot) -> void:
	var count: int = _count_of(slot)
	var base_angle: float = randf() * TAU
	for i in range(count):
		var angle: float = base_angle + float(i) / float(count) * TAU
		_spawn_projectile(slot, Vector2(cos(angle), sin(angle)))
	_play_shot(slot)
	_spawn_area_effect("ring", player.global_position, _area_of(slot) * 0.6, slot.data.projectile_color, 0.35)


func _fire_bomb(slot: WeaponSlot) -> void:
	var count: int = _count_of(slot)
	var target: Node2D = _find_closest_enemy()
	var base: Vector2 = player.aim_dir
	if target != null:
		base = (target.global_position - player.global_position).normalized()
	for i in range(count):
		var offset: float = (float(i) - float(count - 1) * 0.5) * 0.4
		var proj: Node = _spawn_projectile(slot, base.rotated(offset))
		if proj != null:
			proj.mode = ProjectileScript.Mode.BOMB
			proj.explode_radius = _area_of(slot)
			proj.pierce_remaining = 0
	_play_shot(slot)


func _fire_chain_lightning(slot: WeaponSlot) -> void:
	var target: Node2D = _find_closest_enemy(slot.data.area)
	if target == null:
		slot.timer = 0.25
		return
	var damage: float = _damage_of(slot)
	var crit_chance: float = _stat("crit_chance", 0.0)
	var crit_mult: float = _stat("crit_mult", 2.0)
	var hit: Array = []
	var current: Node2D = target
	var from: Vector2 = player.global_position
	var jumps: int = slot.data.chain_targets + 1
	var points: PackedVector2Array = PackedVector2Array()
	points.append(from)
	for i in range(jumps):
		if current == null:
			break
		points.append(current.global_position)
		var is_crit: bool = randf() < crit_chance
		var dmg: float = damage * pow(0.85, float(i)) * (crit_mult if is_crit else 1.0)
		current.take_damage(dmg, slot.data.knockback, (current.global_position - from).normalized(), slot.data.key, is_crit)
		if slot.data.status != "" and randf() <= slot.data.status_chance and current.has_method("apply_status"):
			current.apply_status(slot.data.status, slot.data.status_power, slot.data.status_duration)
		EventBus.impact_requested.emit(current.global_position, slot.data.projectile_color, 0.5)
		hit.append(current)
		from = current.global_position
		current = _closest_excluding(from, hit, 280.0)
	_spawn_lightning_effect(points, slot.data.projectile_color)
	EventBus.sfx(slot.data.sound_key, 0.5)
	EventBus.screen_shake_requested.emit(0.2, 0.12)


func _fire_slash(slot: WeaponSlot) -> void:
	var area: float = _area_of(slot)
	var damage: float = _damage_of(slot)
	var aim: Vector2 = player.aim_dir
	var count: int = _count_of(slot)
	var arc: float = clampf(PI * 0.75 + 0.25 * float(count - 1), 0.0, TAU)
	var crit_chance: float = _stat("crit_chance", 0.0)
	var crit_mult: float = _stat("crit_mult", 2.0)
	var healed: float = 0.0
	for enemy in _enemies_in_radius(player.global_position, area):
		var to_enemy: Vector2 = enemy.global_position - player.global_position
		if arc < TAU and absf(aim.angle_to(to_enemy)) > arc * 0.5:
			continue
		var is_crit: bool = randf() < crit_chance
		enemy.take_damage(damage * (crit_mult if is_crit else 1.0), slot.data.knockback, to_enemy.normalized(), slot.data.key, is_crit)
		if slot.data.status != "" and enemy.has_method("apply_status"):
			enemy.apply_status(slot.data.status, slot.data.status_power, slot.data.status_duration)
		healed += slot.data.lifesteal
	if healed > 0.0 and player.has_method("heal"):
		player.heal(healed)
	_spawn_area_effect("arc", player.global_position, area, slot.data.projectile_color, 0.22, aim.angle(), arc)
	EventBus.sfx(slot.data.sound_key, 0.4)


func _fire_flame(slot: WeaponSlot) -> void:
	var area: float = _area_of(slot)
	var damage: float = _damage_of(slot)
	var aim: Vector2 = player.aim_dir
	var arc: float = PI * 0.42
	for enemy in _enemies_in_radius(player.global_position, area):
		var to_enemy: Vector2 = enemy.global_position - player.global_position
		if absf(aim.angle_to(to_enemy)) > arc * 0.5:
			continue
		enemy.take_damage(damage, slot.data.knockback, to_enemy.normalized(), slot.data.key, false)
		if slot.data.status != "" and enemy.has_method("apply_status"):
			enemy.apply_status(slot.data.status, slot.data.status_power, slot.data.status_duration)
	_spawn_area_effect("cone", player.global_position, area, slot.data.projectile_color, 0.18, aim.angle(), arc)
	EventBus.sfx(slot.data.sound_key, 0.22)


func _fire_aura_pulse(slot: WeaponSlot) -> void:
	var radius: float = _area_of(slot)
	var damage: float = _damage_of(slot)
	var crit_chance: float = _stat("crit_chance", 0.0)
	var crit_mult: float = _stat("crit_mult", 2.0)
	var hits: int = 0
	for enemy in _enemies_in_radius(player.global_position, radius):
		var is_crit: bool = randf() < crit_chance
		var dir: Vector2 = (enemy.global_position - player.global_position).normalized()
		enemy.take_damage(damage * (crit_mult if is_crit else 1.0), slot.data.knockback, dir, slot.data.key, is_crit)
		if slot.data.status != "" and enemy.has_method("apply_status"):
			enemy.apply_status(slot.data.status, slot.data.status_power, slot.data.status_duration)
		hits += 1
	if hits > 0:
		EventBus.sfx("hit", 0.18)


func _refresh_drones(slot: WeaponSlot) -> void:
	slot.drones = slot.drones.filter(func(d): return is_instance_valid(d))
	var target_count: int = _count_of(slot)
	var missing: int = target_count - slot.drones.size()
	for d in slot.drones:
		d.configure_stats(_damage_of(slot), slot.data.area, slot.data.cooldown_at_level(slot.level) * 1.4, _speed_of(slot))
	if missing <= 0:
		return
	for i in range(missing):
		var drone := DRONE_SCENE.instantiate()
		projectiles_container.add_child(drone)
		drone.setup(player, enemies_container, projectiles_container, slot.data)
		drone.orbit_angle = float(slot.drones.size()) / float(maxi(1, target_count)) * TAU
		drone.configure_stats(_damage_of(slot), slot.data.area, slot.data.cooldown_at_level(slot.level) * 1.4, _speed_of(slot))
		slot.drones.append(drone)


func _spawn_projectile(slot: WeaponSlot, direction: Vector2) -> Node:
	if projectiles_container == null or not is_instance_valid(projectiles_container):
		return null
	var proj := PROJECTILE_SCENE.instantiate()
	projectiles_container.add_child(proj)
	proj.global_position = player.global_position
	proj.velocity = direction.normalized() * _speed_of(slot)
	proj.damage = _damage_of(slot)
	proj.pierce_remaining = slot.data.pierce_at_level(slot.level) + int(_stat("extra_pierce", 0.0))
	proj.lifetime = _lifetime_of(slot)
	proj.knockback = slot.data.knockback
	proj.source_key = slot.data.key
	proj.status_kind = slot.data.status
	proj.status_power = slot.data.status_power
	proj.status_duration = slot.data.status_duration
	proj.status_chance = slot.data.status_chance
	proj.lifesteal = slot.data.lifesteal
	proj.crit_chance = _stat("crit_chance", 0.0)
	proj.crit_mult = _stat("crit_mult", 2.0)
	proj.player = player
	proj.enemies_container = enemies_container
	proj.chain_targets = slot.data.chain_targets
	if slot.data.explode_on_hit and slot.data.area > 0.0:
		proj.explode_radius = _area_of(slot)
	proj.setup_projectile(slot.data.projectile_color, slot.data.projectile_kind, slot.data.projectile_radius * _stat("area_mult", 1.0))
	if slot.data.trail:
		proj.enable_trail()
	return proj


func _spawn_orbit_projectiles(slot: WeaponSlot) -> void:
	slot.orbit_projectiles = slot.orbit_projectiles.filter(func(o): return is_instance_valid(o))
	var target_count: int = _count_of(slot)
	var refresh_lifetime: float = slot.data.projectile_lifetime + slot.data.cooldown_at_level(slot.level) + 0.5
	var damage: float = _damage_of(slot)
	var radius: float = slot.data.orbit_radius * _stat("area_mult", 1.0)

	for old in slot.orbit_projectiles:
		old.lifetime = refresh_lifetime
		old.max_lifetime = refresh_lifetime
		old.damage = damage
		old.orbit_radius = radius
		old.orbit_speed = slot.data.orbit_speed
		old.crit_chance = _stat("crit_chance", 0.0)

	var missing: int = target_count - slot.orbit_projectiles.size()
	if missing <= 0:
		return
	for i in range(missing):
		if projectiles_container == null or not is_instance_valid(projectiles_container):
			return
		var idx: int = slot.orbit_projectiles.size()
		var proj := PROJECTILE_SCENE.instantiate()
		projectiles_container.add_child(proj)
		proj.mode = ProjectileScript.Mode.ORBIT
		proj.orbit_player = player
		proj.orbit_angle = float(idx) / float(maxi(1, target_count)) * TAU
		proj.orbit_radius = radius
		proj.orbit_speed = slot.data.orbit_speed
		proj.global_position = player.global_position
		proj.velocity = Vector2.ZERO
		proj.damage = damage
		proj.pierce_remaining = 9999
		proj.lifetime = refresh_lifetime
		proj.knockback = slot.data.knockback
		proj.source_key = slot.data.key
		proj.status_kind = slot.data.status
		proj.status_power = slot.data.status_power
		proj.status_duration = slot.data.status_duration
		proj.status_chance = slot.data.status_chance
		proj.crit_chance = _stat("crit_chance", 0.0)
		proj.crit_mult = _stat("crit_mult", 2.0)
		proj.player = player
		proj.enemies_container = enemies_container
		proj.setup_projectile(slot.data.projectile_color, slot.data.projectile_kind, slot.data.projectile_radius * _stat("area_mult", 1.0))
		if slot.data.trail:
			proj.enable_trail()
		if slot.data.key == "holy_shield" or slot.data.key == "divine_aegis":
			proj.blocks_projectiles = true
			proj.collision_mask = proj.collision_mask | 16
		slot.orbit_projectiles.append(proj)


func _play_shot(slot: WeaponSlot) -> void:
	EventBus.sfx(slot.data.sound_key, 0.30)
	EventBus.weapon_fired.emit(slot.data.key)


# --- Efeitos visuais instantâneos -------------------------------------------

func _spawn_area_effect(kind: String, pos: Vector2, radius: float, color: Color, duration: float, angle: float = 0.0, arc: float = TAU) -> void:
	if effects_container == null or not is_instance_valid(effects_container):
		return
	var fx := AREA_EFFECT_SCENE.instantiate()
	effects_container.add_child(fx)
	fx.global_position = pos
	fx.setup(kind, radius, color, duration, angle, arc)
	if kind == "arc" or kind == "cone":
		fx.follow = player


func _spawn_lightning_effect(points: PackedVector2Array, color: Color) -> void:
	if effects_container == null or not is_instance_valid(effects_container) or points.size() < 2:
		return
	var fx := AREA_EFFECT_SCENE.instantiate()
	effects_container.add_child(fx)
	fx.global_position = Vector2.ZERO
	fx.setup_lightning(points, color, 0.22)


# --- Consultas ---------------------------------------------------------------

func _enemies_in_radius(center: Vector2, radius: float) -> Array:
	var out: Array = []
	if enemies_container == null or not is_instance_valid(enemies_container):
		return out
	var r_sq: float = radius * radius
	for e in enemies_container.get_children():
		if not (e is Node2D) or not e.has_method("take_damage"):
			continue
		if "dead" in e and e.dead:
			continue
		if center.distance_squared_to(e.global_position) <= r_sq:
			out.append(e)
	return out


func _find_closest_enemy(max_range: float = 1400.0) -> Node2D:
	if enemies_container == null or not is_instance_valid(enemies_container):
		return null
	var best: Node2D = null
	var best_dist: float = max_range * max_range
	for child in enemies_container.get_children():
		if not (child is Node2D) or not child.has_method("take_damage"):
			continue
		if "dead" in child and child.dead:
			continue
		var d: float = player.global_position.distance_squared_to(child.global_position)
		if d < best_dist:
			best_dist = d
			best = child
	return best


func _closest_excluding(from: Vector2, exclude: Array, max_dist: float) -> Node2D:
	if enemies_container == null:
		return null
	var best: Node2D = null
	var best_d: float = max_dist * max_dist
	for e in enemies_container.get_children():
		if not (e is Node2D) or exclude.has(e) or not e.has_method("take_damage"):
			continue
		if "dead" in e and e.dead:
			continue
		var d: float = from.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


## Resumo pra HUD / tela de upgrade
func loadout_summary() -> Array:
	var out: Array = []
	for slot in slots:
		out.append({
			"key": slot.data.key,
			"name": slot.data.display_name,
			"icon": slot.data.icon,
			"color": slot.data.icon_color,
			"level": slot.level,
			"max_level": slot.data.max_level,
			"evolved": slot.data.is_evolution,
		})
	return out
