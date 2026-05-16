extends Control

signal back_pressed

@export var screen_title: String = "Tela"


func _ready() -> void:
	if has_node("%TitleLabel"):
		(get_node("%TitleLabel") as Label).text = screen_title
	if has_node("%BackButton"):
		(get_node("%BackButton") as Button).pressed.connect(func(): back_pressed.emit())
