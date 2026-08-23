extends Control

## Menu principal: hub de tudo (jogar, heróis, loja, talentos, codex, recordes).

const P := preload("res://scripts/utils/Theme.gd")

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
	"codex":        "res://scenes/ui/screens/Codex.tscn",
	"map":          "res://scenes/ui/screens/MapSelection.tscn",
}


func _ready() -> void:
	GameManager.change_state(GameManager.GameState.MENU)
	_refresh_subtitle()

	side_menu.option_selected.connect(_on_side_menu_option)
	chest_button.chest_pressed.connect(_on_chest_pressed)
	start_button.start_pressed.connect(_on_start_pressed)
	bottom_nav.tab_pressed.connect(_on_tab_pressed)

	AudioManager.play_menu_music()

	# Primeira vez: manda direto pro tutorial
	if not bool(SaveSystem.get_value("tutorial_seen", false)):
		await get_tree().create_timer(0.35).timeout
		_open_screen("tutorial")


func _refresh_subtitle() -> void:
	var pending_level: int = int(SaveSystem.get_value("pending_level_announce", 0))
	if pending_level > 0:
		var unlocks: Array = SaveSystem.get_value("pending_unlocks_announce", [])
		if unlocks.is_empty():
			subtitle.text = "✨ Conta nível %d!" % pending_level
		else:
			var names: PackedStringArray = []
			for u in unlocks:
				names.append(String(u))
			subtitle.text = "✨ Nível %d · 🔓 %s" % [pending_level, ", ".join(names)]
		subtitle.add_theme_color_override("font_color", P.ACCENT_GOLD)
		SaveSystem.set_value("pending_level_announce", 0)
		SaveSystem.set_value("pending_unlocks_announce", [])
		return

	subtitle.remove_theme_color_override("font_color")
	var best := int(SaveSystem.get_value("best_time", 0))
	var kills := int(SaveSystem.get_value("total_kills", 0))
	if best <= 0:
		subtitle.text = "Sobreviva à noite. Ou tente."
	else:
		subtitle.text = "Recorde: %s  ·  %d KOs" % [GameManager.format_time(best), kills]


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
	var reward: Dictionary = ProgressionManager.claim_daily()
	if reward.is_empty():
		EventBus.sfx("deny", 0.6)
		return
	subtitle.text = "🎁 Dia %d: +%d 🪙 e +%d ⚡" % [int(reward["streak"]), int(reward["coins"]), int(reward["energy"])]
	subtitle.add_theme_color_override("font_color", P.ACCENT_GOLD)


func _on_start_pressed() -> void:
	_open_screen("map")


func _on_tab_pressed(tab: String) -> void:
	match tab:
		"fight":
			_on_start_pressed()
		_:
			_open_screen(tab)


func _open_screen(key: String) -> void:
	var path: String = SCREEN_PATHS.get(key, "")
	if path == "":
		return
	EventBus.sfx("click", 0.5)
	get_tree().change_scene_to_file(path)
