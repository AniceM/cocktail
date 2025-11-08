extends Node
## Manages player progression state and unlocks
## This is the "player data" - what the player has access to

# Signals for when items are unlocked
signal liquor_unlocked(liquor: Liquor)
signal glass_unlocked(glass: GlassType)
signal special_ingredient_unlocked(ingredient: SpecialIngredient)
signal signature_discovered(signature: Signature)

# Unlocked items (stored as names for save/load compatibility)
var unlocked_liquor_names: Array[String] = []
var unlocked_glass_names: Array[String] = []
var unlocked_ingredient_names: Array[String] = []
var discovered_signature_names: Array[String] = []

func _ready() -> void:
	# Wait for GameDataRegistry to load first
	_unlock_everything()

# Temporary: Unlock everything until save/load is implemented
func _unlock_everything() -> void:
	for liquor in GameDataRegistry.all_liquors:
		unlocked_liquor_names.append(liquor.name)

	for glass in GameDataRegistry.all_glasses:
		unlocked_glass_names.append(glass.name)

	for ingredient in GameDataRegistry.all_special_ingredients:
		unlocked_ingredient_names.append(ingredient.name)

	for signature in GameDataRegistry.all_signatures:
		discovered_signature_names.append(signature.name)

	print("Player progression initialized (everything unlocked for testing)")

# Query methods - UI should use these
func get_liquors() -> Array[Liquor]:
	print("Unlocked liquors:", unlocked_liquor_names)
	return GameDataRegistry.all_liquors.filter(
		func(liquor): return liquor.name in unlocked_liquor_names
	)

func get_glasses() -> Array[GlassType]:
	return GameDataRegistry.all_glasses.filter(
		func(glass): return glass.name in unlocked_glass_names
	)

func get_special_ingredients() -> Array[SpecialIngredient]:
	return GameDataRegistry.all_special_ingredients.filter(
		func(ingredient): return ingredient.name in unlocked_ingredient_names
	)

func get_signatures() -> Array[Signature]:
	return GameDataRegistry.all_signatures.filter(
		func(signature): return signature.name in discovered_signature_names
	)

# Check methods
func is_liquor_unlocked(liquor: Liquor) -> bool:
	return liquor.name in unlocked_liquor_names

func is_glass_unlocked(glass: GlassType) -> bool:
	return glass.name in unlocked_glass_names

func is_special_ingredient_unlocked(ingredient: SpecialIngredient) -> bool:
	return ingredient.name in unlocked_ingredient_names

func is_signature_discovered(signature: Signature) -> bool:
	return signature.name in discovered_signature_names

# Unlock methods - called by game events
func unlock_liquor(liquor_name: String) -> void:
	if liquor_name in unlocked_liquor_names:
		return

	unlocked_liquor_names.append(liquor_name)
	var liquor = GameDataRegistry.get_liquor(liquor_name)
	if liquor:
		liquor_unlocked.emit(liquor)

func unlock_glass(glass_name: String) -> void:
	if glass_name in unlocked_glass_names:
		return

	unlocked_glass_names.append(glass_name)
	var glass = GameDataRegistry.get_glass(glass_name)
	if glass:
		glass_unlocked.emit(glass)

func unlock_special_ingredient(ingredient_name: String) -> void:
	if ingredient_name in unlocked_ingredient_names:
		return

	unlocked_ingredient_names.append(ingredient_name)
	var ingredient = GameDataRegistry.get_special_ingredient(ingredient_name)
	if ingredient:
		special_ingredient_unlocked.emit(ingredient)

func discover_signature(signature_name: String) -> void:
	if signature_name in discovered_signature_names:
		return

	discovered_signature_names.append(signature_name)
	var signature = GameDataRegistry.get_signature(signature_name)
	if signature:
		signature_discovered.emit(signature)

# Save/load methods (to be implemented later)
func get_save_data() -> Dictionary:
	return {
		"unlocked_liquors": unlocked_liquor_names,
		"unlocked_glasses": unlocked_glass_names,
		"unlocked_ingredients": unlocked_ingredient_names,
		"discovered_signatures": discovered_signature_names,
	}

func load_save_data(data: Dictionary) -> void:
	unlocked_liquor_names = data.get("unlocked_liquors", [])
	unlocked_glass_names = data.get("unlocked_glasses", [])
	unlocked_ingredient_names = data.get("unlocked_ingredients", [])
	discovered_signature_names = data.get("discovered_signatures", [])
