extends Node

const PROJECTILE_SCENE := preload("res://scenes/projectiles/Projectile.tscn")
const WeaponDataScript := preload("res://scripts/data/WeaponData.gd")

const WEAPON_PATHS := {
	"wand":         "res://resources/weapons/wand.tres",
	"knife":        "res://resources/weapons/knife.tres",
	"orbit":        "res://resources/weapons/orbit.tres",
	"spear":        "res://resources/weapons/spear.tres",
	"shotgun":      "res://resources/weapons/shotgun.tres",
	"fire_staff":   "res://resources/weapons/fire_staff.tres",
	"arrow_storm":  "res://resources/weapons/arrow_storm.tres",
	"holy_shield":  "res://resources/weapons/holy_shield.tres",
	"comet":        "res://resources/weapons/comet.tres",
	"fury":         "res://resources/weapons/fury.tres",
}

const MAX_POWERS := 3

var player: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null

class WeaponSlot:
	var data: Resource
	var level: int = 1
	var timer: float = 0.0
	var orbit_projectiles: Array[Node2D] = []


var slots: Array = []


func configure(player_node: Node2D, enemies_node: Node, projectiles_node: Node) -> void:
	player = player_node
	enemies_container = enemies_node
	projectiles_container = projectiles_node


func equip(key: String) -> void:
	if not WEAPON_PATHS.has(key):
		return
	var data: Resource = load(WEAPON_PATHS[key])
	# Ja possui essa arma/poder? sobe nivel
	for slot in slots:
		if slot.data.key == key:
			slot.level += 1
			return
	# Armas substituem armas. Poderes acumulam (ate o limite).
	if data.is_power():
		if _count_powers() >= MAX_POWERS:
			return
	else:
		_clear_weapon_slots()
	var new_slot := WeaponSlot.new()
	new_slot.data = data
	new_slot.timer = 0.0
	slots.append(new_slot)
	_initial_setup(new_slot)


func _count_powers() -> int:
	var n: int = 0
	for slot in slots:
		if slot.data.is_power():
			n += 1
	return n


func _clear_weapon_slots() -> void:
	# Remove apenas as armas (mantem poderes ja equipados)
	var keep: Array = []
	for slot in slots:
		if slot.data.is_power():
			keep.append(slot)
		else:
			for orb in slot.orbit_projectiles:
				if is_instance_valid(orb):
					orb.queue_free()
			slot.orbit_projectiles.clear()
	slots = keep


func _initial_setup(slot: WeaponSlot) -> void:
	if slot.data.behavior == WeaponDataScript.Behavior.ORBIT_PLAYER:
		_spawn_orbit_projectiles(slot)


func tick(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	for slot in slots:
		slot.timer -= delta
		if slot.timer > 0.0:
			continue
		_fire_weapon(slot)
		slot.timer = slot.data.cooldown_at_level(slot.level)


func _fire_weapon(slot: WeaponSlot) -> void:
	match slot.data.behavior:
		WeaponDataScript.Behavior.PROJECTILE_AIM_CLOSEST:
			_fire_aim_closest(slot)
		WeaponDataScript.Behavior.PROJECTILE_AIM_DIRECTION:
			_fire_aim_direction(slot)
		WeaponDataScript.Behavior.ORBIT_PLAYER:
			_spawn_orbit_projectiles(slot)
		WeaponDataScript.Behavior.AURA_PULSE:
			_fire_aura_pulse(slot)


func _fire_aura_pulse(slot: WeaponSlot) -> void:
	if enemies_container == null:
		return
	# Raio cresce com o nivel (reutilizamos orbit_radius como raio do tornado)
	var radius: float = slot.data.orbit_radius * (1.0 + 0.20 * max(0, slot.level - 1))
	var radius_sq: float = radius * radius
	var damage: float = slot.data.damage_at_level(slot.level) * _player_dmg_mult()
	var hit_count: int = 0
	for enemy in enemies_container.get_children():
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var to_enemy: Vector2 = enemy.global_position - player.global_position
		if to_enemy.length_squared() > radius_sq:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage, slot.data.knockback, to_enemy.normalized(), slot.data.key)
			hit_count += 1
	# Feedback visual minimo: pequeno flash baseado em quantos foram atingidos
	if hit_count > 0:
		EventBus.flash_requested.emit(slot.data.projectile_color, 0.08)


