extends Button

## Botão principal. A energia deixou de ser trava: agora ela vira bônus
## de moedas na partida (gasta na tela de seleção de mapa).

signal start_pressed

var _pulse_tween: Tween


func _ready() -> void:
	pressed.connect(_on_press)
	EventBus.currency_changed.connect(_on_currency_changed)
	_refresh()
	_start_pulse()


func _start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	pivot_offset = size / 2.0
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2(1.00, 1.00), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _refresh() -> void:
	var energy: int = SaveSystem.energy()
	disabled = false
	modulate = Color(1, 1, 1, 1)
	if energy >= 5:
		text = "JOGAR\n⚡ bônus ativo"
	else:
		text = "JOGAR\nsem bônus de energia"


func _on_currency_changed(kind: String, _value: int) -> void:
	if kind == "energy":
		_refresh()


func _on_press() -> void:
	EventBus.sfx("select", 0.8)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08)
	t.tween_property(self, "scale", Vector2(1.00, 1.00), 0.12)
	start_pressed.emit()
