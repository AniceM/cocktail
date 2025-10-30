class_name Liquor
extends Resource

@export var name: String = ""
@export var icon: Texture2D
@export var color: Color = Color.WHITE
@export_multiline var description: String = ""

# Flavor statistics
@export var caustic: int = 0
@export var volatile: int = 0
@export var resonant: int = 0
@export var drift: int = 0
@export var temporal: int = 0
@export var abyss: int = 0

# Convert to FlavorStats for easy manipulation
func get_flavor_stats() -> FlavorStats:
	var stats = FlavorStats.new()
	stats.set_value(FlavorRegistry.CAUSTIC, caustic)
	stats.set_value(FlavorRegistry.VOLATILE, volatile)
	stats.set_value(FlavorRegistry.RESONANT, resonant)
	stats.set_value(FlavorRegistry.DRIFT, drift)
	stats.set_value(FlavorRegistry.TEMPORAL, temporal)
	stats.set_value(FlavorRegistry.ABYSS, abyss)
	return stats