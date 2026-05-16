extends Control

signal back_to_menu


func _ready() -> void:
	%MenuButton.pressed.connect(func(): back_to_menu.emit())


func setup(stats: Dictionary, coin_total: int, bonus: int, won: bool) -> void:
	%TitleLabel.text = "VITÓRIA!" if won else "VOCÊ TOMBOU"
	%TitleLabel.add_theme_color_override("font_color", Color(0.439, 0.871, 0.494) if won else Color(0.886, 0.275, 0.345))

	var minutes := int(stats.get("time", 0)) / 60
	var seconds := int(stats.get("time", 0)) % 60
	%TimeValue.text = "%02d:%02d" % [minutes, seconds]
	%LevelValue.text = "Lv %d" % int(stats.get("level", 1))
	%KillsValue.text = "%d" % int(stats.get("kills", 0))
	%BossValue.text = "%d" % int(stats.get("boss_kills", 0))
	%EvolvedValue.text = "%d" % int(stats.get("evolved", 0))
	%CoinsValue.text = "+%d 🪙" % coin_total
	if bonus > 0:
		%BonusLabel.text = "Bônus vitória: +%d" % bonus
		%BonusLabel.visible = true
	else:
		%BonusLabel.visible = false

	var meta_xp: int = int(stats.get("meta_xp", 0))
	if meta_xp > 0:
		%MetaXpLabel.text = "+%d XP" % meta_xp
		%MetaXpLabel.visible = true
	else:
		%MetaXpLabel.visible = false

	if bool(stats.get("leveled_up", false)):
		var new_lvl: int = int(stats.get("new_meta_level", 1))
		var coin_bonus: int = int(stats.get("level_coin_bonus", 0))
		var lines: PackedStringArray = []
		if coin_bonus > 0:
			lines.append("🎉 Subiu para o nível %d! (+%d 🪙)" % [new_lvl, coin_bonus])
		else:
			lines.append("🎉 Subiu para o nível %d!" % new_lvl)
		var unlocks: Array = stats.get("unlocks", [])
		for u in unlocks:
			lines.append("🔓 %s desbloqueado!" % String(u))
		%LevelUpLabel.text = "\n".join(lines)
		%LevelUpLabel.visible = true
	else:
		%LevelUpLabel.visible = false