func _fire_aim_closest(slot: WeaponSlot) -> void:
	var target := _find_closest_enemy()
	if target == null:
		return
	var direction := (target.global_position - player.global_position).normalized()
	var count: int = slot.data.projectile_count_at_level(slot.level)
	for i in range(count):
		var offset: float = (float(i) - float(count - 1) * 0.5) * 0.18
		_spawn_projectile(slot, direction.rotated(offset))


func _fire_aim_direction(slot: WeaponSlot) -> void:
	var aim: Vector2 = player.aim_dir if player.has_method("get") else Vector2.RIGHT
	if not (aim is Vector2) or aim.length_squared() < 0.01:
		aim = Vector2.RIGHT
	var count: int = slot.data.projectile_count_at_level(slot.level)
	for i in range(count):
		var spread: float = slot.data.spread_radians
		var offset: float = (float(i) - float(count - 1) * 0.5) * spread
		_spawn_projectile(slot, aim.rotated(offset))


func _spawn_projectile(slot: WeaponSlot, direction: Vector2) -> void:
	var proj := PROJECTILE_SCENE.instantiate()
	projectiles_container.add_child(proj)
	proj.global_position = player.global_position
	proj.velocity = direction.normalized() * slot.data.projectile_speed
	proj.damage = slot.data.damage_at_level(slot.level) * _player_dmg_mult()
	proj.pierce_remaining = slot.data.pierce
	proj.lifetime = slot.data.projectile_lifetime
	proj.knockback = slot.data.knockback
	proj.source_key = slot.data.key
	proj.setup_projectile(slot.data.projectile_color, slot.data.projectile_kind, slot.data.projectile_radius)


func _spawn_orbit_projectiles(slot: WeaponSlot) -> void:
	# Limpa entradas inválidas (orbes que morreram por outros motivos)
	slot.orbit_projectiles = slot.orbit_projectiles.filter(func(o): return is_instance_valid(o))

	var target_count: int = slot.data.projectile_count_at_level(slot.level)
	var refresh_lifetime: float = slot.data.projectile_lifetime + slot.data.cooldown_at_level(slot.level)

	# Refresh nos orbes existentes (mantém vivos sem flicker)
	for old in slot.orbit_projectiles:
		old.lifetime = refresh_lifetime
		old.damage = slot.data.damage_at_level(slot.level) * _player_dmg_mult()
		old.orbit_radius = slot.data.orbit_radius
		old.orbit_speed = slot.data.orbit_speed

	# Adiciona orbes faltantes (primeira vez ou se nível subiu)
	var missing: int = target_count - slot.orbit_projectiles.size()
	if missing <= 0:
		return

	for i in range(missing):
		var idx: int = slot.orbit_projectiles.size()
		var proj := PROJECTILE_SCENE.instantiate()
		projectiles_container.add_child(proj)
		proj.orbit_player = player
		proj.orbit_angle = float(idx) / float(target_count) * TAU
		proj.orbit_radius = slot.data.orbit_radius
		proj.orbit_speed = slot.data.orbit_speed
		proj.global_position = player.global_position
		proj.velocity = Vector2.ZERO
		proj.damage = slot.data.damage_at_level(slot.level) * _player_dmg_mult()
		proj.pierce_remaining = slot.data.pierce
		proj.lifetime = refresh_lifetime
		proj.knockback = slot.data.knockback
		proj.source_key = slot.data.key
		proj.setup_projectile(slot.data.projectile_color, slot.data.projectile_kind, slot.data.projectile_radius)
		slot.orbit_projectiles.append(proj)


func _player_dmg_mult() -> float:
	if player == null:
		return 1.0
	if "damage_mult" in player:
		return float(player.damage_mult)
	return 1.0


func _find_closest_enemy() -> Node2D:
	if enemies_container == null:
		return null
	var best: Node2D = null
	var best_dist: float = INF
	for child in enemies_container.get_children():
		if not (child is Node2D):
			continue
		var d: float = player.global_position.distance_squared_to(child.global_position)
		if d < best_dist:
			best_dist = d
			best = child
	return best
