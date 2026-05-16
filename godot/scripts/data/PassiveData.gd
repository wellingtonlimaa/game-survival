class_name PassiveData
extends Resource

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color(0.953, 0.929, 0.871, 1.0)
@export var max_level: int = 5

# Quanto cada nível dá (multiplicado pelo bônus de raridade)
@export var move_speed_per_level: float = 0.0
@export var regen_per_level: float = 0.0
@export var max_hp_bonus_per_level: float = 0.0
@export var magnet_per_level: float = 0.0
@export var armor_per_level: float = 0.0
@export var luck_per_level: float = 0.0
@export var cooldown_mult_per_level: float = 0.0  # negativo reduz (multiplicado)
