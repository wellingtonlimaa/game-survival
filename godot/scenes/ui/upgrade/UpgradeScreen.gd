extends Control

## Tela de escolha de upgrade (level-up e baú).
## Cartas em lista vertical (formato retrato), com raridade, teclas 1-4,
## re-roll e banimento.

const P := preload("res://scripts/utils/Theme.gd")
const UI := preload("res://scripts/utils/UIFactory.gd")
const RarityScript := preload("res://scripts/utils/Rarity.gd")

signal choice_made(choice: Dictionary)
signal reroll_pressed
signal banish_pressed(choice: Dictionary)

var _cards_box: VBoxContainer
var _title: Label
var _subtitle: Label
var _status: Label
var _reroll_button: Button
var _choices: Array = []
var _banish_mode: bool = false
var _banish_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.88)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	margin.add_child(root)

	_title = UI.make_label("VOCÊ EVOLUIU!", 28, P.ACCENT_GOLD, 5)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title)

	_subtitle = UI.make_label("Escolha uma melhoria", 13, P.TEXT_SECONDARY, 3)
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_subtitle)

	_cards_box = VBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 10)
	_cards_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(_cards_box)

	_status = UI.make_label("", 12, P.TEXT_MUTED, 2)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	root.add_child(buttons)

	_reroll_button = UI.make_button("🎲 Re-roll", P.ACCENT_CYAN, P.TEXT_DARK, 15)
	_reroll_button.pressed.connect(func(): reroll_pressed.emit())
	buttons.add_child(_reroll_button)

	_banish_button = UI.make_button("🚫 Banir", Color(0.45, 0.25, 0.32), P.TEXT_PRIMARY, 15)
	_banish_button.pressed.connect(_toggle_banish_mode)
	buttons.add_child(_banish_button)


func setup(choices: Array, rerolls_left: int, banishes_left: int, is_chest: bool = false, level: int = 1) -> void:
	_choices = choices
	_banish_mode = false
	_title.text = "BAÚ ANCESTRAL" if is_chest else "NÍVEL %d!" % level
	_title.add_theme_color_override("font_color", P.ACCENT_GOLD if is_chest else P.ACCENT_PURPLE)
	_subtitle.text = "Escolha sua recompensa" if is_chest else "Escolha uma melhoria"

	for child in _cards_box.get_children():
		child.queue_free()

	var index: int = 0
	for choice in choices:
		var card := _make_card(choice, index)
		_cards_box.add_child(card)
		card.modulate.a = 0.0
		card.position.x = 40.0
		var tween := create_tween()
		tween.tween_interval(0.05 * index)
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.18)
		tween.tween_property(card, "position:x", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		index += 1

	_status.text = "Re-rolls: %d   ·   Banimentos: %d   ·   teclas 1-%d" % [rerolls_left, banishes_left, choices.size()]
	_reroll_button.disabled = rerolls_left <= 0
	_banish_button.disabled = banishes_left <= 0
	_banish_button.text = "🚫 Banir"


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key := event as InputEventKey
	var index: int = -1
	match key.keycode:
		KEY_1, KEY_KP_1: index = 0
		KEY_2, KEY_KP_2: index = 1
		KEY_3, KEY_KP_3: index = 2
		KEY_4, KEY_KP_4: index = 3
		KEY_R:
			if not _reroll_button.disabled:
				reroll_pressed.emit()
			return
	if index >= 0 and index < _choices.size():
		get_viewport().set_input_as_handled()
		_pick(_choices[index])


func _toggle_banish_mode() -> void:
	_banish_mode = not _banish_mode
	_banish_button.text = "✖ Cancelar" if _banish_mode else "🚫 Banir"
	_subtitle.text = "Toque numa carta pra bani-la da run" if _banish_mode else "Escolha uma melhoria"
	EventBus.sfx("click", 0.5)


func _pick(choice: Dictionary) -> void:
	if _banish_mode:
		_banish_mode = false
		banish_pressed.emit(choice)
		return
	choice_made.emit(choice)


func _make_card(choice: Dictionary, index: int) -> Control:
	var rarity: String = String(choice.get("rarity", "comum"))
	var rarity_color: Color = RarityScript.color(rarity)
	var accent: Color = choice.get("color", rarity_color)
	var is_evolution: bool = String(choice.get("kind", "")) == "weapon_evolve"

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 92)
	button.focus_mode = Control.FOCUS_NONE
	var style := UI.panel_style(P.BG_MID, rarity_color, 14, 3 if rarity != "comum" else 2, 10)
	if is_evolution:
		style.bg_color = Color(0.20, 0.15, 0.06, 0.96)
		style.shadow_color = Color(1.0, 0.776, 0.298, 0.55)
		style.shadow_size = 14
	elif rarity == "lendario" or rarity == "epico":
		style.shadow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.45)
		style.shadow_size = 10
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.10)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func(): _pick(choice))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_theme_constant_override("margin_left", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)

	# Ícone
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(58, 58)
	icon_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_panel.add_theme_stylebox_override("panel", UI.panel_style(accent.lerp(P.BG_DEEP, 0.55), accent, 12, 2, 4))
	icon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon_panel)

	var icon_label := UI.make_label(String(choice.get("icon", "✦")), 28, P.TEXT_PRIMARY)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_panel.add_child(icon_label)

	# Texto
	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override("separation", 2)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.add_child(head)

	var num := UI.make_label("%d" % (index + 1), 12, P.TEXT_MUTED)
	head.add_child(num)

	var title := UI.make_label(String(choice.get("title", "?")), 17, P.TEXT_PRIMARY, 3)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)

	var chip := UI.make_chip(RarityScript.label(rarity).to_upper(), rarity_color, 10)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(chip)

	var desc := UI.make_label(String(choice.get("description", "")), 12, P.TEXT_SECONDARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 32)
	texts.add_child(desc)

	if is_evolution:
		var evo_chip := UI.make_chip("EVOLUÇÃO", P.ACCENT_GOLD, 10)
		texts.add_child(evo_chip)

	return button
