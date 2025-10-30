extends Node

# Preload all flavor resources
var CAUSTIC: Flavor = preload("res://data/flavors/caustic.tres")
var VOLATILE: Flavor = preload("res://data/flavors/volatile.tres")
var RESONANT: Flavor = preload("res://data/flavors/resonant.tres")
var DRIFT: Flavor = preload("res://data/flavors/drift.tres")
var TEMPORAL: Flavor = preload("res://data/flavors/temporal.tres")
var ABYSS: Flavor = preload("res://data/flavors/abyss.tres")

func get_all_flavors() -> Array[Flavor]:
	return [CAUSTIC, VOLATILE, RESONANT, DRIFT, TEMPORAL, ABYSS]

func get_flavor_by_name(flavor_name: String) -> Flavor:
	for flavor in get_all_flavors():
		if flavor.name == flavor_name:
			return flavor
	return null