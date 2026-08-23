extends "res://scenes/ui/screens/ScreenBase.gd"

## Antessala da partida: escolhe o mapa e confere herói, dificuldade e duração.

const GAME_WORLD_PATH := "res://scenes/main/GameWorld.tscn"
const RegistryScript := preload("res://scripts/systems/WeaponRegistry.gd")
const ENERGY_COST := 5

var _selected_key: String = "forest"
var _cards: Array = []
var _cards_box: VBoxContainer
var _summary_box: HBoxContainer
var _play_button: Button
var _energy_note: Label
var _weapons_row: HFlowContainer
var _weapon_info: Label


func _init() -> void:
	screen_title = "Escolha o campo"
	screen_icon = "🗺"


func _build_content() -> void:
	_selected_key = MapRegistry.selected_key

	_cards_box = VBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 8)
	content.add_child(_cards_box)

	content.add_child(section("ARMA INICIAL"))
	_weapons_row = HFlowContainer.new()
	_weapons_row.add_theme_constant_override("h_separation", 6)
	_weapons_row.add_theme_constant_override("v_separation", 6)
	content.add_child(_weapons_row)
	_weapon_info = UI.make_label("", 11, P.TEXT_SECONDARY)
	_weapon_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_weapon_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_weapon_info)

	content.add_child(section("SUA PREPARAÇÃO"))
	_summary_box = HBoxContainer.new()
	_summary_box.add_theme_constant_override("separation", 6)
	_summary_box.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_child(_summary_box)

	_energy_note = UI.make_label("", 11, P.TEXT_MUTED)
	_energy_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_energy_note)

	_play_button = UI.make_button("⚔  COMEÇAR A NOITE", P.ACCENT_GOLD, P.TEXT_DARK, 22)
	_play_button.custom_minimum_size = Vector2(0, 62)
	_play_button.pressed.connect(_on_play)
	content.add_child(_play_button)

	_build_cards()
	_build_weapons()
	_refresh_summary()


func _build_cards() -> void:
	for child in _cards_box.get_children():
		child.queue_free()
	_cards.clear()
	for key in MapRegistry.all_keys():
		var data: Resource = MapRegistry.get_map(key)
		var card := _make_card(data)
		_cards_box.add_child(card)
		_cards.append(card)


func _make_card(map_data: Resource) -> Control:
	var selected: bool = map_data.key == _selected_key

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 118)
	button.focus_mode = Control.FOCUS_NONE
	var style := UI.panel_style(P.BG_MID, P.ACCENT_GOLD if selected else P.BORDER, 14, 4 if selected else 2, 8)
	if selected:
		style.shadow_color = Color(1.0, 0.776, 0.298, 0.45)
		style.shadow_size = 12
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(func():
		_selected_key = map_data.key
		EventBus.sfx("click", 0.5)
		_build_cards())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(row)

	var preview := _MapPreview.new()
	preview.map_data = map_data
	preview.custom_minimum_size = Vector2(112, 96)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(preview)

	var texts := VBoxContainer.new()
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.add_theme_constant_override("separation", 3)
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(texts)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 6)
	texts.add_child(title_row)
	title_row.add_child(UI.make_label(map_data.display_name, 18, P.ACCENT_GOLD, 3))
	if selected:
		title_row.add_child(UI.make_chip("ESCOLHIDO", P.ACCENT_GREEN, 10))

	var desc := UI.make_label(map_data.description, 11, P.TEXT_SECONDARY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(desc)

	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 4)
	texts.add_child(tags)
	if map_data.has_lake:
		tags.add_child(UI.make_chip("🌊 lago", map_data.lake_color.lightened(0.3), 10))
	if map_data.has_ruin:
		tags.add_child(UI.make_chip("🏛 ruínas", map_data.ruin_color.lightened(0.3), 10))
	if map_data.fog_color.a > 0.05:
		tags.add_child(UI.make_chip("🌫 névoa", P.TEXT_SECONDARY, 10))
	tags.add_child(UI.make_chip("🔮 %d altares" % map_data.altar_count, P.ACCENT_PURPLE, 10))

	return button


