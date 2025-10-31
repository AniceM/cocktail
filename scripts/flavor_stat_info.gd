extends MarginContainer

# @onready var icon: TextureRect = %Icon
# temporary ColorRect while we don't have icons
@onready var color_rect: ColorRect = %ColorRect
@onready var flavor_stat_label: Label = %FlavorStatLabel

var flavor_name: String

var value: int = 0

var color: Color = Color.WHITE

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	color_rect.color = color
	var v_sign = "+" if value >= 0 else "-"
	flavor_stat_label.text = flavor_name + " " + v_sign + str(abs(value))
