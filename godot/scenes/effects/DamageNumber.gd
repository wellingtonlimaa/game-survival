extends Node2D

## Número de dano. Desenha UMA vez e depois só anima posição/opacidade via
## propriedades do nó — redesenhar texto todo quadro derruba o FPS com horda.

const P := preload("res://scripts/utils/Theme.gd")

@export var lifetime: float = 0.75

var _time: float = 0.0
var _color: Color = Color.WHITE
var _crit: bool = false
var _text: String = ""
var _drift: float = 0.0
var _font_size: int = 18
var _rise: float = 58.0


func setup(value: float, color: Color, crit: bool = false) -> void:
	_color = color
	_crit = crit
	_text = "%d" % int(round(value))
	if crit:
		_text += "!"
		_font_size = 26
		lifetime = 0.9
	_drift = randf_range(-24.0, 24.0)
	z_index = 50
	scale = Vector2(1.35, 1.35) if crit else Vector2(1.15, 1.15)
	queue_redraw()


func setup_text(text: String, color: Color) -> void:
	_text = text
	_color = color
	_font_size = 16
	lifetime = 1.0
	_drift = randf_range(-10.0, 10.0)
	_rise = 40.0
	z_index = 50
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	if _time >= lifetime:
		queue_free()
		return
	var t: float = _time / lifetime
	position.y -= (_rise * (1.0 - t) + 10.0) * delta
	position.x += _drift * delta
	modulate.a = 1.0 - pow(t, 2.2)
	# Pop inicial só nos primeiros quadros
	if t < 0.12:
		var pop: float = 1.0 + (0.35 if _crit else 0.15) * (1.0 - t / 0.12)
		scale = Vector2(pop, pop)


func _draw() -> void:
	var font: Font = ThemeDB.fallback_font
	var width: float = 90.0
	var pos := Vector2(-width * 0.5, 0)
	# draw_string_outline resolve o contorno em UMA chamada (antes eram 4)
	draw_string_outline(font, pos, _text, HORIZONTAL_ALIGNMENT_CENTER, width, _font_size, 4, Color(0.043, 0.035, 0.078, 0.9))
	draw_string(font, pos, _text, HORIZONTAL_ALIGNMENT_CENTER, width, _font_size, _color)
