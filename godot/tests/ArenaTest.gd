extends Node

## Testa o ciclo da arena de chefe: travada por nível → invoca → chefe morre →
## recompensas no chão.

const GAME_WORLD := preload("res://scenes/main/GameWorld.tscn")

var game: Node = null
var arena: Node = null
var elapsed: float = 0.0
var phase: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.selected_goal_seconds = 900
	game = GAME_WORLD.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	for child in game.world_root.get_children():
		if child.has_method("bind_boss"):
			arena = child
			break
	if arena == null:
		print("[ARENA] FALHOU: nenhuma arena no mapa")
		get_tree().quit()
		return
	print("[ARENA] achei %d arenas · primeira exige nivel %d (%s)" % [
		_count_arenas(), arena.required_level, arena.boss_key])
	print("[ARENA] estado inicial=%d (0=LOCKED) com heroi no nivel %d" % [arena.state, game.player.level])


func _count_arenas() -> int:
	var n := 0
	for child in game.world_root.get_children():
		if child.has_method("bind_boss"):
			n += 1
	return n


func _process(delta: float) -> void:
	if game == null or arena == null or not is_instance_valid(arena):
		return
	elapsed += delta
	if is_instance_valid(game.player):
		game.player.hp = game.player.max_hp

	match phase:
		0:
			if elapsed > 0.5:
				if arena.state != 0:
					print("[ARENA] FALHOU: deveria estar travada")
				# sobe o nível do herói e leva ele pra arena
				game.player.level = arena.required_level
				game.player.global_position = arena.global_position
				phase = 1
				elapsed = 0.0
		1:
			game.player.global_position = arena.global_position
			if arena.state == 1:
				print("[ARENA] destravou no nivel %d" % game.player.level)
			if arena.state == 3:  # FIGHTING
				print("[ARENA] chefe invocado apos %.1fs dentro do circulo" % elapsed)
				phase = 2
				elapsed = 0.0
			elif elapsed > 6.0:
				print("[ARENA] FALHOU: nao invocou (estado=%d)" % arena.state)
				get_tree().quit()
		2:
			if arena.boss != null and is_instance_valid(arena.boss):
				print("[ARENA] chefe %s com %d de vida (reforcado)" % [arena.boss.data.display_name, int(arena.boss.max_hp)])
				arena.boss.take_damage(999999.0, 0.0, Vector2.UP, "teste", false)
				phase = 3
				elapsed = 0.0
			elif elapsed > 3.0:
				print("[ARENA] FALHOU: chefe nao apareceu")
				get_tree().quit()
		3:
			if elapsed > 1.0:
				var drops := {}
				for p in game.pickups_container.get_children():
					drops[p.kind] = int(drops.get(p.kind, 0)) + 1
				print("[ARENA] estado final=%d (4=CLEARED) · drops=%s" % [arena.state, str(drops)])
				var ok: bool = arena.state == 4 and drops.has("chest") and drops.has("magnet")
				print("[ARENA] %s" % ("OK" if ok else "FALHOU"))
				get_tree().quit()
