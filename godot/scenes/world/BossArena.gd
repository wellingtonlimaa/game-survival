extends Area2D

## Arena de chefe: círculo ritual espalhado pelo mapa.
##
## Trava por NÍVEL do herói (fica escrito na arena). Estando no nível certo,
## basta ficar em cima por alguns segundos pra invocar um chefe reforçado.
## Derrotou? A arena solta baú, ímã e moedas.

const P := preload("res://scripts/utils/Theme.gd")
const PICKUP_SCENE := preload("res://scenes/pickups/Pickup.tscn")

signal boss_requested(arena: Node, boss_key: String)

enum State { LOCKED, READY, CHANNELING, FIGHTING, CLEARED }

const CHANNEL_TIME := 2.5

@export var radius: float = 190.0

var boss_key: String = "boss_base"
var boss_name: String = "Chefe"
var required_level: int = 5
var player: Node2D = null
var pickups_container: Node = null

var state: int = State.LOCKED
var channel: float = 0.0
var boss: Node = null

var _time: float = 0.0
var _player_inside: bool = false
var _announced: bool = false
var _frame: int = 0


func setup(p_boss_key: String, p_level: int, p_player: Node2D, p_pickups: Node) -> void:
	boss_key = p_boss_key
	required_level = p_level
	player = p_player
	pickups_container = p_pickups
	z_index = -1
	_time = randf() * TAU
	var data_path: String = "res://resources/enemies/%s.tres" % boss_key
	if ResourceLoader.exists(data_path):
		boss_name = String((load(data_path) as Resource).display_name)
	var shape: CircleShape2D = $Collision.shape
	if shape != null:
		shape = shape.duplicate()
		shape.radius = radius
		$Collision.shape = shape


func _process(delta: float) -> void:
	_time += delta
	_frame += 1
	if not is_instance_valid(player):
		return

	if state == State.FIGHTING and (boss == null or not is_instance_valid(boss)):
		_on_boss_defeated()

	var dist: float = global_position.distance_to(player.global_position)
	_player_inside = dist < radius * 0.55

	match state:
		State.LOCKED:
			if player.level >= required_level:
				state = State.READY
				if not _announced:
					_announced = true
					EventBus.toast("Arena liberada: %s" % boss_name, P.ACCENT_GOLD, "⚔")
					EventBus.sfx("chest", 0.6)
		State.READY:
			if _player_inside:
				state = State.CHANNELING
				channel = 0.0
		State.CHANNELING:
			if not _player_inside:
				state = State.READY
				channel = 0.0
			else:
				channel += delta
				if channel >= CHANNEL_TIME:
					_summon()
	# Anel pulsa: precisa redesenhar, mas 20 fps dá conta
	if _frame % 3 == 0:
		queue_redraw()


func _summon() -> void:
	state = State.FIGHTING
	channel = 0.0
	EventBus.narrative_triggered.emit("%s DESPERTOU" % boss_name.to_upper())
	EventBus.screen_shake_requested.emit(0.9, 0.6)
	EventBus.flash_requested.emit(Color(0.9, 0.2, 0.3, 0.3), 0.4)
	boss_requested.emit(self, boss_key)


## Chamado pelo GameWorld depois de criar o chefe
func bind_boss(node: Node) -> void:
	boss = node


func _on_boss_defeated() -> void:
	state = State.CLEARED
	boss = null
	EventBus.toast("Arena conquistada! Pegue o prêmio.", P.ACCENT_GOLD, "🏆")
	_spawn_rewards()


