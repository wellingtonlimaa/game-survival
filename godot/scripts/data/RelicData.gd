class_name RelicData
extends Resource

## Relíquia: efeito único e permanente na run.

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: String = "💎"
@export var icon_color: Color = Color(1.0, 0.776, 0.298, 1.0)

@export_group("Efeitos")
@export var damage_mult_bonus: float = 0.0
@export var xp_mult_bonus: float = 0.0
@export var coin_mult_bonus: float = 0.0
@export var max_hp_bonus: float = 0.0
@export var max_hp_pct_bonus: float = 0.0
@export var max_hp_loss: float = 0.0
@export var armor_bonus: float = 0.0
@export var luck_bonus: float = 0.0
@export var regen_bonus: float = 0.0
@export var heal_on_pickup: float = 0.0
@export var speed_mult: float = 1.0
@export var cooldown_mult: float = 1.0
@export var area_mult: float = 1.0
@export var duration_mult: float = 1.0
@export var dodge_bonus: float = 0.0
@export var crit_chance_bonus: float = 0.0
@export var crit_mult_bonus: float = 0.0
@export var lifesteal_bonus: float = 0.0
@export var pickup_bonus: float = 0.0
@export var extra_projectiles: int = 0
@export var extra_pierce: int = 0
@export var vision_bonus: float = 0.0
@export var extra_rerolls: int = 0
@export var revives: int = 0
@export var dash_cooldown_mult: float = 1.0
@export var grants_weapon: String = ""
