extends Area2D

## Item de chão: gema de XP, moeda, coração, baú, ímã ou bomba.
## Um único script/cena pra todos os drops (antes só existia a gema).

const P := preload("res://scripts/utils/Theme.gd")

@export var pickup_radius: float = 20.0
@export var base_magnet: float = 70.0
@export var max_speed: float = 620.0

var kind: String = "xp"
var value: int = 4
var player: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var magnetized: bool = false

var _time: float = 0.0
var _frame: int = 0
var _spawn_kick: float = 0.0
var _collected: bool = false
var _color: Color = P.ACCENT_PURPLE
var _size: float = 6.0


func setup(p_kind: String, p_value: int, p_player: Node2D) -> void:
	kind = p_kind
	value = p_value
	player = p_player
	var angle: float = randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * randf_range(50.0, 110.0)
	_spawn_kick = 0.4
	_time = randf() * TAU
	match kind:
		"xp":
			_color = P.ACCENT_PURPLE if value < 12 else (P.ACCENT_CYAN if value < 40 else P.ACCENT_GOLD)
			_size = 6.0 if value < 12 else (7.5 if value < 40 else 9.0)
			z_index = 1
		"coin":
			_color = P.ACCENT_GOLD
			_size = 6.5
			z_index = 1
		"heart":
			_color = P.ACCENT_RED
			_size = 9.0
			z_index = 2
		"chest":
			_color = P.ACCENT_GOLD
			_size = 14.0
			z_index = 2
			pickup_radius = 26.0
		"magnet":
			_color = P.ACCENT_CYAN
			_size = 10.0
			z_index = 2
		"bomb":
			_color = P.ACCENT_ORANGE
			_size = 10.0
			z_index = 2
	queue_redraw()


func _physics_process(delta: float) -> void:
	_time += delta
	if not is_instance_valid(player):
		return

	if _spawn_kick > 0.0:
		_spawn_kick = maxf(0.0, _spawn_kick - delta)
		velocity = velocity.lerp(Vector2.ZERO, delta * 5.0)

	_frame += 1
	var to_player: Vector2 = player.global_position - global_position
	var dist: float = to_player.length()

	if dist < pickup_radius:
		_collect()
		return

	# Item longe e parado: só acorda de vez em quando
	if not magnetized and dist > 900.0 and velocity.length_squared() < 4.0:
		if _frame % 15 != 0:
			return

	var attracts: bool = kind == "xp" or kind == "coin"
	if attracts or magnetized:
		var player_magnet: float = float(player.get("pickup_radius")) if "pickup_radius" in player else 0.0
		var effective: float = maxf(base_magnet, player_magnet)
		if magnetized:
			effective = 100000.0
		if dist < effective:
			var pull: float = clampf(1.0 - dist / maxf(1.0, effective), 0.0, 1.0)
			velocity = velocity.lerp(to_player.normalized() * max_speed, clampf(0.18 + pull * 0.82, 0.0, 1.0))

	global_position += velocity * delta
	# Pulso do item não precisa de 60 fps
	if (_frame + get_instance_id()) % 4 == 0:
		queue_redraw()


## Chamado pelo ímã: puxa tudo pro jogador
func magnetize() -> void:
	magnetized = true


## Funde outro drop igual dentro deste (evita centenas de nós no chão)
func merge_value(extra: int) -> void:
	value += extra
	if kind == "xp":
		_color = P.ACCENT_PURPLE if value < 12 else (P.ACCENT_CYAN if value < 40 else P.ACCENT_GOLD)
		_size = 6.0 if value < 12 else (7.5 if value < 40 else 9.0)
	queue_redraw()


