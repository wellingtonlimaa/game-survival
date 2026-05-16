extends PanelContainer

signal selected(choice: Dictionary)
signal banish_requested(choice: Dictionary)

const RarityScript := preload("res://scripts/utils/Rarity.gd")

const KIND_LABELS := {
	"weapon_new":    "ARMA NOVA",
	"weapon_level":  "MELHORIA",
	"weapon_evolve": "EVOLUÇÃO",
	"passive":       "PASSIVA",
	"relic":         "RELÍQUIA",
}

const KIND_FALLBACK_ICONS := {
	"weapon_new":    "⚔",
	"weapon_level":  "⚔",
	"weapon_evolve": "⭐",
	"passive":       "🔮",
	"relic":         "💎",
}

const KEY_ICONS := {
	# weapons
	"wand":          "🪄",
	"knife":         "🔪",
	"orbit":         "💫",
	"spear":         "🗡",
	"boomerang":     "🪃",
	"shotgun":       "🔫",
	"fire_staff":    "🔥",
	"arrow_storm":   "🏹",
	"holy_shield":   "🛡",
	"comet":         "☄",
	"fury":          "🌪",
	# passives
	"move":          "👟",
	"regen":         "❤",
	"magnet":        "🧲",
	"armor":         "🛡",
	"luck":          "🍀",
	"cooldown":      "⚡",
	# relics
	"blood_crown":   "👑",
	"moon_shard":    "🌙",
	"phoenix_ember": "🔥",
	"storm_ring":    "⚡",
	"giant_belt":    "💪",
}

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var rarity_label: Label = %RarityLabel
@onready var rarity_chip: PanelContainer = %RarityChip
@onready var kind_label: Label = %KindLabel
@onready var pick_button: Button = %PickButton
@onready var banish_button: Button = %BanishButton
@onready var icon_panel: PanelContainer = %IconPanel
@onready var icon_label: Label = %IconLabel

var choice: Dictionary


func _ready() -> void:
	pick_button.pressed.connect(_on_pick)
	banish_button.pressed.connect(_on_banish)


func setup(p_choice: Dictionary) -> void:
	choice = p_choice
	title_label.text = String(choice.get("title", "?"))
	description_label.text = String(choice.get("description", ""))

	var rarity_key: String = String(choice.get("rarity", "comum"))
	var rarity_color: Color = RarityScript.color(rarity_key)
	rarity_label.text = String(RarityScript.label(rarity_key)).to_upper()
	rarity_label.add_theme_color_override("font_color", rarity_color)

	var kind: String = String(choice.get("kind", ""))
	kind_label.text = KIND_LABELS.get(kind, "")

	icon_label.text = _resolve_icon(kind, String(choice.get("key", "")))

	var icon_color: Color = choice.get("color", rarity_color)
	_style_icon_panel(icon_color, rarity_color)
	_style_card_panel(rarity_color)
	_style_rarity_chip(rarity_color)


func _resolve_icon(kind: String, key: String) -> String:
	if KEY_ICONS.has(key):
		return KEY_ICONS[key]
	return KIND_FALLBACK_ICONS.get(kind, "✦")


func _style_icon_panel(icon_color: Color, rarity_color: Color) -> void:
	var style: StyleBoxFlat = icon_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style = style.duplicate() as StyleBoxFlat
	style.bg_color = icon_color.lerp(Color(0.1, 0.08, 0.16, 1.0), 0.55)
	style.border_color = rarity_color
	icon_panel.add_theme_stylebox_override("panel", style)


func _style_card_panel(rarity_color: Color) -> void:
	var style: StyleBoxFlat = get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style = style.duplicate() as StyleBoxFlat
	style.border_color = rarity_color
	add_theme_stylebox_override("panel", style)


func _style_rarity_chip(rarity_color: Color) -> void:
	var style: StyleBoxFlat = rarity_chip.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	style = style.duplicate() as StyleBoxFlat
	style.border_color = rarity_color
	style.bg_color = rarity_color.darkened(0.7)
	style.bg_color.a = 0.85
	rarity_chip.add_theme_stylebox_override("panel", style)


func _on_pick() -> void:
	selected.emit(choice)


func _on_banish() -> void:
	banish_requested.emit(choice)


func set_banish_visible(visible_: bool) -> void:
	banish_button.visible = visible_
