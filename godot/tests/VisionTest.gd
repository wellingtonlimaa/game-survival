extends Node

## Confere as passivas novas: campo de visão (zoom da câmera com teto),
## projéteis extras e perfuração extra.

const GAME_WORLD := preload("res://scenes/main/GameWorld.tscn")

var game: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = GAME_WORLD.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Node2D = game.player
	var cam: Camera2D = player.get_node("Camera")
	var us: Node = game.upgrade_system
	print("[VIS] zoom inicial=%.3f visao=%.2f" % [cam.zoom.x, player.vision_mult])

	for i in range(8):   # tenta passar do teto de propósito
		us._apply_passive("vision", 1.0)
	await get_tree().create_timer(0.6).timeout
	print("[VIS] apos 8 niveis: visao=%.2f (teto %.2f) zoom=%.3f" % [player.vision_mult, player.VISION_MAX, cam.zoom.x])

	for i in range(6):
		us._apply_passive("multishot", 1.0)
	for i in range(6):
		us._apply_passive("pierce", 1.0)
	print("[VIS] projeteis extras=%d · perfuracao extra=%d" % [player.extra_projectiles, player.extra_pierce])

	var ok: bool = (
		is_equal_approx(player.vision_mult, player.VISION_MAX)
		and cam.zoom.x < 1.0
		and player.extra_projectiles == 3
		and player.extra_pierce == 3
	)
	print("[VIS] %s" % ("OK" if ok else "FALHOU"))
	get_tree().quit()
