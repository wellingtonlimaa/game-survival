extends Node2D

## Cenário do mapa.
##
## O chão tem milhares de primitivas (mosaico, grama, obstáculos). Desenhar
## isso todo quadro custava ~40 FPS, então o cenário é "assado" UMA vez num
## SubViewport e vira uma textura única. Só as partículas seguem animadas.

var map: Resource
var world: Dictionary = {}
var _ambient: Array[Dictionary] = []
var _tufts: Array = []
var _viewport: SubViewport = null
var _sprite: Sprite2D = null
var _painter: Node2D = null
var _frames_until_freeze: int = 3


func setup(map_data: Resource, world_dict: Dictionary) -> void:
	map = map_data
	world = world_dict
	z_index = -10
	# Precisa rodar mesmo com o jogo pausado pra congelar a textura do cenário
	process_mode = Node.PROCESS_MODE_ALWAYS
	_spawn_ambient()
	_build_tufts()
	_bake_static_world()

	var ambient := _AmbientLayer.new()
	ambient.z_index = 1
	ambient.particles = _ambient
	ambient.ambient_color = map.ambient_color
	ambient.lake = _first_lake()
	add_child(ambient)


func _process(_delta: float) -> void:
	# Assim que a textura fica pronta, o viewport para de renderizar
	if _viewport == null:
		set_process(false)
		return
	_frames_until_freeze -= 1
	if _frames_until_freeze <= 0:
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		set_process(false)


func _bake_static_world() -> void:
	# Mapa grande em resolução cheia estouraria a VRAM (4200x2900 = ~48 MB).
	# Então a textura é assada com no máximo ~8 milhões de pixels e esticada.
	var pixels: float = float(map.world_width) * float(map.world_height)
	var bake_scale: float = 1.0
	if pixels > 8000000.0:
		bake_scale = sqrt(8000000.0 / pixels)

	_viewport = SubViewport.new()
	_viewport.size = Vector2i(int(map.world_width * bake_scale), int(map.world_height * bake_scale))
	_viewport.transparent_bg = false
	_viewport.disable_3d = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	add_child(_viewport)

	_painter = _StaticPainter.new()
	_painter.renderer = self
	_painter.scale = Vector2(bake_scale, bake_scale)
	_viewport.add_child(_painter)

	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.texture = _viewport.get_texture()
	_sprite.scale = Vector2(1.0 / bake_scale, 1.0 / bake_scale)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_sprite.z_index = 0
	add_child(_sprite)


func _first_lake() -> Dictionary:
	for lm in world.get("landmarks", []):
		if lm["kind"] == "lake":
			return {"pos": lm["pos"], "radius": lm["radius"]}
	return {}


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
			"size": randf_range(1.6, 3.0),
			"phase": randf() * TAU,
			"pulse": 0.8,
		})


## Tufos de grama/detritos: dão textura ao chão sem custo de asset.
func _build_tufts() -> void:
	_tufts.clear()
	if map == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(map.key)
	var tuft_count: int = int(clampf(float(map.world_width) * float(map.world_height) / 9000.0, 600.0, 1800.0))
	for i in range(tuft_count):
		_tufts.append({
			"pos": Vector2(rng.randf() * map.world_width, rng.randf() * map.world_height),
			"h": rng.randf_range(4.0, 9.0),
			"w": rng.randf_range(1.0, 2.2),
			"tilt": rng.randf_range(-0.5, 0.5),
			"shade": rng.randf(),
		})


# --- Camada animada (fora da textura) ----------------------------------------

class _AmbientLayer extends Node2D:
	var particles: Array = []
	var ambient_color: Color = Color(1, 1, 1, 0.4)
	var lake: Dictionary = {}
	var t: float = 0.0

	func _process(delta: float) -> void:
		t += delta
		for p in particles:
			p["angle"] += p["speed"] * delta
			p["pulse"] = 0.6 + 0.4 * sin(t * 1.6 + p["phase"])
		queue_redraw()

	func _draw() -> void:
		if not lake.is_empty():
			var rv: Vector2 = lake["radius"]
			var center: Vector2 = lake["pos"]
			var shimmer: float = 0.30 + 0.18 * sin(t * 1.2)
			var pts := PackedVector2Array()
			for i in range(16):
				var a := float(i) / 16.0 * TAU
				pts.append(center + Vector2(rv.x * 0.20, -rv.y * 0.25) + Vector2(cos(a) * rv.x * 0.22, sin(a) * rv.y * 0.08))
			draw_colored_polygon(pts, Color(1, 1, 0.92, shimmer * 0.30))
		for p in particles:
			var pos: Vector2 = p["pos"] + Vector2(cos(p["angle"]) * p["radius"], sin(p["angle"]) * p["radius"] * 0.6)
			var pulse: float = p["pulse"]
			draw_circle(pos, float(p["size"]) * pulse * 2.4, Color(ambient_color.r, ambient_color.g, ambient_color.b, ambient_color.a * pulse * 0.32))
			draw_circle(pos, float(p["size"]) * pulse, Color(ambient_color.r, ambient_color.g, ambient_color.b, ambient_color.a * pulse))
			draw_circle(pos, float(p["size"]) * 0.4, Color(1.0, 1.0, 0.9, 0.8 * pulse))


