extends PanelContainer

# Preload the liquor panel
const AddLiquorButton = preload("uid://33qrbtnnfjbg")

# List of liquors that can be added
@onready var add_liquor_list: VBoxContainer = %AddLiquorList

func _ready() -> void:
	# Remove the fake liquor list and replace it with the real one
	for child in add_liquor_list.get_children():
		child.queue_free()
	for liquor in CocktailData.liquors:
		var add_liquor_button = AddLiquorButton.instantiate()
		add_liquor_button.liquor = liquor
		# liquor_panel.liquor = liquor
		add_liquor_list.add_child(add_liquor_button)
