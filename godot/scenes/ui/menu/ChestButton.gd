extends Button

signal chest_pressed


func _ready() -> void:
	pressed.connect(_on_press)


func _on_press() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.92, 0.92), 0.07)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	chest_pressed.emit()
