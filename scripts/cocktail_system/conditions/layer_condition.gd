class_name LayerCondition
extends CocktailCondition

## Checks if the number of layers falls within a range.

@export var min_layers: int = 0
@export var max_layers: int = 999


func is_met(cocktail: Cocktail) -> bool:
	var layer_count := cocktail.layers.size()
	return layer_count >= min_layers and layer_count <= max_layers
