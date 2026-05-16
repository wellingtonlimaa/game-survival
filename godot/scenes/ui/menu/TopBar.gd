extends PanelContainer

@onready var player_name_label: Label = %PlayerName
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var coins_label: Label = %CoinsLabel
@onready var gems_label: Label = %GemsLabel
@onready var energy_label: Label = %EnergyLabel


func _ready() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	refresh()


func refresh() -> void:
	player_name_label.text = str(SaveSystem.get_value("player_name", "Sobrevivente"))
	var lvl := int(SaveSystem.get_value("player_level", 1))
	level_label.text = str(lvl)
	xp_bar.max_value = float(_xp_to_next(lvl))
	xp_bar.value = float(SaveSystem.get_value("player_xp", 0))
	coins_label.text = str(int(SaveSystem.get_value("coins", 0)))
	gems_label.text = str(int(SaveSystem.get_value("gems", 0)))
	var energy := int(SaveSystem.get_value("energy", 0))
	var max_energy := int(SaveSystem.get_value("max_energy", 60))
	energy_label.text = "%d/%d" % [energy, max_energy]


func _xp_to_next(level: int) -> int:
	return 100 + (level - 1) * 80


func _on_currency_changed(_kind: String, _value: int) -> void:
	refresh()
