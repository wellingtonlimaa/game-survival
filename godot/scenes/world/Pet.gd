extends Node2D

const PROJECTILE_SCENE := preload("res://scenes/projectiles/Projectile.tscn")

@export var orbit_radius: float = 56.0
@export var orbit_speed: float = 2.2
@export var attack_cooldown: float = 1.4
@export var damage: float = 9.0
@export var range: float = 240.0

var player: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null
var orbit_angle: float = 0.0
var attack_timer: float = 0.0
var _time: float = 0.0


func setup(p_player: Node2D, p_enemies: Node, p_projectiles: Node) -> void:
	player = p_player
	enemies_container = p_enemies
	projectiles_container = p_projectiles


func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_time += delta
	orbit_angle += orbit_speed * delta
	global_position = player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius

	attack_timer = max(0.0, attack_timer - delta)
	if attack_timer <= 0.0:
		var target := _find_target()
		if target != null:
			_shoot(target)
			attack_timer = attack_cooldown
	queue_redraw()


func _find_target() -> Node2D:
	if enemies_container == null:
		return null
	var best: Node2D = null
	var best_d: float = range * range
	for e in enemies_container.get_children():
		if not (e is Node2D):
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _shoot(target: Node2D) -> void:
	if projectiles_container == null:
		return
	_spawn_projectile_deferred.call_deferred((target.global_position - global_position).normalized())


func _spawn_projectile_deferred(dir: Vector2) -> void:
	if projectiles_container == null or not is_instance_valid(projectiles_container):
		return
	var proj := PROJECTILE_SCENE.instantiate()
	projectiles_container.add_child(proj)
	proj.collision_layer = 8
	proj.collision_mask = 4
	proj.global_position = global_position
	proj.velocity = dir * 360.0
	proj.damage = damage
	proj.pierce_remaining = 0
	proj.lifetime = 1.2
	proj.knockback = 60.0
	proj.source_key = "pet"
	proj.setup_projectile(Color(0.439, 0.871, 0.494, 1.0), "bolt", 5.0)


func _draw() -> void:
	# Sombra
	draw_circle(Vector2(1, 4), 9.0, Color(0, 0, 0, 0.4))
	# Corpo (esfera de luz verde)
	var pulse: float = 1.0 + sin(_time * 4.0) * 0.08
	draw_circle(Vector2.ZERO, 12.0 * pulse, Color(0.439, 0.871, 0.494, 0.35))
	draw_circle(Vector2.ZERO, 7.0, Color(0.439, 0.871, 0.494, 1.0))
	draw_circle(Vector2(-1, -2), 2.5, Color(1, 1, 1, 0.85))
