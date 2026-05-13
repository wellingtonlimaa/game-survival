extends Node

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const WORLD_RENDERER_SCENE := preload("res://scenes/world/WorldRenderer.tscn")
const GAME_HUD_SCENE := preload("res://scenes/ui/hud/GameHUD.tscn")
const DAMAGE_NUMBER_SCENE := preload("res://scenes/effects/DamageNumber.tscn")
const UPGRADE_SCREEN_SCENE := preload("res://scenes/ui/upgrade/UpgradeScreen.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/screens/GameOver.tscn")
const WorldGeneratorScript := preload("res://scripts/systems/WorldGenerator.gd")
const WeaponSystemScript := preload("res://scripts/systems/WeaponSystem.gd")
const SpawnDirectorScript := preload("res://scripts/systems/SpawnDirector.gd")
const UpgradeSystemScript := preload("res://scripts/systems/UpgradeSystem.gd")
const RunFinalizerScript := preload("res://scripts/systems/RunFinalizer.gd")
const EventDirectorScript := preload("res://scripts/systems/EventDirector.gd")
const MapModifierScript := preload("res://scripts/systems/MapModifier.gd")
const PET_SCENE := preload("res://scenes/world/Pet.tscn")
const MERCHANT_SCENE := preload("res://scenes/world/Merchant.tscn")

const MAIN_MENU_PATH := "res://scenes/ui/menu/MainMenu.tscn"

@onready var world_root: Node2D = $WorldRoot
@onready var hud_root: CanvasLayer = $HUDRoot
@onready var ui_root: CanvasLayer = $UIRoot

var map: Resource
var world: Dictionary
var player: Node2D
var renderer: Node2D
var hud: Control
var enemies_container: Node2D
var projectiles_container: Node2D
var effects_container: Node2D
var pickups_container: Node2D
var weapon_system: Node = null
var spawn_director: Node = null
var upgrade_system: Node = null
var upgrade_screen: Control = null
var game_over_screen: Control = null

var time_alive: float = 0.0
var kills: int = 0
var boss_kills: int = 0
var evolved_count: int = 0
var run_finalized: bool = false

var event_director: Node = null
var modifier_key: String = "calm"
var modifier_info: Dictionary = {}


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	_load_map()
	_pick_modifier()
	_build_containers()
	_build_world()
	_spawn_player()
	_apply_progression()
	_build_hud()
	_build_weapons()
	_build_upgrade_system()
	_build_spawner()
	_build_event_director()
	_spawn_pet_and_merchant()
	_connect_signals()
	_announce_modifier()


