extends Node2D

@export var color_body: Color = Color(0.275, 0.227, 0.412, 1.0)
@export var color_head: Color = Color(0.118, 0.094, 0.18, 1.0)
@export var color_eyes: Color = Color(1.0, 0.776, 0.298, 1.0)

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var bob := sin(_time * 6.0) * 1.5

	# Sombra
	_draw_filled_ellipse(Vector2(0, 16), Vector2(14, 5), Color(0, 0, 0, 0.45))

	# Tronco / capa
	draw_rect(Rect2(-10, -14 + bob, 20, 22), color_body)
	# Cabeça
	draw_circle(Vector2(0, -22 + bob), 11, color_head)
	# Olhos
	draw_circle(Vector2(-3.5, -22 + bob), 2.4, color_eyes)
	draw_circle(Vector2(3.5, -22 + bob), 2.4, color_eyes)


func _draw_filled_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var pts := PackedVector2Array()
	var n := 18
	for i in range(n):
		var a := float(i) / float(n) * TAU
		pts.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(pts, color)
