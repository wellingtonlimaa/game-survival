extends Control

signal resume_pressed
signal back_to_menu_pressed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	%ResumeButton.pressed.connect(_on_resume)
	%MenuButton.pressed.connect(_on_back_to_menu)

	%MusicSlider.value = float(SaveSystem.get_value("music_volume", 0.5))
	%SfxSlider.value = float(SaveSystem.get_value("sfx_volume", 0.8))
	%MuteCheckbox.button_pressed = bool(SaveSystem.get_value("muted", false))

	%MusicSlider.value_changed.connect(_on_music_changed)
	%SfxSlider.value_changed.connect(_on_sfx_changed)
	%MuteCheckbox.toggled.connect(_on_mute_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause"):
		get_viewport().set_input_as_handled()
		_on_resume()


func _on_resume() -> void:
	resume_pressed.emit()


func _on_back_to_menu() -> void:
	back_to_menu_pressed.emit()


func _on_music_changed(v: float) -> void:
	AudioManager.set_music_volume(v)


func _on_sfx_changed(v: float) -> void:
	AudioManager.set_sfx_volume(v)


func _on_mute_toggled(p: bool) -> void:
	AudioManager.set_muted(p)
