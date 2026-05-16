extends CharacterBody2D

signal player_moved(world_pos: Vector2)
signal hp_changed(current: float, maximum: float)
signal xp_changed(current: float, to_next: float, level: int)
signal player_died

@export var speed: float = 245.0
@export var radius: float = 17.0

var aim_dir: Vector2 = Vector2.RIGHT
var last_move_dir: Vector2 = Vector2.RIGHT
var world: Dictionary = {}
var map: Resource

var max_hp: float = 110.0
var hp: float = 110.0
var armor: float = 0.0
var regen: float = 0.0
var luck: float = 0.0
var damage_mult: float = 1.0
var xp_mult: float = 1.0
var pickup_radius: float = 60.0
var level: int = 1
var xp: float = 0.0
var xp_to_next: float = 16.0
var invuln_timer: float = 0.0

@onready var sprite: Node2D = $Sprite
@onready var camera: Camera2D = $Camera


func setup(map_data: Resource, world_dict: Dictionary) -> void:
	map = map_data
	world = world_dict
	global_position = world.get("player_start", Vector2.ZERO)
	_setup_camera_limits()
	EventBus.player_xp_gained.connect(_on_xp_gained)
	hp = max_hp
	hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_next, level)


func apply_damage_to_player(amount: float) -> void:
	if invuln_timer > 0.0:
		return
	var taken: float = max(2.0, amount - armor)
	hp -= taken
	invuln_timer = 0.55
	EventBus.player_damaged.emit(taken)
	EventBus.damage_number_requested.emit(global_position + Vector2(0, -radius), taken, Color(0.886, 0.275, 0.345))
	EventBus.screen_shake_requested.emit(0.4, 0.25)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		player_died.emit()
		EventBus.player_died.emit()


func _on_xp_gained(amount: float) -> void:
	xp += amount * xp_mult
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = round(xp_to_next * 1.28 + 7)
		hp = min(max_hp, hp + max(8.0, max_hp * 0.08))
		EventBus.player_level_up.emit(level)
		hp_changed.emit(hp, max_hp)
	xp_changed.emit(xp, xp_to_next, level)


func _setup_camera_limits() -> void:
	if map == null:
		return
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map.world_width
	camera.limit_bottom = map.world_height
	camera.make_current()


func _physics_process(delta: float) -> void:
	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)
	if regen > 0.0 and hp < max_hp:
		hp = min(max_hp, hp + regen * delta)
		hp_changed.emit(hp, max_hp)

	var input := _read_input()
	if input.length() > 1.0:
		input = input.normalized()
	if input.length_squared() > 0.0:
		last_move_dir = input

	velocity = input * speed
	move_and_slide()
	_resolve_world_collisions()

	# Atualiza aim com o mouse (em world coords)
	var mouse_world := get_global_mouse_position()
	var to_mouse := mouse_world - global_position
	if to_mouse.length_squared() > 4.0:
		aim_dir = to_mouse.normalized()
	else:
		aim_dir = last_move_dir

	if input.length_squared() > 0.0:
		player_moved.emit(global_position)


func _read_input() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		v.y -= 1.0
	if Input.is_action_pressed("move_down"):
		v.y += 1.0
	if Input.is_action_pressed("move_left"):
		v.x -= 1.0
	if Input.is_action_pressed("move_right"):
		v.x += 1.0
	return v


func _resolve_world_collisions() -> void:
	if world.is_empty():
		return

	# Clamp aos limites do mundo
	if map != null:
		global_position.x = clamp(global_position.x, radius, map.world_width - radius)
		global_position.y = clamp(global_position.y, radius, map.world_height - radius)

	# Empurra pra fora de obstáculos (círculo vs círculo)
	for o in world.get("obstacles", []):
		var o_pos: Vector2 = o["pos"]
		var o_r: float = o["radius"]
		var diff := global_position - o_pos
		var min_dist := radius + o_r * 0.85
		var d := diff.length()
		if d < min_dist and d > 0.001:
			global_position = o_pos + diff.normalized() * min_dist

	# Lago: projeta jogador pra fora do lago (elipse)
	for lm in world.get("landmarks", []):
		if lm["kind"] != "lake":
			continue
		var center: Vector2 = lm["pos"]
		var rv: Vector2 = lm["radius"]
		var dx := (global_position.x - center.x) / rv.x
		var dy := (global_position.y - center.y) / rv.y
		var dist := sqrt(dx * dx + dy * dy)
		if dist < 1.0 and dist > 0.001:
			var nx := dx / dist
			var ny := dy / dist
			global_position = Vector2(center.x + nx * rv.x * 1.02, center.y + ny * rv.y * 1.02)
