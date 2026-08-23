extends Area2D

## Recebe projéteis inimigos e repassa o dano pro herói.
## (Antes o Hurtbox não tinha script, então tiro de inimigo não fazia nada.)

func take_damage(damage: float, _knockback: float, _dir: Vector2, _source: String = "", _is_crit: bool = false) -> void:
	var owner_node: Node = get_parent()
	if owner_node != null and owner_node.has_method("apply_damage_to_player"):
		owner_node.apply_damage_to_player(damage)