## Escolha da arma inicial: todas as liberadas aparecem aqui
func _build_weapons() -> void:
	for child in _weapons_row.get_children():
		child.queue_free()
	var current: String = GameManager.starting_weapon()
	for key in RegistryScript.unlocked_keys():
		var data: Resource = RegistryScript.get_data(key)
		if data == null:
			continue
		var selected: bool = key == current
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(54, 54)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = data.icon
		btn.add_theme_font_size_override("font_size", 24)
		var style := UI.panel_style(
			data.icon_color.lerp(P.BG_DEEP, 0.55 if selected else 0.78),
			data.icon_color if selected else P.BORDER, 12, 3 if selected else 2, 4)
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.tooltip_text = "%s — %s" % [data.display_name, data.description]
		btn.pressed.connect(func():
			GameManager.set_starting_weapon(key)
			EventBus.sfx("click", 0.5)
			_build_weapons())
		_weapons_row.add_child(btn)
	var chosen: Resource = RegistryScript.get_data(current)
	if chosen != null:
		_weapon_info.text = "%s %s — %s" % [chosen.icon, chosen.display_name, chosen.description]
		_weapon_info.add_theme_color_override("font_color", chosen.icon_color)


func _refresh_summary() -> void:
	for child in _summary_box.get_children():
		child.queue_free()

	var character: Resource = CharacterRegistry.selected()
	if character != null:
		_summary_box.add_child(UI.make_chip("🧙 %s" % character.display_name, character.body_color.lightened(0.35), 12))
	var weapon: Resource = RegistryScript.get_data(GameManager.starting_weapon())
	if weapon != null:
		_summary_box.add_child(UI.make_chip("%s %s" % [weapon.icon, weapon.display_name], weapon.icon_color, 12))

	var diff: Dictionary = GameManager.difficulty_data()
	_summary_box.add_child(UI.make_chip("%s %s" % [String(diff.get("icon", "🌙")), String(diff.get("label", "Normal"))], P.ACCENT_ORANGE, 12))
	_summary_box.add_child(UI.make_chip("⏱ %d min" % int(GameManager.selected_goal_seconds / 60), P.ACCENT_CYAN, 12))

	var energy: int = SaveSystem.energy()
	if energy >= ENERGY_COST:
		_energy_note.text = "⚡ %d energia — bônus de +20%% de moedas nesta partida" % energy
		_energy_note.add_theme_color_override("font_color", P.CRIT)
	else:
		_energy_note.text = "⚡ sem energia (volta 1 a cada 90s) — dá pra jogar, só sem o bônus de moedas"
		_energy_note.add_theme_color_override("font_color", P.TEXT_MUTED)


func _on_play() -> void:
	MapRegistry.select(_selected_key)
	GameManager.energy_bonus = SaveSystem.spend_energy(ENERGY_COST)
	EventBus.sfx("select", 0.9)
	get_tree().change_scene_to_file(GAME_WORLD_PATH)


## Miniatura procedural do bioma
class _MapPreview extends Control:
	var map_data: Resource

	func _draw() -> void:
		if map_data == null:
			return
		draw_rect(Rect2(Vector2.ZERO, size), map_data.ground_color)
		var tile := 12
		var cols: int = int(size.x / tile) + 1
		var rows: int = int(size.y / tile) + 1
		var variant: Color = map_data.ground_variant_color
		variant.a = 0.8
		for r in range(rows):
			for c in range(cols):
				if (r + c) % 2 == 0:
					draw_rect(Rect2(c * tile, r * tile, tile, tile), variant)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(map_data.key)
		for i in range(46):
			var x := rng.randf() * size.x
			var y := rng.randf() * size.y
			var radius := rng.randf_range(1.5, 3.6)
			if map_data.obstacle_palette.size() > 0:
				draw_circle(Vector2(x, y), radius, map_data.obstacle_palette[i % map_data.obstacle_palette.size()])
		if map_data.has_lake:
			var lake_center := Vector2(size.x * 0.7, size.y * 0.62)
			var lake_radius: float = min(size.x, size.y) * 0.20
			draw_circle(lake_center, lake_radius, map_data.lake_color)
		if map_data.has_ruin:
			var rw: float = min(size.x, size.y) * 0.22
			draw_rect(Rect2(size.x * 0.16, size.y * 0.26, rw, rw), map_data.ruin_color)
		# Lua
		draw_circle(Vector2(size.x * 0.82, size.y * 0.18), 9.0, Color(0.98, 0.92, 0.75, 0.85))
		# Vinheta
		var v: float = min(size.x, size.y) * 0.12
		var shade := Color(0, 0, 0, 0.3)
		draw_rect(Rect2(0, 0, size.x, v), shade)
		draw_rect(Rect2(0, size.y - v, size.x, v), shade)
		draw_rect(Rect2(0, 0, v, size.y), shade)
		draw_rect(Rect2(size.x - v, 0, v, size.y), shade)
		if map_data.fog_color.a > 0.0:
			var fog: Color = map_data.fog_color
			fog.a = min(fog.a, 0.3)
			draw_rect(Rect2(Vector2.ZERO, size), fog)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.435, 0.388, 0.557), false, 2.0)
