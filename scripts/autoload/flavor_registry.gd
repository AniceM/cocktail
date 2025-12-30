extends Node

# Preload all flavor resources
var CAUSTIC: Flavor = preload("uid://dqq43sfhndaps")
var VOLATILE: Flavor = preload("uid://b6nuv127qfro5")
var RESONANT: Flavor = preload("uid://b6uqt6sgi44nl")
var DRIFT: Flavor = preload("uid://ch4po4u8501bh")
var TEMPORAL: Flavor = preload("uid://coifug6hj7rfw")
var ABYSS: Flavor = preload("uid://dqfbs2lug8qb3")

func get_all_flavors() -> Array[Flavor]:
	return [CAUSTIC, VOLATILE, RESONANT, DRIFT, TEMPORAL, ABYSS]

func get_flavor_by_name(flavor_name: String) -> Flavor:
	for flavor in get_all_flavors():
		if flavor.name == flavor_name:
			return flavor
	return null
