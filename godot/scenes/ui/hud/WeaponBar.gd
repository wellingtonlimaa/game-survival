extends Control

## Barra de armas: ícone, cor da arma, nível e recarga em tempo real.

const P := preload("res://scripts/utils/Theme.gd")
const UI := preload("res://scripts/utils/UIFactory.gd")

var weapon_system: Node = null
var _row: HBoxContainer
var _chips: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 5)
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_row)
	EventBus.loadout_changed.connect(_refresh)
	EventBus.weapon_evolved.connect(func(_k): _refresh())


func bind_weapons(p_weapon_system: Node) -> void:
	weapon_system = p_weapon_system
	_refresh()


func _refresh() -> void:
	if weapon_system == null or _row == null:
		return
	for child in _row.get_children():
		child.queue_free()
	_chips.clear()
	for slot in weapon_system.slots:
		var chip := _WeaponChip.new()
		chip.custom_minimum_size = Vector2(48, 50)
		chip.slot = slot
		_row.add_child(chip)
		_chips.append(chip)


class _WeaponChip extends Control:
	const PAL := preload("res://scripts/utils/Theme.gd")
	var slot = null
	var _time: float = 0.0
	var _last_bucket: int = -1

	func _process(delta: float) -> void:
		_time += delta
		if slot == null or slot.data == null:
			return
		# Texto e ícone são caros: redesenha só quando a barra muda de faixa
		var cd: float = slot.data.cooldown_at_level(slot.level)
		var bucket: int = int(clampf(1.0 - maxf(slot.timer, 0.0) / maxf(0.01, cd), 0.0, 1.0) * 8.0)
		if slot.level >= slot.data.max_level:
			bucket += int(_time * 4.0) * 16
		if bucket != _last_bucket:
			_last_bucket = bucket
			queue_redraw()

	func _draw() -> void:
		if slot == null or slot.data == null:
			return
		var col: Color = slot.data.icon_color
		var evolved: bool = slot.data.is_evolution
		var rect := Rect2(Vector2.ZERO, size)

		# Fundo
		draw_rect(rect, Color(0.07, 0.06, 0.12, 0.88))
		draw_rect(rect, col if not evolved else PAL.ACCENT_GOLD, false, 2.0)

		# Recarga (preenchimento de baixo pra cima)
		var cd: float = slot.data.cooldown_at_level(slot.level)
		var pct: float = clampf(1.0 - maxf(slot.timer, 0.0) / maxf(0.01, cd), 0.0, 1.0)
		var fill_h: float = size.y * pct
		draw_rect(Rect2(Vector2(0, size.y - fill_h), Vector2(size.x, fill_h)), Color(col.r, col.g, col.b, 0.20))

		# Ícone
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(0, size.y * 0.52), slot.data.icon, HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, Color(1, 1, 1, 0.95))

		# Nível
		var level_text: String = "★" if evolved else "Lv%d" % slot.level
		var level_col: Color = PAL.ACCENT_GOLD if evolved else PAL.TEXT_PRIMARY
		draw_string(font, Vector2(0, size.y - 5), level_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, level_col)

		# Brilho quando está no máximo
		if slot.level >= slot.data.max_level and not evolved:
			var pulse: float = 0.35 + 0.35 * sin(_time * 3.0)
			draw_rect(rect, Color(1.0, 0.776, 0.298, pulse), false, 2.0)
