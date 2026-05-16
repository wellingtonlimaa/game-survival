class_name WorldGenerator
extends RefCounted

const ALTAR_KINDS := ["heal", "xp", "gold", "storm", "elite"]

var map: Resource


func _init(map_data: Resource) -> void:
	map = map_data


func generate(seed_value: int = 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if seed_value != 0 else Time.get_ticks_msec()

	var center := Vector2(map.world_width * 0.5, map.world_height * 0.5)
	var player_start := Vector2(map.world_width * 0.25, map.world_height * 0.5)

	var landmarks := _generate_landmarks(rng, center, player_start)
	var obstacles := _generate_obstacles(rng, player_start, landmarks)
	var altars := _generate_altars(rng, player_start, landmarks, obstacles)
	var details := _generate_terrain_details(rng)

	return {
		"player_start": player_start,
		"landmarks": landmarks,
		"obstacles": obstacles,
		"altars": altars,
		"details": details,
	}


func _generate_landmarks(rng: RandomNumberGenerator, center: Vector2, player_start: Vector2) -> Array:
	var landmarks: Array = []
	if map.has_lake:
		landmarks.append({
			"kind": "lake",
			"pos": Vector2(map.world_width * 0.72, map.world_height * 0.38),
			"radius": Vector2(220, 140),
		})
	if map.has_ruin:
		landmarks.append({
			"kind": "ruin",
			"pos": Vector2(map.world_width * 0.32, map.world_height * 0.78),
			"radius": 160.0,
		})
	if map.has_boss_clearing:
		landmarks.append({
			"kind": "boss_clearing",
			"pos": center,
			"radius": 220.0,
		})
	# Espaço seguro ao redor do jogador
	landmarks.append({
		"kind": "spawn_clearing",
		"pos": player_start,
		"radius": 180.0,
	})
	return landmarks


func _generate_obstacles(rng: RandomNumberGenerator, player_start: Vector2, landmarks: Array) -> Array:
	var obstacles: Array = []
	var attempts: int = 0
	var max_attempts: int = int(map.obstacle_count) * 8

	while obstacles.size() < map.obstacle_count and attempts < max_attempts:
		attempts += 1
		var x := rng.randf_range(40.0, float(map.world_width - 40))
		var y := rng.randf_range(40.0, float(map.world_height - 40))
		var pos := Vector2(x, y)

		# Não spawnar perto demais do jogador
		if pos.distance_to(player_start) < 220.0:
			continue
		# Não spawnar dentro de landmarks
		if _inside_any_landmark(pos, landmarks, 1.05):
			continue
		# Não amontoar
		var too_close := false
		for o in obstacles:
			if pos.distance_to(o["pos"]) < 40.0:
				too_close = true
				break
		if too_close:
			continue

		var kind: String = String(map.obstacle_kinds[rng.randi() % map.obstacle_kinds.size()])
		var color: Color = map.obstacle_palette[rng.randi() % map.obstacle_palette.size()]
		var radius: float = 18.0 + rng.randf_range(-2.0, 6.0)
		obstacles.append({
			"pos": pos,
			"kind": kind,
			"color": color,
			"radius": radius,
			"height": 36.0 + rng.randf_range(-6.0, 18.0),
		})
	return obstacles


func _generate_altars(rng: RandomNumberGenerator, player_start: Vector2, landmarks: Array, obstacles: Array) -> Array:
	var altars: Array = []
	var positions: Array = [
		Vector2(map.world_width * 0.22, map.world_height * 0.22),
		Vector2(map.world_width * 0.78, map.world_height * 0.22),
		Vector2(map.world_width * 0.22, map.world_height * 0.78),
		Vector2(map.world_width * 0.78, map.world_height * 0.78),
		Vector2(map.world_width * 0.50, map.world_height * 0.50),
	]
	positions.shuffle()
	for i in range(min(map.altar_count, ALTAR_KINDS.size())):
		altars.append({
			"pos": positions[i],
			"kind": ALTAR_KINDS[i],
			"radius": 24.0,
			"active": true,
		})
	return altars


func _generate_terrain_details(rng: RandomNumberGenerator) -> Array:
	var details: Array = []
	for _i in range(420):
		var x := rng.randf_range(0.0, float(map.world_width))
		var y := rng.randf_range(0.0, float(map.world_height))
		details.append({
			"pos": Vector2(x, y),
			"size": rng.randf_range(2.0, 5.0),
			"color": map.detail_color,
		})
	return details


func _inside_any_landmark(pos: Vector2, landmarks: Array, scale: float = 1.0) -> bool:
	for lm in landmarks:
		var kind: String = lm["kind"]
		var lm_pos: Vector2 = lm["pos"]
		var r: Variant = lm["radius"]
		if typeof(r) == TYPE_VECTOR2:
			var rv: Vector2 = r
			var dx := (pos.x - lm_pos.x) / (rv.x * scale)
			var dy := (pos.y - lm_pos.y) / (rv.y * scale)
			if dx * dx + dy * dy <= 1.0:
				return true
		else:
			if pos.distance_to(lm_pos) < float(r) * scale:
				return true
	return false