# --- Pintor do cenário (roda dentro do SubViewport, uma vez só) ---------------

class _StaticPainter extends Node2D:
	var renderer: Node2D = null

	func _draw() -> void:
		if renderer == null:
			return
		var map: Resource = renderer.map
		var world: Dictionary = renderer.world
		if map == null:
			return

		var w: float = float(map.world_width)
		var h: float = float(map.world_height)

		# Chão base
		draw_rect(Rect2(0, 0, w, h), map.ground_color)

		# Mosaico suave (dois tons alternados + manchas maiores)
		var tile: int = int(map.tile_size)
		var cols: int = int(w / tile) + 1
		var rows: int = int(h / tile) + 1
		var variant: Color = map.ground_variant_color.lerp(map.ground_color, 0.45)
		var patch: Color = map.ground_color.lerp(map.detail_color, 0.18)
		for r in range(rows):
			for c in range(cols):
				var parity: int = (r + c) % 4
				if parity == 0:
					draw_rect(Rect2(c * tile, r * tile, tile, tile), variant)
				elif parity == 2 and ((r * 7 + c * 13) % 5 == 0):
					draw_rect(Rect2(c * tile, r * tile, tile, tile), patch)

		# Detalhes finos (pedrinhas/folhas)
		for d in world.get("details", []):
			draw_circle(d["pos"], d["size"], d["color"])

		# Tufos de grama
		var tuft_dark: Color = map.detail_color.darkened(0.15)
		var tuft_light: Color = map.detail_color.lightened(0.20)
		for t in renderer._tufts:
			var pos: Vector2 = t["pos"]
			var col: Color = tuft_light if float(t["shade"]) > 0.65 else tuft_dark
			draw_line(pos, pos + Vector2(float(t["tilt"]) * 3.0, -float(t["h"])), col, float(t["w"]))

		# Marcos
		for lm in world.get("landmarks", []):
			var kind: String = lm["kind"]
			var pos: Vector2 = lm["pos"]
			var r: Variant = lm["radius"]
			match kind:
				"lake":
					var rv: Vector2 = r
					_ellipse(pos, rv, map.lake_color.darkened(0.25))
					_ellipse(pos, rv * 0.94, map.lake_color)
					_ellipse(pos, rv * 0.80, map.lake_color.lightened(0.12))
				"ruin":
					_ruin(pos, float(r), map.ruin_color)
				"boss_clearing":
					draw_circle(pos, float(r), Color(map.detail_color.r, map.detail_color.g, map.detail_color.b, 0.30))
					draw_arc(pos, float(r) - 6.0, 0.0, TAU, 48, Color(1.0, 0.776, 0.298, 0.35), 2.0)
					for i in range(8):
						var a: float = float(i) / 8.0 * TAU
						draw_circle(pos + Vector2(cos(a), sin(a)) * (float(r) - 24.0), 4.0, Color(1.0, 0.776, 0.298, 0.30))

		# Obstáculos
		for o in world.get("obstacles", []):
			_obstacle(o, map)

		# Escurecimento nas bordas do mundo
		var edge: float = 140.0
		for i in range(6):
			var t2: float = float(i) / 6.0
			var inset: float = edge * (1.0 - t2)
			draw_rect(Rect2(0, 0, w, inset), Color(0.02, 0.01, 0.04, 0.07))
			draw_rect(Rect2(0, h - inset, w, inset), Color(0.02, 0.01, 0.04, 0.07))
			draw_rect(Rect2(0, 0, inset, h), Color(0.02, 0.01, 0.04, 0.07))
			draw_rect(Rect2(w - inset, 0, inset, h), Color(0.02, 0.01, 0.04, 0.07))
		draw_rect(Rect2(0, 0, w, h), map.border_color, false, 6.0)

		# Névoa do bioma
		if map.fog_color.a > 0.0:
			draw_rect(Rect2(0, 0, w, h), map.fog_color)

	func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(28):
			var a := float(i) / 28.0 * TAU
			pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
		draw_colored_polygon(pts, color)

	func _ruin(center: Vector2, radius: float, color: Color) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(center.x * 7 + center.y * 13)
		draw_circle(center, radius * 0.9, color.darkened(0.55))
		for i in range(7):
			var a := rng.randf() * TAU
			var d := rng.randf() * radius * 0.65
			var pos := center + Vector2(cos(a) * d, sin(a) * d)
			var s := rng.randf_range(20.0, 46.0)
			var height := rng.randf_range(10.0, 30.0)
			draw_rect(Rect2(pos - Vector2(s, s) * 0.5 + Vector2(3, 5), Vector2(s, s)), Color(0, 0, 0, 0.3))
			draw_rect(Rect2(pos - Vector2(s * 0.5, s * 0.5 + height), Vector2(s, s * 0.5 + height)), color.darkened(0.2))
			draw_rect(Rect2(pos - Vector2(s * 0.5, s * 0.5 + height), Vector2(s, 6.0)), color.lightened(0.15))

	func _obstacle(o: Dictionary, map: Resource) -> void:
		var pos: Vector2 = o["pos"]
		var kind: String = o["kind"]
		var color: Color = o["color"]
		var radius: float = o["radius"]
		var height: float = o.get("height", 36.0)
		var sway: float = sin(pos.x * 0.01) * 1.5

		draw_circle(pos + Vector2(3, 5), radius * 1.05, Color(0, 0, 0, 0.30))

		match kind:
			"tree":
				var lit: Color = map.detail_color
				var trunk_w := radius * 0.42
				draw_rect(Rect2(pos.x - trunk_w * 0.5, pos.y - height * 0.42, trunk_w, height * 0.5), color.darkened(0.5))
				draw_circle(pos + Vector2(sway, -height * 0.45), radius * 1.18, color.darkened(0.2))
				draw_circle(pos + Vector2(sway * 1.2, -height * 0.62), radius * 0.98, color.lerp(lit, 0.45))
				draw_circle(pos + Vector2(sway * 1.4 - radius * 0.28, -height * 0.80), radius * 0.62, color.lerp(lit, 0.75))
				draw_circle(pos + Vector2(sway * 1.5 - radius * 0.42, -height * 0.92), radius * 0.26, lit.lerp(Color(1, 1, 0.85), 0.25))
			"stone":
				draw_circle(pos, radius * 0.95, color.darkened(0.25))
				draw_circle(pos + Vector2(-radius * 0.28, -radius * 0.32), radius * 0.55, color.lightened(0.12))
				draw_arc(pos, radius * 0.95, 0.6, 2.4, 10, color.darkened(0.5), 2.0)
			"grave":
				var gw := radius * 1.3
				var gh := height * 0.8
				draw_rect(Rect2(pos.x - gw * 0.5, pos.y - gh, gw, gh), color.darkened(0.12))
				draw_circle(pos + Vector2(0, -gh), gw * 0.5, color.darkened(0.05))
				draw_rect(Rect2(pos.x - 1.8, pos.y - gh * 0.85, 3.6, gh * 0.42), color.lightened(0.3))
				draw_rect(Rect2(pos.x - 7.0, pos.y - gh * 0.72, 14.0, 3.2), color.lightened(0.3))
				draw_rect(Rect2(pos.x - gw * 0.5, pos.y - 4.0, gw, 4.0), color.darkened(0.4))
			"pillar":
				var pw := radius * 0.66
				var ph := height * 1.25
				draw_rect(Rect2(pos.x - pw * 0.5, pos.y - ph, pw, ph), color)
				draw_rect(Rect2(pos.x - pw * 0.5, pos.y - ph, pw * 0.3, ph), color.lightened(0.12))
				draw_rect(Rect2(pos.x - pw * 0.72, pos.y - ph - 5.0, pw * 1.44, 9.0), color.lightened(0.18))
				draw_rect(Rect2(pos.x - pw * 0.72, pos.y - 6.0, pw * 1.44, 8.0), color.darkened(0.25))
			"cactus":
				var cw := radius * 0.55
				var ch := height * 1.1
				draw_rect(Rect2(pos.x - cw * 0.5, pos.y - ch, cw, ch), color)
				draw_rect(Rect2(pos.x - cw * 0.5, pos.y - ch, cw * 0.3, ch), color.lightened(0.15))
				draw_rect(Rect2(pos.x + cw * 0.3, pos.y - ch * 0.55, cw * 0.5, cw * 1.3), color)
				draw_rect(Rect2(pos.x + cw * 0.3, pos.y - ch * 0.85, cw * 0.45, ch * 0.4), color)
				draw_rect(Rect2(pos.x - cw * 1.0, pos.y - ch * 0.5, cw * 0.45, cw * 1.2), color)
			"bone":
				var bw := radius * 1.25
				draw_rect(Rect2(pos.x - bw * 0.5, pos.y - 4, bw, 7.0), color.lightened(0.35))
				draw_circle(pos - Vector2(bw * 0.5, 0), 5.0, color.lightened(0.35))
				draw_circle(pos + Vector2(bw * 0.5, 0), 5.0, color.lightened(0.35))
				draw_circle(pos + Vector2(bw * 0.5, -6), 4.0, color.lightened(0.28))
			_:
				draw_circle(pos, radius, color)
