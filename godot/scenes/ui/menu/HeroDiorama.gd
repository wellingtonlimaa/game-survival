extends Control

@export var hero_size: Vector2 = Vector2(360, 320)

var _time: float = 0.0
var _particles: Array[Dictionary] = []


func _ready() -> void:
	custom_minimum_size = hero_size
	# Spawna partículas orbitais (vagalumes)
	for i in range(14):
		_particles.append({
			"angle": randf() * TAU,
			"radius": randf_range(70.0, 130.0),
			"speed": randf_range(0.35, 0.85),
			"size": randf_range(1.6, 3.2),
			"phase": randf() * TAU,
		})


func _process(delta: float) -> void:
	_time += delta
	for p in _particles:
		p["angle"] += p["speed"] * delta
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0

	# Halo da lua (gradient circular fake via círculos concêntricos)
	for i in range(12, 0, -1):
		var r := 70.0 + i * 6.0
		var a := 0.04 + (12.0 - i) * 0.005
		draw_circle(center + Vector2(0, -12), r, Color(0.553, 0.412, 0.886, a))

	# Lua
	draw_circle(center + Vector2(0, -12), 64.0, Color(0.984, 0.918, 0.745, 1.0))
	# Cratera (sombra)
	draw_circle(center + Vector2(16, -28), 14.0, Color(0.808, 0.749, 0.604, 0.55))
	draw_circle(center + Vector2(-18, -2), 8.0, Color(0.808, 0.749, 0.604, 0.55))

	# Silhueta de árvores no chão (foreground)
	var ground_y: float = size.y - 48.0
	# Chão
	draw_rect(Rect2(Vector2(0, ground_y), Vector2(size.x, 48.0)), Color(0.043, 0.035, 0.078, 1.0))

	# Árvores em silhueta
	_draw_tree(Vector2(60, ground_y), 60.0, Color(0.055, 0.043, 0.094, 1.0))
	_draw_tree(Vector2(120, ground_y), 80.0, Color(0.075, 0.063, 0.114, 1.0))
	_draw_tree(Vector2(size.x - 110, ground_y), 78.0, Color(0.075, 0.063, 0.114, 1.0))
	_draw_tree(Vector2(size.x - 50, ground_y), 56.0, Color(0.055, 0.043, 0.094, 1.0))

	# Personagem (silhueta animada — bobbing)
	var bob := sin(_time * 2.5) * 3.0
	var feet := Vector2(center.x, ground_y - 4.0 + bob)
	draw_circle(feet + Vector2(0, -38), 14.0, Color(0.118, 0.094, 0.18, 1.0))   # cabeça
	draw_rect(Rect2(feet + Vector2(-12, -28), Vector2(24, 28)), Color(0.275, 0.227, 0.412, 1.0))  # tronco/capuz
	draw_circle(feet + Vector2(-4, -34), 2.6, Color(1.0, 0.776, 0.298, 1.0))    # olho dourado
	draw_circle(feet + Vector2(4, -34), 2.6, Color(1.0, 0.776, 0.298, 1.0))

	# Vagalumes
	for p in _particles:
		var angle: float = p["angle"]
		var radius: float = p["radius"]
		var pulse: float = 0.5 + 0.5 * sin(_time * 3.0 + p["phase"])
		var pos := center + Vector2(cos(angle) * radius, sin(angle) * radius * 0.6 - 20)
		draw_circle(pos, p["size"], Color(1.0, 0.882, 0.502, 0.35 + 0.45 * pulse))
		draw_circle(pos, p["size"] * 0.4, Color(1.0, 1.0, 0.851, 0.85))


func _draw_tree(base: Vector2, height: float, color: Color) -> void:
	var trunk_w := height * 0.12
	# Tronco
	draw_rect(Rect2(base - Vector2(trunk_w / 2.0, height * 0.45), Vector2(trunk_w, height * 0.45)), color)
	# Copa (triângulos empilhados)
	for i in range(3):
		var y := base.y - height * (0.45 + i * 0.18)
		var w := height * (0.55 - i * 0.10)
		var pts := PackedVector2Array([
			Vector2(base.x - w / 2.0, y),
			Vector2(base.x + w / 2.0, y),
			Vector2(base.x, y - height * 0.28),
		])
		draw_colored_polygon(pts, color)
