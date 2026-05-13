extends Control


func _ready() -> void:
	%BackButton.pressed.connect(_back)


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")
