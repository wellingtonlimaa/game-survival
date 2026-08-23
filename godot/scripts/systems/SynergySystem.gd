class_name SynergySystem
extends RefCounted

## Sinergias: combinações de armas que dão bônus permanentes na run.
## São verificadas toda vez que o arsenal muda.

const SYNERGIES := {
	"tempestade": {
		"label": "Tempestade Arcana", "icon": "🌩",
		"weapons": ["wand", "lightning"],
		"description": "+15% de dano",
		"damage_bonus": 0.15,
	},
	"dancarina": {
		"label": "Dançarina das Lâminas", "icon": "🗡",
		"weapons": ["knife", "scythe"],
		"description": "+10% de dano e +8% de velocidade",
		"damage_bonus": 0.10, "speed_bonus": 0.08,
	},
	"inferno": {
		"label": "Círculo de Fogo", "icon": "🔥",
		"weapons": ["fire_staff", "flame"],
		"description": "+18% de dano e +10% de área",
		"damage_bonus": 0.18, "area_bonus": 0.10,
	},
	"guardiao": {
		"label": "Guardião Celeste", "icon": "🛡",
		"weapons": ["holy_shield", "orbit"],
		"description": "+3 de armadura e +10% de área",
		"armor_bonus": 3.0, "area_bonus": 0.10,
	},
	"cacador": {
		"label": "Caçada Sem Fim", "icon": "🏹",
		"weapons": ["arrow_storm", "spirit"],
		"description": "-10% de recarga e +10% de dano",
		"cooldown_bonus": -0.10, "damage_bonus": 0.10,
	},
	"gelo_eterno": {
		"label": "Gelo Eterno", "icon": "❄",
		"weapons": ["frost_nova", "comet"],
		"description": "+12% de dano e +12% de crítico",
		"damage_bonus": 0.12, "crit_bonus": 0.12,
	},
	"demolidor": {
		"label": "Demolidor", "icon": "💣",
		"weapons": ["bomb", "axe"],
		"description": "+15% de área e +12% de dano",
		"area_bonus": 0.15, "damage_bonus": 0.12,
	},
	"arsenal": {
		"label": "Arsenal Completo", "icon": "⭐",
		"weapons": [],
		"needs_slots": 6,
		"description": "6 armas equipadas: +20% de dano",
		"damage_bonus": 0.20,
	},
}


static func check(active_weapon_keys: Array) -> Array:
	var active: Array = []
	for key in SYNERGIES.keys():
		var info: Dictionary = SYNERGIES[key]
		var needs_slots: int = int(info.get("needs_slots", 0))
		if needs_slots > 0:
			if active_weapon_keys.size() >= needs_slots:
				active.append(key)
			continue
		var all_present: bool = true
		for w in info["weapons"]:
			if not active_weapon_keys.has(w):
				all_present = false
				break
		if all_present:
			active.append(key)
	return active
