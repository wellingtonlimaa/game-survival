extends Node

## Simula uma partida inteira com um "bot" pra medir a curva de dificuldade.
## Uso: godot --headless --path godot res://tests/BalanceTest.tscn -- <skill>
## skill: 0.0 (jogador ruim) a 1.0 (jogador ótimo)

const GAME_WORLD := preload("res://scenes/main/GameWorld.tscn")
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")

var game: Node = null
var elapsed: float = 0.0
var next_report: float = 60.0
var skill: float = 0.7
var _angle: float = 0.0
var _last_hp: float = 0.0
var damage_taken: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 3.0
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		skill = clampf(float(args[0]), 0.0, 1.0)

	SaveSystem.set_value("unlocked_weapons", RegistryScript.KEYS.duplicate())
	SaveSystem.set_value("permanent_upgrades", {})
	SaveSystem.set_value("talents", {})
	SaveSystem.set_value("prestige", 0)
	GameManager.selected_goal_seconds = 600
	GameManager.selected_difficulty = "normal"

	game = GAME_WORLD.instantiate()
	add_child(game)
	await get_tree().process_frame
	_last_hp = game.player.max_hp
	print("[BAL] skill=%.2f personagem=%s" % [skill, GameManager.selected_character])


func _physics_process(delta: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	elapsed += delta

	if is_instance_valid(game.player) and not game.player.dead:
		_drive_player(delta)

	if game.upgrade_screen != null:
		_choose_upgrade()

	if elapsed >= next_report:
		_report()
		next_report += 60.0

	if elapsed > 610.0 or game.run_finalized:
		_final_report()


## Bot: repulsão da horda + coleta de gemas + dash no aperto.
func _drive_player(delta: float) -> void:
	var player: Node2D = game.player
	var hp_now: float = player.hp
	if hp_now < _last_hp:
		damage_taken += _last_hp - hp_now
	_last_hp = hp_now

	_angle += delta * 0.4
	var wander: Vector2 = Vector2(cos(_angle), sin(_angle * 0.8))

	# Empurra pra longe de TODA a horda próxima (peso maior pros mais perto)
	var repulsion: Vector2 = Vector2.ZERO
	var closest_dist: float = 1e9
	var aim_target: Node2D = null
	for e in game.enemies_container.get_children():
		if not (e is Node2D):
			continue
		var diff: Vector2 = player.global_position - e.global_position
		var d: float = diff.length()
		if d < closest_dist:
			closest_dist = d
			aim_target = e
		if d < 280.0 and d > 1.0:
			repulsion += diff.normalized() * (280.0 - d) / 280.0

	# Puxa pra gema mais próxima quando está seguro
	var gem_pull: Vector2 = Vector2.ZERO
	if closest_dist > 150.0:
		var best_gem: float = 260.0
		for g in game.pickups_container.get_children():
			if not (g is Node2D):
				continue
			var d: float = player.global_position.distance_to(g.global_position)
			if d < best_gem:
				best_gem = d
				gem_pull = (g.global_position - player.global_position).normalized()

	var dir: Vector2 = (repulsion.normalized() * (1.2 * skill) + gem_pull * 0.6 + wander * (1.0 - skill)).normalized()
	player.velocity = dir * player.speed
	player.move_and_slide()
	if aim_target != null:
		player.aim_dir = (aim_target.global_position - player.global_position).normalized()

	# Dash quando a coisa aperta
	if closest_dist < 70.0 and player.dash_cd_timer <= 0.0:
		player._start_dash(dir)


func _choose_upgrade() -> void:
	var choices: Array = game.upgrade_screen._choices
	if choices.is_empty():
		return
	# Heurística: evolução > arma nova (até 6) > nível de arma > passiva
	var best: Dictionary = choices[0]
	var best_score: int = -1
	for c in choices:
		var score: int = 0
		var weapons: int = game.weapon_system.slots.size()
		var passives: int = game.upgrade_system.passives.size()
		match String(c["kind"]):
			"weapon_evolve": score = 100
			"weapon_new": score = 85 if weapons < 4 else 15
			"passive": score = 80 if passives < weapons else 55
			"weapon_level": score = 65
			"relic": score = 60
			"blessing": score = 20
		if score > best_score:
			best_score = score
			best = c
	game._on_choice_made(best)


func _report() -> void:
	var p: Node2D = game.player
	print("[BAL] t=%3ds nivel=%2d hp=%3d/%3d kills=%4d dps=%5d inimigos=%3d dano_recebido=%d armas=%d moedas=%d" % [
		int(elapsed), p.level, int(p.hp), int(p.max_hp), game.kills,
		int(game.damage_dealt / maxf(1.0, elapsed)),
		game.enemies_container.get_child_count(), int(damage_taken),
		game.weapon_system.slots.size(), game.run_coins,
	])


func _final_report() -> void:
	var p: Node2D = game.player
	print("[BAL] FIM t=%ds nivel=%d kills=%d morreu=%s vitoria=%s" % [
		int(elapsed), p.level, game.kills, str(p.dead), str(game.victory_triggered and not p.dead)])
	var names: Array = []
	for slot in game.weapon_system.slots:
		names.append("%s(nv%d%s)" % [slot.data.key, slot.level, "★" if slot.data.is_evolution else ""])
	print("[BAL] arsenal: %s" % ", ".join(names))
	print("[BAL] passivas: %s" % str(game.upgrade_system.passives))
	print("[BAL] dano total=%d  dps=%d" % [int(game.damage_dealt), int(game.damage_dealt / maxf(1.0, elapsed))])
	Engine.time_scale = 1.0
	get_tree().quit()
