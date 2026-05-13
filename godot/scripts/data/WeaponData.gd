class_name WeaponData
extends Resource

enum Behavior {
	PROJECTILE_AIM_CLOSEST,   # ex: wand
	PROJECTILE_AIM_DIRECTION, # ex: knife (mouse aim)
	ORBIT_PLAYER,             # ex: orbit / book
}

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_color: Color = Color(1.0, 0.776, 0.298, 1.0)

@export_group("Behavior")
@export var behavior: Behavior = Behavior.PROJECTILE_AIM_CLOSEST
@export var cooldown: float = 1.0
@export var damage: float = 10.0
@export var projectile_count: int = 1
@export var projectile_speed: float = 360.0
@export var projectile_lifetime: float = 1.4
@export var projectile_radius: float = 6.0
@export var pierce: int = 0
@export var spread_radians: float = 0.0
@export var knockback: float = 120.0

@export_group("Orbit")
@export var orbit_radius: float = 70.0
@export var orbit_speed: float = 2.8

@export_group("Visual")
@export var projectile_color: Color = Color(0.953, 0.929, 0.871, 1.0)
@export var projectile_kind: String = "bolt"

@export_group("Audio")
@export var sound_key: String = "shoot"


func cooldown_at_level(level: int) -> float:
	return cooldown * pow(0.94, max(0, level - 1))


func damage_at_level(level: int) -> float:
	return damage * (1.0 + 0.18 * max(0, level - 1))


func projectile_count_at_level(level: int) -> int:
	return projectile_count + (level - 1) / 3
