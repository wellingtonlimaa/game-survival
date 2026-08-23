extends Control

## HUD da partida, montado em código (nada de .tscn desatualizado).
## Mostra tempo, objetivo, vida, XP, dash, armas, minimapa, chefe,
## combo, moedas da run, eventos e avisos.

const P := preload("res://scripts/utils/Theme.gd")
const UI := preload("res://scripts/utils/UIFactory.gd")
const MINIMAP_SCENE := preload("res://scenes/ui/hud/Minimap.tscn")
const WEAPON_BAR_SCENE := preload("res://scenes/ui/hud/WeaponBar.tscn")

signal back_to_menu_requested
signal pause_requested

var _player: Node2D = null
var _game: Node = null
var _map: Resource = null

var time_alive: float = 0.0
var goal_seconds: float = 600.0

var timer_label: Label
var goal_label: Label
var map_label: Label
var kills_label: Label
var coins_label: Label
var hp_bar: ProgressBar
var hp_label: Label
var xp_bar: ProgressBar
var level_label: Label
var dash_bar: ProgressBar
var combo_label: Label
var banner_label: Label
var event_label: Label
var toast_box: VBoxContainer
var boss_panel: PanelContainer
var boss_bar: ProgressBar
var boss_name: Label
var minimap: Control
var weapon_bar: Control
var buffs_row: HBoxContainer

var _banner_timer: float = 0.0
var _boss_timer: float = 0.0
var _last_second: int = -1
var _last_remaining: int = -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	EventBus.narrative_triggered.connect(_show_banner)
	EventBus.toast_requested.connect(_show_toast)
	EventBus.combo_changed.connect(_on_combo)
	EventBus.run_coins_changed.connect(_on_run_coins)
	EventBus.boss_hp_changed.connect(_on_boss_hp)
	EventBus.boss_despawned.connect(_hide_boss)
	EventBus.enemy_killed.connect(func(_e, _s): _on_kill())


func setup(map_data: Resource, world: Dictionary, player: Node2D, game: Node = null) -> void:
	_map = map_data
	_player = player
	_game = game
	goal_seconds = float(GameManager.selected_goal_seconds)
	map_label.text = map_data.display_name
	if game != null and "modifier_info" in game and String(game.modifier_key) != "calm":
		var info: Dictionary = game.modifier_info
		map_label.text = "%s · %s %s" % [map_data.display_name, String(info.get("icon", "")), String(info.get("label", ""))]
		map_label.add_theme_color_override("font_color", info.get("color", P.TEXT_SECONDARY))
	minimap.setup(map_data, world, player, game)

	if player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
	if player.has_signal("xp_changed"):
		player.xp_changed.connect(_on_xp_changed)
	if player.has_signal("dash_changed"):
		player.dash_changed.connect(_on_dash_changed)
	_on_hp_changed(player.hp, player.max_hp)
	_on_xp_changed(player.xp, player.xp_to_next, player.level)


func bind_weapons_to_bar(weapon_system: Node) -> void:
	if weapon_bar != null and weapon_bar.has_method("bind_weapons"):
		weapon_bar.bind_weapons(weapon_system)


# --- Construção --------------------------------------------------------------

