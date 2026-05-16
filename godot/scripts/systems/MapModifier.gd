class_name MapModifier
extends RefCounted

const MODIFIERS := {
	"calm": {
		"label": "Noite Tranquila",
		"description": "Sem modificadores.",
		"color": Color(0.722, 0.694, 0.808, 1.0),
		"hp_mult": 1.0,
		"speed_mult": 1.0,
		"coin_mult": 1.0,
		"elite_bias": 0.0,
		"damage_mult": 1.0,
		"damage_taken_mult": 1.0,
	},
	"blood_moon": {
		"label": "Lua de Sangue",
		"description": "+35% moedas, mais elites e inimigos mais perigosos.",
		"color": Color(0.886, 0.275, 0.345, 1.0),
		"hp_mult": 1.15,
		"speed_mult": 1.0,
		"coin_mult": 1.35,
		"elite_bias": 0.10,
		"damage_mult": 1.10,
		"damage_taken_mult": 1.0,
	},
	"gold_rush": {
		"label": "Corrida Dourada",
		"description": "Inimigos rápidos mas drop dobra.",
		"color": Color(1.0, 0.776, 0.298, 1.0),
		"hp_mult": 0.95,
		"speed_mult": 1.18,
		"coin_mult": 2.0,
		"elite_bias": 0.0,
		"damage_mult": 1.0,
		"damage_taken_mult": 1.0,
	},
	"glass_night": {
		"label": "Noite de Vidro",
		"description": "+28% dano dado, mas dano recebido também aumenta.",
		"color": Color(0.392, 0.808, 0.929, 1.0),
		"hp_mult": 0.82,
		"speed_mult": 1.0,
		"coin_mult": 1.10,
		"elite_bias": 0.05,
		"damage_mult": 1.28,
		"damage_taken_mult": 1.30,
	},
}


static func choose_random() -> String:
	var keys: Array = MODIFIERS.keys()
	return String(keys[randi() % keys.size()])


static func get_info(key: String) -> Dictionary:
	return MODIFIERS.get(key, MODIFIERS["calm"])
