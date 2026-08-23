extends Control

## Tela de fim de partida: resultado, estatísticas, recompensas e novidades.

const P := preload("res://scripts/utils/Theme.gd")
const UI := preload("res://scripts/utils/UIFactory.gd")

signal back_to_menu
signal restart

var _root: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.05, 0.92)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 10)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_root)


func setup(stats: Dictionary, coin_total: int, bonus: int, won: bool) -> void:
	var title := UI.make_label("VITÓRIA!" if won else "VOCÊ TOMBOU", 34, P.ACCENT_GREEN if won else P.ACCENT_RED, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(title)

	var subtitle_text: String = "Você sobreviveu à noite inteira!" if won else "A noite venceu... dessa vez."
	if bool(stats.get("is_record", false)):
		subtitle_text = "🏆 NOVO RECORDE PESSOAL!"
	var subtitle := UI.make_label(subtitle_text, 14, P.ACCENT_GOLD if bool(stats.get("is_record", false)) else P.TEXT_SECONDARY, 3)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(subtitle)

	# Grade de estatísticas
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_root.add_child(grid)

	grid.add_child(_stat_card("⏱ Tempo", GameManager.format_time(int(stats.get("time", 0))), P.ACCENT_CYAN))
	grid.add_child(_stat_card("⭐ Nível", "%d" % int(stats.get("level", 1)), P.ACCENT_PURPLE))
	grid.add_child(_stat_card("☠ KOs", "%d" % int(stats.get("kills", 0)), P.ACCENT_RED))
	grid.add_child(_stat_card("👑 Chefes", "%d" % int(stats.get("boss_kills", 0)), P.ACCENT_GOLD))
	grid.add_child(_stat_card("⚔ Dano", _short_number(int(stats.get("damage", 0))), P.ACCENT_ORANGE))
	grid.add_child(_stat_card("📈 DPS médio", "%d" % int(stats.get("dps", 0)), P.ACCENT_GREEN))

	# Recompensas
	var rewards := PanelContainer.new()
	rewards.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_GOLD, 14, 2, 12))
	_root.add_child(rewards)
	var rewards_box := VBoxContainer.new()
	rewards_box.add_theme_constant_override("separation", 4)
	rewards.add_child(rewards_box)

	var coin_line := UI.make_label("🪙 +%d moedas" % coin_total, 20, P.ACCENT_GOLD, 3)
	coin_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rewards_box.add_child(coin_line)

	var gems: int = int(stats.get("gems", 0))
	if gems > 0:
		var gem_line := UI.make_label("🌙 +%d fragmentos de lua" % gems, 14, P.ACCENT_CYAN, 2)
		gem_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_box.add_child(gem_line)

	var meta_xp: int = int(stats.get("meta_xp", 0))
	if meta_xp > 0:
		var xp_line := UI.make_label("✨ +%d XP de conta" % meta_xp, 14, P.ACCENT_PURPLE, 2)
		xp_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_box.add_child(xp_line)
	if bonus > 0:
		var bonus_line := UI.make_label("🏅 Bônus de vitória: +%d" % bonus, 13, P.ACCENT_GREEN, 2)
		bonus_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_box.add_child(bonus_line)

	if bool(stats.get("leveled_up", false)):
		var lvl_line := UI.make_label("🎉 Conta subiu para o nível %d!" % int(stats.get("new_meta_level", 1)), 14, P.ACCENT_GOLD, 2)
		lvl_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lvl_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rewards_box.add_child(lvl_line)

	var unlocks: Array = stats.get("unlocks", [])
	if not unlocks.is_empty():
		var unlock_panel := PanelContainer.new()
		unlock_panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_CYAN, 14, 2, 12))
		_root.add_child(unlock_panel)
		var ubox := VBoxContainer.new()
		ubox.add_theme_constant_override("separation", 3)
		unlock_panel.add_child(ubox)
		var uhead := UI.make_label("🔓 DESBLOQUEADO", 14, P.ACCENT_CYAN, 2)
		uhead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ubox.add_child(uhead)
		for u in unlocks:
			var text: String = ""
			if typeof(u) == TYPE_DICTIONARY:
				text = "%s %s (%s)" % [String(u.get("icon", "✦")), String(u.get("label", "")), String(u.get("kind", ""))]
			else:
				text = "✦ %s" % String(u)
			var line := UI.make_label(text, 13, P.TEXT_PRIMARY, 2)
			line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ubox.add_child(line)

	# Botões
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	_root.add_child(buttons)

	var again := UI.make_button("▶  JOGAR DE NOVO", P.ACCENT_GOLD, P.TEXT_DARK, 20)
	again.custom_minimum_size = Vector2(0, 54)
	again.pressed.connect(func():
		EventBus.sfx("click", 0.8)
		restart.emit())
	buttons.add_child(again)

	var menu := UI.make_button("Voltar ao menu", P.BG_HIGH, P.TEXT_PRIMARY, 16)
	menu.custom_minimum_size = Vector2(0, 44)
	menu.pressed.connect(func():
		EventBus.sfx("click", 0.6)
		back_to_menu.emit())
	buttons.add_child(menu)

	var next_hint: String = UnlockManager.next_unlock_hint()
	if next_hint != "":
		var teaser := PanelContainer.new()
		teaser.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.ACCENT_PURPLE, 12, 2, 10))
		var tbox := VBoxContainer.new()
		tbox.add_theme_constant_override("separation", 2)
		teaser.add_child(tbox)
		var thead := UI.make_label("PRÓXIMO DESBLOQUEIO", 11, P.TEXT_MUTED)
		thead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tbox.add_child(thead)
		var tline := UI.make_label(next_hint, 14, P.ACCENT_PURPLE, 2)
		tline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tbox.add_child(tline)
		_root.add_child(teaser)

	var tip := UI.make_label(_random_tip(), 11, P.TEXT_MUTED, 2)
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(tip)


func _stat_card(label: String, value: String, color: Color) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UI.panel_style(P.BG_MID, P.BORDER, 12, 2, 8))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var l := UI.make_label(label, 11, P.TEXT_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(l)
	var v := UI.make_label(value, 22, color, 3)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(v)
	return panel


func _short_number(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (float(value) / 1000000.0)
	if value >= 1000:
		return "%.1fk" % (float(value) / 1000.0)
	return str(value)


func _random_tip() -> String:
	var tips := [
		"Dica: leve uma arma de área e uma de dano único — cobre todo tipo de horda.",
		"Dica: altares dão vida, XP e ouro. Vale desviar do caminho por eles.",
		"Dica: junte moedas na run e visite o mercador antes do primeiro chefe.",
		"Dica: passiva no máximo + arma no máximo = carta dourada de EVOLUÇÃO.",
		"Dica: o dash tem invulnerabilidade — atravesse a horda no aperto.",
		"Dica: na loja, Vida Máxima e Dano são os primeiros investimentos.",
		"Dica: modificadores mudam tudo. Lua de Sangue paga muito mais moeda.",
	]
	return tips[randi() % tips.size()]
