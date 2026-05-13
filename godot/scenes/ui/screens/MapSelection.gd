extends Control

signal map_chosen(key: String)
signal cancelled

const GAME_WORLD_PATH := "res://scenes/main/GameWorld.tscn"
const MAIN_MENU_PATH := "res://scenes/ui/menu/MainMenu.tscn"

@onready var cards_row: HBoxContainer = %CardsRow
@onready var play_button: Button = %PlayButton
@onready var back_button: Button = %BackButton

var _selected_key: String = MapRegistry.DEFAULT_KEY
var _cards: Array[Control] = []


func _ready() -> void:
	_selected_key = MapRegistry.selected_key
	_build_cards()
	play_button.pressed.connect(_on_play)
	back_button.pressed.connect(_on_back)


func _build_cards() -> void:
	for child in cards_row.get_children():
		child.queue_free()
	_cards.clear()
	for key in MapRegistry.all_keys():
		var data: Resource = MapRegistry.get_map(key)
		var card := _make_card(data)
		cards_row.add_child(card)
		_cards.append(card)
	_refresh_selection()


func _make_card(map_data: Resource) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 320)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("map_key", map_data.key)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.961)
	style.border_color = Color(0.275, 0.227, 0.412, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 12
	style.content_margin_top = 12
	style.content_margin_right = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Preview procedural (TextureRect com cor de bioma)
	var preview := ColorRect.new()
	preview.color = map_data.ground_color
	preview.custom_minimum_size = Vector2(0, 150)
	vbox.add_child(preview)

	# Detail color overlay (dots)
	var preview_overlay := _MapPreview.new()
	preview_overlay.map_data = map_data
	preview_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(preview_overlay)

	var title := Label.new()
	title.text = map_data.display_name
	title.add_theme_color_override("font_color", Color(1.0, 0.776, 0.298, 1))
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = map_data.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.722, 0.694, 0.808, 1))
	desc.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc)

	var button := Button.new()
	button.text = "Escolher"
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.137, 0.094, 0.039, 1))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(1, 0.776, 0.298, 1)
	btn_style.border_color = Color(0.435, 0.275, 0.063, 1)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 4
	btn_style.corner_radius_top_left = 10
	btn_style.corner_radius_top_right = 10
	btn_style.corner_radius_bottom_left = 10
	btn_style.corner_radius_bottom_right = 10
	btn_style.content_margin_left = 10
	btn_style.content_margin_top = 6
	btn_style.content_margin_right = 10
	btn_style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", btn_style)
	button.add_theme_stylebox_override("hover", btn_style)
	button.add_theme_stylebox_override("pressed", btn_style)
	button.pressed.connect(func(): _select(map_data.key))
	vbox.add_child(button)

	return panel


func _select(key: String) -> void:
	_selected_key = key
	_refresh_selection()


func _refresh_selection() -> void:
	for card in _cards:
		var key: String = String(card.get_meta("map_key"))
		var style: StyleBoxFlat = card.get_theme_stylebox("panel") as StyleBoxFlat
		if style == null:
			continue
		var selected := key == _selected_key
		style.border_color = Color(1.0, 0.776, 0.298, 1) if selected else Color(0.275, 0.227, 0.412, 1)
		style.border_width_left = 4 if selected else 2
		style.border_width_top = 4 if selected else 2
		style.border_width_right = 4 if selected else 2
		style.border_width_bottom = 6 if selected else 4


func _on_play() -> void:
	MapRegistry.select(_selected_key)
	get_tree().change_scene_to_file(GAME_WORLD_PATH)


func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


# Pré-visualização desenhada inline
class _MapPreview extends Control:
	var map_data: Resource

	func _draw() -> void:
		if map_data == null:
			return
		# Padrão xadrez do bioma
		var tile := 18
		var cols: int = int(size.x / tile) + 1
		var rows: int = int(size.y / tile) + 1
		for r in range(rows):
			for c in range(cols):
				if (r + c) % 3 == 0:
					draw_rect(Rect2(c * tile, r * tile, tile, tile), map_data.ground_variant_color)
		# Pontos da paleta de obstáculo
		for i in range(20):
			var x := float(i * 31 % int(size.x))
			var y := float((i * 47) % int(size.y))
			if map_data.obstacle_palette.size() > 0:
				draw_circle(Vector2(x, y), 3.0, map_data.obstacle_palette[i % map_data.obstacle_palette.size()])
		# Símbolo de landmark
		if map_data.has_lake:
			draw_circle(Vector2(size.x * 0.75, size.y * 0.6), 14.0, map_data.lake_color)
		if map_data.has_ruin:
			draw_rect(Rect2(size.x * 0.2, size.y * 0.4, 24, 24), map_data.ruin_color)
		# Fog overlay
		if map_data.fog_color.a > 0.0:
			draw_rect(Rect2(Vector2.ZERO, size), map_data.fog_color)
