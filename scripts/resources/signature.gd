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
	SAME_DOMINANT,      # Same flavor dominant in all/most layers
	CRESCENDO,          # Flavor value increases bottom→top
	DECRESCENDO,        # Flavor value decreases bottom→top
	CONSTANT            # Flavor stays roughly same across layers
}

enum ColorRequirement {
	NONE,
	GRADIENT,           # Smooth transition toward target color
	ALTERNATING,        # Layers alternate between colors
	MONOCHROME,         # All layers same/similar color
	SPECIFIC_SEQUENCE   # Exact color order
}

@export var name: String = ""
@export var icon: Texture2D
@export var signature_type: SignatureType = SignatureType.SINGLE_FLAVOR
@export_multiline var condition_description: String = ""
@export_multiline var effect_description: String = ""

# Capacity requirements
@export var min_capacity: int = 0  # Minimum number of liquors poured
@export var max_capacity: int = 999  # Maximum number of liquors poured

# Layer requirements
@export var min_layers: int = 0
@export var max_layers: int = 999

# Flavor requirements
@export var required_flavors: Dictionary[Flavor, int] = {}  # Flavor -> min_value

# Flavor progression across layers
@export var progression_flavor: Flavor = null  # Which flavor to track
@export var flavor_progression: FlavorProgression = FlavorProgression.NONE

# Color requirements
@export var color_requirement: ColorRequirement = ColorRequirement.NONE
@export var required_color_names: Array[ColorUtils.ColorName] = []

# Effects
@export var boosted_secret_types: Array[SecretType] = []
@export var suspicion_modifier: int = 0
@export var reveal_bonus_percent: int = 0