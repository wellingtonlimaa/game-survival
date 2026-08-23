extends Node

## Maestro da partida: monta o mundo, liga os sistemas e cuida do estado da run.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const WORLD_RENDERER_SCENE := preload("res://scenes/world/WorldRenderer.tscn")
const GAME_HUD_SCENE := preload("res://scenes/ui/hud/GameHUD.tscn")
const DAMAGE_NUMBER_SCENE := preload("res://scenes/effects/DamageNumber.tscn")
const AREA_EFFECT_SCENE := preload("res://scenes/effects/AreaEffect.tscn")
const SCREEN_EFFECTS_SCENE := preload("res://scenes/effects/ScreenEffects.tscn")
const UPGRADE_SCREEN_SCENE := preload("res://scenes/ui/upgrade/UpgradeScreen.tscn")
const GAME_OVER_SCENE := preload("res://scenes/ui/screens/GameOver.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/screens/PauseMenu.tscn")
const PET_SCENE := preload("res://scenes/world/Pet.tscn")
const MERCHANT_SCENE := preload("res://scenes/world/Merchant.tscn")
const ALTAR_SCENE := preload("res://scenes/world/Altar.tscn")
const BOSS_ARENA_SCENE := preload("res://scenes/world/BossArena.tscn")
const PICKUP_SCENE := preload("res://scenes/pickups/Pickup.tscn")

const WorldGeneratorScript := preload("res://scripts/systems/WorldGenerator.gd")
const WeaponSystemScript := preload("res://scripts/systems/WeaponSystem.gd")
const SpawnDirectorScript := preload("res://scripts/systems/SpawnDirector.gd")
const UpgradeSystemScript := preload("res://scripts/systems/UpgradeSystem.gd")
const RunFinalizerScript := preload("res://scripts/systems/RunFinalizer.gd")
const EventDirectorScript := preload("res://scripts/systems/EventDirector.gd")
const MapModifierScript := preload("res://scripts/systems/MapModifier.gd")
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")
const P := preload("res://scripts/utils/Theme.gd")

const MAIN_MENU_PATH := "res://scenes/ui/menu/MainMenu.tscn"
const MAX_EFFECT_NODES := 40

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
var screen_effects: CanvasLayer

var weapon_system: Node = null
var spawn_director: Node = null
var upgrade_system: Node = null
var event_director: Node = null
var upgrade_screen: Control = null
var game_over_screen: Control = null
var pause_menu: Control = null

# --- Estado da run ---
var time_alive: float = 0.0
var kills: int = 0
var boss_kills: int = 0
var evolved_count: int = 0
var run_coins: int = 0
var damage_dealt: float = 0.0
var combo: int = 0
var combo_timer: float = 0.0
var run_finalized: bool = false
var victory_triggered: bool = false
var goal_seconds: float = 600.0
var pending_chests: int = 0

var modifier_key: String = "calm"
var modifier_info: Dictionary = {}

const COMBO_WINDOW := 3.0


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().paused = false
	goal_seconds = float(GameManager.selected_goal_seconds)
	_load_map()
	_pick_modifier()
	_build_containers()
	_build_world()
	_spawn_player()
	_build_screen_effects()
	_apply_progression()
	_build_hud()
	_build_weapons()
	_build_upgrade_system()
	_build_spawner()
	_build_event_director()
	_spawn_world_entities()
	_connect_signals()
	_announce_start()
	AudioManager.play_menu_music()


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

	if combo_timer > 0.0:
		combo_timer = maxf(0.0, combo_timer - delta)
		if combo_timer <= 0.0 and combo > 0:
			combo = 0
			_apply_combo_bonus()
			EventBus.combo_changed.emit(0, 0.0)
		else:
			EventBus.combo_changed.emit(combo, combo_timer / COMBO_WINDOW)

	if not victory_triggered and time_alive >= goal_seconds:
		_start_final_showdown()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		_toggle_pause_menu()


func _notification(what: int) -> void:
	# Perder o foco da janela pausa o jogo (evita morrer ao alt-tab)
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and GameManager.state == GameManager.GameState.PLAYING:
		if not run_finalized and pause_menu == null:
			_open_pause_menu()


