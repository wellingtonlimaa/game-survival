class_name SynergySystem
extends RefCounted

const SYNERGIES := {
	"storm_mage":    { "label": "Mago da Tempestade", "weapons": ["wand", "orbit"],  "damage_bonus": 0.12 },
	"blade_dancer":  { "label": "Dançarina das Lâminas", "weapons": ["knife", "orbit"], "speed_bonus": 0.10, "damage_bonus": 0.10 },
	"arcane_storm":  { "label": "Tempestade Arcana", "weapons": ["wand", "knife", "orbit"], "damage_bonus": 0.18, "cooldown_bonus": -0.08 },
}


static func check(active_weapon_keys: Array) -> Array:
	var active: Array = []
	for key in SYNERGIES.keys():
		var info: Dictionary = SYNERGIES[key]
		var weapons: Array = info["weapons"]
		var all_present: bool = true
		for w in weapons:
			if not active_weapon_keys.has(w):
				all_present = false
				break
		if all_present:
			active.append(key)
	return active
