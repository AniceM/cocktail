extends Node
## Manages ephemeral session state during gameplay
## This holds temporary data that exists between scenes but is not saved

# Current session state (not saved, resets on game restart)
signal current_cocktail_changed(cocktail: Cocktail)
signal current_cocktail_updated(cocktail: Cocktail)
signal customer_order_changed(conditions: Array[CocktailCondition])

var current_cocktail: Cocktail = null
var customer_order: Array[CocktailCondition] = []
var current_character = null  # TODO: Type this when Character class exists
var current_chapter = null  # TODO: Type this when Chapter class exists

func set_current_cocktail(cocktail: Cocktail) -> void:
	if cocktail == current_cocktail:
		return
	current_cocktail = cocktail
	current_cocktail_changed.emit(current_cocktail)


func clear_current_cocktail() -> void:
	set_current_cocktail(null)


func notify_cocktail_updated() -> void:
	if current_cocktail == null:
		return
	current_cocktail_updated.emit(current_cocktail)


func set_customer_order(conditions: Array[CocktailCondition]) -> void:
	customer_order = conditions
	customer_order_changed.emit(customer_order)


func clear_customer_order() -> void:
	set_customer_order([])


func are_all_conditions_met() -> bool:
	if current_cocktail == null:
		return false
	if customer_order.is_empty():
		return true
	return customer_order.all(func(condition): return condition.is_met(current_cocktail))


# Helper to reset session (called when starting new game or returning to menu)
func reset_session() -> void:
	clear_current_cocktail()
	clear_customer_order()
	current_character = null
	current_chapter = null
