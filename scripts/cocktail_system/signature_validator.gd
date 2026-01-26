class_name SignatureValidator
extends RefCounted

# Check if a cocktail matches a signature's conditions
static func check_signature(cocktail: Cocktail, signature: Signature) -> bool:
	# Check in order of computational cost (cheapest first for early exit)
	# 1. Capacity checks
	if cocktail.liquors_poured < signature.min_capacity or cocktail.liquors_poured > signature.max_capacity:
		return false

	# 2. Layer count checks
	var layer_count = cocktail.layers.size()
	if layer_count < signature.min_layers or layer_count > signature.max_layers:
		return false

	# 3. Required flavors (check total cocktail stats)
	if not _check_required_flavors(cocktail, signature):
		return false

	# 4. Flavor progression across layers
	if signature.flavor_progression != Signature.FlavorProgression.NONE:
		if not _check_flavor_progression(cocktail, signature):
			return false

	# 5. Color requirements
	if signature.color_requirement != Signature.ColorRequirement.NONE:
		if not _check_color_requirement(cocktail, signature):
			return false

	return true

# Detect all matching signatures from the game registry
static func detect_signatures(cocktail: Cocktail) -> Array[Signature]:
	var matching: Array[Signature] = []

	for signature in GameDataRegistry.all_signatures:
		if check_signature(cocktail, signature):
			matching.append(signature)

	return matching

# Check if cocktail meets required flavor minimums
static func _check_required_flavors(cocktail: Cocktail, signature: Signature) -> bool:
	for flavor in signature.required_flavors:
		var required_value = signature.required_flavors[flavor]
		var actual_value = cocktail.flavor_stats.get_value(flavor)
		if actual_value < required_value:
			return false
	return true

# Check flavor progression patterns across layers
static func _check_flavor_progression(cocktail: Cocktail, signature: Signature) -> bool:
	if cocktail.layers.size() < 2:
		return false # Need at least 2 layers for progression

	if signature.progression_flavor == null:
		return false

	var flavor = signature.progression_flavor
	var progression = signature.flavor_progression

	match progression:
		Signature.FlavorProgression.SAME_DOMINANT:
			return _check_same_dominant_flavor(cocktail, flavor)
		Signature.FlavorProgression.CRESCENDO:
			return _check_crescendo(cocktail, flavor)
		Signature.FlavorProgression.DECRESCENDO:
			return _check_decrescendo(cocktail, flavor)
		Signature.FlavorProgression.CONSTANT:
			return _check_constant(cocktail, flavor)

	return false

# Check if the same flavor is dominant in all layers
static func _check_same_dominant_flavor(cocktail: Cocktail, flavor: Flavor) -> bool:
	for layer in cocktail.layers:
		var dominant = layer.flavor_stats.get_dominant_flavor()
		if dominant != flavor:
			return false
	return true

# Check if flavor value increases from bottom to top
static func _check_crescendo(cocktail: Cocktail, flavor: Flavor) -> bool:
	var prev_value = -1
	for layer in cocktail.layers:
		var current_value = layer.flavor_stats.get_value(flavor)
		if current_value <= prev_value:
			return false
		prev_value = current_value
	return true

# Check if flavor value decreases from bottom to top
static func _check_decrescendo(cocktail: Cocktail, flavor: Flavor) -> bool:
	var prev_value = 999
	for layer in cocktail.layers:
		var current_value = layer.flavor_stats.get_value(flavor)
		if current_value >= prev_value:
			return false
		prev_value = current_value
	return true

# Check if flavor value stays roughly constant across layers
static func _check_constant(cocktail: Cocktail, flavor: Flavor, tolerance: int = 1) -> bool:
	if cocktail.layers.is_empty():
		return false

	var first_value = cocktail.layers[0].flavor_stats.get_value(flavor)
	for i in range(1, cocktail.layers.size()):
		var current_value = cocktail.layers[i].flavor_stats.get_value(flavor)
		if abs(current_value - first_value) > tolerance:
			return false
	return true

# Check color requirements
static func _check_color_requirement(cocktail: Cocktail, signature: Signature) -> bool:
	var requirement = signature.color_requirement
	var required_colors = signature.required_color_names

	match requirement:
		Signature.ColorRequirement.GRADIENT:
			if required_colors.size() != 1:
				push_error("GRADIENT requires exactly 1 color")
				return false
			return _check_gradient(cocktail, required_colors[0])

		Signature.ColorRequirement.ALTERNATING:
			if required_colors.size() != 2:
				push_error("ALTERNATING requires exactly 2 colors")
				return false
			return _check_alternating(cocktail, required_colors[0], required_colors[1])

		Signature.ColorRequirement.MONOCHROME:
			if required_colors.size() != 1:
				push_error("MONOCHROME requires exactly 1 color")
				return false
			return _check_monochrome(cocktail, required_colors[0])

		Signature.ColorRequirement.SPECIFIC_SEQUENCE:
			if required_colors.is_empty():
				push_error("SPECIFIC_SEQUENCE requires at least 1 color")
				return false
			return _check_specific_sequence(cocktail, required_colors)

	return false

# Check if layers form a gradient toward a target color
static func _check_gradient(cocktail: Cocktail, target_color_name: ColorUtils.ColorName) -> bool:
	if cocktail.layers.size() < 2:
		return false

	var layer_colors: Array[Color] = []
	for layer in cocktail.layers:
		layer_colors.append(layer.color)

	return ColorUtils.is_gradient_toward(layer_colors, target_color_name)

# Check if layers alternate between two colors
static func _check_alternating(cocktail: Cocktail, color_name_1: ColorUtils.ColorName, color_name_2: ColorUtils.ColorName) -> bool:
	if cocktail.layers.size() < 2:
		return false

	for i in range(cocktail.layers.size()):
		var layer_color = cocktail.layers[i].color
		var expected_color_name = color_name_1 if i % 2 == 0 else color_name_2

		if not ColorUtils.matches_color_name(layer_color, expected_color_name):
			return false

	return true

# Check if all layers are the same color
static func _check_monochrome(cocktail: Cocktail, target_color_name: ColorUtils.ColorName) -> bool:
	for layer in cocktail.layers:
		if not ColorUtils.matches_color_name(layer.color, target_color_name):
			return false
	return true

# Check if layers match a specific color sequence
static func _check_specific_sequence(cocktail: Cocktail, color_names: Array[ColorUtils.ColorName]) -> bool:
	if cocktail.layers.size() != color_names.size():
		return false

	for i in range(cocktail.layers.size()):
		var layer_color = cocktail.layers[i].color
		var expected_color_name = color_names[i]

		if not ColorUtils.matches_color_name(layer_color, expected_color_name):
			return false

	return true
