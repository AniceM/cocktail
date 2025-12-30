extends Node
## Static catalog of all game data resources
## This is the "database" - it contains everything that exists in the game

# All items that exist in the game (catalog)
var all_liquors: Array[Liquor] = []
var all_glasses: Array[GlassType] = []
var all_signatures: Array[Signature] = []
var all_special_ingredients: Array[SpecialIngredient] = []

func _ready() -> void:
	_load_all_data()

func _load_all_data() -> void:
	_load_resources("res://resources/liquors/", all_liquors)
	_load_resources("res://resources/glasses/", all_glasses)
	_load_resources("res://resources/signatures/", all_signatures)
	_load_resources("res://resources/special_ingredients/", all_special_ingredients)

	print("Game data loaded:")
	print("  - %d liquors" % all_liquors.size())
	print("  - %d glasses" % all_glasses.size())
	print("  - %d signatures" % all_signatures.size())
	print("  - %d special ingredients" % all_special_ingredients.size())

func _load_resources(path: String, target_array: Array) -> void:
	target_array.clear()
	var dir = DirAccess.open(path)
	if not dir:
		push_error("Failed to open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource = load(path + file_name)
			if resource:
				target_array.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()

# Lookup helpers
func get_liquor(liquor_name: String) -> Liquor:
	for liquor in all_liquors:
		if liquor.name == liquor_name:
			return liquor
	push_error("Liquor not found: " + liquor_name)
	return null

func get_glass(glass_name: String) -> GlassType:
	for glass in all_glasses:
		if glass.name == glass_name:
			return glass
	push_error("Glass not found: " + glass_name)
	return null

func get_special_ingredient(ingredient_name: String) -> SpecialIngredient:
	for ingredient in all_special_ingredients:
		if ingredient.name == ingredient_name:
			return ingredient
	push_error("Special ingredient not found: " + ingredient_name)
	return null

func get_signature(signature_name: String) -> Signature:
	for signature in all_signatures:
		if signature.name == signature_name:
			return signature
	push_error("Signature not found: " + signature_name)
	return null