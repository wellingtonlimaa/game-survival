extends PanelContainer

## Navegação inferior. Abas travadas mostram o nível de conta necessário.

const P := preload("res://scripts/utils/Theme.gd")
const UI := preload("res://scripts/utils/UIFactory.gd")

signal tab_pressed(tab: String)

const TABS := [
	{"key": "characters", "label": "Heróis",  "icon": "🧙", "locked_until": 0},
	{"key": "codex",      "label": "Codex",   "icon": "📚", "locked_until": 0},
	{"key": "fight",      "label": "LUTAR",   "icon": "⚔", "locked_until": 0},
	{"key": "shop",       "label": "Loja",    "icon": "🛒", "locked_until": 2},
	{"key": "talents",    "label": "Talentos","icon": "🌳", "locked_until": 5},
]


func _ready() -> void:
	_build()


func _build() -> void:
	var hbox: HBoxContainer = %TabRow
	for child in hbox.get_children():
		child.queue_free()
	for tab in TABS:
		hbox.add_child(_make_tab_button(tab))


func _make_tab_button(tab: Dictionary) -> Control:
	var is_center: bool = tab["key"] == "fight"
	var required_level: int = int(tab.get("locked_until", 0))
	var locked: bool = required_level > 0 and int(SaveSystem.get_value("player_level", 1)) < required_level

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 74 if not is_center else 84)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = locked
	btn.focus_mode = Control.FOCUS_NONE
	if required_level > 0:
		btn.tooltip_text = "Libera no nível de conta %d" % required_level

	if is_center:
		btn.text = "%s\n%s" % [String(tab["icon"]), String(tab["label"])]
		UI.style_button(btn, P.ACCENT_GOLD, P.TEXT_DARK, 16, 20)
	else:
		var top_line: String = String(tab["icon"])
		if locked:
			top_line = "🔒 Lv%d" % required_level
		btn.text = "%s\n%s" % [top_line, String(tab["label"])]
		UI.style_button(btn, Color(0.094, 0.078, 0.149, 0.0), P.TEXT_SECONDARY if not locked else P.TEXT_MUTED, 12, 13)
		var hover := StyleBoxFlat.new()
		hover.bg_color = P.BG_HIGH
		hover.corner_radius_top_left = 12
		hover.corner_radius_top_right = 12
		hover.corner_radius_bottom_left = 12
		hover.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("hover", hover)

	btn.pressed.connect(func(): tab_pressed.emit(String(tab["key"])))
	return btn
