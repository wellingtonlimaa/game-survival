class_name PassiveData
extends Resource

## Passiva de run: cada nível soma os bônus abaixo (escalados pela raridade).

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: String = "🔮"
@export var icon_color: Color = Color(0.953, 0.929, 0.871, 1.0)
@export var max_level: int = 5

@export_group("Bônus por nível")
@export var move_speed_per_level: float = 0.0
@export var regen_per_level: float = 0.0
@export var max_hp_bonus_per_level: float = 0.0
@export var magnet_per_level: float = 0.0
@export var armor_per_level: float = 0.0
@export var luck_per_level: float = 0.0
@export var cooldown_mult_per_level: float = 0.0     # negativo = recarrega mais rápido
@export var damage_mult_per_level: float = 0.0
@export var area_mult_per_level: float = 0.0
@export var projectile_speed_per_level: float = 0.0
@export var duration_per_level: float = 0.0
@export var crit_chance_per_level: float = 0.0
@export var crit_mult_per_level: float = 0.0
@export var coin_mult_per_level: float = 0.0
@export var dodge_per_level: float = 0.0
@export var xp_mult_per_level: float = 0.0
@export var extra_projectiles_per_level: float = 0.0   # fracionário: 0.5 = +1 a cada 2 níveis
@export var extra_pierce_per_level: float = 0.0
@export var vision_per_level: float = 0.0              # afasta a câmera (campo de visão)
