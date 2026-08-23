extends Node

## Carrega todas as telas de UI em sequência procurando erros de runtime.

const SCREENS := [
	"res://scenes/ui/menu/MainMenu.tscn",
	"res://scenes/ui/screens/MapSelection.tscn",
	"res://scenes/ui/screens/Shop.tscn",
	"res://scenes/ui/screens/Characters.tscn",
	"res://scenes/ui/screens/Talents.tscn",
	"res://scenes/ui/screens/Achievements.tscn",
	"res://scenes/ui/screens/Records.tscn",
	"res://scenes/ui/screens/Settings.tscn",
	"res://scenes/ui/screens/Tutorial.tscn",
	"res://scenes/ui/screens/Codex.tscn",
	"res://scenes/ui/screens/GameOver.tscn",
	"res://scenes/ui/screens/PauseMenu.tscn",
]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().process_frame
	for path in SCREENS:
		if not ResourceLoader.exists(path):
			print("[UI] FALTANDO: %s" % path)
			continue
		var packed: PackedScene = load(path)
		var node: Node = packed.instantiate()
		add_child(node)
		if node.has_method("setup") and path.ends_with("GameOver.tscn"):
			node.setup({"time": 321, "kills": 120, "level": 12, "boss_kills": 2, "damage": 45678, "dps": 340, "meta_xp": 200, "leveled_up": true, "new_meta_level": 3, "unlocks": [{"kind": "arma", "label": "Machado", "icon": "⚔"}], "is_record": true}, 480, 250, true)
		elif node.has_method("setup") and path.ends_with("PauseMenu.tscn"):
			node.setup({"time": 100, "kills": 40, "coins": 90, "level": 7},
				{"passives": [{"icon": "⚔", "name": "Força", "level": 2, "color": Color.RED}],
				 "relics": [{"icon": "👑", "name": "Coroa", "color": Color.RED}],
				 "synergies": [{"icon": "🌩", "name": "Tempestade"}]},
				[{"key": "wand", "name": "Varinha", "icon": "🪄", "color": Color.PURPLE, "level": 3, "max_level": 8, "evolved": false}])
		await get_tree().process_frame
		await get_tree().process_frame
		print("[UI] ok: %s" % path)
		node.queue_free()
		await get_tree().process_frame
	print("[UI] TODAS AS TELAS OK")
	get_tree().quit()