# --- Construção --------------------------------------------------------------

func _load_map() -> void:
	map = MapRegistry.selected_map()


func _pick_modifier() -> void:
	modifier_key = MapModifierScript.choose_random()
	modifier_info = MapModifierScript.get_info(modifier_key)


func _build_containers() -> void:
	enemies_container = Node2D.new()
	enemies_container.name = "Enemies"
	world_root.add_child(enemies_container)

	pickups_container = Node2D.new()
	pickups_container.name = "Pickups"
	world_root.add_child(pickups_container)

	projectiles_container = Node2D.new()
	projectiles_container.name = "Projectiles"
	world_root.add_child(projectiles_container)

	effects_container = Node2D.new()
	effects_container.name = "Effects"
	world_root.add_child(effects_container)


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
	player.setup(map, world, enemies_container)


func _build_screen_effects() -> void:
	screen_effects = SCREEN_EFFECTS_SCENE.instantiate()
	add_child(screen_effects)
	screen_effects.bind(player)
	screen_effects.set_darkness(float(modifier_info.get("darkness", 0.0)))


func _apply_progression() -> void:
	RunFinalizerScript.apply_pre_run(player)
	player.damage_mult *= float(modifier_info.get("damage_mult", 1.0))
	player.damage_taken_mult *= float(modifier_info.get("damage_taken_mult", 1.0))
	player.xp_mult *= float(modifier_info.get("xp_mult", 1.0))
	player.coin_mult *= float(modifier_info.get("coin_mult", 1.0))


func _build_hud() -> void:
	hud = GAME_HUD_SCENE.instantiate()
	hud_root.add_child(hud)
	hud.setup(map, world, player, self)
	hud.back_to_menu_requested.connect(_back_to_menu)
	hud.pause_requested.connect(_toggle_pause_menu)


func _build_weapons() -> void:
	weapon_system = WeaponSystemScript.new()
	weapon_system.name = "WeaponSystem"
	add_child(weapon_system)
	weapon_system.configure(player, enemies_container, projectiles_container, effects_container)

	weapon_system.equip(GameManager.starting_weapon())
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
	spawn_director.configure(player, enemies_container, projectiles_container, pickups_container, map, effects_container, modifier_info)


func _build_event_director() -> void:
	event_director = EventDirectorScript.new()
	event_director.name = "EventDirector"
	add_child(event_director)
	event_director.configure(player, pickups_container, spawn_director, effects_container, screen_effects, enemies_container)


func _spawn_world_entities() -> void:
	var pet := PET_SCENE.instantiate()
	world_root.add_child(pet)
	pet.setup(player, enemies_container, projectiles_container)

	var merchant := MERCHANT_SCENE.instantiate()
	world_root.add_child(merchant)
	merchant.global_position = Vector2(map.world_width * 0.62, map.world_height * 0.42)
	merchant.setup(player, self)
	world["merchant_pos"] = merchant.global_position

	for a in world.get("altars", []):
		var altar := ALTAR_SCENE.instantiate()
		world_root.add_child(altar)
		altar.global_position = a["pos"]
		altar.setup(String(a["kind"]), player, spawn_director, pickups_container, enemies_container)

	for arena_data in world.get("boss_arenas", []):
		var arena := BOSS_ARENA_SCENE.instantiate()
		world_root.add_child(arena)
		arena.global_position = arena_data["pos"]
		arena.radius = float(arena_data.get("radius", 190.0))
		arena.setup(String(arena_data["boss"]), int(arena_data["level"]), player, pickups_container)
		arena.boss_requested.connect(_on_arena_boss_requested)


## Arena pediu o chefe: nasce reforçado no centro do círculo
func _on_arena_boss_requested(arena: Node, boss_key: String) -> void:
	if spawn_director == null:
		return
	var spawn_pos: Vector2 = arena.global_position + Vector2(0, -240)
	var boss: Node = spawn_director.spawn_arena_boss(boss_key, spawn_pos)
	if boss != null:
		arena.bind_boss(boss)


