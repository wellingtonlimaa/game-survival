extends Control

@export var minimap_size: Vector2 = Vector2(180, 130)

var map: Resource
var world: Dictionary = {}
var player: Node2D


func _ready() -> void:
	custom_minimum_size = minimap_size


func setup(map_data: Resource, world_dict: Dictionary, player_ref: Node2D) -> void:
	map = map_data
	world = world_dict
	player = player_ref


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if map == null:
		return

	# Painel
	var bg := Color(0.067, 0.055, 0.118, 0.85)
	var border := Color(0.275, 0.227, 0.412, 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), bg)
	draw_rect(Rect2(Vector2.ZERO, size), border, false, 2.0)

	var sx: float = size.x / float(map.world_width)
	var sy: float = size.y / float(map.world_height)

	# Tons do bioma
	draw_rect(Rect2(Vector2.ZERO, size), Color(map.ground_color.r, map.ground_color.g, map.ground_color.b, 0.55))

	# Landmarks
	for lm in world.get("landmarks", []):
		var pos: Vector2 = lm["pos"]
		var screen_pos := Vector2(pos.x * sx, pos.y * sy)
		var r: Variant = lm["radius"]
		var draw_r := 4.0
		if typeof(r) == TYPE_VECTOR2:
			draw_r = max((r as Vector2).x * sx, 3.0)
		else:
			draw_r = max(float(r) * sx, 3.0)
		var col := Color.WHITE
		match lm["kind"]:
			"lake": col = map.lake_color
			"ruin": col = map.ruin_color
			"boss_clearing": col = Color(1, 0.776, 0.298, 0.6)
			"spawn_clearing": col = Color(0.439, 0.871, 0.494, 0.3)
		draw_circle(screen_pos, draw_r, col)

	# Obstáculos (amostrados)
	var i := 0
	for o in world.get("obstacles", []):
		i += 1
		if i % 3 != 0:
			continue
		var pos: Vector2 = o["pos"]
		draw_rect(Rect2(Vector2(pos.x * sx, pos.y * sy) - Vector2(1, 1), Vector2(2, 2)), o["color"])

	# Altares
	for a in world.get("altars", []):
		var pos: Vector2 = a["pos"]
		var col := Color.WHITE
		match a["kind"]:
			"heal":  col = Color(0.439, 0.871, 0.494)
			"xp":    col = Color(0.553, 0.412, 0.886)
			"gold":  col = Color(1.0, 0.776, 0.298)
			"storm": col = Color(0.392, 0.808, 0.929)
			"elite": col = Color(0.886, 0.275, 0.345)
		draw_circle(Vector2(pos.x * sx, pos.y * sy), 3.0, col)

	# Player
	if player != null:
		var pp := Vector2(player.global_position.x * sx, player.global_position.y * sy)
		draw_circle(pp, 4.0, Color(0.953, 0.929, 0.871, 1.0))
		draw_circle(pp, 2.0, Color(0.392, 0.808, 0.929, 1.0))
