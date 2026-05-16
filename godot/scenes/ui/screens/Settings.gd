extends Control

signal back_pressed


func _ready() -> void:
	%BackButton.pressed.connect(_back)
	%MusicSlider.value = float(SaveSystem.get_value("music_volume", 0.5))
	%SfxSlider.value = float(SaveSystem.get_value("sfx_volume", 0.8))
	%MuteCheckbox.button_pressed = bool(SaveSystem.get_value("muted", false))
	%MusicSlider.value_changed.connect(_on_music_changed)
	%SfxSlider.value_changed.connect(_on_sfx_changed)
	%MuteCheckbox.toggled.connect(_on_mute_toggled)

	for diff in ["easy", "normal", "hard", "infernal"]:
		var btn := %DifficultyOption.get_node_or_null(diff.capitalize() + "Btn")
		if btn != null:
			btn.pressed.connect(_make_diff_callback(diff))
	_refresh_diff_buttons()

	%PrestigeButton.pressed.connect(_on_prestige)
	_refresh_prestige_info()


func _make_diff_callback(diff: String) -> Callable:
	return func():
		SaveSystem.set_value("difficulty", diff)
		GameManager.selected_difficulty = diff
		_refresh_diff_buttons()


func _refresh_diff_buttons() -> void:
	var current: String = String(SaveSystem.get_value("difficulty", "normal"))
	for diff in ["easy", "normal", "hard", "infernal"]:
		var btn: Button = %DifficultyOption.get_node_or_null(diff.capitalize() + "Btn")
		if btn == null:
			continue
		var is_selected: bool = (diff == current)
		btn.modulate = Color(1, 1, 1, 1) if is_selected else Color(0.62, 0.62, 0.72, 1)


func _on_music_changed(v: float) -> void:
	AudioManager.set_music_volume(v)


func _on_sfx_changed(v: float) -> void:
	AudioManager.set_sfx_volume(v)


func _on_mute_toggled(p: bool) -> void:
	AudioManager.set_muted(p)


func _refresh_prestige_info() -> void:
	var prestige: int = int(SaveSystem.get_value("prestige", 0))
	var points: int = int(SaveSystem.get_value("prestige_points", 0))
	var best: int = int(SaveSystem.get_value("best_time", 0))
	var total_kills: int = int(SaveSystem.get_value("total_kills", 0))
	%PrestigeInfo.text = "Prestige: %d   ·   Pontos: %d\nRecorde: %ds   ·   KOs totais: %d" % [prestige, points, best, total_kills]
	%PrestigeButton.disabled = not ProgressionManager.can_prestige()
	if %PrestigeButton.disabled:
		%PrestigeButton.text = "Requer 10min OU 1000 KOs"
	else:
		%PrestigeButton.text = "FAZER PRESTÍGIO"


func _on_prestige() -> void:
	if ProgressionManager.do_prestige():
		_refresh_prestige_info()


func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menu/MainMenu.tscn")
