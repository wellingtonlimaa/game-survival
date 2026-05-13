class_name RelicData
extends Resource

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color(1.0, 0.776, 0.298, 1.0)

# Efeitos (aplicados uma vez ao pegar)
@export var damage_mult_bonus: float = 0.0
@export var xp_mult_bonus: float = 0.0
@export var max_hp_bonus: float = 0.0
@export var max_hp_loss: float = 0.0
@export var armor_bonus: float = 0.0
@export var luck_bonus: float = 0.0
@export var regen_bonus: float = 0.0
@export var heal_on_pickup: float = 0.0
@export var grants_weapon: String = ""
