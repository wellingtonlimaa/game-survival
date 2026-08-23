extends "res://scenes/ui/screens/ScreenBase.gd"

## Ajustes: áudio, dificuldade, duração da partida, controles e save.

var _diff_row: HBoxContainer
var _goal_row: HBoxContainer


func _init() -> void:
	screen_title = "Ajustes"
	screen_icon = "⚙"


func _build_content() -> void:
	content.add_child(section("ÁUDIO"))
	content.add_child(_slider("🎵 Música", float(SaveSystem.get_value("music_volume", 0.5)), func(v): AudioManager.set_music_volume(v)))
	content.add_child(_slider("🔊 Efeitos", float(SaveSystem.get_value("sfx_volume", 0.8)), func(v): AudioManager.set_sfx_volume(v)))

	var mute := CheckBox.new()
	mute.text = "Mudo"
	mute.button_pressed = bool(SaveSystem.get_value("muted", false))
	mute.add_theme_color_override("font_color", P.TEXT_SECONDARY)
	mute.add_theme_font_size_override("font_size", 14)
	mute.toggled.connect(func(v): AudioManager.set_muted(v))
	content.add_child(mute)

	content.add_child(section("VÍDEO"))
	var fs_row := HBoxContainer.new()
	fs_row.add_theme_constant_override("separation", 8)
	content.add_child(fs_row)
	var fs_btn := UI.make_button("", P.ACCENT_CYAN, P.TEXT_DARK, 15)
	fs_btn.custom_minimum_size = Vector2(0, 46)
	fs_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var refresh_fs := func():
		fs_btn.text = "🖵  Tela cheia: LIGADA" if GameManager.is_fullscreen() else "🗖  Tela cheia: DESLIGADA"
	refresh_fs.call()
	fs_btn.pressed.connect(func():
		GameManager.toggle_fullscreen()
		EventBus.sfx("click", 0.6)
		refresh_fs.call())
	fs_row.add_child(fs_btn)
	var fs_hint := UI.make_label("Atalho: F11 em qualquer tela", 11, P.TEXT_MUTED)
	fs_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(fs_hint)

	content.add_child(section("DIFICULDADE"))
	_diff_row = HBoxContainer.new()
	_diff_row.add_theme_constant_override("separation", 6)
	content.add_child(_diff_row)
	_refresh_difficulty()

	content.add_child(section("DURAÇÃO DA PARTIDA"))
	_goal_row = HBoxContainer.new()
	_goal_row.add_theme_constant_override("separation", 6)
	content.add_child(_goal_row)
	_refresh_goal()

	content.add_child(section("CONTROLES"))
	var controls := PanelContainer.new()
	controls.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.BORDER, 12, 2, 12))
	var cbox := VBoxContainer.new()
	cbox.add_theme_constant_override("separation", 3)
	controls.add_child(cbox)
	for line in [
		"WASD / setas / analógico — mover",
		"Mouse — mirar (parado, a mira trava sozinha no inimigo)",
		"ESPAÇO / botão direito — dash com invulnerabilidade",
		"ESC ou P — pausar · F11 — tela cheia",
		"1-4 — escolher carta de upgrade · R — re-roll",
	]:
		cbox.add_child(UI.make_label("• %s" % line, 12, P.TEXT_SECONDARY))
	content.add_child(controls)

	content.add_child(section("PERIGO"))
	var wipe := UI.make_button("🗑  Apagar progresso deste slot", Color(0.45, 0.20, 0.26), P.TEXT_PRIMARY, 14)
	wipe.pressed.connect(_confirm_wipe)
	content.add_child(wipe)


func _slider(label: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := UI.make_label(label, 14, P.TEXT_SECONDARY)
	l.custom_minimum_size = Vector2(96, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(0, 26)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row


func _refresh_difficulty() -> void:
	for child in _diff_row.get_children():
		child.queue_free()
	var current: String = String(SaveSystem.get_value("difficulty", "normal"))
	for key in GameManager.DIFFICULTIES.keys():
		var info: Dictionary = GameManager.DIFFICULTIES[key]
		var unlocked: bool = GameManager.difficulty_unlocked(key)
		var selected: bool = key == current
		var text: String = "%s\n%s" % [String(info["icon"]), String(info["label"])]
		if not unlocked:
			text = "🔒\nLv %d" % int(info.get("unlock_level", 1))
		var btn := UI.make_button(text, P.ACCENT_GOLD if selected else P.BG_HIGH,
			P.TEXT_DARK if selected else P.TEXT_SECONDARY, 13)
		btn.custom_minimum_size = Vector2(0, 56)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.disabled = not unlocked
		if unlocked:
			btn.pressed.connect(func():
				GameManager.set_difficulty(key)
				EventBus.sfx("click", 0.6)
				_refresh_difficulty())
		_diff_row.add_child(btn)


func _refresh_goal() -> void:
	for child in _goal_row.get_children():
		child.queue_free()
	var current: int = int(SaveSystem.get_value("goal_seconds", 600))
	for goal in GameManager.GOALS:
		var selected: bool = int(goal["seconds"]) == current
		var btn := UI.make_button("%s\n%s" % [String(goal["label"]), String(goal["note"])],
			P.ACCENT_CYAN if selected else P.BG_HIGH,
			P.TEXT_DARK if selected else P.TEXT_SECONDARY, 13)
		btn.custom_minimum_size = Vector2(0, 52)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func():
			GameManager.set_goal(int(goal["seconds"]))
			EventBus.sfx("click", 0.6)
			_refresh_goal())
		_goal_row.add_child(btn)


func _confirm_wipe() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = "Isso apaga moedas, níveis, desbloqueios e recordes deste slot. Tem certeza?"
	dialog.title = "Apagar progresso"
	dialog.confirmed.connect(func():
		SaveSystem.data = SaveSystem.default_data()
		SaveSystem.save_now()
		EventBus.sfx("deny", 0.8)
		get_tree().change_scene_to_file(MAIN_MENU_PATH))
	add_child(dialog)
	dialog.popup_centered()
