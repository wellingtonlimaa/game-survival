extends Node

## Testa o caminho completo de evolução de TODAS as armas:
## arma no nível máximo + passiva exigida no nível certo → carta dourada.

const GAME_WORLD := preload("res://scenes/main/GameWorld.tscn")
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")

var game: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	SaveSystem.set_value("unlocked_weapons", RegistryScript.KEYS.duplicate())
	game = GAME_WORLD.instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_run()
	get_tree().quit()


func _run() -> void:
	var ok: int = 0
	var fail: int = 0
	for key in RegistryScript.KEYS:
		var result: String = _test_weapon(key)
		if result == "":
			ok += 1
		else:
			fail += 1
			print("[EVO] FALHOU %s: %s" % [key, result])
	print("[EVO] %d evoluções ok, %d falhas" % [ok, fail])


func _test_weapon(key: String) -> String:
	var ws: Node = game.weapon_system
	var us: Node = game.upgrade_system
	# Zera o estado entre testes
	for slot in ws.slots.duplicate():
		ws._clear_persistent(slot)
	ws.slots.clear()
	us.passives.clear()

	if not ws.equip(key):
		return "não equipou"
	var slot = ws.slot_for(key)
	for i in range(slot.data.max_level - 1):
		ws.equip(key)
	if slot.level != slot.data.max_level:
		return "não chegou ao nível máximo (%d)" % slot.level

	var info: Dictionary = RegistryScript.evolution_for(key)
	if info.is_empty():
		return "sem evolução cadastrada"
	var passive_key: String = String(info.get("requires", ""))
	var res: Resource = us.passive_data(passive_key)
	if res == null:
		return "passiva '%s' não existe" % passive_key
	var needed: int = us.evolution_passive_requirement(res)
	for i in range(needed):
		us._apply_passive(passive_key, 1.0)

	if not us._can_evolve(slot):
		return "requisito não reconhecido"

	var choices: Array = us.roll_choices(false)
	var found: bool = false
	for c in choices:
		if String(c["kind"]) == "weapon_evolve" and String(c["key"]) == key:
			found = true
			us.pick(c)
			break
	if not found:
		return "carta de evolução não apareceu"

	var evolved = ws.slot_for(String(info["into"]))
	if evolved == null:
		return "arma não virou %s" % String(info["into"])
	if not evolved.data.is_evolution:
		return "flag is_evolution não marcada"
	return ""
