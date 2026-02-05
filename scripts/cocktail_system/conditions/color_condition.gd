class_name ColorCondition
extends CocktailCondition

## Checks for color patterns across layers.

enum Requirement {
	GRADIENT, ## Smooth transition toward target color
	ALTERNATING, ## Layers alternate between colors
	MONOCHROME, ## All layers same/similar color
	SPECIFIC_SEQUENCE ## Exact color order
}

@export var requirement: Requirement = Requirement.MONOCHROME
@export var required_color_names: Array[ColorUtils.ColorName] = []


func is_met(cocktail: Cocktail) -> bool:
	match requirement:
		Requirement.GRADIENT:
			return _check_gradient(cocktail)
		Requirement.ALTERNATING:
			return _check_alternating(cocktail)
		Requirement.MONOCHROME:
			return _check_monochrome(cocktail)
		Requirement.SPECIFIC_SEQUENCE:
			return _check_specific_sequence(cocktail)

	return false


func _check_gradient(cocktail: Cocktail) -> bool:
	if required_color_names.size() != 1:
		push_error("GRADIENT requires exactly 1 color")
		return false
	if cocktail.layers.size() < 2:
		return false

	var layer_colors: Array[Color] = []
	for layer in cocktail.layers:
		layer_colors.append(layer.color)

	return ColorUtils.is_gradient_toward(layer_colors, required_color_names[0])


func _check_alternating(cocktail: Cocktail) -> bool:
	if required_color_names.size() != 2:
		push_error("ALTERNATING requires exactly 2 colors")
		return false
	if cocktail.layers.size() < 2:
		return false

	for i in range(cocktail.layers.size()):
		var layer_color := cocktail.layers[i].color
		var expected_color_name := required_color_names[0] if i % 2 == 0 else required_color_names[1]
		if not ColorUtils.matches_color_name(layer_color, expected_color_name):
			return false

	return true


func _check_monochrome(cocktail: Cocktail) -> bool:
	if required_color_names.size() != 1:
		push_error("MONOCHROME requires exactly 1 color")
		return false

	for layer in cocktail.layers:
		if not ColorUtils.matches_color_name(layer.color, required_color_names[0]):
			return false
	return true


func _check_specific_sequence(cocktail: Cocktail) -> bool:
	if required_color_names.is_empty():
		push_error("SPECIFIC_SEQUENCE requires at least 1 color")
		return false
	if cocktail.layers.size() != required_color_names.size():
		return false

	for i in range(cocktail.layers.size()):
		var layer_color := cocktail.layers[i].color
		if not ColorUtils.matches_color_name(layer_color, required_color_names[i]):
			return false

	return true
