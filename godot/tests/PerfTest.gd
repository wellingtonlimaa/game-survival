extends Node

## Teste de estresse: enche a tela de inimigos e mede o FPS.
## Uso: godot --path godot res://tests/PerfTest.tscn

const GAME_WORLD := preload("res://scenes/main/GameWorld.tscn")
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")

var game: Node = null
var elapsed: float = 0.0
var samples: Array = []
var spawned: bool = false
var _shot: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveSystem.set_value("unlocked_weapons", RegistryScript.KEYS.duplicate())
	game = GAME_WORLD.instantiate()
	add_child(game)


func _process(delta: float) -> void:
	elapsed += delta
	if game == null or not is_instance_valid(game):
		return

	if not spawned and elapsed > 1.0:
		spawned = true
		# 6 armas no nível 4 + 180 inimigos
		for key in ["knife", "frost_nova", "fury", "orbit", "lightning", "flame"]:
			for i in range(4):
				game.weapon_system.equip(key)
		var horde: int = 90 if "realista" in OS.get_cmdline_user_args() else 180
		for i in range(horde):
			var key: String = ["shade", "runner", "brute", "archer", "bat"][i % 5]
			game.spawn_director.spawn_enemy(key, game.player.global_position + Vector2(randf_range(-500, 500), randf_range(-500, 500)), i % 12 == 0)
		var mode: String = "normal"
		var uargs: PackedStringArray = OS.get_cmdline_user_args()
		for a in uargs:
			if a in ["nodraw", "noproc", "novis"]:
				mode = a
		for e in game.enemies_container.get_children():
			match mode:
				"nodraw":
					e.set_notify_transform(false)
					e.hide()
				"noproc":
					e.set_physics_process(false)
				"novis":
					e.visible = false
		print("[PERF] %d inimigos, %d armas, modo=%s" % [game.enemies_container.get_child_count(), game.weapon_system.slots.size(), mode])

	# Fecha telas de upgrade na hora: com o jogo pausado a medição de FPS mente
	if game.upgrade_screen != null:
		var choices: Array = game.upgrade_screen._choices
		if not choices.is_empty():
			game._on_choice_made(choices[0])

	if spawned and elapsed > 2.0:
		samples.append(Engine.get_frames_per_second())
		if is_instance_valid(game.player):
			game.player.hp = game.player.max_hp
		# Repõe a horda pra medir sempre com a tela cheia
		var horde_target: int = 90 if "realista" in OS.get_cmdline_user_args() else 180
		var missing: int = horde_target - game.enemies_container.get_child_count()
		for i in range(mini(missing, 6)):
			var key: String = ["shade", "runner", "brute", "archer", "bat"][i % 5]
			game.spawn_director.spawn_enemy(key, game.player.global_position + Vector2(randf_range(-520, 520), randf_range(-520, 520)), i % 12 == 0)

	if elapsed > 11.5 and not _shot:
		_shot = true
		await RenderingServer.frame_post_draw
		for a in OS.get_cmdline_user_args():
			if a.contains("/") or a.contains(":"):
				get_viewport().get_texture().get_image().save_png("%s/horda.png" % a)
				break

	if elapsed > 12.0:
		var total: float = 0.0
		var worst: float = 9999.0
		for s in samples:
			total += float(s)
			worst = minf(worst, float(s))
		print("[PERF] process=%.2fms physics=%.2fms draw_calls=%d objetos=%d nós=%d" % [
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
			int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
		print("[PERF] contagem: inimigos=%d pickups=%d projeteis=%d efeitos=%d mundo=%d hud=%d" % [
			game.enemies_container.get_child_count(), game.pickups_container.get_child_count(),
			game.projectiles_container.get_child_count(), game.effects_container.get_child_count(),
			game.world_root.get_child_count(), game.hud_root.get_child_count()])
		print("[PERF] fps medio=%.1f pior=%.0f amostras=%d inimigos=%d projeteis=%d" % [
			total / maxf(1.0, float(samples.size())), worst, samples.size(),
			game.enemies_container.get_child_count(),
			game.projectiles_container.get_child_count()])
		get_tree().quit()
