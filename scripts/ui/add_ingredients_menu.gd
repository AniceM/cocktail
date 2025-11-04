extends Control

# Signals
signal add_liquor(liquor: Liquor)

# Preload the liquor panel
const AddLiquorButton = preload("uid://33qrbtnnfjbg")

# List of liquors that can be added
@onready var add_liquor_list: VBoxContainer = %AddLiquorList

# Handle scrolling
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var down_arrow: TextureRect = %DownArrow

func _ready() -> void:
	# Remove the fake liquor list and replace it with the real one
	for child in add_liquor_list.get_children():
		child.queue_free()
	for liquor in CocktailData.liquors:
		var add_liquor_button: Button = AddLiquorButton.instantiate()
		add_liquor_button.liquor = liquor
		add_liquor_button.pressed.connect(_on_add_liquor_button_pressed.bind(liquor))
		add_liquor_list.add_child(add_liquor_button)

	# Connect the scroll event to _on_scroll
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll)

# Switch buttons to disabled/enabled
func set_disabled(disabled: bool = true) -> void:
	for child in add_liquor_list.get_children():
		if child is Button:
			child.disabled = disabled

func _on_scroll(value: float) -> void:
	var v_scroll_bar = scroll_container.get_v_scroll_bar()
	if value == v_scroll_bar.max_value - v_scroll_bar.page:
		down_arrow.hide()
	else:
		down_arrow.show()

func _on_add_liquor_button_pressed(liquor: Liquor) -> void:
	add_liquor.emit(liquor)