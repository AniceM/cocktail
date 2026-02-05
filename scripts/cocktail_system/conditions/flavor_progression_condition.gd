class_name FlavorProgressionCondition
extends CocktailCondition

## Checks for a flavor value pattern across layers.

enum Progression {
	SAME_DOMINANT, ## Same flavor dominant in all layers
	CRESCENDO, ## Flavor value increases bottom → top
	DECRESCENDO, ## Flavor value decreases bottom → top
	CONSTANT ## Flavor stays roughly the same across layers
}

@export var flavor: Flavor = null
@export var progression: Progression = Progression.SAME_DOMINANT
@export var constant_tolerance: int = 1


func is_met(cocktail: Cocktail) -> bool:
	if cocktail.layers.size() < 2:
		return false
	if flavor == null:
		return false

	match progression:
		Progression.SAME_DOMINANT:
			return _check_same_dominant(cocktail)
		Progression.CRESCENDO:
			return _check_crescendo(cocktail)
		Progression.DECRESCENDO:
			return _check_decrescendo(cocktail)
		Progression.CONSTANT:
			return _check_constant(cocktail)

	return false


func _check_same_dominant(cocktail: Cocktail) -> bool:
	for layer in cocktail.layers:
		var dominant := layer.flavor_stats.get_dominant_flavor()
		if dominant != flavor:
			return false
	return true


func _check_crescendo(cocktail: Cocktail) -> bool:
	var prev_value := -1
	for layer in cocktail.layers:
		var current_value := layer.flavor_stats.get_value(flavor)
		if current_value <= prev_value:
			return false
		prev_value = current_value
	return true


func _check_decrescendo(cocktail: Cocktail) -> bool:
	var prev_value := 999
	for layer in cocktail.layers:
		var current_value := layer.flavor_stats.get_value(flavor)
		if current_value >= prev_value:
			return false
		prev_value = current_value
	return true


func _check_constant(cocktail: Cocktail) -> bool:
	if cocktail.layers.is_empty():
		return false

	var first_value := cocktail.layers[0].flavor_stats.get_value(flavor)
	for i in range(1, cocktail.layers.size()):
		var current_value := cocktail.layers[i].flavor_stats.get_value(flavor)
		if abs(current_value - first_value) > constant_tolerance:
			return false
	return true
