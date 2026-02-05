class_name FlavorCondition
extends CocktailCondition

## Checks if the cocktail's total flavor stats meet minimum and/or maximum thresholds.

@export var min_flavors: Dictionary[Flavor, int] = {}
@export var max_flavors: Dictionary[Flavor, int] = {}


func is_met(cocktail: Cocktail) -> bool:
	for flavor in min_flavors:
		if cocktail.flavor_stats.get_value(flavor) < min_flavors[flavor]:
			return false

	for flavor in max_flavors:
		if cocktail.flavor_stats.get_value(flavor) > max_flavors[flavor]:
			return false

	return true
