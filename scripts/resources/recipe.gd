class_name Recipe
extends Resource

## A specific cocktail defined as an ordered sequence of steps.

@export var name: String = ""
@export var icon: Texture2D
@export_multiline var description: String = ""

## The required glass type for this recipe. Null means any glass.
@export var required_glass: GlassType = null

## Ordered sequence of steps to make this recipe.
@export var steps: Array[RecipeStep] = []


## Check if a cocktail's action history matches this recipe exactly.
func matches(cocktail: Cocktail) -> bool:
	if required_glass != null and cocktail.glass != required_glass:
		return false

	if cocktail.action_history.size() != steps.size():
		return false

	for i in range(steps.size()):
		if not _steps_match(cocktail.action_history[i], steps[i]):
			return false

	return true


## Returns how many consecutive steps match from the start.
## Useful for showing recipe progress in UI.
func get_progress(cocktail: Cocktail) -> int:
	if required_glass != null and cocktail.glass != required_glass:
		return 0

	var matched := 0
	var limit := mini(cocktail.action_history.size(), steps.size())

	for i in range(limit):
		if _steps_match(cocktail.action_history[i], steps[i]):
			matched += 1
		else:
			break

	return matched


func _steps_match(actual: RecipeStep, expected: RecipeStep) -> bool:
	if actual.action != expected.action:
		return false

	match actual.action:
		RecipeStep.Action.ADD_LIQUOR:
			return actual.liquor == expected.liquor
		RecipeStep.Action.ADD_SPECIAL_INGREDIENT:
			return actual.special_ingredient == expected.special_ingredient
		RecipeStep.Action.MIX:
			return true

	return false
