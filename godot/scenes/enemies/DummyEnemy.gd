extends Area2D

@export var max_hp: float = 30.0
@export var speed: float = 70.0
@export var contact_damage: float = 10.0
@export var radius: float = 14.0
@export var xp_value: int = 4
@export var coin_value: int = 1
@export var enemy_color: Color = Color(0.886, 0.275, 0.345, 1.0)

var hp: float
var target: Node2D = null
var knock_velocity: Vector2 = Vector2.ZERO
var hit_flash: float = 0.0

var _contact_cooldown: float = 0.0


func _ready() -> void:
	hp = max_hp
	body_entered.connect(_on_body_entered)


func setup(_target: Node2D, hp_mult: float = 1.0, speed_mult: float = 1.0) -> void:
	target = _target
	max_hp *= hp_mult
	hp = max_hp
	speed *= speed_mult


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	# Knockback decai rápido
	knock_velocity = knock_velocity.lerp(Vector2.ZERO, clamp(delta * 6.0, 0.0, 1.0))
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta * 4.0)
	if _contact_cooldown > 0.0:
		_contact_cooldown = max(0.0, _contact_cooldown - delta)

	var direction := (target.global_position - global_position).normalized()
	global_position += (direction * speed + knock_velocity) * delta

	queue_redraw()


func take_damage(damage: float, knockback: float, dir: Vector2, _source: String = "") -> void:
	hp -= damage
	hit_flash = 1.0
	knock_velocity += dir * knockback
	if hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.enemy_killed.emit(self, "")
	# Drop XP (gem proxy) — futuro: spawn Gem node. Por enquanto XP direto:
	EventBus.player_xp_gained.emit(float(xp_value))
	queue_free()


func _on_body_entered(body: Node) -> void:
	if _contact_cooldown > 0.0:
		return
	if body.has_method("apply_damage_to_player"):
		body.apply_damage_to_player(contact_damage)
		_contact_cooldown = 0.4


func _draw() -> void:
	# Sombra
	draw_circle(Vector2(2, 5), radius * 1.05, Color(0, 0, 0, 0.4))

	# Corpo
	var col := enemy_color
	if hit_flash > 0.0:
		col = enemy_color.lerp(Color.WHITE, hit_flash)
	draw_circle(Vector2.ZERO, radius, col)

	# Olhos
	draw_circle(Vector2(-radius * 0.35, -radius * 0.2), radius * 0.18, Color(1.0, 0.949, 0.42, 1.0))
	draw_circle(Vector2(radius * 0.35, -radius * 0.2), radius * 0.18, Color(1.0, 0.949, 0.42, 1.0))

	# Barra de vida (só se ferido)
	if hp < max_hp:
		var bar_w := radius * 1.6
		var pct: float = clamp(hp / max_hp, 0.0, 1.0)
		var bar_y := -radius - 8.0
		draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w, 4.0), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w * pct, 4.0), Color(0.439, 0.871, 0.494, 1.0))
