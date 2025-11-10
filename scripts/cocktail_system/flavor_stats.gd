class_name FlavorStats
extends RefCounted

# Every flavor has a value that goes from -inf to 10 (clamped)
var stats: Dictionary = {} # Flavor -> int

func _init() -> void:
	# Initialize with all flavors at 0
	for flavor in get_all_flavors():
		stats[flavor] = 0

func get_value(flavor: Flavor) -> int:
	return stats.get(flavor, 0)

func set_value(flavor: Flavor, value: int) -> void:
	stats[flavor] = min(value, 10)

func add_value(flavor: Flavor, amount: int) -> void:
	stats[flavor] = min(stats.get(flavor, 0) + amount, 10)

func add_stats(other_stats: FlavorStats) -> void:
	for flavor in other_stats.stats:
		add_value(flavor, other_stats.get_value(flavor))

func get_dominant_flavor() -> Flavor:
	var max_value = -999999
	var dominant = null
	for flavor in stats:
		if stats[flavor] > max_value:
			max_value = stats[flavor]
			dominant = flavor
	return dominant

func get_all_flavors() -> Array[Flavor]:
	# TODO: Load from a global registry or preload
	return []

func duplicate_stats() -> FlavorStats:
	var new_stats = FlavorStats.new()
	for flavor in stats:
		new_stats.set_value(flavor, stats[flavor])
	return new_stats