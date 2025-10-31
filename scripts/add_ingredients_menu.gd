extends Control

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
		var add_liquor_button = AddLiquorButton.instantiate()
		add_liquor_button.liquor = liquor
		# liquor_panel.liquor = liquor
		add_liquor_list.add_child(add_liquor_button)

	# Connect the scroll event to _on_scroll
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll)

func _on_scroll(value: float) -> void:
	var v_scroll_bar = scroll_container.get_v_scroll_bar()
	if value == v_scroll_bar.max_value - v_scroll_bar.page:
		down_arrow.hide()
	else:
		down_arrow.show()
