extends Button

## Baú diário de verdade: 23h de espera, sequência crescente de recompensa.

signal chest_pressed

var _refresh_timer: float = 0.0


func _ready() -> void:
	pressed.connect(_on_press)
	_refresh()


func _process(delta: float) -> void:
	_refresh_timer -= delta
	if _refresh_timer <= 0.0:
		_refresh_timer = 1.0
		_refresh()


func _refresh() -> void:
	var streak: int = int(SaveSystem.get_value("daily_streak", 0))
	if ProgressionManager.daily_available():
		disabled = false
		modulate = Color(1, 1, 1, 1)
		text = "🎁\nBaú diário!"
		tooltip_text = "Sequência atual: %d dia(s)" % streak
	else:
		disabled = true
		modulate = Color(0.65, 0.63, 0.72, 1)
		var remaining: int = ProgressionManager.seconds_to_daily()
		text = "📦\n%02dh %02dm" % [int(remaining / 3600.0), int(fmod(remaining / 60.0, 60.0))]
		tooltip_text = "Volta amanhã pra manter a sequência (%d dias)" % streak


func _on_press() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.92, 0.92), 0.07)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chest_pressed.emit()
	_refresh()
