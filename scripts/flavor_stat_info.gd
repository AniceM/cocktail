extends PanelContainer

# @onready var icon: TextureRect = %Icon
# temporary ColorRect while we don't have icons
@onready var color_rect: ColorRect = %ColorRect
@onready var flavor_stat_value: Label = %FlavorStatValue

var value: int = 0
var color: Color = Color.WHITE

func _ready() -> void:
    # icon.texture = null
    color_rect.color = color
    flavor_stat_value.text = str(value)