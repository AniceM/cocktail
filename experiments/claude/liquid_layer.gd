class_name LiquidLayer
extends RefCounted

## Represents a single layer of liquid with a color and amount

var color: Color
var amount: float  # Height in pixels

func _init(p_color: Color, p_amount: float) -> void:
	color = p_color
	amount = p_amount

func duplicate() -> LiquidLayer:
	return LiquidLayer.new(color, amount)
