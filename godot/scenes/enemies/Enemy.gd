extends Area2D

const EnemyDataScript := preload("res://scripts/data/EnemyData.gd")
const PROJECTILE_SCENE := preload("res://scenes/projectiles/Projectile.tscn")
const GEM_SCENE := preload("res://scenes/pickups/Gem.tscn")

var data: Resource = null
var hp: float = 0.0
var max_hp: float = 0.0
var target: Node2D = null
var enemies_container: Node = null
var projectiles_container: Node = null
var pickups_container: Node = null

var hp_mult: float = 1.0
var damage_mult: float = 1.0
var coin_mult: float = 1.0

var knock_velocity: Vector2 = Vector2.ZERO
var hit_flash: float = 0.0
var attack_timer: float = 0.0
var windup_timer: float = 0.0
var windup_active: bool = false
var contact_cd: float = 0.0

@onready var collision_shape: CollisionShape2D = $Collision


func setup(enemy_data: Resource, player_ref: Node2D, enemies_node: Node, projectiles_node: Node, pickups_node: Node, p_hp_mult: float = 1.0, p_damage_mult: float = 1.0, p_coin_mult: float = 1.0) -> void:
	data = enemy_data
	target = player_ref
	enemies_container = enemies_node
	projectiles_container = projectiles_node
	pickups_container = pickups_node
	hp_mult = p_hp_mult
	damage_mult = p_damage_mult
	coin_mult = p_coin_mult

	max_hp = data.hp * hp_mult
	hp = max_hp

	var shape: CircleShape2D = collision_shape.shape
	shape.radius = data.radius

	attack_timer = data.attack_cooldown
	queue_redraw()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if data == null or not is_instance_valid(target):
		return

	# Knockback decai
	knock_velocity = knock_velocity.lerp(Vector2.ZERO, clamp(delta * 6.0, 0.0, 1.0))
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta * 4.0)
	if contact_cd > 0.0:
		contact_cd = max(0.0, contact_cd - delta)
	attack_timer = max(0.0, attack_timer - delta)

	match data.behavior:
		EnemyDataScript.Behavior.CHASE:
			_behavior_chase(delta)
		EnemyDataScript.Behavior.KITE_AND_SHOOT:
			_behavior_kite(delta)
		EnemyDataScript.Behavior.EXPLODE_CLOSE:
			_behavior_explode(delta)
		EnemyDataScript.Behavior.SUMMONER:
			_behavior_summoner(delta)
		EnemyDataScript.Behavior.BOSS_RADIAL:
			_behavior_boss(delta)

	queue_redraw()


func _behavior_chase(delta: float) -> void:
	var to_target := target.global_position - global_position
	var dir := to_target.normalized()
	global_position += (dir * data.speed + knock_velocity) * delta


func _behavior_kite(delta: float) -> void:
	var to_target := target.global_position - global_position
	var dist: float = to_target.length()
	var dir := to_target.normalized() if dist > 0.001 else Vector2.RIGHT
	var move_dir := Vector2.ZERO
	if dist < data.prefered_distance * 0.85:
		move_dir = -dir * 0.85
	elif dist > data.prefered_distance * 1.15:
		move_dir = dir * 0.6
	else:
		# circle-strafe
		move_dir = dir.rotated(PI * 0.5) * 0.35
	global_position += (move_dir * data.speed + knock_velocity) * delta

	if attack_timer <= 0.0 and not windup_active:
		windup_active = true
		windup_timer = data.windup_time
	if windup_active:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_fire_at_player()
			windup_active = false
			attack_timer = data.attack_cooldown


func _behavior_explode(delta: float) -> void:
	var to_target := target.global_position - global_position
	var dist: float = to_target.length()
	var dir := to_target.normalized() if dist > 0.001 else Vector2.RIGHT

	if dist > data.trigger_distance and not windup_active:
		global_position += (dir * data.speed + knock_velocity) * delta
	else:
		if not windup_active:
			windup_active = true
			windup_timer = data.windup_time
		windup_timer -= delta
		if windup_timer <= 0.0:
			_explode()


func _behavior_summoner(delta: float) -> void:
	var to_target := target.global_position - global_position
	var dist: float = to_target.length()
	var dir := to_target.normalized() if dist > 0.001 else Vector2.RIGHT
	if dist < data.prefered_distance:
		global_position += (-dir * data.speed * 0.7 + knock_velocity) * delta
	else:
		global_position += (dir * data.speed * 0.3 + knock_velocity) * delta

	if attack_timer <= 0.0 and not windup_active:
		windup_active = true
		windup_timer = data.windup_time
	if windup_active:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_summon_minions()
			windup_active = false
			attack_timer = data.attack_cooldown


