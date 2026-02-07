extends Control

const CocktailConditionContainer = preload("uid://ch8605xklis8s")

@onready var _conditions_container: VBoxContainer = %ConditionsContainer


func _ready() -> void:
	# Listen to customer order changes
	GameSession.customer_order_changed.connect(_on_customer_order_changed)

	# Initial display
	_update_display()


func _on_customer_order_changed(_conditions: Array[CocktailCondition]) -> void:
	_update_display()


func _update_display() -> void:
	if not is_node_ready():
		return

	# Clear existing condition containers
	for child in _conditions_container.get_children():
		child.queue_free()

	# Create new containers for each condition
	for condition in GameSession.customer_order:
		var container = CocktailConditionContainer.instantiate()
		_conditions_container.add_child(container)
		container.cocktail_condition = condition
