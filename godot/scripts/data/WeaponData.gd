class_name WeaponData
extends Resource

## Definição data-driven de uma arma. Cada .tres em resources/weapons é uma arma.

enum Behavior {
	PROJECTILE_AIM_CLOSEST,   # tiro automático no inimigo mais próximo
	PROJECTILE_AIM_DIRECTION, # tiro na direção da mira
	ORBIT_PLAYER,             # orbes girando ao redor do herói
	AURA_PULSE,               # dano em área contínuo ao redor do herói
	ARC_THROW,                # machado: arremesso em arco, atravessa
	BOOMERANG,                # vai e volta pra mão do herói
	CHAIN_LIGHTNING,          # raio instantâneo que pula entre inimigos
	GROUND_BOMB,              # bomba arremessada que explode em área
	SLASH_ARC,                # golpe corpo a corpo em leque
	NOVA_BURST,               # explosão radial de projéteis
	CONE_FLAME,               # jato de chamas curto e contínuo
	SUMMON_DRONE,             # invoca sentinela que atira sozinha
	HOMING_SHOT,              # projétil teleguiado
}

enum Family {
	WEAPON,  # armas ofensivas clássicas
	POWER,   # poderes passivos-ativos (órbita, aura)
}

@export var key: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: String = "⚔"
@export var icon_color: Color = Color(1.0, 0.776, 0.298, 1.0)
@export var family: Family = Family.WEAPON

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
@export var area: float = 60.0            # raio de efeito (aura, bomba, nova, leque)
@export var chain_targets: int = 0        # saltos do raio
@export var homing_strength: float = 0.0  # 0 = reto, 1 = gruda no alvo
@export var explode_on_hit: bool = false  # projétil estoura em área ao acertar

@export_group("Scaling")
@export var damage_per_level: float = 0.22     # +22% de dano base por nível
@export var cooldown_per_level: float = 0.05   # -5% de recarga por nível
@export var count_per_level: float = 0.0       # projéteis extras por nível (fracionário)
@export var area_per_level: float = 0.06       # +6% de área por nível
@export var pierce_per_level: float = 0.0
@export var max_level: int = 8

@export_group("Status")
@export var status: String = ""            # burn | slow | poison | stun | mark
@export var status_power: float = 0.0
@export var status_duration: float = 0.0
@export var status_chance: float = 1.0
@export var lifesteal: float = 0.0         # cura por acerto

@export_group("Orbit")
@export var orbit_radius: float = 70.0
@export var orbit_speed: float = 2.8

@export_group("Visual")
@export var projectile_color: Color = Color(0.953, 0.929, 0.871, 1.0)
@export var projectile_kind: String = "bolt"  # bolt | blade | orbit | axe | bomb | flame | spark
@export var trail: bool = false

@export_group("Audio")
@export var sound_key: String = "shoot"

@export_group("Evolution")
@export var evolves_into: String = ""      # chave da arma evoluída
@export var evolution_hint: String = ""    # texto mostrado no card
@export var is_evolution: bool = false     # armas evoluídas não aparecem no pool normal


func is_power() -> bool:
	return family == Family.POWER


func damage_at_level(level: int) -> float:
	return damage * (1.0 + damage_per_level * float(max(0, level - 1)))


func cooldown_at_level(level: int) -> float:
	return maxf(0.06, cooldown * pow(1.0 - cooldown_per_level, float(max(0, level - 1))))


func projectile_count_at_level(level: int) -> int:
	return projectile_count + int(floor(count_per_level * float(max(0, level - 1)) + 0.0001))


func area_at_level(level: int) -> float:
	return area * (1.0 + area_per_level * float(max(0, level - 1)))


func pierce_at_level(level: int) -> int:
	return pierce + int(floor(pierce_per_level * float(max(0, level - 1)) + 0.0001))


## Texto curto do que o próximo nível entrega (mostrado no card de upgrade)
func next_level_summary(level: int) -> String:
	var parts: PackedStringArray = []
	parts.append("+%d%% dano" % int(round(damage_per_level * 100.0)))
	if cooldown_per_level > 0.0:
		parts.append("-%d%% recarga" % int(round(cooldown_per_level * 100.0)))
	var before: int = projectile_count_at_level(level)
	var after: int = projectile_count_at_level(level + 1)
	if after > before:
		parts.append("+%d projétil" % (after - before))
	var pierce_before: int = pierce_at_level(level)
	var pierce_after: int = pierce_at_level(level + 1)
	if pierce_after > pierce_before:
		parts.append("+1 perfuração")
	return "  ·  ".join(parts)