func _behavior_boss(delta: float) -> void:
	var to_target := target.global_position - global_position
	var dir := to_target.normalized()
	global_position += (dir * data.speed * 0.7 + knock_velocity) * delta

	if attack_timer <= 0.0 and not windup_active:
		windup_active = true
		windup_timer = data.windup_time
	if windup_active:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_fire_radial()
			windup_active = false
			attack_timer = data.attack_cooldown


func _fire_at_player() -> void:
	if projectiles_container == null:
		return
	var dir := (target.global_position - global_position).normalized()
	_spawn_enemy_projectile(dir)


func _fire_radial() -> void:
	if projectiles_container == null:
		return
	var count: int = data.projectile_count
	if count <= 0:
		count = 1
	for i in range(count):
		var angle: float = float(i) / float(count) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		_spawn_enemy_projectile(dir)


func _spawn_enemy_projectile(dir: Vector2) -> void:
	_spawn_enemy_projectile_deferred.call_deferred(global_position, dir.normalized(), damage_mult)


func _spawn_enemy_projectile_deferred(origin: Vector2, dir: Vector2, dmg_mult: float) -> void:
	if projectiles_container == null or not is_instance_valid(projectiles_container):
		return
	var proj := PROJECTILE_SCENE.instantiate()
	projectiles_container.add_child(proj)
	proj.collision_layer = 16
	proj.collision_mask = 2
	proj.global_position = origin
	proj.velocity = dir * data.projectile_speed
	proj.damage = data.projectile_damage * dmg_mult
	proj.pierce_remaining = 0
	proj.lifetime = data.projectile_lifetime
	proj.knockback = 80.0
	proj.source_key = "enemy:%s" % data.key
	proj.setup_projectile(data.projectile_color, "bolt", data.projectile_radius)


func _explode() -> void:
	# Dano e knockback no player (se perto)
	var dist: float = target.global_position.distance_to(global_position)
	if dist < 120.0:
		if target.has_method("apply_damage_to_player"):
			target.apply_damage_to_player(data.contact_damage * damage_mult)
	EventBus.screen_shake_requested.emit(0.6, 0.3)
	EventBus.flash_requested.emit(Color(1.0, 0.561, 0.243, 0.4), 0.2)
	# Auto-destroi
	_remove_from_game(false)


func _summon_minions() -> void:
	if enemies_container == null or data.summon_pool.size() == 0:
		return
	_summon_minions_deferred.call_deferred(global_position)


func _summon_minions_deferred(origin: Vector2) -> void:
	if enemies_container == null or not is_instance_valid(enemies_container):
		return
	var enemy_scene: PackedScene = preload("res://scenes/enemies/Enemy.tscn")
	for i in range(data.summon_count):
		var key: String = String(data.summon_pool[i % data.summon_pool.size()])
		var path: String = "res://resources/enemies/%s.tres" % key
		if not ResourceLoader.exists(path):
			continue
		var minion_data: Resource = load(path)
		var minion := enemy_scene.instantiate()
		enemies_container.add_child(minion)
		var angle: float = randf() * TAU
		minion.global_position = origin + Vector2(cos(angle), sin(angle)) * 60.0
		minion.setup(minion_data, target, enemies_container, projectiles_container, pickups_container, hp_mult, damage_mult, coin_mult)


func take_damage(damage: float, knockback: float, dir: Vector2, _source: String = "") -> void:
	hp -= damage
	hit_flash = 1.0
	knock_velocity += dir * knockback
	if hp <= 0.0:
		_die()


func _die() -> void:
	EventBus.enemy_killed.emit(self, "")
	_drop_xp()
	_remove_from_game(true)


func _drop_xp() -> void:
	if pickups_container == null:
		return
	_spawn_gem_deferred.call_deferred(global_position, int(data.xp_value), target, pickups_container)


func _spawn_gem_deferred(pos: Vector2, xp: int, t: Node2D, container: Node) -> void:
	if container == null or not is_instance_valid(container):
		return
	var gem: Node2D = GEM_SCENE.instantiate()
	container.add_child(gem)
	gem.global_position = pos
	gem.setup(xp, t)


