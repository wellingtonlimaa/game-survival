class_name UIFactory
extends RefCounted

## Fábrica de estilos: evita repetir 30 linhas de StyleBoxFlat em cada tela.

const P := preload("res://scripts/utils/Theme.gd")


static func panel_style(
	bg: Color = P.BG_MID,
	border: Color = P.BORDER,
	radius: int = 14,
	border_width: int = 2,
	margin: int = 12
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_left = border_width
	s.border_width_top = border_width
	s.border_width_right = border_width
	s.border_width_bottom = border_width + 1
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = margin
	s.content_margin_top = margin
	s.content_margin_right = margin
	s.content_margin_bottom = margin
	return s


static func glow_panel_style(accent: Color, radius: int = 14, margin: int = 12) -> StyleBoxFlat:
	var s := panel_style(P.BG_MID, accent, radius, 3, margin)
	s.shadow_color = Color(accent.r, accent.g, accent.b, 0.45)
	s.shadow_size = 12
	s.shadow_offset = Vector2(0, 2)
	return s


static func make_panel(bg: Color = P.BG_MID, border: Color = P.BORDER, radius: int = 14, margin: int = 12) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", panel_style(bg, border, radius, 2, margin))
	return p


static func make_label(text: String, size: int = 14, color: Color = P.TEXT_PRIMARY, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", P.BG_DEEP)
	return l


static func style_button(
	btn: Button,
	bg: Color = P.ACCENT_GOLD,
	fg: Color = P.TEXT_DARK,
	radius: int = 12,
	font_size: int = 16
) -> Button:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = bg.darkened(0.45)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 4
	normal.corner_radius_top_left = radius
	normal.corner_radius_top_right = radius
	normal.corner_radius_bottom_left = radius
	normal.corner_radius_bottom_right = radius
	normal.content_margin_left = 14
	normal.content_margin_top = 8
	normal.content_margin_right = 14
	normal.content_margin_bottom = 10

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.12)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.15)
	pressed.border_width_bottom = 2
	pressed.content_margin_top = 10
	pressed.content_margin_bottom = 8

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.196, 0.165, 0.235, 1.0)
	disabled.border_color = Color(0.145, 0.125, 0.180, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", fg)
	btn.add_theme_color_override("font_hover_color", fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_color_override("font_disabled_color", P.TEXT_MUTED)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.focus_mode = Control.FOCUS_NONE
	return btn


static func make_button(text: String, bg: Color = P.ACCENT_GOLD, fg: Color = P.TEXT_DARK, font_size: int = 16) -> Button:
	var b := Button.new()
	b.text = text
	return style_button(b, bg, fg, 12, font_size)


static func make_chip(text: String, accent: Color, font_size: int = 11) -> PanelContainer:
	var holder := PanelContainer.new()
	var s := panel_style(Color(0.067, 0.055, 0.118, 0.85), accent, 100, 1, 4)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 2
	s.content_margin_bottom = 3
	holder.add_theme_stylebox_override("panel", s)
	holder.add_child(make_label(text, font_size, accent))
	return holder


static func make_progress(color: Color, bg: Color = Color(0.067, 0.055, 0.118, 0.9), height: int = 12) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, height)
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = bg
	bg_style.corner_radius_top_left = height / 2
	bg_style.corner_radius_top_right = height / 2
	bg_style.corner_radius_bottom_left = height / 2
	bg_style.corner_radius_bottom_right = height / 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = height / 2
	fill.corner_radius_top_right = height / 2
	fill.corner_radius_bottom_left = height / 2
	fill.corner_radius_bottom_right = height / 2
	bar.add_theme_stylebox_override("background", bg_style)
	bar.add_theme_stylebox_override("fill", fill)
	return bar
