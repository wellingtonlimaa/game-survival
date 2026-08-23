extends Node

## Utilitário de captura: abre cenas e salva PNGs pra inspeção visual.
## Uso: godot --path godot res://tests/Shot.tscn -- <destino> <modo>
## modos: menu | game | screens

var out_dir: String = "user://shots"
var mode: String = "game"
var game: Node = null
var shots_done: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	if args.size() > 1:
		mode = args[1]
	DirAccess.make_dir_recursive_absolute(out_dir)
	print("[SHOT] destino=%s modo=%s" % [out_dir, mode])
	match mode:
		"menu":
			await _shoot_menu()
		"screens":
			await _shoot_screens()
		"arena":
			await _shoot_arena()
		_:
			await _shoot_game()
	print("[SHOT] pronto (%d imagens)" % shots_done)
	get_tree().quit()


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img: Image = get_viewport().get_texture().get_image()
	var path: String = "%s/%s.png" % [out_dir, name]
	img.save_png(path)
	shots_done += 1
	print("[SHOT] %s" % path)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shoot_menu() -> void:
	var scene: Node = load("res://scenes/ui/menu/MainMenu.tscn").instantiate()
	add_child(scene)
	await _wait(0.8)
	await _capture("menu")
	scene.queue_free()


func _shoot_screens() -> void:
	for entry in [
		["res://scenes/ui/screens/MapSelection.tscn", "mapas"],
		["res://scenes/ui/screens/Shop.tscn", "loja"],
		["res://scenes/ui/screens/Characters.tscn", "herois"],
		["res://scenes/ui/screens/Codex.tscn", "codex"],
		["res://scenes/ui/screens/Talents.tscn", "talentos"],
		["res://scenes/ui/screens/Achievements.tscn", "conquistas"],
	]:
		var scene: Node = load(String(entry[0])).instantiate()
		add_child(scene)
		await _wait(0.5)
		await _capture(String(entry[1]))
		scene.queue_free()
		await get_tree().process_frame


## Foto da arena de chefe (travada, liberada e com o chefe)
func _shoot_arena() -> void:
	GameManager.selected_goal_seconds = 900
	game = load("res://scenes/main/GameWorld.tscn").instantiate()
	add_child(game)
	await _wait(1.0)
	var arena: Node = null
	for child in game.world_root.get_children():
		if child.has_method("bind_boss"):
			arena = child
			break
	if arena == null:
		print("[SHOT] sem arena")
		return
	# travada
	game.player.global_position = arena.global_position + Vector2(0, 150)
	await _wait(0.8)
	await _capture("arena_travada")
	# liberada + invocando
	game.player.level = arena.required_level
	game.player.global_position = arena.global_position
	await _wait(1.6)
	await _capture("arena_invocando")
	await _wait(1.6)
	await _capture("arena_chefe")


func _shoot_game() -> void:
	SaveSystem.set_value("unlocked_weapons", [
		"wand", "knife", "spear", "orbit", "arrow_storm", "fury", "shotgun",
		"fire_staff", "spirit", "boomerang", "axe", "lightning", "bomb",
		"scythe", "flame", "frost_nova", "drone", "holy_shield", "comet", "book",
	])
	GameManager.selected_goal_seconds = 600
	game = load("res://scenes/main/GameWorld.tscn").instantiate()
	add_child(game)
	await _wait(1.2)
	await _capture("jogo_inicio")

	# Simula progressão pra ver HUD cheio
	for i in range(6):
		EventBus.player_xp_gained.emit(400.0)
		await get_tree().process_frame
		if game.upgrade_screen != null:
			await _capture("upgrade_%d" % i) if i == 0 else null
			var choices: Array = game.upgrade_screen._choices
			if not choices.is_empty():
				game._on_choice_made(choices[0])
		await get_tree().process_frame

	EventBus.pickup_collected.emit("coin", 250.0)
	await _wait(6.0)
	await _capture("jogo_meio")

	if game.spawn_director != null:
		game.spawn_director.spawn_miniboss()
	await _wait(4.0)
	await _capture("jogo_boss")

	game._open_pause_menu()
	await _wait(0.6)
	await _capture("pausa")
	game._close_pause_menu()

	if is_instance_valid(game.player):
		game.player.hp = 1.0
		game.player.apply_damage_to_player(999.0)
	await _wait(1.0)
	await _capture("game_over")
