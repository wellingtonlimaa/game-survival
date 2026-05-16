extends Control

signal option_selected(option: String)

@onready var toggle_button: Button = %ToggleButton
@onready var popup_panel: PanelContainer = %PopupPanel
@onready var settings_btn: Button = %SettingsButton
@onready var mail_btn: Button = %MailButton
@onready var announce_btn: Button = %AnnounceButton
@onready var settings_badge: Control = %SettingsBadge
@onready var mail_badge: Control = %MailBadge
@onready var announce_badge: Control = %AnnounceBadge

var _open := false


func _ready() -> void:
	popup_panel.visible = false
	popup_panel.modulate.a = 0.0
	popup_panel.scale = Vector2(0.85, 0.85)

	toggle_button.pressed.connect(_toggle)
	settings_btn.pressed.connect(func(): _emit("settings"))
	mail_btn.pressed.connect(func(): _emit("mail"))
	announce_btn.pressed.connect(func(): _emit("announce"))

	EventBus.mail_received.connect(refresh_badges)
	EventBus.announcement_received.connect(refresh_badges)
	refresh_badges()


func refresh_badges() -> void:
	settings_badge.visible = false
	mail_badge.visible = bool(SaveSystem.get_value("has_mail", false))
	announce_badge.visible = bool(SaveSystem.get_value("has_announcement", false))
	# Notification dot no botão toggle se algo pendente
	%ToggleBadge.visible = mail_badge.visible or announce_badge.visible


func _toggle() -> void:
	_open = not _open
	if _open:
		popup_panel.visible = true
		var tween := create_tween().set_parallel(true)
		tween.tween_property(popup_panel, "modulate:a", 1.0, 0.15)
		tween.tween_property(popup_panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(popup_panel, "modulate:a", 0.0, 0.12)
		tween.tween_property(popup_panel, "scale", Vector2(0.85, 0.85), 0.12)
		tween.finished.connect(func(): popup_panel.visible = false)


func _emit(opt: String) -> void:
	_toggle()
	option_selected.emit(opt)
