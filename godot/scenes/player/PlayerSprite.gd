extends Node2D

## Desenho procedural do herói: capuz, capa que balança, pernas animadas,
## piscada de invulnerabilidade e squash no dash.

@export var color_body: Color = Color(0.275, 0.227, 0.412, 1.0)
@export var color_head: Color = Color(0.118, 0.094, 0.18, 1.0)
@export var color_eyes: Color = Color(1.0, 0.776, 0.298, 1.0)
@export var color_cape: Color = Color(0.196, 0.157, 0.302, 1.0)

var _time: float = 0.0
var _motion: Vector2 = Vector2.ZERO
var _speed_ratio: float = 0.0
var _facing: float = 1.0
var _invuln: bool = false
var _hit_flash: float = 0.0
var _dashing: bool = false


func set_motion(motion: Vector2, invuln: bool, hit_flash: float, dashing: bool) -> void:
	_motion = motion
	_speed_ratio = clampf(motion.length(), 0.0, 1.4)
	if absf(motion.x) > 0.08:
		_facing = signf(motion.x)
	_invuln = invuln
	_hit_flash = hit_flash
	_dashing = dashing


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var walk: float = sin(_time * 11.0) * _speed_ratio
	var bob: float = absf(sin(_time * 11.0)) * 2.2 * _speed_ratio - sin(_time * 2.0) * 0.8
	var squash: float = 1.0 + (0.12 if _dashing else 0.0)

	# Piscada quando invulnerável
	if _invuln and fmod(_time, 0.18) < 0.09:
		modulate.a = 0.45
	else:
		modulate.a = 1.0

	var body: Color = color_body
	var head: Color = color_head
	if _hit_flash > 0.0:
		body = body.lerp(Color.WHITE, _hit_flash)
		head = head.lerp(Color.WHITE, _hit_flash * 0.8)

	# Sombra
	_ellipse(Vector2(0, 17), Vector2(13.5, 4.6), Color(0, 0, 0, 0.42))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing * squash, 1.0 / squash))

	# Capa (atrás), balança conforme o movimento
	var sway: float = -_motion.x * 6.0 - walk * 1.6
	draw_colored_polygon(PackedVector2Array([
		Vector2(-8, -16 + bob),
		Vector2(8, -16 + bob),
		Vector2(11 + sway, 8 + bob),
		Vector2(-11 + sway, 8 + bob),
	]), color_cape)

	# Pernas
	var leg_swing: float = walk * 3.4
	draw_rect(Rect2(-6.5, 6 + bob, 5.0, 9.0 + leg_swing), head)
	draw_rect(Rect2(1.5, 6 + bob, 5.0, 9.0 - leg_swing), head)

	# Tronco / túnica
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9, -13 + bob),
		Vector2(9, -13 + bob),
		Vector2(11, 8 + bob),
		Vector2(-11, 8 + bob),
	]), body)
	# Cinto
	draw_rect(Rect2(-10, -1 + bob, 20, 3.4), body.darkened(0.35))
	draw_rect(Rect2(-2.5, -1.6 + bob, 5, 4.6), color_eyes.darkened(0.15))

	# Braços
	draw_rect(Rect2(-12.5, -11 + bob, 4.0, 12.0 - leg_swing), body.darkened(0.18))
	draw_rect(Rect2(8.5, -11 + bob, 4.0, 12.0 + leg_swing), body.darkened(0.18))

	# Cabeça encapuzada
	draw_circle(Vector2(0, -21 + bob), 11.0, head)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11.5, -21 + bob),
		Vector2(0, -35 + bob),
		Vector2(11.5, -21 + bob),
	]), head.lightened(0.06))
	# Sombra do capuz
	draw_circle(Vector2(0, -19.5 + bob), 8.4, Color(0.05, 0.04, 0.09, 0.92))
	# Olhos brilhantes
	draw_circle(Vector2(-3.6, -20 + bob), 2.4, color_eyes)
	draw_circle(Vector2(3.6, -20 + bob), 2.4, color_eyes)
	draw_circle(Vector2(-3.6, -20 + bob), 1.1, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(3.6, -20 + bob), 1.1, Color(1, 1, 1, 0.9))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(18):
		var a: float = float(i) / 18.0 * TAU
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
