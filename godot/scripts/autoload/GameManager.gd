extends Node

## Estado global da sessão: dificuldade, objetivo da run e navegação.

enum GameState {
	BOOT,
	MENU,
	PLAYING,
	UPGRADE,
	CHEST,
	PAUSED,
	GAME_OVER,
	VICTORY,
}

var state: GameState = GameState.BOOT
var current_save_slot: int = 1
var selected_character: String = "hunter"
var selected_difficulty: String = "normal"
var selected_goal_seconds: int = 600
var run_seed: int = 0
var energy_bonus: bool = false  # gastou energia: +20% de moedas na run
var selected_weapon: String = ""   # arma inicial escolhida (vazia = a do herói)

const DIFFICULTIES := {
	"easy":     {"label": "Tranquilo", "icon": "🌱", "hp_mod": 0.80, "damage_mod": 0.80, "coin_mod": 0.85, "unlock_level": 1},
	"normal":   {"label": "Normal",    "icon": "🌙", "hp_mod": 1.00, "damage_mod": 1.00, "coin_mod": 1.00, "unlock_level": 1},
	"hard":     {"label": "Difícil",   "icon": "🔥", "hp_mod": 1.25, "damage_mod": 1.20, "coin_mod": 1.30, "unlock_level": 4},
	"infernal": {"label": "Infernal",  "icon": "💀", "hp_mod": 1.55, "damage_mod": 1.45, "coin_mod": 1.70, "unlock_level": 8},
}

const GOALS := [
	{"seconds": 300,  "label": "5 min",  "note": "Partida rápida"},
	{"seconds": 600,  "label": "10 min", "note": "Clássica"},
	{"seconds": 900,  "label": "15 min", "note": "Maratona"},
]


func _ready() -> void:
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	state = GameState.MENU
	# O save carrega depois deste autoload: aplica no próximo quadro
	apply_saved_fullscreen.call_deferred()


## Lê a preferência de tela cheia do save (chamado no boot e pelo Main)
func apply_saved_fullscreen() -> void:
	selected_weapon = String(SaveSystem.get_value("selected_weapon", ""))
	var wanted: bool = bool(SaveSystem.get_value("fullscreen", false))
	if wanted != is_fullscreen():
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if wanted else DisplayServer.WINDOW_MODE_WINDOWED)


## F11 alterna tela cheia em qualquer tela do jogo
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		get_viewport().set_input_as_handled()
		toggle_fullscreen()


func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN


func apply_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)
	SaveSystem.set_value("fullscreen", enabled)


func toggle_fullscreen() -> void:
	apply_fullscreen(not is_fullscreen())


## Arma inicial: a escolhida na tela de mapas ou a padrão do herói
func starting_weapon() -> String:
	var chosen: String = String(SaveSystem.get_value("selected_weapon", ""))
	var unlocked: Array = SaveSystem.get_value("unlocked_weapons", [])
	if chosen != "" and unlocked.has(chosen):
		return chosen
	var character: Resource = CharacterRegistry.selected()
	if character != null and character.starter_weapon != "":
		return character.starter_weapon
	return "wand"


func set_starting_weapon(key: String) -> void:
	selected_weapon = key
	SaveSystem.set_value("selected_weapon", key)


func change_state(new_state: GameState) -> void:
	state = new_state


func change_scene(scene_path: String) -> void:
	EventBus.scene_change_requested.emit(scene_path)
	get_tree().change_scene_to_file(scene_path)


func difficulty_data() -> Dictionary:
	return DIFFICULTIES.get(selected_difficulty, DIFFICULTIES["normal"])


func difficulty_unlocked(key: String) -> bool:
	var info: Dictionary = DIFFICULTIES.get(key, {})
	if info.is_empty():
		return false
	return int(SaveSystem.get_value("player_level", 1)) >= int(info.get("unlock_level", 1))


func set_difficulty(key: String) -> void:
	if not DIFFICULTIES.has(key) or not difficulty_unlocked(key):
		return
	selected_difficulty = key
	SaveSystem.set_value("difficulty", key)


func set_goal(seconds: int) -> void:
	selected_goal_seconds = seconds
	SaveSystem.set_value("goal_seconds", seconds)


func format_time(seconds: int) -> String:
	return "%02d:%02d" % [int(seconds / 60.0), seconds % 60]
