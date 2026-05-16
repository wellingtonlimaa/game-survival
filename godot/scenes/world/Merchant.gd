extends Area2D

@export var cost: int = 90
@export var radius: float = 22.0

var player: Node2D = null
var active: bool = true
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var shape: CircleShape2D = $Collision.shape
	shape.radius = radius


func setup(p_player: Node2D) -> void:
	player = p_player


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if not active:
		return
	if body != player:
		return
	# Tenta comprar upgrade especial
	if int(SaveSystem.get_value("coins", 0)) >= cost:
		SaveSystem.add_coins(-cost)
		active = false
		EventBus.narrative_triggered.emit("🛒 Compra do mercador realizada!")
		# Trigger chest upgrade
		EventBus.chest_opened.emit(self)
		queue_free()
	else:
		EventBus.narrative_triggered.emit("🛒 Falta moeda...")


func _draw() -> void:
	if not active:
		return
	# Sombra
	draw_circle(Vector2(2, 6), radius * 1.1, Color(0, 0, 0, 0.4))
	# Corpo (capuz vermelho)
	draw_rect(Rect2(-radius * 0.7, -radius * 0.6, radius * 1.4, radius * 1.4), Color(0.553, 0.235, 0.247, 1.0))
	# Cabeça
	draw_circle(Vector2(0, -radius * 0.6), radius * 0.55, Color(0.165, 0.118, 0.094, 1.0))
	# Olhos
	draw_circle(Vector2(-3, -radius * 0.6), 2.0, Color(1.0, 0.776, 0.298, 1.0))
	draw_circle(Vector2(3, -radius * 0.6), 2.0, Color(1.0, 0.776, 0.298, 1.0))
	# Bandeirola "🛒"
	var pulse: float = 0.6 + 0.4 * sin(_time * 2.5)
	draw_arc(Vector2(0, -radius * 1.4), 18.0, 0.0, TAU, 24, Color(1, 0.776, 0.298, pulse), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(-8, -radius * 1.4 + 8), "🛒", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.95))
	# Indicador de custo
	draw_string(ThemeDB.fallback_font, Vector2(-12, radius + 18), "🪙 %d" % cost, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.776, 0.298, 0.95))
