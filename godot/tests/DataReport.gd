extends Node

## Relatório de dados: DPS das armas, curva de XP, raridades e escalada
## dos inimigos. Serve pra balancear sem abrir o jogo.
## Uso: godot --headless --path godot res://tests/DataReport.tscn

const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")
const RarityScript := preload("res://scripts/utils/Rarity.gd")
const PlayerScript := preload("res://scenes/player/Player.gd")

const ENEMY_KEYS := [
	"shade", "runner", "bat", "brute", "archer", "exploder", "charger",
	"slime", "summoner", "golem", "miniboss", "boss_base", "boss_final",
]


func _ready() -> void:
	_weapons()
	_xp_curve()
	_rarity()
	_enemy_scaling()
	get_tree().quit()


func _weapons() -> void:
	print("\n=== ARMAS (dano por segundo teórico, alvo único) ===")
	print("chave              nv1     nv4     nv8    tipo")
	for key in RegistryScript.KEYS:
		var d: Resource = RegistryScript.get_data(key)
		if d == null:
			print("%-18s FALTANDO" % key)
			continue
		var line := "%-18s" % key
		for lvl in [1, 4, 8]:
			var dps: float = d.damage_at_level(lvl) * float(d.projectile_count_at_level(lvl)) / maxf(0.05, d.cooldown_at_level(lvl))
			line += "%7.1f" % dps
		line += "  %s%s" % [d.icon, " ★evolui" if d.evolves_into != "" else ""]
		print(line)


func _xp_curve() -> void:
	print("\n=== CURVA DE XP ===")
	var total: float = 0.0
	for lvl in [1, 2, 3, 5, 8, 12, 16, 20, 25, 30]:
		var need: float = PlayerScript.xp_needed(lvl)
		print("nivel %2d → %5d xp (gemas de 5xp: %d)" % [lvl, int(need), int(need / 5.0)])
	for lvl in range(1, 31):
		total += PlayerScript.xp_needed(lvl)
	print("acumulado até o nível 30: %d xp" % int(total))


func _rarity() -> void:
	print("\n=== RARIDADE (1000 sorteios) ===")
	for luck in [0.0, 0.5, 1.5]:
		var counts := {"comum": 0, "raro": 0, "epico": 0, "lendario": 0}
		for i in range(1000):
			counts[RarityScript.roll(luck, false)] += 1
		print("sorte %.1f → comum %d · raro %d · épico %d · lendário %d" % [
			luck, counts["comum"], counts["raro"], counts["epico"], counts["lendario"]])
	var chest := {"comum": 0, "raro": 0, "epico": 0, "lendario": 0}
	for i in range(1000):
		chest[RarityScript.roll(0.0, true)] += 1
	print("baú          → comum %d · raro %d · épico %d · lendário %d" % [
		chest["comum"], chest["raro"], chest["epico"], chest["lendario"]])


func _enemy_scaling() -> void:
	print("\n=== INIMIGOS (vida no minuto X, dificuldade normal) ===")
	print("chave         base   1min   3min   6min  10min   dano")
	for key in ENEMY_KEYS:
		var path: String = "res://resources/enemies/%s.tres" % key
		if not ResourceLoader.exists(path):
			print("%-12s FALTANDO" % key)
			continue
		var d: Resource = load(path)
		var line := "%-12s" % key
		for t in [0.0, 60.0, 180.0, 360.0, 600.0]:
			line += "%7d" % int(d.hp * (1.0 + t / 150.0))
		line += "%7d" % int(d.contact_damage)
		print(line)