func _announce_start() -> void:
	var goal_min: int = int(goal_seconds / 60.0)
	EventBus.toast("%s · sobreviva %d min" % [map.display_name, goal_min], P.ACCENT_GOLD, "🌙")
	if modifier_key != "calm":
		await get_tree().create_timer(1.6).timeout
		EventBus.toast(String(modifier_info.get("label", "")), modifier_info.get("color", P.ACCENT_PURPLE), String(modifier_info.get("icon", "⚙")))


func _connect_signals() -> void:
	EventBus.damage_number_requested.connect(_on_damage_number_requested)
	EventBus.crit_number_requested.connect(_on_crit_number_requested)
	EventBus.floating_text_requested.connect(_on_floating_text_requested)
	EventBus.impact_requested.connect(_on_impact_requested)
	EventBus.explosion_requested.connect(_on_explosion_requested)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	EventBus.boss_killed.connect(_on_boss_killed)
	EventBus.weapon_evolved.connect(_on_weapon_evolved)
	EventBus.pickup_collected.connect(_on_pickup_collected)
	EventBus.chest_opened.connect(_on_chest_opened)
	EventBus.player_stats_changed.connect(_refresh_hud_buffs)
	EventBus.loadout_changed.connect(_on_loadout_changed)


func _refresh_hud_buffs() -> void:
	if hud != null and upgrade_system != null and hud.has_method("refresh_buffs"):
		hud.refresh_buffs(upgrade_system.summary())


func _on_loadout_changed() -> void:
	if weapon_system != null and weapon_system.slots.size() >= 6:
		UnlockManager.notify_arsenal_full()


# --- Efeitos -----------------------------------------------------------------

func _effects_full() -> bool:
	return effects_container == null or effects_container.get_child_count() > MAX_EFFECT_NODES


func _on_damage_number_requested(world_pos: Vector2, value: float, color: Color) -> void:
	if _effects_full():
		return
	var dmg := DAMAGE_NUMBER_SCENE.instantiate()
	effects_container.add_child(dmg)
	dmg.global_position = world_pos
	dmg.setup(value, color, false)


func _on_crit_number_requested(world_pos: Vector2, value: float, color: Color) -> void:
	if _effects_full():
		return
	var dmg := DAMAGE_NUMBER_SCENE.instantiate()
	effects_container.add_child(dmg)
	dmg.global_position = world_pos
	dmg.setup(value, color, true)


func _on_floating_text_requested(world_pos: Vector2, text: String, color: Color) -> void:
	if text == "" or _effects_full():
		return
	var node := DAMAGE_NUMBER_SCENE.instantiate()
	effects_container.add_child(node)
	node.global_position = world_pos
	node.setup_text(text, color)


func _on_impact_requested(world_pos: Vector2, color: Color, power: float) -> void:
	if _effects_full():
		return
	var fx := AREA_EFFECT_SCENE.instantiate()
	effects_container.add_child(fx)
	fx.global_position = world_pos
	fx.setup("impact", 16.0 + 18.0 * power, color, 0.22 + 0.1 * power)


func _on_explosion_requested(world_pos: Vector2, radius: float, color: Color) -> void:
	if effects_container == null:
		return
	var fx := AREA_EFFECT_SCENE.instantiate()
	effects_container.add_child(fx)
	fx.global_position = world_pos
	fx.setup("explosion", radius, color, 0.35)


# --- Eventos de jogo ---------------------------------------------------------

func _on_enemy_damaged(_enemy: Node, amount: float, _crit: bool) -> void:
	damage_dealt += amount


func _on_enemy_killed(enemy: Node, _src: String) -> void:
	kills += 1
	combo += 1
	combo_timer = COMBO_WINDOW
	EventBus.combo_changed.emit(combo, 1.0)
	if combo > 0 and combo % 25 == 0:
		EventBus.toast("COMBO x%d" % combo, P.ACCENT_GOLD, "🔥")
		EventBus.sfx("chest", 0.5)
	_apply_combo_bonus()
	if enemy != null and "data" in enemy and enemy.data != null:
		if enemy.data.tier == 3:
			boss_kills += 1
	UnlockManager.notify_run_progress(kills, int(time_alive), boss_kills)


## Combo aquece o dano: +4% a cada 10 KOs seguidos (máx +30%).
func _apply_combo_bonus() -> void:
	if not is_instance_valid(player):
		return
	player.combo_mult = 1.0 + minf(0.30, float(int(combo / 10)) * 0.04)


