extends Node2D

## Efeito visual temporário: anel, leque, cone, explosão, raio ou faísca.
## Tudo desenhado proceduralmente — sem sprites.

var kind: String = "ring"
var radius: float = 80.0
var color: Color = Color.WHITE
var duration: float = 0.25
var angle: float = 0.0
var arc: float = TAU
var follow: Node2D = null
var points: PackedVector2Array = PackedVector2Array()
var particles: Array = []

var _elapsed: float = 0.0


func setup(p_kind: String, p_radius: float, p_color: Color, p_duration: float, p_angle: float = 0.0, p_arc: float = TAU) -> void:
	kind = p_kind
	radius = p_radius
	color = p_color
	duration = maxf(0.05, p_duration)
	angle = p_angle
	arc = p_arc
	z_index = 6
	if kind == "impact" or kind == "explosion":
		_make_particles(10 if kind == "impact" else 18)
	queue_redraw()


func setup_lightning(p_points: PackedVector2Array, p_color: Color, p_duration: float) -> void:
	kind = "lightning"
	points = p_points
	color = p_color
	duration = maxf(0.05, p_duration)
	z_index = 7
	queue_redraw()


func _make_particles(count: int) -> void:
	particles.clear()
	for i in range(count):
		var a: float = randf() * TAU
		particles.append({
			"dir": Vector2(cos(a), sin(a)),
			"speed": randf_range(60.0, 220.0),
			"size": randf_range(1.6, 3.6),
		})


func _process(delta: float) -> void:
	_elapsed += delta
	if follow != null and is_instance_valid(follow) and (kind == "arc" or kind == "cone"):
		global_position = follow.global_position
	if _elapsed >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t: float = clampf(_elapsed / duration, 0.0, 1.0)
	var alpha: float = 1.0 - t
	var col := Color(color.r, color.g, color.b, alpha)

	match kind:
		"ring":
			var r: float = radius * (0.35 + t * 0.85)
			draw_arc(Vector2.ZERO, r, 0.0, TAU, 42, Color(col.r, col.g, col.b, alpha * 0.8), 4.0 * (1.0 - t * 0.6))
		"arc":
			var start: float = angle - arc * 0.5
			var swing: float = start + arc * clampf(t * 1.6, 0.0, 1.0)
			draw_arc(Vector2.ZERO, radius * 0.92, start, swing, 32, Color(col.r, col.g, col.b, alpha * 0.9), 9.0)
			draw_arc(Vector2.ZERO, radius * 0.72, start, swing, 32, Color(1, 1, 1, alpha * 0.35), 3.0)
		"cone":
			# Jato de chamas: bolhas ao longo do cone, do quente pro escuro
			var puffs := 9
			for i in range(puffs):
				var f: float = float(i) / float(puffs - 1)
				var spread: float = arc * 0.5 * f
				for side in [-1.0, 0.0, 1.0]:
					if side != 0.0 and f < 0.25:
						continue
					var a: float = angle + spread * side * 0.85
					var dist: float = radius * (0.12 + f * 0.9)
					var pos: Vector2 = Vector2(cos(a), sin(a)) * dist
					var wobble: float = 1.0 + sin(_elapsed * 26.0 + float(i) * 1.7 + side) * 0.12
					var size: float = radius * (0.10 + f * 0.17) * wobble
					var heat: Color = Color(1.0, 0.85, 0.45).lerp(col, f)
					draw_circle(pos, size, Color(heat.r, heat.g, heat.b, alpha * (0.55 - f * 0.25)))
			draw_circle(Vector2(cos(angle), sin(angle)) * radius * 0.12, radius * 0.16, Color(1.0, 0.95, 0.7, alpha * 0.7))
		"explosion":
			draw_circle(Vector2.ZERO, radius * (0.5 + t * 0.6), Color(col.r, col.g, col.b, alpha * 0.35))
			draw_arc(Vector2.ZERO, radius * (0.6 + t * 0.5), 0.0, TAU, 40, Color(1, 1, 1, alpha * 0.55), 3.0)
			_draw_particles(t, alpha, 1.0)
		"impact":
			_draw_particles(t, alpha, 0.5)
			draw_circle(Vector2.ZERO, radius * (1.0 - t) * 0.5, Color(1, 1, 1, alpha * 0.5))
		"lightning":
			if points.size() >= 2:
				for i in range(1, points.size()):
					var p1: Vector2 = to_local(points[i - 1])
					var p2: Vector2 = to_local(points[i])
					_draw_bolt(p1, p2, Color(col.r, col.g, col.b, alpha), 3.0)
					_draw_bolt(p1, p2, Color(1, 1, 1, alpha * 0.7), 1.2)
		"telegraph":
			draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, 0.18 * alpha))
			draw_arc(Vector2.ZERO, radius - 3.0, -PI / 2.0, -PI / 2.0 + t * TAU, 32, Color(col.r, col.g, col.b, 0.85), 3.0)


func _scaled(pts: PackedVector2Array, factor: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p * factor)
	return out


func _draw_particles(t: float, alpha: float, scale: float) -> void:
	for p in particles:
		var dir: Vector2 = p["dir"]
		var dist: float = float(p["speed"]) * t * scale
		draw_circle(dir * dist, float(p["size"]) * (1.0 - t), Color(color.r, color.g, color.b, alpha))


func _draw_bolt(from: Vector2, to: Vector2, col: Color, width: float) -> void:
	var segments := 6
	var prev := from
	var normal: Vector2 = (to - from).normalized().rotated(PI / 2.0)
	for i in range(1, segments + 1):
		var t: float = float(i) / float(segments)
		var base: Vector2 = from.lerp(to, t)
		var offset: float = 0.0
		if i < segments:
			offset = sin(float(i) * 12.7 + _elapsed * 40.0) * 9.0
		var point: Vector2 = base + normal * offset
		draw_line(prev, point, col, width)
		prev = point
