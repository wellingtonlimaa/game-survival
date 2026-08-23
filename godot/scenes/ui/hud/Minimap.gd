extends Control

## Minimapa: mundo, altares, mercador, inimigos, chefe e o herói.

const P := preload("res://scripts/utils/Theme.gd")

@export var minimap_size: Vector2 = Vector2(120, 88)

var map: Resource
var world: Dictionary = {}
var player: Node2D
var game: Node = null
var _time: float = 0.0
var _frame: int = 0


func _ready() -> void:
	custom_minimum_size = minimap_size
	size = minimap_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(map_data: Resource, world_dict: Dictionary, player_ref: Node2D, game_ref: Node = null) -> void:
	map = map_data
	world = world_dict
	player = player_ref
	game = game_ref


func _process(delta: float) -> void:
	_time += delta
	# 60 fps de minimapa é desperdício: redesenha ~12x por segundo
	_frame += 1
	if _frame % 5 == 0:
		queue_redraw()


func _draw() -> void:
	if map == null:
		return

	var bg := Color(0.067, 0.055, 0.118, 0.80)
	draw_rect(Rect2(Vector2.ZERO, size), bg)
	draw_rect(Rect2(Vector2.ZERO, size), Color(map.ground_color.r, map.ground_color.g, map.ground_color.b, 0.45))
	draw_rect(Rect2(Vector2.ZERO, size), P.BORDER, false, 2.0)

	var sx: float = size.x / float(map.world_width)
	var sy: float = size.y / float(map.world_height)

	# Landmarks
	for lm in world.get("landmarks", []):
		var pos: Vector2 = lm["pos"]
		var screen_pos := Vector2(pos.x * sx, pos.y * sy)
		var r: Variant = lm["radius"]
		var draw_r: float = maxf((r as Vector2).x * sx, 2.5) if typeof(r) == TYPE_VECTOR2 else maxf(float(r) * sx, 2.5)
		var col := Color.WHITE
		match lm["kind"]:
			"lake": col = map.lake_color
			"ruin": col = map.ruin_color
			"boss_clearing": col = Color(1, 0.776, 0.298, 0.45)
			"spawn_clearing": col = Color(0.439, 0.871, 0.494, 0.25)
		draw_circle(screen_pos, draw_r, col)

	# Obstáculos (amostra)
	var i := 0
	for o in world.get("obstacles", []):
		i += 1
		if i % 5 != 0:
			continue
		var pos: Vector2 = o["pos"]
		draw_rect(Rect2(Vector2(pos.x * sx, pos.y * sy) - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), o["color"])

	# Inimigos
	if game != null and "enemies_container" in game and is_instance_valid(game.enemies_container):
		var drawn: int = 0
		for e in game.enemies_container.get_children():
			if not (e is Node2D):
				continue
			var is_boss_dot: bool = "data" in e and e.data != null and e.data.is_boss()
			if not is_boss_dot:
				drawn += 1
				if drawn > 70:
					continue
			var epos := Vector2(e.global_position.x * sx, e.global_position.y * sy)
			var is_boss: bool = "data" in e and e.data != null and e.data.is_boss()
			if is_boss:
				var pulse: float = 0.6 + 0.4 * sin(_time * 6.0)
				draw_circle(epos, 4.0 * pulse, Color(1.0, 0.25, 0.35, 0.95))
			else:
				draw_circle(epos, 1.4, Color(0.886, 0.275, 0.345, 0.75))

	# Altares
	for a in world.get("altars", []):
		var pos: Vector2 = a["pos"]
		var col := Color.WHITE
		match a["kind"]:
			"heal":  col = P.ACCENT_GREEN
			"xp":    col = P.ACCENT_PURPLE
			"gold":  col = P.ACCENT_GOLD
			"storm": col = P.ACCENT_CYAN
			"elite": col = P.ACCENT_RED
		draw_circle(Vector2(pos.x * sx, pos.y * sy), 2.6, col)

	# Arenas de chefe
	for a in world.get("boss_arenas", []):
		var apos: Vector2 = a["pos"]
		var screen := Vector2(apos.x * sx, apos.y * sy)
		var unlocked: bool = player != null and is_instance_valid(player) and player.level >= int(a["level"])
		var col: Color = P.ACCENT_GOLD if unlocked else Color(0.45, 0.42, 0.55)
		var pulse: float = 0.6 + 0.4 * sin(_time * 3.0) if unlocked else 1.0
		draw_arc(screen, 6.0, 0.0, TAU, 14, Color(col.r, col.g, col.b, pulse), 2.0)
		draw_circle(screen, 2.2, col)

	# Mercador
	if world.has("merchant_pos"):
		var mpos: Vector2 = world["merchant_pos"]
		var blink: float = 0.55 + 0.45 * sin(_time * 3.0)
		draw_circle(Vector2(mpos.x * sx, mpos.y * sy), 3.0, Color(1.0, 0.776, 0.298, blink))

	# Herói
	if player != null and is_instance_valid(player):
		var pp := Vector2(player.global_position.x * sx, player.global_position.y * sy)
		draw_circle(pp, 3.6, P.TEXT_PRIMARY)
		draw_circle(pp, 1.8, P.ACCENT_CYAN)