func _on_boss_killed(boss: Node) -> void:
	EventBus.hitstop_requested.emit(0.18)
	EventBus.toast("CHEFE DERROTADO!", P.ACCENT_GOLD, "👑")
	_spawn_reward_chest(player.global_position + Vector2(0, -40))
	var is_final: bool = boss != null and "data" in boss and boss.data != null and String(boss.data.key) == "boss_final"
	if victory_triggered and is_final:
		_finalize_run.call_deferred(true)


func _on_weapon_evolved(_k: String) -> void:
	evolved_count += 1


func _on_pickup_collected(kind: String, value: float) -> void:
	match kind:
		"coin":
			var gained: int = int(round(value * float(player.coin_mult if "coin_mult" in player else 1.0)))
			run_coins += gained
			EventBus.run_coins_changed.emit(run_coins)
		"magnet":
			_magnet_all()
		"bomb":
			if spawn_director != null:
				var killed: int = spawn_director.nuke_screen(9999.0)
				EventBus.toast("%d inimigos varridos!" % killed, P.ACCENT_ORANGE, "💥")


func _magnet_all() -> void:
	for p in pickups_container.get_children():
		if p.has_method("magnetize"):
			p.magnetize()


func _on_player_died() -> void:
	_finalize_run.call_deferred(false)


func _on_level_up(_new_level: int) -> void:
	_show_upgrade_screen.call_deferred(false)


func _on_chest_opened(_chest: Node) -> void:
	pending_chests += 1
	_show_upgrade_screen.call_deferred(true)


# --- API usada pelo mercador / eventos ---------------------------------------

func try_spend_run_coins(cost: int) -> bool:
	if run_coins < cost:
		return false
	run_coins -= cost
	EventBus.run_coins_changed.emit(run_coins)
	return true


func grant_reroll() -> void:
	if upgrade_system != null:
		upgrade_system.rerolls_left += 1


func grant_random_weapon() -> void:
	if weapon_system == null:
		return
	var options: Array = []
	for key in RegistryScript.unlocked_keys():
		if not weapon_system.has_weapon(key):
			options.append(key)
	if options.is_empty() or weapon_system.is_full():
		# Sem espaço/opção: sobe o nível de uma arma aleatória
		if weapon_system.slots.size() > 0:
			var slot = weapon_system.slots[randi() % weapon_system.slots.size()]
			weapon_system.equip(slot.data.key)
		return
	var key: String = String(options[randi() % options.size()])
	weapon_system.equip(key)
	var data: Resource = RegistryScript.get_data(key)
	if data != null:
		EventBus.toast("Nova arma: %s" % data.display_name, data.icon_color, data.icon)


func open_chest_reward() -> void:
	_show_upgrade_screen.call_deferred(true)


func _spawn_reward_chest(pos: Vector2) -> void:
	var chest := PICKUP_SCENE.instantiate()
	pickups_container.add_child(chest)
	chest.global_position = pos
	chest.setup("chest", 1, player)


# --- Fim de jogo / vitória ---------------------------------------------------

func _start_final_showdown() -> void:
	victory_triggered = true
	if spawn_director != null:
		spawn_director.spawn_final_boss()
	EventBus.narrative_triggered.emit("O CEIFADOR DA NOITE DESPERTOU")
	EventBus.toast("Derrote o Ceifador pra vencer!", P.ACCENT_RED, "☠")


func _show_upgrade_screen(chest: bool) -> void:
	if run_finalized:
		return
	if upgrade_screen != null:
		# Já tem uma tela aberta: guarda pra depois
		if chest:
			pending_chests += 1
		return
	var choices: Array = upgrade_system.roll_choices(chest)
	if choices.is_empty():
		return
	GameManager.change_state(GameManager.GameState.UPGRADE)
	get_tree().paused = true
	if hud != null:
		hud.visible = false

	upgrade_screen = UPGRADE_SCREEN_SCENE.instantiate()
	upgrade_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(upgrade_screen)
	upgrade_screen.setup(choices, upgrade_system.rerolls_left, upgrade_system.banishes_left, chest, player.level)

	upgrade_screen.choice_made.connect(_on_choice_made)
	upgrade_screen.reroll_pressed.connect(_on_reroll)
	upgrade_screen.banish_pressed.connect(_on_banish)
	if chest:
		pending_chests = maxi(0, pending_chests - 1)


