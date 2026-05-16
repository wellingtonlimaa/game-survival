extends Node2D

var map: Resource
var world: Dictionary = {}
var _ambient: Array[Dictionary] = []
var _time: float = 0.0


func setup(map_data: Resource, world_dict: Dictionary) -> void:
	map = map_data
	world = world_dict
	_spawn_ambient()
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	for p in _ambient:
		p["angle"] += p["speed"] * delta
		p["pulse"] = 0.6 + 0.4 * sin(_time * 1.6 + p["phase"])
	queue_redraw()


func _spawn_ambient() -> void:
	_ambient.clear()
	if map == null:
		return
	for i in range(map.ambient_count):
		_ambient.append({
			"pos": Vector2(randf() * map.world_width, randf() * map.world_height),
			"angle": randf() * TAU,
			"radius": randf_range(40.0, 90.0),
			"speed": map.ambient_speed * randf_range(0.7, 1.3),
			"size": randf_range(1.4, 2.6),
			"phase": randf() * TAU,
			"pulse": 0.8,
		})


func _draw() -> void:
	if map == null:
		return

	# Fundo do mundo
	draw_rect(Rect2(0, 0, map.world_width, map.world_height), map.ground_color)

	# Tiles em xadrez sutil (variação procedural sem texturas)
	var tile: int = int(map.tile_size)
	var cols: int = int(map.world_width / tile) + 1
	var rows: int = int(map.world_height / tile) + 1
	for r in range(rows):
		for c in range(cols):
			if (r + c) % 3 == 0:
				draw_rect(Rect2(c * tile, r * tile, tile, tile), map.ground_variant_color)

	# Detalhes do terreno
	for d in world.get("details", []):
		draw_circle(d["pos"], d["size"], d["color"])

	# Landmarks
	for lm in world.get("landmarks", []):
		var kind: String = lm["kind"]
		var pos: Vector2 = lm["pos"]
		var r: Variant = lm["radius"]
		match kind:
			"lake":
				var rv: Vector2 = r
				_draw_ellipse(pos, rv, map.lake_color)
				_draw_ellipse(pos, rv * 0.85, Color(map.lake_color.r * 1.2, map.lake_color.g * 1.2, map.lake_color.b * 1.3, 1.0))
			"ruin":
				_draw_ruin(pos, float(r), map.ruin_color)
			"boss_clearing":
				draw_circle(pos, float(r), Color(map.detail_color.r, map.detail_color.g, map.detail_color.b, 0.35))
				draw_arc(pos, float(r) - 6.0, 0.0, TAU, 64, Color(1.0, 0.776, 0.298, 0.45), 2.0)

	# Obstáculos
	for o in world.get("obstacles", []):
		_draw_obstacle(o)

	# Altares (desenho base — a interação acontece em Altar.gd)
	for a in world.get("altars", []):
		_draw_altar(a)

	# Bordas do mundo
	draw_rect(Rect2(0, 0, map.world_width, map.world_height), map.border_color, false, 4.0)

	# Partículas ambientais
	for p in _ambient:
		var pos: Vector2 = p["pos"] + Vector2(cos(p["angle"]) * p["radius"], sin(p["angle"]) * p["radius"] * 0.6)
		var pulse: float = p["pulse"]
		var color: Color = map.ambient_color
		draw_circle(pos, p["size"] * pulse, Color(color.r, color.g, color.b, color.a * pulse))
		draw_circle(pos, p["size"] * 0.4, Color(1.0, 1.0, 0.851, 0.7))

	# Fog leve (cobre tudo se fog_color tem alpha)
	if map.fog_color.a > 0.0:
		draw_rect(Rect2(0, 0, map.world_width, map.world_height), map.fog_color)


func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var n := 32
	for i in range(n):
		var a := float(i) / float(n) * TAU
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)


func _draw_ruin(center: Vector2, radius: float, color: Color) -> void:
	# 4-6 blocos quadrados pra simular ruínas
	var rng := RandomNumberGenerator.new()
	rng.seed = int(center.x * 7 + center.y * 13)
	for i in range(6):
		var a := rng.randf() * TAU
		var d := rng.randf() * radius * 0.65
		var pos := center + Vector2(cos(a) * d, sin(a) * d)
		var s := rng.randf_range(22.0, 44.0)
		draw_rect(Rect2(pos - Vector2(s, s) * 0.5, Vector2(s, s)), color)
		draw_rect(Rect2(pos - Vector2(s, s) * 0.5, Vector2(s, s)), color.darkened(0.4), false, 2.0)


