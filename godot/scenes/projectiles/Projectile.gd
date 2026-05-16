extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var pierce_remaining: int = 0
var lifetime: float = 1.0
var projectile_color: Color = Color.WHITE
var projectile_kind: String = "bolt"
var radius: float = 6.0
var knockback: float = 100.0
var source_key: String = ""

# Orbit mode
var orbit_player: Node2D = null
var orbit_angle: float = 0.0
var orbit_radius: float = 70.0
var orbit_speed: float = 2.8

var _hit_cooldowns: Dictionary = {}


func setup_projectile(p_color: Color, p_kind: String, p_radius: float) -> void:
	projectile_color = p_color
	projectile_kind = p_kind
	radius = p_radius
	var collision: CollisionShape2D = $Collision
	var shape: CircleShape2D = collision.shape
	shape.radius = p_radius


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	if orbit_player != null and is_instance_valid(orbit_player):
		orbit_angle += orbit_speed * delta
		global_position = orbit_player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
	else:
		global_position += velocity * delta

	# Decrementa hit cooldowns (para projétil persistente acertar mesmo inimigo de novo)
	for key in _hit_cooldowns.keys():
		_hit_cooldowns[key] -= delta
	for key in _hit_cooldowns.keys().duplicate():
		if _hit_cooldowns[key] <= 0.0:
			_hit_cooldowns.erase(key)

	queue_redraw()


func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("take_damage"):
		return
	# Não acertar o mesmo alvo durante o cooldown (orbit)
	var id := area.get_instance_id()
	if _hit_cooldowns.has(id):
		return

	var dir: Vector2 = velocity.normalized() if velocity.length_squared() > 0.001 else (area.global_position - global_position).normalized()
	area.take_damage(damage, knockback, dir, source_key)
	EventBus.damage_number_requested.emit(area.global_position, damage, projectile_color)

	if pierce_remaining > 0:
		pierce_remaining -= 1
		_hit_cooldowns[id] = 0.35
	else:
		queue_free()


func _draw() -> void:
	match projectile_kind:
		"bolt":
			draw_circle(Vector2.ZERO, radius * 1.3, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.32))
			draw_circle(Vector2.ZERO, radius, projectile_color)
			draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.85))
		"blade":
			var dir: Vector2 = velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.RIGHT
			var perp := dir.rotated(PI / 2.0)
			var pts := PackedVector2Array([
				dir * radius * 1.6,
				perp * radius * 0.6,
				-dir * radius * 1.2,
				-perp * radius * 0.6,
			])
			draw_colored_polygon(pts, projectile_color)
		"orbit":
			draw_circle(Vector2.ZERO, radius * 1.4, Color(projectile_color.r, projectile_color.g, projectile_color.b, 0.25))
			draw_circle(Vector2.ZERO, radius, projectile_color)
			draw_arc(Vector2.ZERO, radius * 0.7, 0.0, TAU, 16, Color(1, 1, 1, 0.6), 1.5)
		_:
			draw_circle(Vector2.ZERO, radius, projectile_color)