func _on_choice_made(choice: Dictionary) -> void:
	upgrade_system.pick(choice)
	_close_upgrade_screen()
	if pending_chests > 0:
		pending_chests -= 1
		_show_upgrade_screen.call_deferred(true)


func _on_reroll() -> void:
	var new_choices: Array = upgrade_system.reroll()
	if new_choices.is_empty():
		return
	upgrade_screen.setup(new_choices, upgrade_system.rerolls_left, upgrade_system.banishes_left, false, player.level)


func _on_banish(choice: Dictionary) -> void:
	var new_choices: Array = upgrade_system.banish(choice)
	if new_choices.is_empty():
		return
	upgrade_screen.setup(new_choices, upgrade_system.rerolls_left, upgrade_system.banishes_left, false, player.level)


func _close_upgrade_screen() -> void:
	if upgrade_screen != null:
		upgrade_screen.queue_free()
		upgrade_screen = null
	if hud != null:
		hud.visible = true
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)


func _toggle_pause_menu() -> void:
	if run_finalized or GameManager.state == GameManager.GameState.UPGRADE:
		return
	if pause_menu != null:
		_close_pause_menu()
	else:
		_open_pause_menu()


func _open_pause_menu() -> void:
	if pause_menu != null:
		return
	GameManager.change_state(GameManager.GameState.PAUSED)
	get_tree().paused = true
	if hud != null:
		hud.visible = false
	pause_menu = PAUSE_MENU_SCENE.instantiate()
	ui_root.add_child(pause_menu)
	pause_menu.setup(_run_stats(), upgrade_system.summary() if upgrade_system != null else {}, weapon_system.loadout_summary() if weapon_system != null else [])
	pause_menu.resume_pressed.connect(_close_pause_menu)
	pause_menu.back_to_menu_pressed.connect(_back_to_menu)
	pause_menu.restart_pressed.connect(_restart_run)


func _close_pause_menu() -> void:
	if pause_menu == null:
		return
	pause_menu.queue_free()
	pause_menu = null
	if hud != null:
		hud.visible = true
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)


func _run_stats() -> Dictionary:
	return {
		"time": int(time_alive),
		"kills": kills,
		"boss_kills": boss_kills,
		"evolved": evolved_count,
		"coins": run_coins,
		"damage": int(damage_dealt),
		"level": player.level if is_instance_valid(player) else 1,
		"dps": int(damage_dealt / maxf(1.0, time_alive)),
		"goal": int(goal_seconds),
	}


func _finalize_run(won: bool) -> void:
	if run_finalized:
		return
	run_finalized = true
	get_tree().paused = true
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	if hud != null:
		hud.visible = false
	if won:
		EventBus.sfx("victory", 1.0)

	var stats: Dictionary = _run_stats()
	stats["won"] = won
	stats["map"] = map.key
	stats["modifier"] = modifier_key

	var result: Dictionary = RunFinalizerScript.finalize(stats)

	game_over_screen = GAME_OVER_SCENE.instantiate()
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_root.add_child(game_over_screen)
	stats["meta_xp"] = int(result.get("meta_xp", 0))
	stats["new_meta_level"] = int(result.get("new_meta_level", 1))
	stats["leveled_up"] = bool(result.get("leveled_up", false))
	stats["level_coin_bonus"] = int(result.get("level_coin_bonus", 0))
	stats["unlocks"] = result.get("unlocks", [])
	stats["achievements"] = result.get("achievements", [])
	stats["best_time"] = int(result.get("best_time", 0))
	stats["is_record"] = bool(result.get("is_record", false))
	stats["gems"] = int(result.get("gems", 0))
	game_over_screen.setup(stats, int(result.get("coin_total", 0)), int(result.get("bonus", 0)), won)
	game_over_screen.back_to_menu.connect(_back_to_menu)
	game_over_screen.restart.connect(_restart_run)


func _restart_run() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)
	get_tree().reload_current_scene()


func _back_to_menu() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)
