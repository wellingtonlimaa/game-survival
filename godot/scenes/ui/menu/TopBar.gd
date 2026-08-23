extends PanelContainer

## Barra superior: nome, nível de conta, XP, moedas, gemas e energia
## (com contagem regressiva pra próxima recarga).

@onready var player_name_label: Label = %PlayerName
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var coins_label: Label = %CoinsLabel
@onready var gems_label: Label = %GemsLabel
@onready var energy_label: Label = %EnergyLabel

var _tick: float = 0.0


func _ready() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	refresh()


func _process(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = 1.0
		_refresh_energy()


func refresh() -> void:
	player_name_label.text = str(SaveSystem.get_value("player_name", "Sobrevivente"))
	var lvl := int(SaveSystem.get_value("player_level", 1))
	level_label.text = str(lvl)
	xp_bar.max_value = float(ProgressionManager.meta_xp_to_next(lvl))
	xp_bar.value = float(SaveSystem.get_value("player_xp", 0))
	coins_label.text = str(int(SaveSystem.get_value("coins", 0)))
	gems_label.text = str(int(SaveSystem.get_value("gems", 0)))
	_refresh_energy()


func _refresh_energy() -> void:
	var energy := SaveSystem.energy()
	var max_energy := int(SaveSystem.get_value("max_energy", 60))
	if energy >= max_energy:
		energy_label.text = "%d/%d" % [energy, max_energy]
	else:
		var s := SaveSystem.seconds_to_next_energy()
		energy_label.text = "%d/%d (%ds)" % [energy, max_energy, s]


func _on_currency_changed(_kind: String, _value: int) -> void:
	refresh()
