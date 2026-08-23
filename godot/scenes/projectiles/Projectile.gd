extends Area2D

## Projétil genérico: reto, teleguiado, orbital, bumerangue, arremesso em arco
## ou bomba. Também é usado pelos inimigos (hostile = true).

const P := preload("res://scripts/utils/Theme.gd")

enum Mode { STRAIGHT, ORBIT, BOOMERANG, ARC, BOMB, HOMING }

var mode: int = Mode.STRAIGHT
var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var pierce_remaining: int = 0
var lifetime: float = 1.0
var max_lifetime: float = 1.0
var projectile_color: Color = Color.WHITE
var projectile_kind: String = "bolt"
var radius: float = 6.0
var knockback: float = 100.0
var source_key: String = ""
var hostile: bool = false

# Efeitos
var status_kind: String = ""
var status_power: float = 0.0
var status_duration: float = 0.0
var status_chance: float = 1.0
var lifesteal: float = 0.0
var crit_chance: float = 0.0
var crit_mult: float = 2.0
var explode_radius: float = 0.0
var chain_targets: int = 0
var player: Node2D = null
var enemies_container: Node = null
var blocks_projectiles: bool = false

# Orbital
var orbit_player: Node2D = null
var orbit_angle: float = 0.0
var orbit_radius: float = 70.0
var orbit_speed: float = 2.8

# Bumerangue / arco / homing
var homing_strength: float = 0.0
var return_time: float = 0.6
var spin: float = 0.0
var _spin_angle: float = 0.0
var _elapsed: float = 0.0
var _trail: Array[Vector2] = []
var _trail_enabled: bool = false
var _hit_cooldowns: Dictionary = {}
var _consumed: bool = false


func setup_projectile(p_color: Color, p_kind: String, p_radius: float) -> void:
	projectile_color = p_color
	projectile_kind = p_kind
	radius = maxf(2.0, p_radius)
	var collision: CollisionShape2D = $Collision
	var shape: CircleShape2D = collision.shape
	if shape != null:
		shape = shape.duplicate()
		shape.radius = radius
		collision.shape = shape
	max_lifetime = lifetime
	z_index = 4
	queue_redraw()


func enable_trail() -> void:
	_trail_enabled = true


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	_elapsed += delta
	lifetime -= delta
	if lifetime <= 0.0:
		_expire()
		return

	match mode:
		Mode.ORBIT:
			_move_orbit(delta)
		Mode.BOOMERANG:
			_move_boomerang(delta)
		Mode.HOMING:
			_move_homing(delta)
		Mode.ARC:
			_move_arc(delta)
		Mode.BOMB:
			_move_bomb(delta)
		_:
			global_position += velocity * delta

	_spin_angle += spin * delta

	if not _hit_cooldowns.is_empty():
		for key in _hit_cooldowns.keys():
			_hit_cooldowns[key] = float(_hit_cooldowns[key]) - delta
			if float(_hit_cooldowns[key]) <= 0.0:
				_hit_cooldowns.erase(key)

	if _trail_enabled:
		_trail.push_front(global_position)
		if _trail.size() > 8:
			_trail.resize(8)

	queue_redraw()


func _move_orbit(delta: float) -> void:
	if orbit_player == null or not is_instance_valid(orbit_player):
		queue_free()
		return
	orbit_angle += orbit_speed * delta
	global_position = orbit_player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius


func _move_boomerang(delta: float) -> void:
	var t: float = _elapsed / maxf(0.1, max_lifetime)
	if t < 0.45:
		global_position += velocity * delta
	else:
		# volta pra mão do herói
		if player != null and is_instance_valid(player):
			var to_player: Vector2 = player.global_position - global_position
			if to_player.length() < 18.0:
				_expire()
				return
			velocity = velocity.lerp(to_player.normalized() * velocity.length(), clampf(delta * 4.0, 0.0, 1.0))
		global_position += velocity * delta


func _move_homing(delta: float) -> void:
	if homing_strength > 0.0:
		var target: Node2D = _find_target()
		if target != null:
			var desired: Vector2 = (target.global_position - global_position).normalized() * velocity.length()
			velocity = velocity.lerp(desired, clampf(delta * homing_strength, 0.0, 1.0))
	global_position += velocity * delta


func _move_arc(delta: float) -> void:
	# Arremesso: desacelera na ida e acelera de volta pra baixo (efeito visual de arco)
	global_position += velocity * delta
	velocity = velocity.lerp(Vector2.ZERO, clampf(delta * 0.9, 0.0, 1.0))


func _move_bomb(delta: float) -> void:
	global_position += velocity * delta
	velocity = velocity.lerp(Vector2.ZERO, clampf(delta * 2.2, 0.0, 1.0))
	if lifetime <= 0.05:
		_explode()


func _find_target() -> Node2D:
	if enemies_container == null or not is_instance_valid(enemies_container):
		return null
	var best: Node2D = null
	var best_d: float = 520.0 * 520.0
	for e in enemies_container.get_children():
		if not (e is Node2D) or not is_instance_valid(e):
			continue
		if "dead" in e and e.dead:
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


func _expire() -> void:
	if _consumed:
		return
	if explode_radius > 0.0 and mode == Mode.BOMB:
		_explode()
		return
	_consumed = true
	queue_free()


