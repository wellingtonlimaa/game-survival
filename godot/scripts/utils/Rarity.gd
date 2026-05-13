class_name Rarity
extends RefCounted

const KEYS := ["comum", "raro", "epico", "lendario"]

const MULTIPLIERS := {
	"comum":    1.00,
	"raro":     1.35,
	"epico":    1.75,
	"lendario": 2.30,
}

const COLORS := {
	"comum":    Color(0.722, 0.694, 0.808, 1.0),
	"raro":     Color(0.392, 0.808, 0.929, 1.0),
	"epico":    Color(0.624, 0.388, 0.937, 1.0),
	"lendario": Color(1.000, 0.776, 0.298, 1.0),
}

const LABELS := {
	"comum":    "Comum",
	"raro":     "Raro",
	"epico":    "Épico",
	"lendario": "Lendário",
}


static func roll(luck: float = 0.0, chest_bonus: bool = false) -> String:
	# Probabilidades base
	var legendary_chance: float = 0.02 + luck * 0.04
	var epic_chance: float = 0.08 + luck * 0.06
	var rare_chance: float = 0.20 + luck * 0.08
	if chest_bonus:
		legendary_chance += 0.10
		epic_chance += 0.10
		rare_chance += 0.10

	var r: float = randf()
	if r < legendary_chance:
		return "lendario"
	if r < legendary_chance + epic_chance:
		return "epico"
	if r < legendary_chance + epic_chance + rare_chance:
		return "raro"
	return "comum"


static func mult(rarity_key: String) -> float:
	return MULTIPLIERS.get(rarity_key, 1.0)


static func color(rarity_key: String) -> Color:
	return COLORS.get(rarity_key, Color.WHITE)


static func label(rarity_key: String) -> String:
	return LABELS.get(rarity_key, "?")
