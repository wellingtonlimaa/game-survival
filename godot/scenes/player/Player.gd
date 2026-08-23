extends CharacterBody2D

## Herói: movimento com inércia, dash com invulnerabilidade, crítico,
## regeneração, esquiva e ressurreição. Todos os sistemas leem os stats daqui.

const P := preload("res://scripts/utils/Theme.gd")

signal player_moved(world_pos: Vector2)
signal hp_changed(current: float, maximum: float)
signal xp_changed(current: float, to_next: float, level: int)
signal dash_changed(ready_pct: float)
signal player_died

@export var speed: float = 250.0
@export var radius: float = 17.0
@export var acceleration: float = 2600.0
@export var friction: float = 2200.0

var aim_dir: Vector2 = Vector2.RIGHT
var last_move_dir: Vector2 = Vector2.RIGHT
var world: Dictionary = {}
var map: Resource

# --- Stats -------------------------------------------------------------------
var max_hp: float = 120.0
var hp: float = 120.0
var armor: float = 0.0
var regen: float = 0.0
var luck: float = 0.0
var damage_mult: float = 1.0
var combo_mult: float = 1.0   # bônus temporário por sequência de KOs
var damage_taken_mult: float = 1.0
var xp_mult: float = 1.0
var coin_mult: float = 1.0
var pickup_radius: float = 78.0
var cooldown_mult: float = 1.0
var area_mult: float = 1.0
var projectile_speed_mult: float = 1.0
var duration_mult: float = 1.0
var crit_chance: float = 0.05
var crit_mult: float = 2.0
var extra_projectiles: int = 0
var extra_pierce: int = 0
var vision_mult: float = 1.0          # 1.0 = padrão · limitado em VISION_MAX
const VISION_MAX := 1.45
var dodge_chance: float = 0.0
var lifesteal_on_hit: float = 0.0
var revives: int = 0
var dash_cooldown: float = 3.2
var dash_speed: float = 900.0
var dash_time: float = 0.16

var level: int = 1
var xp: float = 0.0
var xp_to_next: float = 28.0
var invuln_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cd_timer: float = 0.0
var dead: bool = false

var _hit_flash: float = 0.0
var _dash_dir: Vector2 = Vector2.RIGHT
var _dash_trail: Array = []
var _trail_drawn: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _mouse_idle: float = 0.0
var _enemies_container: Node = null
var _base_zoom: Vector2 = Vector2(1.06, 1.06)
var _applied_vision: float = 1.0

@onready var sprite: Node2D = $Sprite
@onready var camera: Camera2D = $Camera


func setup(map_data: Resource, world_dict: Dictionary, enemies_container: Node = null) -> void:
	map = map_data
	world = world_dict
	_enemies_container = enemies_container
	global_position = world.get("player_start", Vector2.ZERO)
	_setup_camera_limits()
	EventBus.player_xp_gained.connect(_on_xp_gained)
	hp = max_hp
	xp_to_next = xp_needed(level)
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_next, level)
	add_to_group("player")


static func xp_needed(lvl: int) -> float:
	return round(14.0 + 7.0 * float(lvl) + pow(float(lvl), 1.80))


# --- Dano / cura -------------------------------------------------------------

func apply_damage_to_player(amount: float) -> void:
	if dead or invuln_timer > 0.0 or dash_timer > 0.0:
		return
	if dodge_chance > 0.0 and randf() < dodge_chance:
		EventBus.floating_text_requested.emit(global_position + Vector2(0, -radius - 8), "ESQUIVA", P.ACCENT_CYAN)
		EventBus.sfx("dash", 0.35)
		invuln_timer = 0.25
		return

	var taken: float = maxf(1.0, amount * damage_taken_mult - armor)
	hp -= taken
	invuln_timer = 0.6
	_hit_flash = 1.0
	EventBus.player_damaged.emit(taken)
	EventBus.damage_number_requested.emit(global_position + Vector2(0, -radius - 4), taken, P.ACCENT_RED)
	EventBus.screen_shake_requested.emit(0.45, 0.22)
	EventBus.flash_requested.emit(Color(0.886, 0.275, 0.345, 0.22), 0.16)
	EventBus.sfx("hurt", 0.6)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_handle_death()


