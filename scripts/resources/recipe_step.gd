class_name RecipeStep
extends Resource

## A single step in a cocktail recipe, or a recorded action in the cocktail's history.

enum Action {
	ADD_LIQUOR,
	MIX,
	ADD_SPECIAL_INGREDIENT
}

@export var action: Action = Action.ADD_LIQUOR
@export var liquor: Liquor = null ## Used when action == ADD_LIQUOR
@export var special_ingredient: SpecialIngredient = null ## Used when action == ADD_SPECIAL_INGREDIENT
