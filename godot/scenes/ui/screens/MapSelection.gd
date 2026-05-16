extends Control

signal map_chosen(key: String)
signal cancelled

const GAME_WORLD_PATH := "res://scenes/main/GameWorld.tscn"
const MAIN_MENU_PATH := "res://scenes/ui/menu/MainMenu.tscn"

@onready var cards_row: HBoxContainer = %CardsRow

const CARD_MIN_WIDTH := 140
const CARD_MIN_HEIGHT := 270
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
	panel.custom_minimum_size = Vector2(CARD_MIN_WIDTH, CARD_MIN_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.set_meta("map_key", map_data.key)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.094, 0.078, 0.149, 0.961)
	style.border_color = Color(0.275, 0.227, 0.412, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 4
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	# Preview procedural com borda própria
	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(0, 115)
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = map_data.ground_color
	frame_style.border_color = Color(0.435, 0.388, 0.557, 1)
	frame_style.border_width_left = 2
	frame_style.border_width_top = 2
	frame_style.border_width_right = 2
	frame_style.border_width_bottom = 2
	frame_style.corner_radius_top_left = 10
	frame_style.corner_radius_top_right = 10
	frame_style.corner_radius_bottom_left = 10
	frame_style.corner_radius_bottom_right = 10
	preview_frame.add_theme_stylebox_override("panel", frame_style)
	vbox.add_child(preview_frame)

	# Overlay desenhado em cima da cor de fundo
	var preview_overlay := _MapPreview.new()
	preview_overlay.map_data = map_data
	preview_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_frame.add_child(preview_overlay)

	var title := Label.new()
	title.text = map_data.display_name
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", Color(1.0, 0.776, 0.298, 1))
	title.add_theme_color_override("font_outline_color", Color(0.043, 0.035, 0.078, 1))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_font_size_override("font_size", 17)
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = map_data.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.82, 0.80, 0.88, 1))
	desc.add_theme_font_size_override("font_size", 11)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc)

	# Chips de features
	var tags_row := HBoxContainer.new()
	tags_row.add_theme_constant_override("separation", 4)
	tags_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(tags_row)

	if map_data.has_lake:
		tags_row.add_child(_make_chip("🌊", map_data.lake_color))
	if map_data.has_ruin:
		tags_row.add_child(_make_chip("🏛", map_data.ruin_color))
	if map_data.fog_color.a > 0.05:
		tags_row.add_child(_make_chip("🌫", Color(0.722, 0.694, 0.808, 1)))

	var button := Button.new()
	button.text = "Escolher"
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color(0.137, 0.094, 0.039, 1))
	panel.set_meta("button", button)
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
	btn_style.content_margin_bottom = 8
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
		style.shadow_color = Color(1.0, 0.776, 0.298, 0.55) if selected else Color(0, 0, 0, 0.4)
		style.shadow_size = 14 if selected else 6
		var btn: Button = card.get_meta("button") as Button
		if btn != null:
			btn.text = "Escolher"


func _make_chip(text: String, accent: Color) -> Control:
	var holder := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.067, 0.055, 0.118, 0.85)
	s.border_color = accent
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.corner_radius_top_left = 100
	s.corner_radius_top_right = 100
	s.corner_radius_bottom_left = 100
	s.corner_radius_bottom_right = 100
	s.content_margin_left = 6
	s.content_margin_top = 2
	s.content_margin_right = 6
	s.content_margin_bottom = 2
	holder.add_theme_stylebox_override("panel", s)
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.92, 0.90, 0.96, 1))
	lbl.add_theme_font_size_override("font_size", 11)
	holder.add_child(lbl)
	return holder


func _on_play() -> void:
	MapRegistry.select(_selected_key)
	get_tree().change_scene_to_file(GAME_WORLD_PATH)


func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


# Pré-visualização desenhada inline
class _MapPreview extends Control:
	var map_data: Resource

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _draw() -> void:
		if map_data == null:
			return
		# Padrão xadrez do bioma (mais denso e suave)
		var tile := 14
		var cols: int = int(size.x / tile) + 1
		var rows: int = int(size.y / tile) + 1
		var variant: Color = map_data.ground_variant_color
		variant.a = 0.75
		for r in range(rows):
			for c in range(cols):
				if (r + c) % 2 == 0:
					draw_rect(Rect2(c * tile, r * tile, tile, tile), variant)
		# Pontos da paleta de obstáculo (densidade maior, seed estável por mapa)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(map_data.key)
		for i in range(50):
			var x := rng.randf() * size.x
			var y := rng.randf() * size.y
			var radius := rng.randf_range(1.5, 4.0)
			if map_data.obstacle_palette.size() > 0:
				draw_circle(Vector2(x, y), radius, map_data.obstacle_palette[i % map_data.obstacle_palette.size()])
		# Landmarks com contorno
		if map_data.has_lake:
			var lake_center := Vector2(size.x * 0.72, size.y * 0.62)
			var lake_radius: float = min(size.x, size.y) * 0.18
			draw_circle(lake_center, lake_radius, map_data.lake_color)
			var lake_rim: Color = map_data.lake_color.lightened(0.3)
			lake_rim.a = 0.7
			draw_arc(lake_center, lake_radius, 0.0, TAU, 32, lake_rim, 1.5, true)
		if map_data.has_ruin:
			var rw: float = min(size.x, size.y) * 0.22
			var ruin_rect := Rect2(size.x * 0.18, size.y * 0.30, rw, rw)
			draw_rect(ruin_rect, map_data.ruin_color)
			var ruin_rim: Color = map_data.ruin_color.lightened(0.3)
			ruin_rim.a = 0.75
			draw_rect(ruin_rect, ruin_rim, false, 1.5)
		# Vinheta (escurece as 4 bordas)
		var vignette := Color(0, 0, 0, 0.28)
		var v: float = min(size.x, size.y) * 0.10
		draw_rect(Rect2(0, 0, size.x, v), vignette)
		draw_rect(Rect2(0, size.y - v, size.x, v), vignette)
		draw_rect(Rect2(0, 0, v, size.y), vignette)
		draw_rect(Rect2(size.x - v, 0, v, size.y), vignette)
		# Fog overlay (clamped pra não escurecer demais)
		if map_data.fog_color.a > 0.0:
			var fog: Color = map_data.fog_color
			fog.a = min(fog.a, 0.35)
			draw_rect(Rect2(Vector2.ZERO, size), fog)
