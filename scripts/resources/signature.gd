class_name Signature
extends Resource

enum SignatureType {
	SINGLE_FLAVOR,
	MULTI_FLAVOR,
	COLOR_BASED,
	RARE
}

@export var name: String = ""
@export var icon: Texture2D
@export var signature_type: SignatureType = SignatureType.SINGLE_FLAVOR
@export_multiline var condition_description: String = ""
@export_multiline var effect_description: String = ""

# For detection logic (you'll implement this later)
@export var required_flavors: Dictionary[Flavor, int] = {} # Flavor -> min_value
@export var required_layers: int = 0
@export var required_color_sequence: Array[Color] = []

# Effects
@export var boosted_secret_types: Array[SecretType] = []
@export var suspicion_modifier: int = 0
@export var reveal_bonus_percent: int = 0