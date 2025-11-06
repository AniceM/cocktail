extends Node

var liquors: Array[Liquor] = []
var glasses: Array[GlassType] = []
var signatures: Array[Signature] = []
var special_ingredients: Array[SpecialIngredient] = []
var secret_types: Array[SecretType] = []

func _ready() -> void:
	load_all_data()

func load_all_data() -> void:
	load_resources("res://data/liquors/", liquors)
	load_resources("res://data/glasses/", glasses)
	load_resources("res://data/signatures/", signatures)
	load_resources("res://data/special_ingredients/", special_ingredients)
	
	print("Cocktail data loaded:")
	print("  - %d liquors" % liquors.size())
	print("  - %d glasses" % glasses.size())
	print("  - %d signatures" % signatures.size())
	print("  - %d special ingredients" % special_ingredients.size())

func load_resources(path: String, target_array: Array) -> void:
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