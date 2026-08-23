extends Node

## Teste automatizado de fumaça: roda a partida sem interface gráfica,
## força level-ups, baús, compras e evoluções, e imprime um relatório.
## Uso: godot --headless --path godot res://tests/SmokeTest.tscn --quit-after 4000

const GAME_WORLD := preload("res://scenes/main/GameWorld.tscn")
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")

var game: Node = null
var elapsed: float = 0.0
var step: int = 0
var report: Array = []
var _input_checked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Libera tudo pra testar o máximo de código possível
	SaveSystem.set_value("unlocked_weapons", RegistryScript.KEYS.duplicate())
	SaveSystem.set_value("unlocked_relics", [
		"blood_crown", "moon_shard", "phoenix_ember", "storm_ring", "giant_belt",
		"hourglass", "dark_mirror", "leech_fang", "winged_boots", "gambler_coin",
		"void_star", "titan_heart",
	])
	GameManager.selected_goal_seconds = 25
	game = GAME_WORLD.instantiate()
	add_child(game)
	print("[SMOKE] partida iniciada")


func _process(delta: float) -> void:
	if game == null or not is_instance_valid(game):
		return
	elapsed += delta

	# Herói imortal pra run inteira rodar
	if is_instance_valid(game.player):
		game.player.hp = game.player.max_hp
		game.player.invuln_timer = 1.0

	step += 1
	if step % 30 == 0:
		_drive()

	if not _input_checked and elapsed > 2.0:
		_check_input()

	if elapsed > 32.0:
		_finish()


## Confere se o mapa de teclas realmente move o herói (regressão do project.godot)
func _check_input() -> void:
	_input_checked = true
	var before: Vector2 = game.player.global_position
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("move_right")
	var moved: float = game.player.global_position.x - before.x
	print("[SMOKE] input: mover direita deslocou %.1f px %s" % [moved, "OK" if moved > 1.0 else "FALHOU"])
	if not InputMap.has_action("dash"):
		print("[SMOKE] input: acao dash FALTANDO")
	else:
		print("[SMOKE] input: dash OK")


func _drive() -> void:
	if not is_instance_valid(game) or game.upgrade_system == null:
		return

	# Escolhe uma carta se a tela estiver aberta
	if game.upgrade_screen != null:
		var choices: Array = game.upgrade_screen._choices
		if not choices.is_empty():
			game._on_choice_made(choices[randi() % choices.size()])
		return

	# Ganha XP e moedas o tempo todo
	EventBus.player_xp_gained.emit(60.0)
	EventBus.pickup_collected.emit("coin", 25.0)

	# Testa APIs do mercador
	if step % 300 == 0:
		game.try_spend_run_coins(10)
		game.grant_random_weapon()
		game.grant_reroll()
	if step % 600 == 0:
		game.open_chest_reward()
	if step % 900 == 0 and game.spawn_director != null:
		game.spawn_director.spawn_miniboss()
		game.spawn_director.nuke_screen(50.0)


func _finish() -> void:
	var lines: Array = []
	lines.append("[SMOKE] tempo=%.1fs" % elapsed)
	if is_instance_valid(game):
		lines.append("[SMOKE] kills=%d nivel=%d moedas=%d inimigos=%d" % [
			game.kills,
			game.player.level if is_instance_valid(game.player) else -1,
			game.run_coins,
			game.enemies_container.get_child_count() if is_instance_valid(game.enemies_container) else -1,
		])
		if game.weapon_system != null:
			for slot in game.weapon_system.slots:
				lines.append("[SMOKE] arma %s nv%d %s" % [slot.data.key, slot.level, "EVOLUIDA" if slot.data.is_evolution else ""])
		if game.upgrade_system != null:
			lines.append("[SMOKE] passivas=%s" % str(game.upgrade_system.passives))
			lines.append("[SMOKE] reliquias=%s" % str(game.upgrade_system.relics))
			lines.append("[SMOKE] sinergias=%s" % str(game.upgrade_system.active_synergies))
		lines.append("[SMOKE] projeteis=%d efeitos=%d pickups=%d" % [
			game.projectiles_container.get_child_count(),
			game.effects_container.get_child_count(),
			game.pickups_container.get_child_count(),
		])
	for l in lines:
		print(l)
	print("[SMOKE] OK")
	get_tree().quit()