func _draw_obstacle(o: Dictionary) -> void:
	var pos: Vector2 = o["pos"]
	var kind: String = o["kind"]
	var color: Color = o["color"]
	var radius: float = o["radius"]
	var height: float = o.get("height", 36.0)

	# Sombra no chão
	draw_circle(pos + Vector2(2, 4), radius * 1.05, Color(0, 0, 0, 0.32))

	match kind:
		"tree":
			# Tronco
			var trunk_w := radius * 0.5
			draw_rect(Rect2(pos.x - trunk_w * 0.5, pos.y - height * 0.4, trunk_w, height * 0.5), color.darkened(0.35))
			# Copa em 2 camadas
			draw_circle(pos + Vector2(0, -height * 0.5), radius * 1.1, color.darkened(0.15))
			draw_circle(pos + Vector2(0, -height * 0.7), radius * 0.85, color)
		"stone":
			draw_circle(pos, radius * 0.95, color.darkened(0.18))
			draw_circle(pos + Vector2(-radius * 0.3, -radius * 0.35), radius * 0.5, color.lightened(0.10))
		"grave":
			var w := radius * 1.4
			var h := height * 0.8
			draw_rect(Rect2(pos.x - w * 0.5, pos.y - h, w, h), color.darkened(0.10))
			# Arco superior
			draw_circle(pos + Vector2(0, -h), w * 0.5, color.darkened(0.05))
			# Cruz
			draw_rect(Rect2(pos.x - 1.5, pos.y - h * 0.85, 3.0, h * 0.4), color.lightened(0.25))
			draw_rect(Rect2(pos.x - 6.0, pos.y - h * 0.7, 12.0, 3.0), color.lightened(0.25))
		"pillar":
			var pw := radius * 0.7
			var ph := height * 1.2
			draw_rect(Rect2(pos.x - pw * 0.5, pos.y - ph, pw, ph), color)
			draw_rect(Rect2(pos.x - pw * 0.7, pos.y - ph - 4, pw * 1.4, 8.0), color.lightened(0.1))
		"cactus":
			var cw := radius * 0.6
			var ch := height * 1.1
			draw_rect(Rect2(pos.x - cw * 0.5, pos.y - ch, cw, ch), color)
			# Braço lateral
			draw_rect(Rect2(pos.x + cw * 0.3, pos.y - ch * 0.55, cw * 0.5, cw * 1.4), color)
			draw_rect(Rect2(pos.x + cw * 0.3, pos.y - ch * 0.85, cw * 0.45, ch * 0.4), color)
		"bone":
			var bw := radius * 1.3
			draw_rect(Rect2(pos.x - bw * 0.5, pos.y - 4, bw, 8.0), color.lightened(0.3))
			draw_circle(pos - Vector2(bw * 0.5, 0), 5.0, color.lightened(0.3))
			draw_circle(pos + Vector2(bw * 0.5, 0), 5.0, color.lightened(0.3))
		_:
			draw_circle(pos, radius, color)


func _draw_altar(a: Dictionary) -> void:
	var pos: Vector2 = a["pos"]
	var kind: String = a["kind"]
	var radius: float = a.get("radius", 24.0)
	var active: bool = a.get("active", true)

	var altar_colors := {
		"heal":  Color(0.439, 0.871, 0.494, 1.0),
		"xp":    Color(0.553, 0.412, 0.886, 1.0),
		"gold":  Color(1.0, 0.776, 0.298, 1.0),
		"storm": Color(0.392, 0.808, 0.929, 1.0),
		"elite": Color(0.886, 0.275, 0.345, 1.0),
	}
	var col: Color = altar_colors.get(kind, Color.WHITE)
	if not active:
		col = col.darkened(0.6)

	# Base
	draw_circle(pos + Vector2(0, 6), radius * 1.1, Color(0, 0, 0, 0.4))
	draw_circle(pos, radius, Color(0.118, 0.094, 0.18, 1.0))
	# Pedestal
	draw_rect(Rect2(pos.x - radius * 0.55, pos.y - radius * 0.2, radius * 1.1, radius * 0.6), Color(0.275, 0.227, 0.412, 1.0))
	# Cristal
	var crystal_size := radius * 0.55
	var crystal := PackedVector2Array([
		pos + Vector2(0, -crystal_size),
		pos + Vector2(crystal_size * 0.55, 0),
		pos + Vector2(0, crystal_size * 0.55),
		pos + Vector2(-crystal_size * 0.55, 0),
	])
	draw_colored_polygon(crystal, col)
	# Brilho pulsante
	if active:
		var pulse: float = 0.5 + 0.5 * sin(_time * 2.5)
		draw_circle(pos + Vector2(0, -crystal_size * 0.3), 4.0 + pulse * 2.0, Color(col.r, col.g, col.b, 0.55 * pulse))
