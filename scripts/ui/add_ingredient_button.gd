extends Button

const FlavorStatInfo = preload("uid://dthjdr2uef2ib")

@onready var ingredient_icon: TextureRect = %IngredientIcon
@onready var ingredient_name: Label = %IngredientName
@onready var flavor_stats_container: GridContainer = %FlavorStatsContainer

@export var liquor: Liquor:
	set(value):
		liquor = value
		if value:
			special_ingredient = null
		if is_node_ready():
			_update_ui()

@export var special_ingredient: SpecialIngredient:
	set(value):
		special_ingredient = value
		if value:
			liquor = null
		if is_node_ready():
			_update_ui()


func _ready() -> void:
	_update_ui()


func _update_ui() -> void:
	# Clear existing flavor stats
	for child in flavor_stats_container.get_children():
		child.queue_free()

	var display_name := ""
	var stats: Dictionary = {}

	if liquor:
		display_name = liquor.name
		stats = liquor.get_flavor_stats().stats
	elif special_ingredient:
		display_name = special_ingredient.name
		stats = special_ingredient.get_flavor_stats().stats
	else:
		ingredient_name.text = ""
		return

	ingredient_name.text = display_name
	# ingredient_icon.texture = ...  # TODO

	# Add the flavor stats to the panel
	var flavor_stat_info_instances = []
	for flavor in stats:
		if stats[flavor] == 0:
			continue
		var flavor_stat_info = FlavorStatInfo.instantiate()
		flavor_stat_info.flavor = flavor
		flavor_stat_info.value = stats[flavor]
		flavor_stat_info_instances.append(flavor_stat_info)

	# Add in order of biggest to smallest value
	flavor_stat_info_instances.sort_custom(func(a, b): return a.value > b.value)
	for flavor_stat_info in flavor_stat_info_instances:
		flavor_stats_container.add_child(flavor_stat_info)
