extends Button

const FlavorStatInfo = preload("uid://dthjdr2uef2ib")

@onready var liquor_icon: TextureRect = %LiquorIcon
@onready var liquor_name: Label = %LiquorName
@onready var flavor_stats_container: VBoxContainer = %FlavorStatsContainer

# Associated liquor
var liquor: Liquor:
	set(value):
		liquor = value
		if is_node_ready():
			_update_ui()

func _ready() -> void:
	# Empty the flavor stats container, just in case
	for child in flavor_stats_container.get_children():
		child.queue_free()
	
	# Update the UI if liquor is already set
	if liquor:
		_update_ui()

func _update_ui() -> void:
	liquor_name.text = liquor.name
	# liquor_icon.texture = liquor.icon  # TODO

	# Add the flavor stats to the liquor panel
	var flavor_stats = liquor.get_flavor_stats().stats
	var flavor_stat_info_instances = []
	for flavor in flavor_stats:
		# If the flavor stat is 0, no need to show it
		if flavor_stats[flavor] == 0:
			continue
		var flavor_stat_info = FlavorStatInfo.instantiate()
		flavor_stat_info.color = flavor.color
		flavor_stat_info.flavor_name = flavor.name
		flavor_stat_info.value = str(flavor_stats[flavor])
		flavor_stat_info_instances.append(flavor_stat_info)

	# Add in order of biggest to smallest value
	flavor_stat_info_instances.sort_custom(func(a, b): return a.value > b.value)
	for flavor_stat_info in flavor_stat_info_instances:
		flavor_stats_container.add_child(flavor_stat_info)