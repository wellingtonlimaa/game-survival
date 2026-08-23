extends Control

## Cena de fundo do menu: lua, floresta em silhueta, vagalumes e o herói
## selecionado (usa as cores do personagem equipado).

@export var hero_size: Vector2 = Vector2(340, 300)

var _time: float = 0.0
var _particles: Array[Dictionary] = []
var _body: Color = Color(0.275, 0.227, 0.412)
var _head: Color = Color(0.118, 0.094, 0.18)
var _eyes: Color = Color(1.0, 0.776, 0.298)


func _ready() -> void:
	custom_minimum_size = hero_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(16):
		_particles.append({
			"angle": randf() * TAU,
			"radius": randf_range(70.0, 140.0),
			"speed": randf_range(0.3, 0.8),
			"size": randf_range(1.6, 3.2),
			"phase": randf() * TAU,
		})
	_load_character()
	EventBus.currency_changed.connect(func(_k, _v): _load_character())


func _load_character() -> void:
	var c: Resource = CharacterRegistry.selected()
	if c != null:
		_body = c.body_color
		_head = c.head_color
		_eyes = c.eye_color


func _process(delta: float) -> void:
	_time += delta
	for p in _particles:
		p["angle"] += p["speed"] * delta
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var ground_y: float = size.y - 44.0

	# Halo da lua
	for i in range(12, 0, -1):
		draw_circle(center + Vector2(0, -26), 62.0 + i * 6.0, Color(0.553, 0.412, 0.886, 0.035 + (12.0 - i) * 0.004))
	# Lua
	draw_circle(center + Vector2(0, -26), 58.0, Color(0.984, 0.918, 0.745))
	draw_circle(center + Vector2(16, -40), 12.0, Color(0.878, 0.827, 0.686, 0.6))
	draw_circle(center + Vector2(-16, -16), 7.0, Color(0.878, 0.827, 0.686, 0.55))
	draw_circle(center + Vector2(4, -6), 5.0, Color(0.878, 0.827, 0.686, 0.45))

	# O cenário sangra pras laterais (o Control é menor que o desenho)
	var bleed: float = 260.0

	# Morros ao fundo
	_hill(Vector2(size.x * 0.1 - bleed * 0.4, ground_y + 6), 260.0, 46.0, Color(0.055, 0.047, 0.098))
	_hill(Vector2(size.x * 0.85 + bleed * 0.4, ground_y + 8), 300.0, 38.0, Color(0.067, 0.055, 0.110))

	# Chão
	draw_rect(Rect2(Vector2(-bleed, ground_y), Vector2(size.x + bleed * 2.0, size.y - ground_y + 40.0)), Color(0.043, 0.035, 0.078))

	# Árvores em silhueta
	_tree(Vector2(-bleed * 0.75, ground_y), 70.0, Color(0.055, 0.043, 0.094))
	_tree(Vector2(-bleed * 0.35, ground_y), 92.0, Color(0.075, 0.063, 0.114))
	_tree(Vector2(28, ground_y), 60.0, Color(0.055, 0.043, 0.094))
	_tree(Vector2(size.x - 28, ground_y), 64.0, Color(0.055, 0.043, 0.094))
	_tree(Vector2(size.x + bleed * 0.35, ground_y), 88.0, Color(0.075, 0.063, 0.114))
	_tree(Vector2(size.x + bleed * 0.75, ground_y), 68.0, Color(0.055, 0.043, 0.094))

	# Herói (mesma silhueta do jogo)
	var bob: float = sin(_time * 2.2) * 3.0
	var feet := Vector2(center.x, ground_y - 6.0 + bob)
	draw_circle(feet + Vector2(0, 6), 18.0, Color(0, 0, 0, 0.35))
	draw_colored_polygon(PackedVector2Array([
		feet + Vector2(-13, -34), feet + Vector2(13, -34),
		feet + Vector2(17, 2), feet + Vector2(-17, 2),
	]), _body.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		feet + Vector2(-11, -30), feet + Vector2(11, -30),
		feet + Vector2(13, 0), feet + Vector2(-13, 0),
	]), _body)
	draw_circle(feet + Vector2(0, -42), 13.0, _head)
	draw_colored_polygon(PackedVector2Array([
		feet + Vector2(-13.5, -42), feet + Vector2(0, -59), feet + Vector2(13.5, -42),
	]), _head.lightened(0.05))
	draw_circle(feet + Vector2(0, -40), 10.0, Color(0.05, 0.04, 0.09, 0.92))
	draw_circle(feet + Vector2(-4.2, -41), 2.8, _eyes)
	draw_circle(feet + Vector2(4.2, -41), 2.8, _eyes)

	# Vagalumes
	for p in _particles:
		var angle: float = p["angle"]
		var radius: float = p["radius"]
		var pulse: float = 0.5 + 0.5 * sin(_time * 3.0 + p["phase"])
		var pos := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.55 - 14)
		draw_circle(pos, p["size"] * 2.0, Color(1.0, 0.882, 0.502, 0.16 * pulse))
		draw_circle(pos, p["size"], Color(1.0, 0.882, 0.502, 0.35 + 0.45 * pulse))
		draw_circle(pos, p["size"] * 0.4, Color(1.0, 1.0, 0.851, 0.85))


func _hill(base: Vector2, width: float, height: float, color: Color) -> void:
	var pts := PackedVector2Array()
	var steps := 16
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var x: float = base.x - width * 0.5 + width * t
		var y: float = base.y - sin(t * PI) * height
		pts.append(Vector2(x, y))
	pts.append(Vector2(base.x + width * 0.5, base.y + 40.0))
	pts.append(Vector2(base.x - width * 0.5, base.y + 40.0))
	draw_colored_polygon(pts, color)


func _tree(base: Vector2, height: float, color: Color) -> void:
	var trunk_w := height * 0.11
	draw_rect(Rect2(base - Vector2(trunk_w / 2.0, height * 0.42), Vector2(trunk_w, height * 0.42)), color)
	for i in range(3):
		var y := base.y - height * (0.42 + i * 0.17)
		var w := height * (0.58 - i * 0.11)
		draw_colored_polygon(PackedVector2Array([
			Vector2(base.x - w / 2.0, y), Vector2(base.x + w / 2.0, y), Vector2(base.x, y - height * 0.3),
		]), color)
