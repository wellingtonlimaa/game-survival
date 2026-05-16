extends PanelContainer

signal tab_pressed(tab: String)

const TABS := [
	{ "key": "characters", "label": "Heróis",   "icon": "👥", "locked_until": null },
	{ "key": "talents",    "label": "Talentos", "icon": "🌳", "locked_until": "level_5" },
	{ "key": "fight",      "label": "LUTAR",    "icon": "⭐", "locked_until": null },
	{ "key": "shop",       "label": "Loja",     "icon": "🛒", "locked_until": null },
	{ "key": "premium",    "label": "VIP",      "icon": "💎", "locked_until": "level_10" },
]


func _ready() -> void:
	_build()


func _build() -> void:
	var hbox: HBoxContainer = %TabRow
	for tab in TABS:
		var btn := _make_tab_button(tab)
		hbox.add_child(btn)


func _make_tab_button(tab: Dictionary) -> Control:
	var is_center: bool = (tab["key"] == "fight")
	var locked := _is_locked(tab.get("locked_until"))

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 76 if not is_center else 86)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.disabled = locked
	btn.focus_mode = Control.FOCUS_NONE

	# Conteúdo (ícone + label)
	if is_center:
		btn.text = "⭐\n%s" % tab["label"]
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color(0.137, 0.094, 0.039, 1))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 0.776, 0.298, 1)
		style.border_color = Color(0.435, 0.275, 0.063, 1)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 5
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		style.content_margin_left = 6
		style.content_margin_top = 8
		style.content_margin_right = 6
		style.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
	else:
		var icon: String = "🔒" if locked else String(tab["icon"])
		btn.text = "%s\n%s" % [icon, String(tab["label"])]
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(0.722, 0.694, 0.808, 1) if not locked else Color(0.486, 0.467, 0.557, 1))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.094, 0.078, 0.149, 0.0)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.165, 0.141, 0.235, 1)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", hover)

	btn.pressed.connect(func(): tab_pressed.emit(tab["key"]))
	return btn


func _is_locked(req: Variant) -> bool:
	if req == null:
		return false
	if typeof(req) != TYPE_STRING:
		return false
	if String(req).begins_with("level_"):
		var need := int(String(req).substr(6))
		return int(SaveSystem.get_value("player_level", 1)) < need
	return false
