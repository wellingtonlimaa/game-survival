extends CanvasLayer

## Feedback de tela: tremor de câmera, flash, vinheta de vida baixa,
## escurecimento (eclipse) e hit-stop.
## Antes os sinais de shake/flash eram emitidos e ninguém escutava.

const P := preload("res://scripts/utils/Theme.gd")

var camera: Camera2D = null
var player: Node2D = null

var shake_intensity: float = 0.0
var shake_time: float = 0.0
var shake_total: float = 0.0
var darkness: float = 0.0

var _flash_color: Color = Color(0, 0, 0, 0)
var _flash_time: float = 0.0
var _flash_total: float = 0.0
var _hp_pct: float = 1.0
var _time: float = 0.0
var _hitstop_until: int = 0
var _overlay: Control


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)

	EventBus.screen_shake_requested.connect(_on_shake)
	EventBus.flash_requested.connect(_on_flash)
	EventBus.hitstop_requested.connect(_on_hitstop)


func bind(p_player: Node2D) -> void:
	player = p_player
	if player != null and player.has_node("Camera"):
		camera = player.get_node("Camera")
	if player != null and player.has_signal("hp_changed"):
		player.hp_changed.connect(func(cur, mx): _hp_pct = cur / maxf(1.0, mx))


func _process(delta: float) -> void:
	_time += delta

	if _hitstop_until > 0 and Time.get_ticks_msec() >= _hitstop_until:
		_hitstop_until = 0
		Engine.time_scale = 1.0

	if shake_time > 0.0:
		shake_time = maxf(0.0, shake_time - delta)
		if camera != null and is_instance_valid(camera):
			var falloff: float = shake_time / maxf(0.01, shake_total)
			var power: float = shake_intensity * falloff * 14.0
			camera.offset = Vector2(randf_range(-power, power), randf_range(-power, power))
	elif camera != null and is_instance_valid(camera) and camera.offset != Vector2.ZERO:
		camera.offset = camera.offset.lerp(Vector2.ZERO, clampf(delta * 12.0, 0.0, 1.0))

	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)

	_overlay.queue_redraw()


func _on_shake(intensity: float, duration: float) -> void:
	if intensity * duration < shake_intensity * shake_time:
		return
	shake_intensity = clampf(intensity, 0.0, 2.0)
	shake_time = duration
	shake_total = duration


func _on_flash(color: Color, duration: float) -> void:
	_flash_color = color
	_flash_time = duration
	_flash_total = maxf(0.05, duration)


func _on_hitstop(duration: float) -> void:
	Engine.time_scale = 0.08
	_hitstop_until = Time.get_ticks_msec() + int(duration * 1000.0)


func set_darkness(value: float) -> void:
	darkness = clampf(value, 0.0, 0.8)


func _draw_overlay() -> void:
	var size: Vector2 = _overlay.size

	# Escuridão do eclipse (buraco de luz ao redor do herói)
	if darkness > 0.0:
		var steps := 7
		for i in range(steps):
			var t: float = float(i) / float(steps)
			var inset: float = size.x * 0.16 * t
			var a: float = darkness * (0.16 + t * 0.10)
			_overlay.draw_rect(Rect2(0, 0, size.x, inset), Color(0.02, 0.01, 0.05, a))
			_overlay.draw_rect(Rect2(0, size.y - inset, size.x, inset), Color(0.02, 0.01, 0.05, a))
			_overlay.draw_rect(Rect2(0, 0, inset, size.y), Color(0.02, 0.01, 0.05, a))
			_overlay.draw_rect(Rect2(size.x - inset, 0, inset, size.y), Color(0.02, 0.01, 0.05, a))

	# Vinheta constante (dá foco no centro)
	var vignette_steps := 6
	for i in range(vignette_steps):
		var t: float = float(i) / float(vignette_steps)
		var inset: float = size.x * 0.10 * (1.0 - t)
		var a: float = 0.05 * (1.0 - t)
		_overlay.draw_rect(Rect2(0, 0, size.x, inset), Color(0, 0, 0, a))
		_overlay.draw_rect(Rect2(0, size.y - inset, size.x, inset), Color(0, 0, 0, a))
		_overlay.draw_rect(Rect2(0, 0, inset, size.y), Color(0, 0, 0, a))
		_overlay.draw_rect(Rect2(size.x - inset, 0, inset, size.y), Color(0, 0, 0, a))

	# Vida baixa: pulso vermelho nas bordas
	if _hp_pct < 0.35:
		var danger: float = (0.35 - _hp_pct) / 0.35
		var pulse: float = 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * 6.0))
		var border: float = size.x * 0.14
		var col := Color(0.886, 0.10, 0.18, 0.30 * danger * pulse)
		for i in range(5):
			var t: float = float(i) / 5.0
			var inset: float = border * (1.0 - t)
			var a: float = col.a * (1.0 - t)
			_overlay.draw_rect(Rect2(0, 0, size.x, inset), Color(col.r, col.g, col.b, a))
			_overlay.draw_rect(Rect2(0, size.y - inset, size.x, inset), Color(col.r, col.g, col.b, a))
			_overlay.draw_rect(Rect2(0, 0, inset, size.y), Color(col.r, col.g, col.b, a))
			_overlay.draw_rect(Rect2(size.x - inset, 0, inset, size.y), Color(col.r, col.g, col.b, a))

	# Flash
	if _flash_time > 0.0:
		var alpha: float = _flash_color.a * (_flash_time / _flash_total)
		_overlay.draw_rect(Rect2(Vector2.ZERO, size), Color(_flash_color.r, _flash_color.g, _flash_color.b, alpha))
