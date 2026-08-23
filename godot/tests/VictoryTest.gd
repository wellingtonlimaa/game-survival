extends Node

## Testa o fim de jogo: objetivo cumprido → Ceifador aparece → morre → VITÓRIA.

const GAME_WORLD := preload("res://scenes/main/GameWorld.tscn")

var game: Node = null
var elapsed: float = 0.0
var nuked: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.selected_goal_seconds = 5
	game = GAME_WORLD.instantiate()
	add_child(game)
	print("[VIT] objetivo de 5s")


func _process(delta: float) -> void:
	elapsed += delta
	if game == null or not is_instance_valid(game):
		return
	if is_instance_valid(game.player):
		game.player.hp = game.player.max_hp

	if game.victory_triggered and not nuked and elapsed > 7.0:
		nuked = true
		var boss: Node = null
		for e in game.enemies_container.get_children():
			if "data" in e and e.data != null and String(e.data.key) == "boss_final":
				boss = e
		if boss == null:
			print("[VIT] FALHOU: Ceifador não apareceu")
			get_tree().quit()
			return
		print("[VIT] Ceifador na arena com %d de vida" % int(boss.hp))
		boss.take_damage(999999.0, 0.0, Vector2.UP, "teste", false)

	if elapsed > 9.0:
		var won: bool = game.run_finalized and game.game_over_screen != null
		print("[VIT] run_finalized=%s tela_final=%s" % [str(game.run_finalized), str(game.game_over_screen != null)])
		print("[VIT] vitorias salvas=%d" % int(SaveSystem.get_value("victories", 0)))
		print("[VIT] %s" % ("OK" if won else "FALHOU"))
		get_tree().quit()
