extends Node

const MAIN_MENU_PATH := "res://scenes/ui/menu/MainMenu.tscn"


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	GameManager.apply_saved_fullscreen()
	get_tree().change_scene_to_file.call_deferred(MAIN_MENU_PATH)
