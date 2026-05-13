extends PanelContainer

signal selected(choice: Dictionary)
signal banish_requested(choice: Dictionary)

const RarityScript := preload("res://scripts/utils/Rarity.gd")

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var rarity_label: Label = %RarityLabel
@onready var pick_button: Button = %PickButton
@onready var banish_button: Button = %BanishButton
@onready var icon_rect: ColorRect = %IconRect

var choice: Dictionary
var _base_style: StyleBoxFlat


func _ready() -> void:
	pick_button.pressed.connect(_on_pick)
	banish_button.pressed.connect(_on_banish)


func setup(p_choice: Dictionary) -> void:
	choice = p_choice
	title_label.text = String(choice.get("title", "?"))
	description_label.text = String(choice.get("description", ""))
	var rarity_key: String = String(choice.get("rarity", "comum"))
	rarity_label.text = RarityScript.label(rarity_key)
	rarity_label.add_theme_color_override("font_color", RarityScript.color(rarity_key))

	var icon_color: Color = choice.get("color", Color.WHITE)
	icon_rect.color = icon_color

	# Borda do painel pela raridade
	var style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style = style.duplicate() as StyleBoxFlat
		style.border_color = RarityScript.color(rarity_key)
		add_theme_stylebox_override("panel", style)


func _on_pick() -> void:
	selected.emit(choice)


func _on_banish() -> void:
	banish_requested.emit(choice)


func set_banish_visible(visible_: bool) -> void:
	banish_button.visible = visible_
