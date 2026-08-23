class_name MapModifier
extends RefCounted

## Modificador sorteado no início de cada partida.
## Muda o sabor da run e é anunciado no HUD.

const MODIFIERS := {
	"calm": {
		"label": "Noite Tranquila", "icon": "🌙",
		"description": "Nenhum modificador. A noite comum já basta.",
		"color": Color(0.722, 0.694, 0.808, 1.0),
		"hp_mult": 1.0, "coin_mult": 1.0, "elite_bias": 0.0,
		"damage_mult": 1.0, "damage_taken_mult": 1.0, "xp_mult": 1.0, "spawn_mult": 1.0,
	},
	"blood_moon": {
		"label": "Lua de Sangue", "icon": "🩸",
		"description": "+40% moedas, mais elites e inimigos mais duros.",
		"color": Color(0.886, 0.275, 0.345, 1.0),
		"hp_mult": 1.18, "coin_mult": 1.40, "elite_bias": 0.10,
		"damage_mult": 1.0, "damage_taken_mult": 1.10, "xp_mult": 1.0, "spawn_mult": 1.0,
	},
	"gold_rush": {
		"label": "Corrida Dourada", "icon": "💰",
		"description": "Inimigos frágeis e cheios de moeda. Corre!",
		"color": Color(1.0, 0.776, 0.298, 1.0),
		"hp_mult": 0.88, "coin_mult": 2.20, "elite_bias": 0.0,
		"damage_mult": 1.0, "damage_taken_mult": 1.0, "xp_mult": 0.9, "spawn_mult": 1.15,
	},
	"glass_night": {
		"label": "Noite de Vidro", "icon": "🔮",
		"description": "+35% de dano seu, mas você também apanha muito mais.",
		"color": Color(0.392, 0.808, 0.929, 1.0),
		"hp_mult": 0.85, "coin_mult": 1.15, "elite_bias": 0.05,
		"damage_mult": 1.35, "damage_taken_mult": 1.45, "xp_mult": 1.0, "spawn_mult": 1.0,
	},
	"swarm": {
		"label": "Enxame Infinito", "icon": "🐝",
		"description": "O dobro de inimigos, mas todos frágeis. XP jorra.",
		"color": Color(0.549, 0.902, 0.400, 1.0),
		"hp_mult": 0.70, "coin_mult": 1.0, "elite_bias": 0.02,
		"damage_mult": 1.0, "damage_taken_mult": 1.0, "xp_mult": 1.25, "spawn_mult": 1.75,
	},
	"eclipse": {
		"label": "Eclipse", "icon": "🌑",
		"description": "A noite fecha. Menos visão, +50% de XP.",
		"color": Color(0.435, 0.361, 0.639, 1.0),
		"hp_mult": 1.05, "coin_mult": 1.1, "elite_bias": 0.06,
		"damage_mult": 1.0, "damage_taken_mult": 1.0, "xp_mult": 1.50, "spawn_mult": 1.0,
		"darkness": 0.45,
	},
}


static func choose_random() -> String:
	# "calm" tem peso menor: modificador é o tempero da partida
	var pool: Array = ["calm", "blood_moon", "gold_rush", "glass_night", "swarm", "eclipse", "blood_moon", "swarm"]
	return String(pool[randi() % pool.size()])


static func get_info(key: String) -> Dictionary:
	return MODIFIERS.get(key, MODIFIERS["calm"])


static func all_keys() -> Array:
	return MODIFIERS.keys()
