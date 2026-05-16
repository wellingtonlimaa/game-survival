extends Control

# Background sombrio: gradiente noturno + padrão de pontos (halftone-like)
@export var dot_color: Color = Color(0.275, 0.227, 0.412, 0.32)
@export var dot_radius: float = 1.5
@export var dot_spacing: float = 22.0

var _time: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	# Gradiente vertical (top mais escuro → bottom roxo)
	var steps := 24
	for i in range(steps):
		var t := float(i) / float(steps)
		var top := Color(0.055, 0.043, 0.094, 1.0)
		var mid := Color(0.094, 0.063, 0.149, 1.0)
		var btm := Color(0.110, 0.094, 0.165, 1.0)
		var col: Color
		if t < 0.5:
			col = top.lerp(mid, t * 2.0)
		else:
			col = mid.lerp(btm, (t - 0.5) * 2.0)
		draw_rect(Rect2(0.0, t * size.y, size.x, size.y / float(steps) + 1.0), col)

	# Padrão de pontos (offset alternado, "halftone")
	var cols := int(size.x / dot_spacing) + 2
	var rows := int(size.y / dot_spacing) + 2
	for r in range(rows):
		for c in range(cols):
			var x: float = c * dot_spacing + (dot_spacing / 2.0 if r % 2 == 0 else 0.0)
			var y: float = r * dot_spacing
			# Pulso sutil pra dar vida
			var pulse: float = 0.7 + 0.3 * sin(_time * 0.7 + r * 0.4 + c * 0.2)
			draw_circle(Vector2(x, y), dot_radius * pulse, dot_color)
