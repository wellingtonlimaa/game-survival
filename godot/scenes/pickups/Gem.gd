extends Area2D

@export var float_speed: float = 1.6
@export var pickup_radius: float = 18.0
@export var magnet_radius: float = 80.0
@export var max_speed: float = 480.0

var value: int = 4
var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var _time: float = 0.0
var _spawn_kick: float = 0.0


func setup(p_value: int, p_player: Node2D) -> void:
	value = p_value
	player = p_player
	# pequeno chute pra fora ao surgir
	var angle: float = randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * 80.0
	_spawn_kick = 0.4
	queue_redraw()


func _physics_process(delta: float) -> void:
	_time += delta
	if not is_instance_valid(player):
		return

	# Decai chute inicial
	if _spawn_kick > 0.0:
		_spawn_kick = max(0.0, _spawn_kick - delta)
		velocity = velocity.lerp(Vector2.ZERO, delta * 4.0)

	var to_player := player.global_position - global_position
	var dist: float = to_player.length()

	var player_magnet: float = player.get("pickup_radius") if player.has_method("get") and "pickup_radius" in player else 0.0
	var effective_magnet: float = max(magnet_radius, player_magnet)

	if dist < pickup_radius:
		_collect()
		return

	if dist < effective_magnet:
		var pull: float = clamp(1.0 - dist / effective_magnet, 0.0, 1.0)
		velocity = velocity.lerp(to_player.normalized() * max_speed, clamp(0.15 + pull * 0.85, 0.0, 1.0))

	global_position += velocity * delta


func _collect() -> void:
	EventBus.player_xp_gained.emit(float(value))
	EventBus.pickup_collected.emit("xp", float(value))
	queue_free()


func _draw() -> void:
	var pulse: float = 1.0 + sin(_time * float_speed * TAU) * 0.08
	# glow externo
	draw_circle(Vector2.ZERO, 9.0 * pulse, Color(0.553, 0.412, 0.886, 0.32))
	# corpo
	var pts := PackedVector2Array([
		Vector2(0, -7) * pulse,
		Vector2(5, 0) * pulse,
		Vector2(0, 7) * pulse,
		Vector2(-5, 0) * pulse,
	])
	draw_colored_polygon(pts, Color(0.553, 0.412, 0.886, 1.0))
	# brilho
	draw_circle(Vector2(-1.5, -2.5) * pulse, 1.5, Color(1, 1, 1, 0.85))
