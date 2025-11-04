class_name Cocktail
extends RefCounted

var glass: GlassType
var layers: Array[CocktailLayer] = []
var special_ingredient: SpecialIngredient = null
var signatures: Array[Signature] = []

func _init(glass_type: GlassType) -> void:
	glass = glass_type

func reset() -> void:
	layers.clear()
	special_ingredient = null
	signatures.clear()

# Add a liquor to the cocktail
# Returns [success, is_new_layer]
func add_liquor(liquor: Liquor) -> Array[bool]:
	if get_total_liquor_count() >= glass.capacity:
		print("Glass is full!")
		return [false, false]
	
	# If the liquor is different from the last one, create a new layer
	if layers.size() == 0 or !layers[-1].is_unique_liquor(liquor):
		var new_layer = CocktailLayer.new()
		layers.append(new_layer)
		new_layer.add_liquor(liquor)
		print("Adding liquor: %s to new layer" % liquor.name)
		return [true, true]
	else:
		layers[-1].add_liquor(liquor)
		print("Adding liquor: %s to last layer" % liquor.name)
		return [true, false]

func mix() -> void:
	if layers.is_empty():
		return
	
	# Combine all layers into one
	var combined_layer = CocktailLayer.new()
	
	for layer in layers:
		# Add all liquors from each layer
		for liquor in layer.liquors:
			combined_layer.add_liquor(liquor)
	
	# Replace all layers with the single combined layer
	layers.clear()
	layers.append(combined_layer)

func add_special_ingredient(ingredient: SpecialIngredient) -> bool:
	if special_ingredient != null:
		return false
	special_ingredient = ingredient
	return true

func get_total_flavor_stats() -> FlavorStats:
	var total = FlavorStats.new()
	# Add all layers
	for layer in layers:
		total.add_stats(layer.flavor_stats)
	
	# Add special ingredient
	if special_ingredient:
		total.add_stats(special_ingredient.get_flavor_stats())
	
	# Apply glass bonuses
	apply_glass_bonuses(total)
	
	return total

func apply_glass_bonuses(stats: FlavorStats) -> void:
	match glass.bonus_type:
		GlassType.BonusType.AMPLIFY_DOMINANT:
			var dominant = stats.get_dominant_flavor()
			if dominant:
				stats.add_value(dominant, 2)
		GlassType.BonusType.DOUBLE_STATS:
			for flavor in stats.stats:
				stats.set_value(flavor, stats.get_value(flavor) * 2)
		# Add more cases as needed

# func detect_signatures(signature_database: Array[Signature]) -> void:
# 	signatures.clear()
# 	for sig in signature_database:
# 		if check_signature_match(sig):
# 			signatures.append(sig)

# func check_signature_match(sig: Signature) -> bool:
# 	# Implement signature detection logic
# 	# This will check flavor thresholds, color patterns, etc.
# 	return false

func get_total_liquor_count() -> int:
	var count = 0
	for layer in layers:
		count += layer.liquors.size()
	return count

func get_reveal_rate(secret_type: SecretType) -> float:
	var stats = get_total_flavor_stats()
	var base_rate = 0.0
	
	# Check which flavors boost this secret type
	for flavor in stats.stats:
		if flavor.boosted_secret_types.has(secret_type):
			base_rate += stats.get_value(flavor) * 0.1 # 10% per point
	
	# Apply signature bonuses
	for sig in signatures:
		if sig.boosted_secret_types.has(secret_type):
			base_rate += sig.reveal_bonus_percent / 100.0
	
	return clamp(base_rate, 0.0, 1.0)