func heal(amount: float) -> void:
	if dead or amount <= 0.0:
		return
	var before: float = hp
	hp = minf(max_hp, hp + amount)
	if hp > before:
		EventBus.player_healed.emit(hp - before)
		hp_changed.emit(hp, max_hp)


func add_max_hp(amount: float, heal_same: bool = true) -> void:
	max_hp = maxf(20.0, max_hp + amount)
	if heal_same and amount > 0.0:
		hp = minf(max_hp, hp + amount)
	hp = minf(hp, max_hp)
	hp_changed.emit(hp, max_hp)


func _handle_death() -> void:
	if revives > 0:
		revives -= 1
		hp = max_hp * 0.6
		invuln_timer = 2.5
		EventBus.player_revived.emit()
		EventBus.flash_requested.emit(Color(1.0, 0.9, 0.5, 0.55), 0.6)
		EventBus.screen_shake_requested.emit(0.8, 0.4)
		EventBus.sfx("evolve", 0.9)
		EventBus.toast("A Fênix te trouxe de volta!", P.ACCENT_ORANGE, "🔥")
		hp_changed.emit(hp, max_hp)
		return
	dead = true
	hp = 0.0
	hp_changed.emit(hp, max_hp)
	EventBus.sfx("death", 1.0)
	player_died.emit()
	EventBus.player_died.emit()


# --- XP / nível --------------------------------------------------------------

func _on_xp_gained(amount: float) -> void:
	if dead:
		return
	xp += amount * xp_mult
	var leveled: bool = false
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = xp_needed(level)
		heal(maxf(8.0, max_hp * 0.08))
		leveled = true
		EventBus.player_level_up.emit(level)
	if leveled:
		EventBus.sfx("levelup", 0.8)
	xp_changed.emit(xp, xp_to_next, level)


