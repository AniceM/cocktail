extends Control

signal add_liquor(liquor: Liquor)

const AddLiquorButtonScene = preload("uid://33qrbtnnfjbg")

@onready var _add_liquor_list: VBoxContainer = %AddLiquorList
@onready var _scroll_container: ScrollContainer = %ScrollContainer


func _ready() -> void:
	_populate_liquors()


func _populate_liquors() -> void:
	for child in _add_liquor_list.get_children():
		child.queue_free()

	for liquor in PlayerProgression.get_liquors():
		var button = AddLiquorButtonScene.instantiate()
		button.liquor = liquor
		button.pressed.connect(_on_add_liquor_button_pressed.bind(liquor))
		_add_liquor_list.add_child(button)

# Switch buttons to disabled/enabled
func set_disabled(disabled: bool = true) -> void:
	for child in _add_liquor_list.get_children():
		if child is Button:
			child.disabled = disabled

func _on_add_liquor_button_pressed(liquor: Liquor) -> void:
	add_liquor.emit(liquor)


func reset_scroll() -> void:
	_scroll_container.scroll_vertical = 0
	_scroll_container.scroll_horizontal = 0