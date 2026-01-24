extends MarginContainer

@onready var flavor_badge: TextureRect = %FlavorBadge
@onready var flavor_stat_label: Label = %FlavorStatLabel

@export var flavor: Flavor:
	set(new_flavor):
		flavor = new_flavor
		if is_node_ready():
			_update_ui()

@export var value: int = 0:
	set(new_value):
		value = new_value
		if is_node_ready():
			_update_ui()

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	if not flavor:
		return

	# Update badge texture from flavor resource
	flavor_badge.texture = flavor.icon

	# Update label text
	var v_sign = "+" if value >= 0 else "-"
	flavor_stat_label.text = flavor.name + " " + v_sign + str(abs(value))