func _collect() -> void:
	if _collected:
		return
	_collected = true
	match kind:
		"xp":
			EventBus.player_xp_gained.emit(float(value))
			EventBus.sfx("gem", 0.18)
		"coin":
			EventBus.sfx("coin", 0.3)
		"heart":
			if player.has_method("heal"):
				player.heal(float(value))
			EventBus.sfx("heal", 0.5)
			EventBus.floating_text_requested.emit(global_position, "+%d ❤" % value, P.ACCENT_GREEN)
		"chest":
			EventBus.chest_opened.emit(self)
			EventBus.sfx("chest", 0.8)
		"magnet":
			EventBus.sfx("gem", 0.6)
			EventBus.floating_text_requested.emit(global_position, "ÍMÃ!", P.ACCENT_CYAN)
		"bomb":
			EventBus.sfx("explosion", 0.8)
			EventBus.floating_text_requested.emit(global_position, "BOOM!", P.ACCENT_ORANGE)
	# Um único evento por item (antes moeda/ímã disparavam duas vezes)
	EventBus.pickup_collected.emit(kind, float(value))
	queue_free()


func _draw() -> void:
	var pulse: float = 1.0 + sin(_time * 3.4) * 0.09
	match kind:
		"xp":
			draw_circle(Vector2.ZERO, _size * 1.6 * pulse, Color(_color.r, _color.g, _color.b, 0.28))
			var pts := PackedVector2Array([
				Vector2(0, -_size) * pulse, Vector2(_size * 0.7, 0) * pulse,
				Vector2(0, _size) * pulse, Vector2(-_size * 0.7, 0) * pulse,
			])
			draw_colored_polygon(pts, _color)
			draw_circle(Vector2(-_size * 0.2, -_size * 0.35) * pulse, _size * 0.22, Color(1, 1, 1, 0.85))
		"coin":
			draw_circle(Vector2(1, 3), _size * 0.9, Color(0, 0, 0, 0.3))
			draw_circle(Vector2.ZERO, _size * pulse, _color)
			draw_circle(Vector2.ZERO, _size * 0.62 * pulse, Color(1.0, 0.898, 0.55))
			draw_arc(Vector2.ZERO, _size * 0.35, 0.0, TAU, 10, Color(0.6, 0.42, 0.1, 0.8), 1.5)
		"heart":
			draw_circle(Vector2(-_size * 0.32, -_size * 0.18) * pulse, _size * 0.48 * pulse, _color)
			draw_circle(Vector2(_size * 0.32, -_size * 0.18) * pulse, _size * 0.48 * pulse, _color)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-_size * 0.75, -_size * 0.05) * pulse,
				Vector2(_size * 0.75, -_size * 0.05) * pulse,
				Vector2(0, _size * 0.85) * pulse,
			]), _color)
		"chest":
			var bob: float = sin(_time * 2.4) * 2.0
			draw_circle(Vector2(0, _size * 0.7), _size * 0.9, Color(0, 0, 0, 0.35))
			draw_rect(Rect2(-_size, -_size * 0.5 + bob, _size * 2.0, _size * 1.1), Color(0.443, 0.294, 0.169))
			draw_rect(Rect2(-_size, -_size * 0.95 + bob, _size * 2.0, _size * 0.55), Color(0.549, 0.376, 0.220))
			draw_rect(Rect2(-_size * 0.18, -_size * 0.5 + bob, _size * 0.36, _size * 0.6), P.ACCENT_GOLD)
			var glow: float = 0.4 + 0.4 * sin(_time * 4.0)
			draw_arc(Vector2(0, bob), _size * 1.7, 0.0, TAU, 26, Color(1.0, 0.776, 0.298, glow * 0.6), 2.0)
		"magnet":
			draw_arc(Vector2.ZERO, _size * pulse, PI, TAU, 18, _color, 5.0)
			draw_rect(Rect2(-_size - 2.5, -1.0, 5.0, _size * 0.8), _color)
			draw_rect(Rect2(_size - 2.5, -1.0, 5.0, _size * 0.8), Color(1, 1, 1, 0.8))
		"bomb":
			draw_circle(Vector2.ZERO, _size * pulse, Color(0.18, 0.16, 0.20))
			draw_circle(Vector2(-_size * 0.3, -_size * 0.3), _size * 0.28, Color(0.45, 0.42, 0.46))
			var fuse: float = 0.5 + 0.5 * sin(_time * 14.0)
			draw_circle(Vector2(0, -_size * 1.25), 3.0 + fuse * 2.0, Color(1.0, 0.7, 0.25, 0.95))
