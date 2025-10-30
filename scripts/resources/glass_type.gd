# scripts/resources/glass_type.gd
class_name GlassType
extends Resource

enum BonusType {
	NONE,
	AMPLIFY_DOMINANT, # Signal Glass
	BOOST_MULTI_FLAVOR, # Chronos Coupe
	BOOST_COLOR_BASED, # Aether Highball
	DOUBLE_STATS, # Singularity Shot
	TOP_LAYER_TWICE, # Eclipse Flute
	INVERT_NEGATIVES, # Graviton Snifter
	BOOST_ANOMALY_FRAGMENT # Meridian Tumbler
}

@export var name: String = ""
@export var icon: Texture2D
@export var capacity: int = 3
@export_multiline var description: String = ""
@export var bonus_type: BonusType = BonusType.NONE
# @export_multiline var bonus_description: String = ""
@export var suspicion_bonus: int = 0 # Extra suspicion slots

func get_bonus_description() -> String:
	match bonus_type:
		BonusType.AMPLIFY_DOMINANT:
			return "Amplifies the dominant flavor."
		BonusType.BOOST_MULTI_FLAVOR:
			return "Enhances the effect of multi-flavor signatures."
		BonusType.BOOST_COLOR_BASED:
			return "Enhances the effect of color-based signatures."
		BonusType.DOUBLE_STATS:
			return "Doubles every flavor."
		BonusType.TOP_LAYER_TWICE:
			return "The top layer's flavors are doubled."
		BonusType.INVERT_NEGATIVES:
			return "Converts negative flavors of liquors to positives."
		BonusType.BOOST_ANOMALY_FRAGMENT:
			return "Makes it easier to detect Anomalies and Fragments."
	return ""