func _remove_from_game(_killed: bool) -> void:
	queue_free()


func _on_body_entered(body: Node) -> void:
	if contact_cd > 0.0:
		return
	if body.has_method("apply_damage_to_player"):
		body.apply_damage_to_player(data.contact_damage * damage_mult)
		contact_cd = 0.5


func _draw() -> void:
	if data == null:
		return
	# Sombra
	draw_circle(Vector2(2, 5), data.radius * 1.05, Color(0, 0, 0, 0.4))

	# Indicador de windup
	if windup_active:
		var pct: float = clamp(1.0 - windup_timer / max(0.05, data.windup_time), 0.0, 1.0)
		draw_arc(Vector2.ZERO, data.radius + 6.0, -PI / 2.0, -PI / 2.0 + pct * TAU, 24, Color(1.0, 0.776, 0.298, 0.85), 3.0)

	# Corpo (silhueta varia por tipo)
	var col: Color = data.body_color
	if hit_flash > 0.0:
		col = data.body_color.lerp(Color.WHITE, hit_flash)
	_draw_silhouette(col)

	# Olhos
	draw_circle(Vector2(-data.radius * 0.35, -data.radius * 0.18), data.radius * 0.18, data.eye_color)
	draw_circle(Vector2(data.radius * 0.35, -data.radius * 0.18), data.radius * 0.18, data.eye_color)

	# Barra de HP
	if hp < max_hp:
		var bar_w: float = data.radius * 1.8
		var pct: float = clamp(hp / max_hp, 0.0, 1.0)
		var bar_y: float = -data.radius - 10.0
		draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w, 4.0), Color(0, 0, 0, 0.7))
		var bar_col: Color = Color(0.439, 0.871, 0.494) if pct > 0.5 else (Color(1.0, 0.776, 0.298) if pct > 0.25 else Color(0.886, 0.275, 0.345))
		draw_rect(Rect2(-bar_w / 2.0, bar_y, bar_w * pct, 4.0), bar_col)

	# Coroa pra boss/miniboss
	if data.tier == EnemyDataScript.Tier.BOSS:
		_draw_crown(Color(1.0, 0.776, 0.298, 1.0), -data.radius * 1.05)
	elif data.tier == EnemyDataScript.Tier.MINIBOSS:
		_draw_crown(Color(1.0, 0.776, 0.298, 0.7), -data.radius * 0.95)


func _draw_silhouette(col: Color) -> void:
	var r: float = data.radius
	match data.silhouette:
		"tall":
			draw_rect(Rect2(-r * 0.55, -r, r * 1.1, r * 1.8), col)
			draw_circle(Vector2(0, -r * 0.9), r * 0.6, col)
		"wide":
			draw_rect(Rect2(-r * 0.9, -r * 0.6, r * 1.8, r * 1.2), col)
			draw_circle(Vector2(0, -r * 0.55), r * 0.7, col)
		"crown":
			draw_circle(Vector2.ZERO, r, col)
			# espinhos
			for i in range(5):
				var angle: float = -PI / 2.0 + (float(i) - 2.0) * 0.55
				var tip: Vector2 = Vector2(cos(angle), sin(angle)) * r * 1.4
				var base_l: Vector2 = Vector2(cos(angle - 0.18), sin(angle - 0.18)) * r * 0.95
				var base_r: Vector2 = Vector2(cos(angle + 0.18), sin(angle + 0.18)) * r * 0.95
				draw_colored_polygon(PackedVector2Array([tip, base_l, base_r]), col.darkened(0.15))
		"mask":
			draw_circle(Vector2.ZERO, r, col)
			draw_rect(Rect2(-r * 0.8, -r * 0.25, r * 1.6, r * 0.5), col.darkened(0.25))
		"skull":
			draw_circle(Vector2.ZERO, r, col)
			draw_rect(Rect2(-r * 0.35, r * 0.05, r * 0.7, r * 0.5), col.darkened(0.3))
		_:  # blob
			draw_circle(Vector2.ZERO, r, col)


func _draw_crown(col: Color, y: float) -> void:
	var pts := PackedVector2Array([
		Vector2(-12, y),
		Vector2(-8, y - 8),
		Vector2(-4, y),
		Vector2(0, y - 10),
		Vector2(4, y),
		Vector2(8, y - 8),
		Vector2(12, y),
		Vector2(12, y + 4),
		Vector2(-12, y + 4),
	])
	draw_colored_polygon(pts, col)
