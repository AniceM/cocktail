extends Node2D

signal animation_started()
signal animation_finished()

@onready var liquid = %Liquid

@export var full_glass_y: float = 0
@export var full_glass_scaling: float = 1
@export var first_liquid_y: float = 225.0
@export var first_liquid_scaling: float = 0.75
@export var animation_duration: float = 0.5

var add_liquid_y_increment: float = 0
var add_liquid_scaling: float = 0

# How many times a liquid can be added
var glass_max_liquids: int = 4
# Current amount of liquids
var liquid_amount: int = 0

var tween: Tween

func _ready() -> void:
	# Define the y and scaling increments based the capacity of the glass and the first liquid values
	add_liquid_y_increment = (full_glass_y - first_liquid_y) / (glass_max_liquids - 1)
	add_liquid_scaling = (full_glass_scaling - first_liquid_scaling) / (glass_max_liquids - 1)

	# Set the initial values
	set_liquid_amount(1)

func set_liquid_amount(amount: int, animate: bool = false) -> void:
	if amount == liquid_amount:
		return

	liquid_amount = amount

	var target_y = first_liquid_y + (add_liquid_y_increment * (amount - 1))
	var target_scale = Vector2.ZERO if amount == 0 else Vector2(
		first_liquid_scaling + (add_liquid_scaling * (amount - 1)),
		first_liquid_scaling + (add_liquid_scaling * (amount - 1))
	)

	if animate:
		# Kill any existing tween
		if tween:
			tween.kill()

		# Create new tween
		tween = create_tween()
		tween.set_parallel(true) # Animate position and scale simultaneously

		# Emit animation started signal
		animation_started.emit()

		# Tween position and scale
		tween.tween_property(liquid, "position:y", target_y, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(liquid, "scale", target_scale, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Emit animation finished signal when done
		tween.finished.connect(func(): animation_finished.emit(), CONNECT_ONE_SHOT)
	else:
		# Set values directly without animation
		liquid.position.y = target_y
		liquid.scale = target_scale
