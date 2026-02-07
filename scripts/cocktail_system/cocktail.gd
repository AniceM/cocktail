class_name Cocktail
extends RefCounted

# Type of glass the cocktail is served in
# Some glasses can hold more liquors than others
# Some glasses have special effects
var glass: GlassType

# Current layers currently in the cocktail
# A layer is a collection of liquors mixed together
var layers: Array[CocktailLayer] = []

# Total number of liquors poured (doesn't change when mixing)
var liquors_poured: int = 0

# Special ingredient added to the cocktail, if any
var special_ingredient: SpecialIngredient = null

# List of signatures unlocked by the current composition of the cocktail
var signatures: Array[Signature] = []

# Cached flavor stats calculation (sum of all liquors' stats + special ingredient + glass bonuses)
var flavor_stats: FlavorStats = FlavorStats.new()

# Ordered history of actions performed on this cocktail (for recipe matching)
var action_history: Array[RecipeStep] = []

func _init(glass_type: GlassType) -> void:
	glass = glass_type
	_recalculate_flavor_stats()

func reset() -> void:
	layers.clear()
	liquors_poured = 0
	special_ingredient = null
	signatures.clear()
	action_history.clear()
	_recalculate_flavor_stats()

# Add a liquor to the cocktail
# Returns [success, is_new_layer]
func add_liquor(liquor: Liquor) -> Array[bool]:
	if liquors_poured >= glass.capacity:
		Log.msg(self, "Glass is full!")
		return [false, false]

	liquors_poured += 1
	_record_action(RecipeStep.Action.ADD_LIQUOR, liquor, null)

	# If the liquor is different from the last one, create a new layer
	if layers.size() == 0 or !layers[-1].is_unique_liquor(liquor):
		var new_layer = CocktailLayer.new()
		layers.append(new_layer)
		new_layer.add_liquor(liquor)
		Log.msg(self, "Adding liquor: %s to new layer" % liquor.name)
		_recalculate_flavor_stats()
		return [true, true]
	else:
		layers[-1].add_liquor(liquor)
		Log.msg(self, "Adding liquor: %s to last layer" % liquor.name)
		_recalculate_flavor_stats()
		return [true, false]

func mix() -> bool:
	# Need at least 2 layers to mix
	if layers.size() <= 1:
		return false

	# Combine all layers into one
	var combined_layer = CocktailLayer.new()

	for layer in layers:
		# Add all liquors from each layer
		for liquor in layer.liquors:
			combined_layer.add_liquor(liquor)

	# Replace all layers with the single combined layer
	layers.clear()
	layers.append(combined_layer)
	_recalculate_flavor_stats()
	_record_action(RecipeStep.Action.MIX, null, null)
	return true

func add_special_ingredient(ingredient: SpecialIngredient) -> bool:
	special_ingredient = ingredient
	_recalculate_flavor_stats()
	# Only 1 special ingredient allowed
	if action_history.size() > 0 and action_history[-1].action == RecipeStep.Action.ADD_SPECIAL_INGREDIENT:
		action_history.pop_back()
	_record_action(RecipeStep.Action.ADD_SPECIAL_INGREDIENT, null, ingredient)
	return true

func is_full() -> bool:
	return liquors_poured >= glass.capacity

func _recalculate_flavor_stats() -> void:
	flavor_stats = FlavorStats.new()
	# Add all layers
	for layer in layers:
		flavor_stats.add_stats(layer.flavor_stats)

	# Add special ingredient
	if special_ingredient:
		flavor_stats.add_stats(special_ingredient.get_flavor_stats())

	# Apply glass bonuses
	_apply_glass_bonuses()

func _apply_glass_bonuses() -> void:
	match glass.bonus_type:
		GlassType.BonusType.AMPLIFY_DOMINANT:
			var dominant = flavor_stats.get_dominant_flavor()
			if dominant:
				flavor_stats.add_value(dominant, 2)
		GlassType.BonusType.DOUBLE_STATS:
			for flavor in flavor_stats.stats:
				flavor_stats.set_value(flavor, flavor_stats.get_value(flavor) * 2)
		# Add more cases as needed

func detect_signatures() -> void:
	signatures = []
	for sig in GameDataRegistry.all_signatures:
		if sig.is_met(self):
			signatures.append(sig)

func get_reveal_rate(secret_type: SecretType) -> float:
	var base_rate = 0.0

	# Check which flavors boost this secret type
	for flavor in flavor_stats.stats:
		if flavor.boosted_secret_types.has(secret_type):
			base_rate += flavor_stats.get_value(flavor) * 0.1 # 10% per point

	# Apply signature bonuses
	for sig in signatures:
		if sig.boosted_secret_types.has(secret_type):
			base_rate += sig.reveal_bonus_percent / 100.0

	return clamp(base_rate, 0.0, 1.0)


func _record_action(action: RecipeStep.Action, liquor: Liquor, ingredient: SpecialIngredient) -> void:
	var step := RecipeStep.new()
	step.action = action
	step.liquor = liquor
	step.special_ingredient = ingredient
	action_history.append(step)
