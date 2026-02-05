class_name CocktailCondition
extends Resource

## Base class for all cocktail conditions.
## Subclasses implement is_met() to check if a cocktail satisfies the condition.

@export_multiline var description: String = ""


## Returns true if the given cocktail satisfies this condition.
func is_met(_cocktail: Cocktail) -> bool:
	push_error("CocktailCondition.is_met() not implemented in base class")
	return false
