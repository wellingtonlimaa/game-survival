extends Node

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

const DIFFICULTIES := {
	"easy":     { "hp_mod": 0.85, "speed_mod": 0.92, "coin_mod": 0.90 },
	"normal":   { "hp_mod": 1.00, "speed_mod": 1.00, "coin_mod": 1.00 },
	"hard":     { "hp_mod": 1.18, "speed_mod": 1.08, "coin_mod": 1.18 },
	"infernal": { "hp_mod": 1.42, "speed_mod": 1.18, "coin_mod": 1.40 },
}


func _ready() -> void:
	randomize()
	state = GameState.MENU


func change_state(new_state: GameState) -> void:
	state = new_state


func change_scene(scene_path: String) -> void:
	EventBus.scene_change_requested.emit(scene_path)
	get_tree().change_scene_to_file(scene_path)


func difficulty_data() -> Dictionary:
	return DIFFICULTIES.get(selected_difficulty, DIFFICULTIES["normal"])