func _build() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 4)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# --- Topo ---
	var top := MarginContainer.new()
	top.add_theme_constant_override("margin_left", 10)
	top.add_theme_constant_override("margin_right", 10)
	top.add_theme_constant_override("margin_top", 8)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(top)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(top_row)

	# Coluna esquerda: contadores
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(left)

	kills_label = UI.make_label("☠ 0", 15, P.TEXT_PRIMARY, 3)
	left.add_child(kills_label)
	coins_label = UI.make_label("🪙 0", 15, P.ACCENT_GOLD, 3)
	left.add_child(coins_label)
	combo_label = UI.make_label("", 14, P.ACCENT_ORANGE, 3)
	left.add_child(combo_label)

	# Coluna central: cronômetro
	var center := VBoxContainer.new()
	center.add_theme_constant_override("separation", 0)
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(center)

	timer_label = UI.make_label("00:00", 30, P.TEXT_PRIMARY, 5)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(timer_label)

	goal_label = UI.make_label("", 11, P.TEXT_SECONDARY, 3)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(goal_label)

	map_label = UI.make_label("", 11, P.TEXT_SECONDARY, 3)
	map_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center.add_child(map_label)

	# Coluna direita: pausa + minimapa
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 4)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	top_row.add_child(right)

	var pause_btn := UI.make_button("⏸", P.BG_HIGH, P.TEXT_PRIMARY, 18)
	pause_btn.custom_minimum_size = Vector2(46, 40)
	pause_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	pause_btn.pressed.connect(func(): pause_requested.emit())
	right.add_child(pause_btn)

	minimap = MINIMAP_SCENE.instantiate()
	minimap.size_flags_horizontal = Control.SIZE_SHRINK_END
	right.add_child(minimap)

	# --- Barras de vida / XP ---
	var bars := MarginContainer.new()
	bars.add_theme_constant_override("margin_left", 12)
	bars.add_theme_constant_override("margin_right", 12)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars)

	var bars_box := VBoxContainer.new()
	bars_box.add_theme_constant_override("separation", 3)
	bars_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.add_child(bars_box)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	hp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_box.add_child(hp_row)

	hp_bar = UI.make_progress(P.ACCENT_RED, Color(0.10, 0.05, 0.09, 0.85), 14)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_row.add_child(hp_bar)
	hp_label = UI.make_label("100/100", 12, P.TEXT_PRIMARY, 3)
	hp_label.custom_minimum_size = Vector2(78, 0)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(hp_label)

	var xp_row := HBoxContainer.new()
	xp_row.add_theme_constant_override("separation", 6)
	xp_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_box.add_child(xp_row)

	xp_bar = UI.make_progress(P.ACCENT_PURPLE, Color(0.08, 0.06, 0.13, 0.85), 9)
	xp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	xp_row.add_child(xp_bar)
	level_label = UI.make_label("Lv 1", 12, P.ACCENT_PURPLE, 3)
	level_label.custom_minimum_size = Vector2(78, 0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_row.add_child(level_label)

	var dash_row := HBoxContainer.new()
	dash_row.add_theme_constant_override("separation", 6)
	dash_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_box.add_child(dash_row)
	var dash_icon := UI.make_label("💨 ESPAÇO", 10, P.TEXT_MUTED, 2)
	dash_icon.custom_minimum_size = Vector2(78, 0)
	dash_row.add_child(dash_icon)
	dash_bar = UI.make_progress(P.ACCENT_CYAN, Color(0.06, 0.09, 0.12, 0.8), 6)
	dash_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dash_bar.max_value = 1.0
	dash_bar.value = 1.0
	dash_row.add_child(dash_bar)

	# --- Chefe ---
	boss_panel = PanelContainer.new()
	boss_panel.add_theme_stylebox_override("panel", UI.panel_style(Color(0.12, 0.05, 0.09, 0.88), P.ACCENT_RED, 10, 2, 8))
	boss_panel.visible = false
	boss_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var boss_margin := MarginContainer.new()
	boss_margin.add_theme_constant_override("margin_left", 12)
	boss_margin.add_theme_constant_override("margin_right", 12)
	boss_margin.add_theme_constant_override("margin_top", 4)
	boss_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_margin.add_child(boss_panel)
	root.add_child(boss_margin)

	var boss_box := VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 2)
	boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_panel.add_child(boss_box)
	boss_name = UI.make_label("CHEFE", 13, P.ACCENT_RED, 3)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_name)
	boss_bar = UI.make_progress(P.ACCENT_RED, Color(0.10, 0.03, 0.06, 0.9), 12)
	boss_box.add_child(boss_bar)

	# --- Centro: eventos e avisos ---
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(spacer)

	banner_label = UI.make_label("", 22, P.ACCENT_GOLD, 5)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.modulate.a = 0.0
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner_label)

	toast_box = VBoxContainer.new()
	toast_box.alignment = BoxContainer.ALIGNMENT_END
	toast_box.add_theme_constant_override("separation", 4)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var toast_margin := MarginContainer.new()
	toast_margin.add_theme_constant_override("margin_left", 16)
	toast_margin.add_theme_constant_override("margin_right", 16)
	toast_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_margin.add_child(toast_box)
	root.add_child(toast_margin)

	event_label = UI.make_label("", 13, P.ACCENT_CYAN, 3)
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(event_label)

	# --- Rodapé: armas + passivas ---
	var bottom := MarginContainer.new()
	bottom.add_theme_constant_override("margin_left", 8)
	bottom.add_theme_constant_override("margin_right", 8)
	bottom.add_theme_constant_override("margin_bottom", 10)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom)

	var bottom_box := VBoxContainer.new()
	bottom_box.add_theme_constant_override("separation", 4)
	bottom_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_child(bottom_box)

	buffs_row = HBoxContainer.new()
	buffs_row.alignment = BoxContainer.ALIGNMENT_CENTER
	buffs_row.add_theme_constant_override("separation", 4)
	buffs_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_box.add_child(buffs_row)

	weapon_bar = WEAPON_BAR_SCENE.instantiate()
	bottom_box.add_child(weapon_bar)


