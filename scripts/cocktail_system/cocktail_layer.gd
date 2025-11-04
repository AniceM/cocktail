class_name CocktailLayer
extends RefCounted

var color: Color = Color.WHITE
var flavor_stats: FlavorStats = FlavorStats.new()
var liquors: Array[Liquor] = [] # Track what went into this layer

func add_liquor(liquor: Liquor) -> void:
	liquors.append(liquor)
	flavor_stats.add_stats(liquor.get_flavor_stats())
	# Blend colors (you'll need to implement color mixing logic)
	color = blend_color(color, liquor.color)

func blend_color(base: Color, new_color: Color) -> Color:
	# Simple average for now
	return base.lerp(new_color, 0.5)

func is_unique_liquor(liquor: Liquor) -> bool:
	for liq in liquors:
		if liq != liquor:
			return false
	return true