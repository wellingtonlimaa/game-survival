class_name EnemyData
extends Resource

enum Behavior {
	CHASE,           # persegue direto
	KITE_AND_SHOOT,  # mantém distância e atira
	EXPLODE_CLOSE,   # aproxima até a distância de gatilho e explode
	SUMMONER,        # invoca lacaios periodicamente
	BOSS_RADIAL,     # atira em padrão radial
	CHARGER,         # telegrafa e dispara uma investida em linha reta
	SPIRAL,          # atira em espiral contínua (chefes)
	SPLITTER,        # ao morrer se divide em dois menores
}

enum Tier {
	NORMAL,
	ELITE,
	MINIBOSS,
	BOSS,
}

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var tier: Tier = Tier.NORMAL

@export_group("Stats")
@export var hp: float = 30.0
@export var speed: float = 90.0
@export var contact_damage: float = 10.0
@export var radius: float = 14.0
@export var xp_value: int = 4
@export var coin_value: int = 1
@export var armor: float = 0.0
@export var knockback_resist: float = 0.0   # 0 = leve, 1 = imóvel

@export_group("Behavior")
@export var behavior: Behavior = Behavior.CHASE
@export var attack_cooldown: float = 1.6
@export var prefered_distance: float = 220.0  # kite
@export var trigger_distance: float = 105.0   # exploder
@export var windup_time: float = 0.6
@export var summon_pool: PackedStringArray = []
@export var summon_count: int = 2
@export var split_into: String = ""
@export var split_count: int = 2
@export var charge_speed: float = 520.0
@export var charge_duration: float = 0.55
@export var explode_radius: float = 120.0

@export_group("Drops")
@export var coin_chance: float = 0.25
@export var heart_chance: float = 0.0
@export var chest_chance: float = 0.0

@export_group("Visual")
@export var body_color: Color = Color(0.886, 0.275, 0.345, 1.0)
@export var eye_color: Color = Color(1.0, 0.949, 0.42, 1.0)
@export var silhouette: String = "blob"  # blob | tall | wide | crown | mask | skull | horned
@export var icon: String = "👾"

@export_group("Projectile")
@export var projectile_speed: float = 220.0
@export var projectile_damage: float = 10.0
@export var projectile_radius: float = 6.0
@export var projectile_lifetime: float = 2.0
@export var projectile_color: Color = Color(0.886, 0.275, 0.345, 1.0)
@export var projectile_count: int = 1


func is_boss() -> bool:
	return tier == Tier.BOSS or tier == Tier.MINIBOSS