# --- Loop --------------------------------------------------------------------

func _process(delta: float) -> void:
	if GameManager.state == GameManager.GameState.PLAYING:
		time_alive += delta
		var second: int = int(time_alive)
		if second != _last_second:
			_last_second = second
			timer_label.text = GameManager.format_time(second)
			var remaining: int = int(maxf(0.0, goal_seconds - time_alive))
			if remaining != _last_remaining:
				_last_remaining = remaining
				if remaining > 0:
					goal_label.text = "objetivo em %s" % GameManager.format_time(remaining)
					goal_label.add_theme_color_override("font_color", P.TEXT_SECONDARY)
				else:
					goal_label.text = "SOBREVIVÊNCIA EXTRA"
					goal_label.add_theme_color_override("font_color", P.ACCENT_RED)

			if _game != null and "event_director" in _game and _game.event_director != null:
				var label: String = _game.event_director.event_label()
				if label != event_label.text:
					event_label.text = label
				event_label.modulate.a = 1.0 if label != "" else 0.0

	if _banner_timer > 0.0:
		_banner_timer = maxf(0.0, _banner_timer - delta)
		if _banner_timer > 1.8:
			banner_label.modulate.a = minf(1.0, banner_label.modulate.a + delta * 5.0)
		else:
			banner_label.modulate.a = maxf(0.0, banner_label.modulate.a - delta * 1.3)

	if _boss_timer > 0.0:
		_boss_timer = maxf(0.0, _boss_timer - delta)
		if _boss_timer <= 0.0:
			boss_panel.visible = false


func _on_kill() -> void:
	if _game == null:
		return
	kills_label.text = "☠ %d" % int(_game.kills)


func _on_run_coins(total: int) -> void:
	coins_label.text = "🪙 %d" % total


func _on_combo(count: int, pct: float) -> void:
	if count < 5:
		combo_label.text = ""
		return
	combo_label.text = "COMBO x%d" % count
	combo_label.modulate.a = 0.5 + 0.5 * pct


func _on_hp_changed(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "%d/%d" % [int(round(current)), int(round(maximum))]
	var pct: float = current / maxf(1.0, maximum)
	var fill: StyleBoxFlat = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null:
		fill.bg_color = P.hp_color(pct)


func _on_xp_changed(current: float, to_next: float, level: int) -> void:
	xp_bar.max_value = to_next
	xp_bar.value = current
	level_label.text = "Lv %d" % level


func _on_dash_changed(pct: float) -> void:
	dash_bar.value = pct


func _on_boss_hp(current: float, maximum: float, name_text: String) -> void:
	boss_panel.visible = true
	boss_name.text = name_text.to_upper()
	boss_bar.max_value = maximum
	boss_bar.value = current
	_boss_timer = 6.0


func _hide_boss() -> void:
	boss_panel.visible = false
	_boss_timer = 0.0


func _show_banner(text: String) -> void:
	banner_label.text = text
	_banner_timer = 2.6


func _show_toast(text: String, color: Color, icon: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.panel_style(Color(0.07, 0.06, 0.12, 0.92), color, 10, 2, 8))
	panel.modulate.a = 0.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UI.make_label(("%s %s" % [icon, text]).strip_edges(), 13, color, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	toast_box.add_child(panel)
	if toast_box.get_child_count() > 4:
		toast_box.get_child(0).queue_free()

	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_interval(2.2)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)


## Ícones de passivas/relíquias ativas (atualizado pela tela de upgrade)
func refresh_buffs(summary: Dictionary) -> void:
	for child in buffs_row.get_children():
		child.queue_free()
	for p in summary.get("passives", []):
		buffs_row.add_child(UI.make_chip("%s%d" % [String(p["icon"]), int(p["level"])], p["color"], 11))
	for r in summary.get("relics", []):
		buffs_row.add_child(UI.make_chip(String(r["icon"]), r["color"], 11))
