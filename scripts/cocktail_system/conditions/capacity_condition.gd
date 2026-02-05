class_name CapacityCondition
extends CocktailCondition

## Checks if the number of liquors poured falls within a range.

@export var min_capacity: int = 0
@export var max_capacity: int = 999


func is_met(cocktail: Cocktail) -> bool:
	return cocktail.liquors_poured >= min_capacity and cocktail.liquors_poured <= max_capacity