# --- Loop --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		velocity = Vector2.ZERO
		return

	if invuln_timer > 0.0:
		invuln_timer = maxf(0.0, invuln_timer - delta)
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta * 3.0)
	if dash_cd_timer > 0.0:
		dash_cd_timer = maxf(0.0, dash_cd_timer - delta)
		dash_changed.emit(dash_ready_pct())

	if regen > 0.0 and hp < max_hp:
		hp = minf(max_hp, hp + regen * delta)
		hp_changed.emit(hp, max_hp)

	var input := _read_input()
	if input.length() > 1.0:
		input = input.normalized()
	if input.length_squared() > 0.0:
		last_move_dir = input.normalized()

	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		velocity = _dash_dir * dash_speed
		_dash_trail.push_front(global_position)
		if _dash_trail.size() > 7:
			_dash_trail.resize(7)
	else:
		if Input.is_action_just_pressed("dash") and dash_cd_timer <= 0.0:
			_start_dash(input)
		var target_velocity: Vector2 = input * speed
		if input.length_squared() > 0.0:
			velocity = velocity.move_toward(target_velocity, acceleration * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		if not _dash_trail.is_empty():
			_dash_trail.remove_at(_dash_trail.size() - 1)

	move_and_slide()
	_resolve_world_collisions()
	_update_aim(input, delta)

	if velocity.length_squared() > 1.0:
		player_moved.emit(global_position)

	if sprite != null:
		sprite.set_motion(velocity / maxf(1.0, speed), invuln_timer > 0.0, _hit_flash, dash_timer > 0.0)
	# Só redesenha enquanto houver rastro de dash
	if not _dash_trail.is_empty() or _trail_drawn:
		_trail_drawn = not _dash_trail.is_empty()
		queue_redraw()


func _start_dash(input: Vector2) -> void:
	_dash_dir = input.normalized() if input.length_squared() > 0.01 else last_move_dir
	dash_timer = dash_time
	dash_cd_timer = dash_cooldown
	invuln_timer = maxf(invuln_timer, dash_time + 0.12)
	_dash_trail.clear()
	EventBus.player_dashed.emit()
	EventBus.sfx("dash", 0.45)
	dash_changed.emit(0.0)


func dash_ready_pct() -> float:
	if dash_cooldown <= 0.0:
		return 1.0
	return clampf(1.0 - dash_cd_timer / dash_cooldown, 0.0, 1.0)


func _read_input() -> Vector2:
	var v := Vector2.ZERO
	v.x = Input.get_axis("move_left", "move_right")
	v.y = Input.get_axis("move_up", "move_down")
	return v


## Mira segue o mouse; se o mouse ficar parado, mira no inimigo mais próximo.
func _update_aim(input: Vector2, delta: float) -> void:
	var mouse_screen: Vector2 = get_viewport().get_mouse_position()
	if mouse_screen.distance_to(_last_mouse_pos) > 2.0:
		_mouse_idle = 0.0
		_last_mouse_pos = mouse_screen
	else:
		_mouse_idle += delta

	if _mouse_idle < 2.5:
		var to_mouse: Vector2 = get_global_mouse_position() - global_position
		if to_mouse.length_squared() > 16.0:
			aim_dir = to_mouse.normalized()
			return

	var target: Node2D = _closest_enemy()
	if target != null:
		aim_dir = (target.global_position - global_position).normalized()
	elif input.length_squared() > 0.0:
		aim_dir = input.normalized()
	else:
		aim_dir = last_move_dir


func _closest_enemy() -> Node2D:
	if _enemies_container == null or not is_instance_valid(_enemies_container):
		return null
	var best: Node2D = null
	var best_d: float = 900.0 * 900.0
	for e in _enemies_container.get_children():
		if not (e is Node2D) or not e.has_method("take_damage"):
			continue
		var d: float = global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best


## Campo de visão: afasta a câmera (com teto pra não virar mapa inteiro)
func apply_vision() -> void:
	vision_mult = clampf(vision_mult, 1.0, VISION_MAX)
	if is_equal_approx(vision_mult, _applied_vision):
		return
	_applied_vision = vision_mult
	if camera != null:
		var tween := create_tween()
		tween.tween_property(camera, "zoom", _base_zoom / vision_mult, 0.35).set_trans(Tween.TRANS_SINE)


func _setup_camera_limits() -> void:
	if map == null:
		return
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map.world_width
	camera.limit_bottom = map.world_height
	_base_zoom = camera.zoom
	camera.make_current()


func _resolve_world_collisions() -> void:
	if map != null:
		global_position.x = clampf(global_position.x, radius, float(map.world_width) - radius)
		global_position.y = clampf(global_position.y, radius, float(map.world_height) - radius)
	if world.is_empty():
		return

	for o in world.get("obstacles", []):
		var o_pos: Vector2 = o["pos"]
		var o_r: float = o["radius"]
		var diff: Vector2 = global_position - o_pos
		var min_dist: float = radius + o_r * 0.75
		var d: float = diff.length()
		if d < min_dist and d > 0.001:
			global_position = o_pos + diff.normalized() * min_dist

	for lm in world.get("landmarks", []):
		if lm["kind"] != "lake":
			continue
		var center: Vector2 = lm["pos"]
		var rv: Vector2 = lm["radius"]
		var dx: float = (global_position.x - center.x) / rv.x
		var dy: float = (global_position.y - center.y) / rv.y
		var dist: float = sqrt(dx * dx + dy * dy)
		if dist < 1.0 and dist > 0.001:
			global_position = Vector2(center.x + (dx / dist) * rv.x * 1.02, center.y + (dy / dist) * rv.y * 1.02)


func _draw() -> void:
	# Rastro do dash
	for i in range(_dash_trail.size()):
		var t: float = 1.0 - float(i) / float(maxi(1, _dash_trail.size()))
		var pos: Vector2 = to_local(_dash_trail[i])
		draw_circle(pos, radius * 0.7 * t, Color(0.722, 0.553, 1.0, 0.22 * t))