func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	time_alive += delta
	if weapon_system != null:
		weapon_system.tick(delta)
	if spawn_director != null:
		spawn_director.tick(delta)
	if event_director != null:
		event_director.tick(delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()


func _load_map() -> void:
	map = MapRegistry.selected_map()


func _pick_modifier() -> void:
	modifier_key = MapModifierScript.choose_random()
	modifier_info = MapModifierScript.get_info(modifier_key)


func _announce_modifier() -> void:
	if modifier_key == "calm":
		return
	EventBus.narrative_triggered.emit("⚙ %s" % String(modifier_info.get("label", "")))


func _spawn_pet_and_merchant() -> void:
	# Pet sempre presente (1 inicial)
	var pet := PET_SCENE.instantiate()
	world_root.add_child(pet)
	pet.setup(player, enemies_container, projectiles_container)

	# Mercador num spot fixo do mapa
	var merchant := MERCHANT_SCENE.instantiate()
	world_root.add_child(merchant)
	merchant.global_position = Vector2(map.world_width * 0.50, map.world_height * 0.35)
	merchant.setup(player)


func _build_event_director() -> void:
	event_director = EventDirectorScript.new()
	event_director.name = "EventDirector"
	add_child(event_director)
	event_director.configure(player, pickups_container, spawn_director, effects_container, hud_root)


func _build_containers() -> void:
	enemies_container = Node2D.new()
	enemies_container.name = "Enemies"
	world_root.add_child(enemies_container)

	projectiles_container = Node2D.new()
	projectiles_container.name = "Projectiles"
	world_root.add_child(projectiles_container)

	effects_container = Node2D.new()
	effects_container.name = "Effects"
	world_root.add_child(effects_container)

	pickups_container = Node2D.new()
	pickups_container.name = "Pickups"
	world_root.add_child(pickups_container)


func _build_world() -> void:
	var generator: RefCounted = WorldGeneratorScript.new(map)
	world = generator.generate()

	renderer = WORLD_RENDERER_SCENE.instantiate()
	world_root.add_child(renderer)
	world_root.move_child(renderer, 0)
	renderer.setup(map, world)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	world_root.add_child(player)
	player.setup(map, world)


func _apply_progression() -> void:
	RunFinalizerScript.apply_pre_run(player)
	# Modifier de mapa altera dano dado
	player.damage_mult *= float(modifier_info.get("damage_mult", 1.0))


func _build_hud() -> void:
	hud = GAME_HUD_SCENE.instantiate()
	hud_root.add_child(hud)
	hud.setup(map, world, player)
	hud.back_to_menu_requested.connect(_back_to_menu)


func _build_weapons() -> void:
	weapon_system = WeaponSystemScript.new()
	weapon_system.name = "WeaponSystem"
	add_child(weapon_system)
	weapon_system.configure(player, enemies_container, projectiles_container)
	# Arma inicial baseada no personagem selecionado
	var character: Resource = CharacterRegistry.selected()
	var starter: String = "wand"
	if character != null and character.starter_weapon != "":
		starter = character.starter_weapon
	weapon_system.equip(starter)
	if hud.has_method("bind_weapons_to_bar"):
		hud.bind_weapons_to_bar(weapon_system)


func _build_upgrade_system() -> void:
	upgrade_system = UpgradeSystemScript.new()
	upgrade_system.name = "UpgradeSystem"
	add_child(upgrade_system)
	upgrade_system.configure(player, weapon_system)


func _build_spawner() -> void:
	spawn_director = SpawnDirectorScript.new()
	spawn_director.name = "SpawnDirector"
	add_child(spawn_director)
	spawn_director.configure(player, enemies_container, projectiles_container, pickups_container, map)


func _connect_signals() -> void:
	EventBus.damage_number_requested.connect(_on_damage_number_requested)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.boss_killed.connect(_on_boss_killed)
	EventBus.weapon_evolved.connect(_on_weapon_evolved)


func _on_damage_number_requested(world_pos: Vector2, value: float, color: Color) -> void:
	if effects_container == null:
		return
	var dmg := DAMAGE_NUMBER_SCENE.instantiate()
	effects_container.add_child(dmg)
	dmg.global_position = world_pos
	dmg.setup(value, color)


func _on_enemy_killed(enemy: Node, _src: String) -> void:
	kills += 1
	if enemy != null and "data" in enemy and enemy.data != null:
		if enemy.data.tier == 3:
			boss_kills += 1


func _on_boss_killed(_b: Node) -> void:
	boss_kills += 1


func _on_weapon_evolved(_k: String) -> void:
	evolved_count += 1


func _on_player_died() -> void:
	_finalize_run.call_deferred(false)


func _on_level_up(_new_level: int) -> void:
	_show_upgrade_screen.call_deferred(false)


func _show_upgrade_screen(chest: bool) -> void:
	if upgrade_screen != null:
		return
	var choices: Array = upgrade_system.roll_choices(chest)
	if choices.is_empty():
		return
	GameManager.change_state(GameManager.GameState.UPGRADE)
	get_tree().paused = true

	upgrade_screen = UPGRADE_SCREEN_SCENE.instantiate()
	upgrade_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(upgrade_screen)
	upgrade_screen.setup(choices, upgrade_system.rerolls_left, upgrade_system.banishes_left, chest)

	upgrade_screen.choice_made.connect(_on_choice_made)
	upgrade_screen.reroll_pressed.connect(_on_reroll)
	upgrade_screen.banish_pressed.connect(_on_banish)


func _on_choice_made(choice: Dictionary) -> void:
	upgrade_system.pick(choice)
	_close_upgrade_screen()


func _on_reroll() -> void:
	var new_choices: Array = upgrade_system.reroll()
	if new_choices.is_empty():
		return
	upgrade_screen.setup(new_choices, upgrade_system.rerolls_left, upgrade_system.banishes_left)


func _on_banish(choice: Dictionary) -> void:
	var new_choices: Array = upgrade_system.banish(choice)
	if new_choices.is_empty():
		return
	upgrade_screen.setup(new_choices, upgrade_system.rerolls_left, upgrade_system.banishes_left)


func _close_upgrade_screen() -> void:
	if upgrade_screen != null:
		upgrade_screen.queue_free()
		upgrade_screen = null
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)


func _finalize_run(won: bool) -> void:
	if run_finalized:
		return
	run_finalized = true
	get_tree().paused = true
	GameManager.change_state(GameManager.GameState.GAME_OVER)

	var stats := {
		"time": int(time_alive),
		"kills": kills,
		"boss_kills": boss_kills,
		"evolved": evolved_count,
		"coins": kills,  # 1 moeda por kill, simplificado
		"level": player.level if is_instance_valid(player) else 1,
		"won": won,
	}

	var result: Dictionary = RunFinalizerScript.finalize(stats)

	game_over_screen = GAME_OVER_SCENE.instantiate()
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(game_over_screen)
	game_over_screen.setup(stats, int(result.get("coin_total", 0)), int(result.get("bonus", 0)), won)
	game_over_screen.back_to_menu.connect(_back_to_menu)


func _back_to_menu() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)
