extends Button

signal start_pressed

@export var energy_cost: int = 5

var _pulse_tween: Tween


func _ready() -> void:
	pressed.connect(_on_press)
	EventBus.currency_changed.connect(_on_currency_changed)
	_refresh_cost()
	_start_pulse()


func _start_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
	pivot_offset = size / 2.0
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2(1.00, 1.00), 0.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _refresh_cost() -> void:
	var energy := int(SaveSystem.get_value("energy", 0))
	var enabled := energy >= energy_cost
	disabled = not enabled
	modulate = Color(1, 1, 1, 1) if enabled else Color(0.55, 0.55, 0.6, 1)
	text = "COMEÇAR\n⚡ x %d" % energy_cost


func _on_currency_changed(kind: String, _value: int) -> void:
	if kind == "energy":
		_refresh_cost()


func _on_press() -> void:
	if not SaveSystem.spend_energy(energy_cost):
		return
	# Animação de press (squash)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.95, 0.95), 0.08)
	t.tween_property(self, "scale", Vector2(1.00, 1.00), 0.12)
	start_pressed.emit()
