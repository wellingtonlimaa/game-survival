extends Control

signal back_to_menu_requested

@onready var minimap: Control = %Minimap
@onready var weapon_bar: PanelContainer = %WeaponBar
@onready var timer_label: Label = %TimerLabel
@onready var map_label: Label = %MapLabel
@onready var back_button: Button = %BackButton
@onready var hp_bar: ProgressBar = %HpBar
@onready var hp_label: Label = %HpLabel
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel

var time_alive: float = 0.0
var _player: Node2D = null
var _banner_timer: float = 0.0


func _ready() -> void:
	back_button.pressed.connect(func(): back_to_menu_requested.emit())
	EventBus.narrative_triggered.connect(_show_banner)
	%BannerLabel.modulate.a = 0.0


func setup(map_data: Resource, world: Dictionary, player: Node2D) -> void:
	map_label.text = map_data.display_name
	minimap.setup(map_data, world, player)
	_setup_modifier_label()
	_player = player
	if player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
	if player.has_signal("xp_changed"):
		player.xp_changed.connect(_on_xp_changed)
	_on_hp_changed(player.hp, player.max_hp)
	_on_xp_changed(player.xp, player.xp_to_next, player.level)


func _process(delta: float) -> void:
	if GameManager.state != GameManager.GameState.PLAYING:
		return
	time_alive += delta
	var minutes := int(time_alive) / 60
	var seconds := int(time_alive) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

	if _banner_timer > 0.0:
		_banner_timer = max(0.0, _banner_timer - delta)
		var banner: Label = %BannerLabel
		if _banner_timer > 2.0:
			banner.modulate.a = min(1.0, banner.modulate.a + delta * 5.0)
		else:
			banner.modulate.a = max(0.0, banner.modulate.a - delta * 1.2)


func _show_banner(text: String) -> void:
	var banner: Label = %BannerLabel
	banner.text = text
	_banner_timer = 2.8


func bind_weapons_to_bar(weapon_system: Node) -> void:
	if weapon_bar != null and weapon_bar.has_method("bind_weapons"):
		weapon_bar.bind_weapons(weapon_system)


func _setup_modifier_label() -> void:
	var game_world = get_tree().current_scene
	if game_world == null:
		return
	if not "modifier_key" in game_world:
		return
	var key: String = String(game_world.modifier_key)
	if key == "" or key == "calm":
		map_label.text = map_label.text
		return
	var info: Dictionary = game_world.modifier_info
	map_label.text = "%s · %s" % [map_label.text, String(info.get("label", ""))]


func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d / %d" % [int(round(current)), int(round(maximum))]


func _on_xp_changed(current: float, to_next: float, level: int) -> void:
	xp_bar.max_value = to_next
	xp_bar.value = current
	level_label.text = "Lv %d" % level
