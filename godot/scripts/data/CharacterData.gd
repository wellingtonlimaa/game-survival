class_name CharacterData
extends Resource

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var unlock_hint: String = ""

@export_group("Stats Modifiers")
@export var hp_mult: float = 1.0
@export var speed_mult: float = 1.0
@export var damage_mult_bonus: float = 0.0
@export var armor_bonus: float = 0.0
@export var luck_bonus: float = 0.0
@export var regen_bonus: float = 0.0
@export var pickup_bonus: float = 0.0
@export var xp_mult_bonus: float = 0.0

@export_group("Loadout")
@export var starter_weapon: String = "wand"

@export_group("Visual")
@export var body_color: Color = Color(0.275, 0.227, 0.412, 1.0)
@export var head_color: Color = Color(0.118, 0.094, 0.18, 1.0)
@export var eye_color: Color = Color(1.0, 0.776, 0.298, 1.0)
