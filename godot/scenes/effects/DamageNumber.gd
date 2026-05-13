extends Node2D

@export var lifetime: float = 0.85

var _time: float = 0.0
var _value: float = 0.0
var _color: Color = Color.WHITE


func setup(value: float, color: Color) -> void:
	_value = value
	_color = color
	z_index = 50


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	position.y -= 36.0 * delta
	queue_redraw()


func _draw() -> void:
	var alpha: float = clamp(1.0 - (_time / lifetime), 0.0, 1.0)
	var col: Color = Color(_color.r, _color.g, _color.b, alpha)
	var outline: Color = Color(0.043, 0.035, 0.078, alpha)
	var text: String = "%d" % int(round(_value))
	var font: Font = ThemeDB.fallback_font
	var size: int = 20
	# Outline (4 offsets)
	for ox in [-1, 1]:
		for oy in [-1, 1]:
			draw_string(font, Vector2(-12 + ox, oy), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, outline)
	draw_string(font, Vector2(-12, 0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, size, col)