func _explode() -> void:
	if _consumed:
		return
	_consumed = true
	EventBus.explosion_requested.emit(global_position, explode_radius, projectile_color)
	EventBus.sfx("explosion", 0.55)
	EventBus.screen_shake_requested.emit(0.35, 0.2)
	if enemies_container != null and is_instance_valid(enemies_container):
		var r_sq: float = explode_radius * explode_radius
		for e in enemies_container.get_children():
			if not (e is Node2D) or not e.has_method("take_damage"):
				continue
			var to_e: Vector2 = e.global_position - global_position
			if to_e.length_squared() > r_sq:
				continue
			_damage_enemy(e, to_e.normalized(), 1.0)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _consumed:
		return
	if hostile:
		_hit_player(area)
		return

	# Escudo sagrado: destrói tiros inimigos que encostarem
	if blocks_projectiles and "hostile" in area and area.hostile:
		EventBus.impact_requested.emit(area.global_position, projectile_color, 0.3)
		EventBus.sfx("hit", 0.25)
		area.queue_free()
		return

	if not area.has_method("take_damage"):
		return
	if "dead" in area and area.dead:
		return
	var id: int = area.get_instance_id()
	if _hit_cooldowns.has(id):
		return

	var dir: Vector2 = velocity.normalized()
	if dir.length_squared() < 0.001:
		dir = (area.global_position - global_position).normalized()
	_damage_enemy(area, dir, 1.0)

	if explode_radius > 0.0:
		_explode()
		return

	if chain_targets > 0:
		_chain_from(area)

	if pierce_remaining > 0:
		pierce_remaining -= 1
		_hit_cooldowns[id] = 0.35
	elif mode == Mode.ORBIT or mode == Mode.BOOMERANG:
		_hit_cooldowns[id] = 0.45
	else:
		_consumed = true
		queue_free()


func _hit_player(area: Area2D) -> void:
	var victim: Node = area
	if not victim.has_method("take_damage"):
		return
	victim.take_damage(damage, knockback, velocity.normalized(), source_key)
	_consumed = true
	queue_free()


func _damage_enemy(enemy: Node, dir: Vector2, scale: float) -> void:
	var is_crit: bool = randf() < crit_chance
	var final_damage: float = damage * scale * (crit_mult if is_crit else 1.0)
	enemy.take_damage(final_damage, knockback, dir, source_key, is_crit)
	if status_kind != "" and randf() <= status_chance and enemy.has_method("apply_status"):
		enemy.apply_status(status_kind, status_power, status_duration)
	if lifesteal > 0.0 and player != null and is_instance_valid(player) and player.has_method("heal"):
		player.heal(lifesteal)
	EventBus.impact_requested.emit(enemy.global_position, projectile_color, 0.35 if not is_crit else 0.8)
	EventBus.sfx("crit" if is_crit else "hit", 0.5 if is_crit else 0.28)


func _chain_from(first: Node) -> void:
	if enemies_container == null or not is_instance_valid(enemies_container):
		return
	var hit: Array = [first]
	var current: Node2D = first as Node2D
	for i in range(chain_targets):
		var next: Node2D = _closest_excluding(current.global_position, hit, 260.0)
		if next == null:
			break
		EventBus.floating_text_requested.emit(next.global_position, "", projectile_color)
		_damage_enemy(next, (next.global_position - current.global_position).normalized(), 0.7)
		hit.append(next)
		current = next


func _closest_excluding(from: Vector2, exclude: Array, max_dist: float) -> Node2D:
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


# --- Desenho -----------------------------------------------------------------

func _draw() -> void:
	if _trail_enabled and _trail.size() > 1:
		for i in range(1, _trail.size()):
			var a: float = (1.0 - float(i) / float(_trail.size())) * 0.35
			var p1: Vector2 = to_local(_trail[i - 1])
			var p2: Vector2 = to_local(_trail[i])
			draw_line(p1, p2, Color(projectile_color.r, projectile_color.g, projectile_color.b, a), radius * 0.9)

	match projectile_kind:
		"bolt":
			draw_circle(Vector2.ZERO, radius * 1.5, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.22))
			draw_circle(Vector2.ZERO, radius, projectile_color)
			draw_circle(Vector2(-radius * 0.25, -radius * 0.25), radius * 0.4, Color(1, 1, 1, 0.85))
		"blade":
			var dir: Vector2 = velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.RIGHT
			var perp: Vector2 = dir.rotated(PI / 2.0)
			draw_colored_polygon(PackedVector2Array([
				dir * radius * 1.9,
				perp * radius * 0.62,
				-dir * radius * 1.3,
				-perp * radius * 0.62,
			]), projectile_color)
			draw_line(-dir * radius, dir * radius * 1.6, Color(1, 1, 1, 0.5), 1.5)
		"orbit":
			var pulse: float = 1.0 + sin(_elapsed * 6.0) * 0.06
			draw_circle(Vector2.ZERO, radius * 1.6 * pulse, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.20))
			draw_circle(Vector2.ZERO, radius * pulse, projectile_color)
			draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 16, Color(1, 1, 1, 0.6), 1.5)
		"axe":
			var pts := PackedVector2Array()
			for i in range(4):
				var a: float = _spin_angle + float(i) * PI * 0.5
				pts.append(Vector2(cos(a), sin(a)) * (radius * (1.5 if i % 2 == 0 else 0.55)))
			draw_colored_polygon(pts, projectile_color)
			draw_circle(Vector2.ZERO, radius * 0.35, Color(0.25, 0.2, 0.16))
		"bomb":
			draw_circle(Vector2.ZERO, radius, projectile_color)
			draw_circle(Vector2(-radius * 0.3, -radius * 0.3), radius * 0.35, Color(0.45, 0.42, 0.4))
			var fuse: float = 0.5 + 0.5 * sin(_elapsed * 24.0)
			draw_circle(Vector2(0, -radius * 1.2), 2.5 + fuse * 1.5, Color(1.0, 0.7, 0.25, 0.9))
		"spark":
			draw_circle(Vector2.ZERO, radius, projectile_color)
		_:
			draw_circle(Vector2.ZERO, radius, projectile_color)
