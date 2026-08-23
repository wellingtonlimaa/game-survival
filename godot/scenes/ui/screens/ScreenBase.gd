class_name ScreenBase
extends Control

## Casca comum das telas de menu: fundo animado, cabeçalho com título,
## botão de voltar e área rolável de conteúdo.

const P := preload("res://scripts/utils/Theme.gd")
const UI := preload("res://scripts/utils/UIFactory.gd")
const MENU_BACKGROUND := preload("res://scenes/ui/menu/MenuBackground.tscn")
const MAIN_MENU_PATH := "res://scenes/ui/menu/MainMenu.tscn"

signal back_pressed

@export var screen_title: String = "Tela"
@export var screen_icon: String = "✦"

var content: VBoxContainer
var header_extra: HBoxContainer
var title_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_shell()
	_build_content()


func _build_shell() -> void:
	var bg := MENU_BACKGROUND.instantiate()
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# Cabeçalho
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	var back := UI.make_button("←", P.BG_HIGH, P.TEXT_PRIMARY, 20)
	back.custom_minimum_size = Vector2(50, 44)
	back.pressed.connect(_on_back)
	header.add_child(back)

	title_label = UI.make_label("%s  %s" % [screen_icon, screen_title.to_upper()], 22, P.ACCENT_GOLD, 4)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)

	header_extra = HBoxContainer.new()
	header_extra.add_theme_constant_override("separation", 6)
	header_extra.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(header_extra)

	# Conteúdo
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)


## Sobrescrito por cada tela
func _build_content() -> void:
	pass


func _on_back() -> void:
	EventBus.sfx("click", 0.5)
	back_pressed.emit()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back()


# --- Helpers de layout -------------------------------------------------------

func section(text: String, color: Color = P.TEXT_MUTED) -> Control:
	var label := UI.make_label(text, 13, color, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func info_row(icon: String, label: String, value: String, color: Color = P.TEXT_PRIMARY) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.BORDER, 12, 2, 10))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	row.add_child(UI.make_label(icon, 20, color))
	var name_label := UI.make_label(label, 15, P.TEXT_SECONDARY)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	row.add_child(UI.make_label(value, 17, color, 2))
	return panel
