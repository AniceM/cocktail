class_name Signature
extends Resource

@export var name: String = ""
@export var icon: Texture2D
@export_multiline var condition_description: String = ""
@export_multiline var effect_description: String = ""

# Conditions
@export var conditions: Array[CocktailCondition] = []

# Effects
@export var boosted_secret_types: Array[SecretType] = []
@export var suspicion_modifier: int = 0
@export var reveal_bonus_percent: int = 0

# Glow
const GLOW_BASE_COLOR := Color(1.0, 0.85, 0.4)


# ============================================================================
# Validation
# ============================================================================

## Returns true if the given cocktail satisfies all conditions.
func is_met(cocktail: Cocktail) -> bool:
	if conditions.is_empty():
		push_warning("Signature '%s' has no conditions; treating as not met." % name)
		return false
	for condition in conditions:
		if not condition.is_met(cocktail):
			return false
	return true


# ============================================================================
# Glow Color
# ============================================================================

## Returns a color suitable for glow effects, inferred from signature conditions.
## Rare signatures (all three condition types) get special treatment.
## Priority: rare > color requirements > progression flavor > flavor requirements.
## The color is brightened/intensified for better glow visibility.
func get_glow_color() -> Color:
	var base_color: Color

	var color_cond := _get_condition(ColorCondition) as ColorCondition
	var prog_cond := _get_condition(FlavorProgressionCondition) as FlavorProgressionCondition
	var flavor_cond := _get_condition(FlavorCondition) as FlavorCondition

	if color_cond and prog_cond and flavor_cond:
		# Rare: has color, progression, AND flavor requirements
		base_color = _get_rare_color()
	elif color_cond:
		base_color = _color_from_color_condition(color_cond)
	elif prog_cond:
		base_color = prog_cond.flavor.color if prog_cond.flavor else GLOW_BASE_COLOR
	elif flavor_cond:
		base_color = _color_from_flavor_condition(flavor_cond)
	else:
		base_color = GLOW_BASE_COLOR

	return _intensify_for_glow(base_color)


func _get_condition(type: Variant) -> CocktailCondition:
	for condition in conditions:
		if is_instance_of(condition, type):
			return condition
	return null


func _color_from_flavor_condition(cond: FlavorCondition) -> Color:
	if cond.min_flavors.is_empty():
		return GLOW_BASE_COLOR

	if cond.min_flavors.size() == 1:
		var flavor: Flavor = cond.min_flavors.keys()[0]
		return flavor.color if flavor else GLOW_BASE_COLOR

	# Blend all required flavor colors
	var colors: Array[Color] = []
	for flavor: Flavor in cond.min_flavors.keys():
		if flavor:
			colors.append(flavor.color)
	return ColorUtils.blend_colors(colors) if not colors.is_empty() else GLOW_BASE_COLOR


func _color_from_color_condition(cond: ColorCondition) -> Color:
	if cond.required_color_names.is_empty():
		return GLOW_BASE_COLOR

	var colors: Array[Color] = []
	for color_name in cond.required_color_names:
		colors.append(ColorUtils.color_name_to_color(color_name))
	return ColorUtils.blend_colors(colors)


func _get_rare_color() -> Color:
	# Rare signatures get a special iridescent purple/gold
	return Color(0.8, 0.6, 1.0) # Soft purple


func _intensify_for_glow(color: Color) -> Color:
	# Create an HDR glow color - values above 1.0 create intense bloom
	# First normalize to a bright version of the color
	var h := color.h
	var s := clampf(color.s, 0.4, 0.9) # Keep saturation visible
	var v := 1.0

	var bright := Color.from_hsv(h, s, v, 1.0)

	# Push into HDR range for intensity (multiply by > 1.0)
	var intensity := 1.5
	return Color(bright.r * intensity, bright.g * intensity, bright.b * intensity, 1.0)
