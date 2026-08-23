extends Control

## Menu de pausa com resumo da build (armas, passivas, relíquias, sinergias).

const P := preload("res://scripts/utils/Theme.gd")
const UI := preload("res://scripts/utils/UIFactory.gd")

signal resume_pressed
signal back_to_menu_pressed
signal restart_pressed

var _content: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 10)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_content)


func setup(stats: Dictionary, build: Dictionary, loadout: Array) -> void:
	var title := UI.make_label("PAUSADO", 30, P.ACCENT_GOLD, 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(title)

	# Resumo rápido
	var info := UI.make_label("⏱ %s   ☠ %d   🪙 %d   ⭐ Lv %d" % [
		GameManager.format_time(int(stats.get("time", 0))),
		int(stats.get("kills", 0)),
		int(stats.get("coins", 0)),
		int(stats.get("level", 1)),
	], 15, P.TEXT_PRIMARY, 3)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(info)

	# Armas
	if not loadout.is_empty():
		_content.add_child(_section("ARSENAL"))
		var weapons_row := HBoxContainer.new()
		weapons_row.alignment = BoxContainer.ALIGNMENT_CENTER
		weapons_row.add_theme_constant_override("separation", 5)
		for w in loadout:
			var text: String = "%s %s" % [String(w["icon"]), "★" if bool(w["evolved"]) else "Lv%d" % int(w["level"])]
			weapons_row.add_child(UI.make_chip(text, w["color"], 12))
		_content.add_child(weapons_row)

	# Passivas e relíquias
	var passives: Array = build.get("passives", [])
	if not passives.is_empty():
		_content.add_child(_section("PASSIVAS"))
		var prow := HBoxContainer.new()
		prow.alignment = BoxContainer.ALIGNMENT_CENTER
		prow.add_theme_constant_override("separation", 5)
		for p in passives:
			prow.add_child(UI.make_chip("%s %s %d" % [String(p["icon"]), String(p["name"]), int(p["level"])], p["color"], 11))
		_content.add_child(prow)

	var relics: Array = build.get("relics", [])
	if not relics.is_empty():
		_content.add_child(_section("RELÍQUIAS"))
		var rrow := HBoxContainer.new()
		rrow.alignment = BoxContainer.ALIGNMENT_CENTER
		rrow.add_theme_constant_override("separation", 5)
		for r in relics:
			rrow.add_child(UI.make_chip("%s %s" % [String(r["icon"]), String(r["name"])], r["color"], 11))
		_content.add_child(rrow)

	var synergies: Array = build.get("synergies", [])
	if not synergies.is_empty():
		_content.add_child(_section("SINERGIAS"))
		for s in synergies:
			var line := UI.make_label("%s %s" % [String(s["icon"]), String(s["name"])], 13, P.ACCENT_CYAN, 2)
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_content.add_child(line)

	# Áudio
	_content.add_child(_section("ÁUDIO"))
	_content.add_child(_slider("Música", float(SaveSystem.get_value("music_volume", 0.5)), func(v): AudioManager.set_music_volume(v)))
	_content.add_child(_slider("Efeitos", float(SaveSystem.get_value("sfx_volume", 0.8)), func(v): AudioManager.set_sfx_volume(v)))

	var mute := CheckBox.new()
	mute.text = "Mudo"
	mute.button_pressed = bool(SaveSystem.get_value("muted", false))
	mute.add_theme_color_override("font_color", P.TEXT_SECONDARY)
	mute.toggled.connect(func(v): AudioManager.set_muted(v))
	_content.add_child(mute)

	# Botões
	_content.add_child(_spacer(6))
	var resume := UI.make_button("▶  CONTINUAR", P.ACCENT_GREEN, P.TEXT_DARK, 20)
	resume.custom_minimum_size = Vector2(0, 52)
	resume.pressed.connect(func(): resume_pressed.emit())
	_content.add_child(resume)

	var restart := UI.make_button("↻  Recomeçar", P.BG_HIGH, P.TEXT_PRIMARY, 15)
	restart.pressed.connect(func(): restart_pressed.emit())
	_content.add_child(restart)

	var menu := UI.make_button("✖  Sair pro menu", Color(0.45, 0.22, 0.28), P.TEXT_PRIMARY, 15)
	menu.pressed.connect(func(): back_to_menu_pressed.emit())
	_content.add_child(menu)

	var hint := UI.make_label("ESC ou P para voltar ao jogo", 11, P.TEXT_MUTED, 2)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(hint)


func _section(text: String) -> Control:
	var label := UI.make_label(text, 12, P.TEXT_MUTED, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c


func _slider(label: String, value: float, on_change: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var l := UI.make_label(label, 13, P.TEXT_SECONDARY)
	l.custom_minimum_size = Vector2(70, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 24)
	slider.value_changed.connect(on_change)
	row.add_child(slider)
	return row


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		resume_pressed.emit()