func _spawn_rewards() -> void:
	if pickups_container == null or not is_instance_valid(pickups_container):
		return
	var drops := [
		["chest", 1, Vector2(0, -40)],
		["magnet", 1, Vector2(-60, 20)],
		["bomb", 1, Vector2(60, 20)],
		["heart", 40, Vector2(0, 60)],
	]
	for d in drops:
		var item := PICKUP_SCENE.instantiate()
		pickups_container.add_child(item)
		item.global_position = global_position + (d[2] as Vector2)
		item.setup(String(d[0]), int(d[1]), player)
	for i in range(8):
		var coin := PICKUP_SCENE.instantiate()
		pickups_container.add_child(coin)
		var a: float = float(i) / 8.0 * TAU
		coin.global_position = global_position + Vector2(cos(a), sin(a)) * 90.0
		coin.setup("coin", 25, player)


func _draw() -> void:
	var col: Color = _state_color()
	var pulse: float = 0.5 + 0.5 * sin(_time * 2.0)

	# Chão da arena
	draw_circle(Vector2.ZERO, radius, Color(col.r, col.g, col.b, 0.06))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(col.r, col.g, col.b, 0.35), 3.0)
	draw_arc(Vector2.ZERO, radius * 0.55, 0.0, TAU, 48, Color(col.r, col.g, col.b, 0.22), 2.0)

	# Runas girando
	var rune_count: int = 8
	for i in range(rune_count):
		var a: float = float(i) / float(rune_count) * TAU + _time * 0.15
		var pos: Vector2 = Vector2(cos(a), sin(a)) * (radius * 0.78)
		draw_circle(pos, 6.0 + pulse * 2.0, Color(col.r, col.g, col.b, 0.5))
		draw_circle(pos, 2.5, Color(1, 1, 1, 0.5))

	# Obelisco central
	draw_circle(Vector2(0, 10), 26.0, Color(0, 0, 0, 0.35))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-16, 8), Vector2(16, 8), Vector2(11, -52), Vector2(-11, -52),
	]), Color(0.145, 0.118, 0.208))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, -52), Vector2(11, -52), Vector2(0, -74),
	]), Color(col.r, col.g, col.b, 0.9))
	draw_circle(Vector2(0, -44), 7.0 + pulse * 2.5, Color(col.r, col.g, col.b, 0.75))

	var font: Font = ThemeDB.fallback_font
	match state:
		State.LOCKED:
			_label(font, "🔒 REQUER NÍVEL %d" % required_level, -104.0, 15, P.TEXT_MUTED)
			_label(font, boss_name, -86.0, 12, Color(0.6, 0.58, 0.68))
		State.READY:
			_label(font, "⚔ ARENA DE %s" % boss_name.to_upper(), -110.0, 15, P.ACCENT_GOLD)
			_label(font, "fique dentro do círculo para invocar", -92.0, 12, P.TEXT_SECONDARY)
			if _player_inside:
				_label(font, "invocando...", -78.0, 12, P.ACCENT_GOLD)
		State.CHANNELING:
			var pct: float = clampf(channel / CHANNEL_TIME, 0.0, 1.0)
			draw_arc(Vector2.ZERO, radius * 0.42, -PI / 2.0, -PI / 2.0 + pct * TAU, 40, P.ACCENT_GOLD, 7.0)
			_label(font, "INVOCANDO %s" % boss_name.to_upper(), -110.0, 16, P.ACCENT_GOLD)
			_label(font, "%d%%" % int(pct * 100.0), -90.0, 14, P.TEXT_PRIMARY)
		State.FIGHTING:
			pass  # a barra do chefe no HUD já diz tudo
		State.CLEARED:
			_label(font, "✔ ARENA CONQUISTADA", -104.0, 14, P.ACCENT_GREEN)


func _label(font: Font, text: String, y: float, size: int, color: Color) -> void:
	draw_string(font, Vector2(-150, y), text, HORIZONTAL_ALIGNMENT_CENTER, 300, size, color)


func _state_color() -> Color:
	match state:
		State.LOCKED:
			return Color(0.45, 0.42, 0.55)
		State.CLEARED:
			return P.ACCENT_GREEN
		State.FIGHTING:
			return P.ACCENT_RED
	return P.ACCENT_GOLD
