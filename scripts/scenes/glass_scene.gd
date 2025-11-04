extends Node2D

signal animation_started()
signal animation_finished()

# Visuals
@onready var liquid_sprite: Sprite2D = %Liquid
@onready var bubbles: GPUParticles2D = %Bubbles

# Data to control liquid amount
var glass_max_liquids: int = 4  # Maximum amount of liquids
var liquid_amount: int = 0  # Current amount of liquids
@export var full_glass_y: float = 0
@export var full_glass_scaling: float = 1
@export var first_liquid_y: float = 225.0
@export var first_liquid_scaling: float = 0.75
@export var animation_duration: float = 0.5

# Incremental values (calculated at runtime)
var add_liquid_y_increment: float = 0
var add_liquid_scaling: float = 0

# Track all liquid sprites for cleanup
var extra_liquid_sprites: Array[Sprite2D] = []
var current_liquid_sprite: Sprite2D  # The liquid sprite we're currently working with

var tween: Tween

func _ready() -> void:
	# Define the y and scaling increments based the capacity of the glass and the first liquid values
	add_liquid_y_increment = (full_glass_y - first_liquid_y) / (glass_max_liquids - 1)
	add_liquid_scaling = (full_glass_scaling - first_liquid_scaling) / (glass_max_liquids - 1)

	# Initialize with the original values
	current_liquid_sprite = liquid_sprite
	_set_liquid_amount(0, false)

func add_liquid(color: Color, is_new_layer: bool, animate: bool = false) -> void:
	# If it is a new layer, duplicate Liquid
	# and add it to the scene to show the separation between layers
	if is_new_layer:
		var new_liquid_sprite = liquid_sprite.duplicate()

		# Add to the same parent as the current liquid sprite
		current_liquid_sprite.get_parent().add_child(new_liquid_sprite)

		# Set its color
		new_liquid_sprite.self_modulate = color

		# Track it and switch to working with this one
		extra_liquid_sprites.append(new_liquid_sprite)
		current_liquid_sprite = new_liquid_sprite
	else:
		# Just update the color of current liquid sprite
		current_liquid_sprite.self_modulate = color

	# Add the liquid
	_set_liquid_amount(liquid_amount + 1, animate)

func reset() -> void:
	# Switch to the original liquid sprite and move it to the front
	current_liquid_sprite = liquid_sprite

	# Remove all duplicated liquids
	for extra_liquid in extra_liquid_sprites:
		extra_liquid.queue_free()

	# Clear the array
	extra_liquid_sprites.clear()

	# Reset liquid amount
	_set_liquid_amount(0, false)

func _set_liquid_amount(amount: int, animate: bool = false) -> void:
	if amount == liquid_amount and amount != 0:
		return

	liquid_amount = amount

	# Update bubbles
	if amount > 1:
		bubbles.emitting = true
		bubbles.visible = true
	else:
		bubbles.emitting = false
		bubbles.visible = false

	# Calculate target y and scale
	var target_y = first_liquid_y + (add_liquid_y_increment * (amount - 1))
	var target_scale = Vector2.ZERO if amount == 0 else Vector2(
		first_liquid_scaling + (add_liquid_scaling * (amount - 1)),
		first_liquid_scaling + (add_liquid_scaling * (amount - 1))
	)

	# Animate the liquid change when needed
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
		tween.tween_property(current_liquid_sprite, "position:y", target_y, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(current_liquid_sprite, "scale", target_scale, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Emit animation finished signal when done
		tween.finished.connect(func(): animation_finished.emit(), CONNECT_ONE_SHOT)
	else:
		# Set values directly without animation
		current_liquid_sprite.position.y = target_y
		current_liquid_sprite.scale = target_scale
