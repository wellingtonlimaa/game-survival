extends Area2D

## Altar do mapa: o jogador encosta e recebe uma bênção (uma vez por altar).
## Antes os altares eram só desenho — agora são o motivo pra explorar o mapa.

const P := preload("res://scripts/utils/Theme.gd")

const INFO := {
	"heal": {"label": "Altar da Vida", "icon": "❤", "color": Color(0.439, 0.871, 0.494), "text": "+40% de vida"},
	"xp": {"label": "Altar do Saber", "icon": "🔮", "color": Color(0.553, 0.412, 0.886), "text": "Explosão de XP"},
	"gold": {"label": "Altar da Fortuna", "icon": "🪙", "color": Color(1.0, 0.776, 0.298), "text": "+80 moedas"},
	"storm": {"label": "Altar da Tempestade", "icon": "⚡", "color": Color(0.392, 0.808, 0.929), "text": "Raio devastador"},
	"elite": {"label": "Altar do Desafio", "icon": "☠", "color": Color(0.886, 0.275, 0.345), "text": "Horda + baú"},
}

var kind: String = "heal"
var radius: float = 30.0
var active: bool = true
var player: Node2D = null
var spawn_director: Node = null
var pickups_container: Node = null
var enemies_container: Node = null

var _time: float = 0.0
var _near: bool = false


func setup(p_kind: String, p_player: Node2D, p_spawner: Node, p_pickups: Node, p_enemies: Node) -> void:
	kind = p_kind
	player = p_player
	spawn_director = p_spawner
	pickups_container = p_pickups
	enemies_container = p_enemies
	z_index = 1
	_time = randf() * TAU


func _process(delta: float) -> void:
	_time += delta
	if active and is_instance_valid(player):
		var dist: float = global_position.distance_to(player.global_position)
		_near = dist < radius * 3.0
		if dist < radius:
			_activate()
	queue_redraw()


func _activate() -> void:
	if not active:
		return
	active = false
	var info: Dictionary = INFO.get(kind, INFO["heal"])
	var color: Color = info["color"]

	match kind:
		"heal":
			if player.has_method("heal"):
				player.heal(player.max_hp * 0.40)
		"xp":
			_spawn_gem_burst()
		"gold":
			EventBus.pickup_collected.emit("coin", 80.0)
		"storm":
			_storm()
		"elite":
			_challenge()

	EventBus.altar_used.emit(kind)
	EventBus.toast(String(info["label"]), color, String(info["icon"]))
	EventBus.floating_text_requested.emit(global_position + Vector2(0, -40), String(info["text"]), color)
	EventBus.flash_requested.emit(Color(color.r, color.g, color.b, 0.22), 0.3)
	EventBus.sfx("altar", 0.9)
	EventBus.impact_requested.emit(global_position, color, 1.2)


func _spawn_gem_burst() -> void:
	if pickups_container == null:
		return
	var pickup_scene: PackedScene = load("res://scenes/pickups/Pickup.tscn")
	for i in range(12):
		var gem := pickup_scene.instantiate()
		pickups_container.add_child(gem)
		var angle: float = float(i) / 12.0 * TAU
		gem.global_position = global_position + Vector2(cos(angle), sin(angle)) * randf_range(20.0, 60.0)
		gem.setup("xp", 14, player)


func _storm() -> void:
	if enemies_container == null:
		return
	var strike_radius: float = 420.0
	for e in enemies_container.get_children():
		if not e.has_method("take_damage"):
			continue
		var d: float = global_position.distance_to(e.global_position)
		if d > strike_radius:
			continue
		e.take_damage(220.0, 220.0, (e.global_position - global_position).normalized(), "altar", true)
		if e.has_method("apply_status"):
			e.apply_status("stun", 1.0, 1.2)
	EventBus.explosion_requested.emit(global_position, strike_radius, P.ACCENT_CYAN)
	EventBus.screen_shake_requested.emit(0.9, 0.4)
	EventBus.sfx("thunder", 1.0)


func _challenge() -> void:
	if spawn_director != null:
		spawn_director.spawn_wave("brute", 4, true, 220.0)
		spawn_director.spawn_wave("charger", 3, true, 260.0)
	if pickups_container != null:
		var pickup_scene: PackedScene = load("res://scenes/pickups/Pickup.tscn")
		var chest := pickup_scene.instantiate()
		pickups_container.add_child(chest)
		chest.global_position = global_position + Vector2(0, 46)
		chest.setup("chest", 1, player)


func _draw() -> void:
	var info: Dictionary = INFO.get(kind, INFO["heal"])
	var col: Color = info["color"]
	if not active:
		col = col.darkened(0.62)

	# Base
	draw_circle(Vector2(0, 8), radius * 1.05, Color(0, 0, 0, 0.42))
	draw_circle(Vector2.ZERO, radius * 0.92, Color(0.118, 0.094, 0.18, 1.0))
	draw_arc(Vector2.ZERO, radius * 0.92, 0.0, TAU, 28, Color(0.275, 0.227, 0.412), 2.0)
	# Pedestal
	draw_rect(Rect2(-radius * 0.45, -radius * 0.2, radius * 0.9, radius * 0.55), Color(0.275, 0.227, 0.412, 1.0))

	# Cristal flutuante
	var bob: float = sin(_time * 2.0) * 3.0 if active else 0.0
	var crystal: float = radius * 0.5
	var center := Vector2(0, -radius * 0.45 + bob)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -crystal),
		center + Vector2(crystal * 0.55, 0),
		center + Vector2(0, crystal * 0.6),
		center + Vector2(-crystal * 0.55, 0),
	]), col)

	if active:
		var pulse: float = 0.5 + 0.5 * sin(_time * 2.6)
		draw_circle(center, crystal * (1.2 + pulse * 0.4), Color(col.r, col.g, col.b, 0.16 * pulse))
		draw_arc(Vector2.ZERO, radius * (1.35 + pulse * 0.12), 0.0, TAU, 30, Color(col.r, col.g, col.b, 0.30), 2.0)
		if _near:
			var font: Font = ThemeDB.fallback_font
			draw_string(font, Vector2(-56, -radius - 26), String(INFO[kind]["label"]), HORIZONTAL_ALIGNMENT_CENTER, 112, 13, col)
			draw_string(font, Vector2(-56, -radius - 12), "encoste pra usar", HORIZONTAL_ALIGNMENT_CENTER, 112, 11, Color(0.85, 0.83, 0.9, 0.85))
