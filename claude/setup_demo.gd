@tool
extends EditorScript

## Run this script from the editor to setup demo liquids in bottles
## Tools > Execute EditorScript

func _run() -> void:
	var scene_root = get_scene()
	if not scene_root:
		print("No scene loaded!")
		return

	# Find all bottles and the glass
	var bottles = []
	var glass = null

	for child in scene_root.get_children():
		if child.name.begins_with("Bottle"):
			bottles.append(child)
		elif child.name == "Glass":
			glass = child

	if bottles.is_empty():
		print("No bottles found!")
		return

	# Setup demo liquids
	if bottles.size() > 0:
		# Bottle 1 - Red liquid (Cranberry juice)
		bottles[0].add_liquid_layer(Color(0.8, 0.1, 0.1), 120.0)

	if bottles.size() > 1:
		# Bottle 2 - Orange liquid (Orange juice)
		bottles[1].add_liquid_layer(Color(1.0, 0.6, 0.1), 100.0)

	if bottles.size() > 2:
		# Bottle 3 - Blue liquid (Blue curacao)
		bottles[2].add_liquid_layer(Color(0.1, 0.4, 0.9), 90.0)

	if bottles.size() > 3:
		# Bottle 4 - Yellow liquid (Pineapple juice)
		bottles[3].add_liquid_layer(Color(0.95, 0.85, 0.2), 110.0)

	print("Demo liquids setup complete! Click on bottles to pour into glass.")
