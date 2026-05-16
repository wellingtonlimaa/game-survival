extends Control

@onready var subtitle: Label = %Subtitle
@onready var side_menu: Control = %SideMenu
@onready var chest_button: Button = %ChestButton
@onready var start_button: Button = %StartButton
@onready var bottom_nav: Control = %BottomNav

const SCREEN_PATHS := {
	"shop":         "res://scenes/ui/screens/Shop.tscn",
	"characters":   "res://scenes/ui/screens/Characters.tscn",
	"talents":      "res://scenes/ui/screens/Talents.tscn",
	"achievements": "res://scenes/ui/screens/Achievements.tscn",
	"records":      "res://scenes/ui/screens/Records.tscn",
	"settings":     "res://scenes/ui/screens/Settings.tscn",
	"tutorial":     "res://scenes/ui/screens/Tutorial.tscn",
}


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	_refresh_subtitle()

	side_menu.option_selected.connect(_on_side_menu_option)
	chest_button.chest_pressed.connect(_on_chest_pressed)
	start_button.start_pressed.connect(_on_start_pressed)
	bottom_nav.tab_pressed.connect(_on_tab_pressed)


func _refresh_subtitle() -> void:
	var best := int(SaveSystem.get_value("best_time", 0))
	if best <= 0:
		subtitle.text = "Nenhuma vitória registrada"
	else:
		var minutes := best / 60
		var seconds := best % 60
		subtitle.text = "Melhor tempo: %dm %ds" % [minutes, seconds]


func _on_side_menu_option(opt: String) -> void:
	match opt:
		"settings":
			_open_screen("settings")
		"mail":
			SaveSystem.set_value("has_mail", false)
			_open_screen("achievements")
		"announce":
			SaveSystem.set_value("has_announcement", false)
			_open_screen("tutorial")


func _on_chest_pressed() -> void:
	# Bônus diário (placeholder): dá 50 moedas e regen 20 energia
	SaveSystem.add_coins(50)
	var energy: int = int(SaveSystem.get_value("energy", 0))
	var max_e: int = int(SaveSystem.get_value("max_energy", 60))
	SaveSystem.set_value("energy", min(max_e, energy + 20))
	EventBus.currency_changed.emit("energy", SaveSystem.get_value("energy", 0))


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/screens/MapSelection.tscn")


func _on_tab_pressed(tab: String) -> void:
	match tab:
		"fight":
			_on_start_pressed()
		"characters":
			_open_screen("characters")
		"talents":
			_open_screen("talents")
		"shop":
			_open_screen("shop")
		"premium":
			_open_screen("records")


func _open_screen(key: String) -> void:
	var path: String = SCREEN_PATHS.get(key, "")
	if path == "":
		return
	get_tree().change_scene_to_file(path)
