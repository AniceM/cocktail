class_name Signature
extends Resource

enum SignatureType {
	SINGLE_FLAVOR,
	MULTI_FLAVOR,
	COLOR_BASED,
	RARE
}

enum FlavorProgression {
	NONE,
	SAME_DOMINANT, # Same flavor dominant in all/most layers
	CRESCENDO, # Flavor value increases bottom→top
	DECRESCENDO, # Flavor value decreases bottom→top
	CONSTANT # Flavor stays roughly same across layers
}

enum ColorRequirement {
	NONE,
	GRADIENT, # Smooth transition toward target color
	ALTERNATING, # Layers alternate between colors
	MONOCHROME, # All layers same/similar color
	SPECIFIC_SEQUENCE # Exact color order
}

@export var name: String = ""
@export var icon: Texture2D
@export var signature_type: SignatureType = SignatureType.SINGLE_FLAVOR
@export_multiline var condition_description: String = ""
@export_multiline var effect_description: String = ""

# Capacity requirements
@export var min_capacity: int = 0 # Minimum number of liquors poured
@export var max_capacity: int = 999 # Maximum number of liquors poured

# Layer requirements
@export var min_layers: int = 0
@export var max_layers: int = 999

# Flavor requirements
@export var min_flavors: Dictionary[Flavor, int] = {} # Flavor -> min_value
@export var max_flavors: Dictionary[Flavor, int] = {} # Flavor -> max_value (optional upper bound)

# Flavor progression across layers
@export var progression_flavor: Flavor = null # Which flavor to track
@export var flavor_progression: FlavorProgression = FlavorProgression.NONE

# Color requirements
@export var color_requirement: ColorRequirement = ColorRequirement.NONE
@export var required_color_names: Array[ColorUtils.ColorName] = []

# Effects
@export var boosted_secret_types: Array[SecretType] = []
@export var suspicion_modifier: int = 0
@export var reveal_bonus_percent: int = 0


# ============================================================================
# Glow Color
# ============================================================================

## Returns a color suitable for glow effects, based on signature type.
## The color is brightened/intensified for better glow visibility.
func get_glow_color() -> Color:
	var base_color: Color

	match signature_type:
		SignatureType.SINGLE_FLAVOR:
			base_color = _get_single_flavor_color()
		SignatureType.MULTI_FLAVOR:
			base_color = _get_multi_flavor_color()
		SignatureType.COLOR_BASED:
			base_color = _get_color_based_color()
		SignatureType.RARE:
			base_color = _get_rare_color()

	return _intensify_for_glow(base_color)


func _get_single_flavor_color() -> Color:
	# Use the first (and typically only) required flavor's color
	if min_flavors.is_empty():
		return Color(1.0, 0.85, 0.4) # Default gold

	var flavor: Flavor = min_flavors.keys()[0]
	return flavor.color if flavor else Color(1.0, 0.85, 0.4)


func _get_multi_flavor_color() -> Color:
	# Blend all required flavor colors
	if min_flavors.is_empty():
		return Color(1.0, 0.85, 0.4) # Default gold

	var colors: Array[Color] = []
	for flavor: Flavor in min_flavors.keys():
		if flavor:
			colors.append(flavor.color)

	return ColorUtils.blend_colors(colors) if not colors.is_empty() else Color(1.0, 0.85, 0.4)


func _get_color_based_color() -> Color:
	# Convert required color names to actual colors and blend them
	if required_color_names.is_empty():
		return Color(1.0, 0.85, 0.4) # Default gold

	var colors: Array[Color] = []
	for color_name in required_color_names:
		colors.append(ColorUtils.color_name_to_color(color_name))

	return ColorUtils.blend_colors(colors)


func _get_rare_color() -> Color:
	# Rare signatures get a special iridescent purple/gold
	return Color(0.8, 0.6, 1.0) # Soft purple


func _intensify_for_glow(color: Color) -> Color:
	# Create an HDR glow color - values above 1.0 create intense bloom
	# First normalize to a bright version of the color
	var h := color.h
	var s := clampf(color.s, 0.4, 0.9)  # Keep saturation visible
	var v := 1.0

	var bright := Color.from_hsv(h, s, v, 1.0)

	# Push into HDR range for intensity (multiply by > 1.0)
	var intensity := 1.5
	return Color(bright.r * intensity, bright.g * intensity, bright.b * intensity, 1.0)