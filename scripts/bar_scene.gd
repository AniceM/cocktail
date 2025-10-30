extends Node2D

@onready var liquid_amount_edit: SpinBox = %LiquidAmountEdit
@onready var glass: Node2D = %Glass

func _ready() -> void:
	liquid_amount_edit.value_changed.connect(set_liquid_amount)
	liquid_amount_edit.value = glass.liquid_amount

	# Connect to glass animation signals
	glass.animation_started.connect(_on_glass_animation_started)
	glass.animation_finished.connect(_on_glass_animation_finished)

func set_liquid_amount(amount: float) -> void:
	if amount > glass.glass_max_liquids:
		amount = float(glass.glass_max_liquids)
		liquid_amount_edit.value = amount
	glass.set_liquid_amount(int(amount), true) # Animate the change

func _on_glass_animation_started() -> void:
	liquid_amount_edit.editable = false

func _on_glass_animation_finished() -> void:
	liquid_amount_edit.editable = true
