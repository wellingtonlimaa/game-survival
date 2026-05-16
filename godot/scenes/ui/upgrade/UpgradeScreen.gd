extends Control

signal choice_made(choice: Dictionary)
signal reroll_pressed
signal banish_pressed(choice: Dictionary)

const UPGRADE_CARD_SCENE := preload("res://scenes/ui/upgrade/UpgradeCard.tscn")

@onready var cards_row: Container = %CardsRow
@onready var title_label: Label = %TitleLabel
@onready var reroll_button: Button = %RerollButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	reroll_button.pressed.connect(func(): reroll_pressed.emit())


func setup(choices: Array, rerolls_left: int, banishes_left: int, is_chest: bool = false) -> void:
	title_label.text = "BAÚ ANCESTRAL" if is_chest else "VOCÊ EVOLUIU!"
	for child in cards_row.get_children():
		child.queue_free()
	for choice in choices:
		var card := UPGRADE_CARD_SCENE.instantiate()
		cards_row.add_child(card)
		card.setup(choice)
		card.set_banish_visible(banishes_left > 0)
		card.selected.connect(_on_card_selected)
		card.banish_requested.connect(_on_card_banish)
	status_label.text = "Re-rolls: %d   ·   Banimentos: %d" % [rerolls_left, banishes_left]
	reroll_button.disabled = rerolls_left <= 0


func _on_card_selected(choice: Dictionary) -> void:
	choice_made.emit(choice)


func _on_card_banish(choice: Dictionary) -> void:
	banish_pressed.emit(choice)
