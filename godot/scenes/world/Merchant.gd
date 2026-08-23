extends Area2D

## Mercador da noite: troca moedas DA RUN por vantagens imediatas.
## (Antes ele cobrava moedas do save e não entregava nada.)

const P := preload("res://scripts/utils/Theme.gd")

const OFFERS := [
	{"key": "heal", "label": "Poção Cheia", "icon": "🧪", "cost": 40, "desc": "Cura toda a vida"},
	{"key": "power", "label": "Óleo de Guerra", "icon": "⚔", "cost": 70, "desc": "+15% de dano"},
	{"key": "weapon", "label": "Arma Misteriosa", "icon": "🎁", "cost": 95, "desc": "Uma arma nova"},
	{"key": "chest", "label": "Baú do Mercador", "icon": "📦", "cost": 130, "desc": "Escolha uma melhoria"},
	{"key": "reroll", "label": "Dado de Osso", "icon": "🎲", "cost": 35, "desc": "+1 re-roll"},
	{"key": "armor", "label": "Placa Enferrujada", "icon": "🛡", "cost": 60, "desc": "+3 de armadura"},
]

@export var radius: float = 26.0

var player: Node2D = null
var game: Node = null
var offer: Dictionary = {}
var sold_out: bool = false
var _time: float = 0.0
var _near: bool = false
var _cooldown: float = 0.0
var _sales: int = 0
var _flash: float = 0.0
var _message: String = ""
var _message_timer: float = 0.0


func setup(p_player: Node2D, p_game: Node = null) -> void:
	player = p_player
	game = p_game
	_roll_offer()
	z_index = 2
	var shape: CircleShape2D = $Collision.shape
	if shape != null:
		shape = shape.duplicate()
		shape.radius = radius
		$Collision.shape = shape


func _roll_offer() -> void:
	offer = OFFERS[randi() % OFFERS.size()]


func _process(delta: float) -> void:
	_time += delta
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 2.0)
	if _message_timer > 0.0:
		_message_timer = maxf(0.0, _message_timer - delta)

	if not sold_out and is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		_near = dist < 190.0
		if dist < radius + 14.0 and _cooldown <= 0.0:
			_try_buy()
	queue_redraw()


func _try_buy() -> void:
	_cooldown = 1.2
	var cost: int = int(offer.get("cost", 50))
	if game == null or not game.has_method("try_spend_run_coins"):
		return
	if not game.try_spend_run_coins(cost):
		_message = "Falta moeda!"
		_message_timer = 1.6
		EventBus.sfx("deny", 0.6)
		return

	_flash = 1.0
	_sales += 1
	_message = "Vendido!"
	_message_timer = 1.6
	EventBus.sfx("coin", 0.9)
	EventBus.toast("Mercador: %s" % String(offer.get("label", "")), P.ACCENT_GOLD, String(offer.get("icon", "🛒")))

	match String(offer.get("key", "")):
		"heal":
			if player.has_method("heal"):
				player.heal(player.max_hp)
		"power":
			player.damage_mult += 0.15
		"armor":
			player.armor += 3.0
		"reroll":
			if game.has_method("grant_reroll"):
				game.grant_reroll()
		"weapon":
			if game.has_method("grant_random_weapon"):
				game.grant_random_weapon()
		"chest":
			if game.has_method("open_chest_reward"):
				game.open_chest_reward()

	if _sales >= 3:
		sold_out = true
		_message = "Fechado!"
	else:
		_roll_offer()


func _draw() -> void:
	var bob: float = sin(_time * 2.0) * 2.0
	# Sombra
	draw_circle(Vector2(2, radius * 0.55), radius * 1.1, Color(0, 0, 0, 0.4))

	if sold_out:
		_draw_body(Color(0.36, 0.30, 0.32), bob)
		_draw_label("FECHADO", Color(0.6, 0.58, 0.66), -radius - 26.0)
		return

	_draw_body(Color(0.553, 0.235, 0.247).lerp(Color.WHITE, _flash * 0.5), bob)

	# Toldo da barraca
	for i in range(4):
		var x: float = -radius + float(i) * (radius * 0.55)
		var col: Color = P.ACCENT_GOLD if i % 2 == 0 else Color(0.72, 0.25, 0.28)
		draw_rect(Rect2(x, -radius * 1.75 + bob, radius * 0.55, radius * 0.42), col)

	var pulse: float = 0.55 + 0.45 * sin(_time * 3.0)
	draw_arc(Vector2.ZERO, radius * 1.6, 0.0, TAU, 26, Color(1, 0.776, 0.298, 0.25 * pulse), 2.0)

	if _message_timer > 0.0:
		_draw_label(_message, P.ACCENT_GOLD, -radius - 44.0)

	if _near:
		var font: Font = ThemeDB.fallback_font
		var label: String = "%s %s" % [String(offer.get("icon", "🛒")), String(offer.get("label", ""))]
		draw_string(font, Vector2(-80, -radius - 30 + bob), label, HORIZONTAL_ALIGNMENT_CENTER, 160, 13, P.TEXT_PRIMARY)
		draw_string(font, Vector2(-80, -radius - 16 + bob), String(offer.get("desc", "")), HORIZONTAL_ALIGNMENT_CENTER, 160, 11, P.TEXT_SECONDARY)
		draw_string(font, Vector2(-80, radius + 22), "🪙 %d" % int(offer.get("cost", 0)), HORIZONTAL_ALIGNMENT_CENTER, 160, 14, P.ACCENT_GOLD)


func _draw_body(body_color: Color, bob: float) -> void:
	# Corpo encapuzado atrás do balcão
	draw_rect(Rect2(-radius * 0.7, -radius * 0.6 + bob, radius * 1.4, radius * 1.3), body_color)
	draw_circle(Vector2(0, -radius * 0.75 + bob), radius * 0.5, Color(0.165, 0.118, 0.094, 1.0))
	draw_circle(Vector2(-4, -radius * 0.78 + bob), 2.2, P.ACCENT_GOLD)
	draw_circle(Vector2(4, -radius * 0.78 + bob), 2.2, P.ACCENT_GOLD)
	# Balcão
	draw_rect(Rect2(-radius * 1.1, radius * 0.35, radius * 2.2, radius * 0.4), Color(0.35, 0.24, 0.18))


func _draw_label(text: String, color: Color, y: float) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(-70, y), text, HORIZONTAL_ALIGNMENT_CENTER, 140, 14, color)
