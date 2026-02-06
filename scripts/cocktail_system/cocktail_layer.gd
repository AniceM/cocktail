class_name CocktailLayer
extends RefCounted

var color: Color = Color.WHITE
var flavor_stats: FlavorStats = FlavorStats.new()
var liquors: Array[Liquor] = [] # Track what went into this layer

func add_liquor(liquor: Liquor) -> void:
	liquors.append(liquor)
	flavor_stats.add_stats(liquor.get_flavor_stats())
	if liquors.size() == 1:
		color = liquor.color
	else:
		color = blend_color(color, liquor.color)

func blend_color(current_color: Color, new_color: Color) -> Color:
	var total_count := float(liquors.size())
	# current_color is the mean of the previous (total_count - 1) liquors.
	# Rebuild the weighted sum, add the new color, then divide by total_count.
	return Color(
		((current_color.r * (total_count - 1.0)) + new_color.r) / total_count,
		((current_color.g * (total_count - 1.0)) + new_color.g) / total_count,
		((current_color.b * (total_count - 1.0)) + new_color.b) / total_count,
		((current_color.a * (total_count - 1.0)) + new_color.a) / total_count
	)

func is_unique_liquor(liquor: Liquor) -> bool:
	for liq in liquors:
		if liq != liquor:
			return false
	return true
