extends Node2D

## Sentinela/pet: orbita o herói e atira sozinha no inimigo mais próximo.
## Usada tanto pelo pet inicial quanto pela arma "Sentinela".

const PROJECTILE_SCENE := preload("res://scenes/projectiles/Projectile.tscn")

@export var orbit_radius: float = 62.0
@export var orbit_speed: float = 1.9
@export var attack_cooldown: float = 1.35
@export var damage: float = 9.0
@export var attack_range: float = 260.0
@export var projectile_speed: float = 420.0
@export var body_color: Color = Color(0.439, 0.871, 0.494, 1.0)

var player: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null
var weapon_data: Resource = null
var orbit_angle: float = 0.0
var attack_timer: float = 0.0
var _time: float = 0.0
var _recoil: float = 0.0


func setup(p_player: Node2D, p_enemies: Node, p_projectiles: Node, p_data: Resource = null) -> void:
	player = p_player
	enemies_container = p_enemies
	projectiles_container = p_projectiles
	weapon_data = p_data
	if weapon_data != null:
		body_color = weapon_data.icon_color
		attack_range = weapon_data.area
		projectile_speed = weapon_data.projectile_speed
	z_index = 2


func configure_stats(p_damage: float, p_range: float, p_cooldown: float, p_speed: float) -> void:
	damage = p_damage
	attack_range = p_range
	attack_cooldown = maxf(0.25, p_cooldown)
	projectile_speed = p_speed


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_time += delta
	orbit_angle += orbit_speed * delta
	var bob: float = sin(_time * 3.0) * 4.0
	global_position = player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle) * 0.75) * orbit_radius + Vector2(0, bob - 10.0)

	if _recoil > 0.0:
		_recoil = maxf(0.0, _recoil - delta * 4.0)

	attack_timer = maxf(0.0, attack_timer - delta)
	if attack_timer <= 0.0:
		var target: Node2D = _find_target()
		if target != null:
			_shoot(target)
			attack_timer = attack_cooldown
	queue_redraw()


func _find_target() -> Node2D:
	if enemies_container == null or not is_instance_valid(enemies_container):
		return null
	var best: Node2D = null
	var best_d: float = attack_range * attack_range
	for e in enemies_container.get_children():
		if not (e is Node2D) or not e.has_method("take_damage"):
			continue
		if "dead" in e and e.dead:
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _shoot(target: Node2D) -> void:
	if projectiles_container == null:
		return
	_recoil = 1.0
	_spawn_projectile_deferred.call_deferred((target.global_position - global_position).normalized())
	EventBus.sfx("shoot", 0.18)


func _spawn_projectile_deferred(dir: Vector2) -> void:
	if projectiles_container == null or not is_instance_valid(projectiles_container):
		return
	var proj := PROJECTILE_SCENE.instantiate()
	projectiles_container.add_child(proj)
	proj.global_position = global_position
	proj.velocity = dir * projectile_speed
	proj.damage = damage
	proj.pierce_remaining = 0
	proj.lifetime = 1.4
	proj.knockback = 45.0
	proj.source_key = "drone"
	proj.player = player
	proj.enemies_container = enemies_container
	if player != null and "crit_chance" in player:
		proj.crit_chance = float(player.crit_chance)
		proj.crit_mult = float(player.crit_mult)
	if weapon_data != null:
		proj.status_kind = weapon_data.status
		proj.status_power = weapon_data.status_power
		proj.status_duration = weapon_data.status_duration
	proj.setup_projectile(body_color, "bolt", 5.0)
	proj.enable_trail()


func _draw() -> void:
	var pulse: float = 1.0 + sin(_time * 4.0) * 0.07
	var squash: float = 1.0 - _recoil * 0.2
	# Sombra
	draw_circle(Vector2(1, 14), 7.0, Color(0, 0, 0, 0.3))
	# Halo
	draw_circle(Vector2.ZERO, 13.0 * pulse, Color(body_color.r, body_color.g, body_color.b, 0.28))
	# Corpo
	draw_circle(Vector2.ZERO, 7.5 * squash, body_color)
	draw_circle(Vector2(-1.5, -2.0), 2.6, Color(1, 1, 1, 0.85))
	# Aro orbital
	draw_arc(Vector2.ZERO, 11.0, _time * 2.0, _time * 2.0 + PI * 1.2, 14, Color(1, 1, 1, 0.35), 1.5)
