extends Node2D

signal animation_started()
signal animation_finished()

# Visuals
@onready var liquid_sprite: Node2D = %Liquid
@onready var bubbles: GPUParticles2D = %Bubbles
@onready var liquid_top: Sprite2D = %LiquidTop
@onready var liquid_rim_top: Sprite2D = %LiquidRimTop

# Data to control liquid amount
var glass_max_liquids: int = 4 # Maximum amount of liquids
var liquid_amount: int = 0 # Current amount of liquids
@export var full_glass_y: float = 0
@export var full_glass_scaling: float = 1
@export var first_liquid_y: float = 225.0
@export var first_liquid_scaling: float = 0.75
@export var animation_duration: float = 0.5

# Incremental values (calculated at runtime)
var add_liquid_y_increment: float = 0
var add_liquid_scaling: float = 0

# Track all liquid sprites for cleanup
var extra_liquid_sprites: Array[Node2D] = []
var current_liquid_sprite: Node2D # The liquid sprite we're currently working with

var tween: Tween

func _ready() -> void:
	# Define the y and scaling increments based the capacity of the glass and the first liquid values
	add_liquid_y_increment = (full_glass_y - first_liquid_y) / (glass_max_liquids - 1)
	add_liquid_scaling = (full_glass_scaling - first_liquid_scaling) / (glass_max_liquids - 1)

	# Initialize with the original values
	current_liquid_sprite = liquid_sprite
	_set_liquid_amount(0, false)

func reset() -> void:
	# Switch to the original liquid sprite and move it to the front
	current_liquid_sprite = liquid_sprite

	# Remove all duplicated liquids
	for extra_liquid in extra_liquid_sprites:
		extra_liquid.queue_free()

	# Clear the array
	extra_liquid_sprites.clear()

	# Restore top parts visibility on the original liquid sprite
	liquid_top.visible = true
	liquid_rim_top.visible = true

	# Reset liquid amount
	_set_liquid_amount(0, false)

func add_liquid(color: Color, is_new_layer: bool, animate: bool = false) -> void:
	# For the first liquid, just use the existing Liquid node
	if liquid_amount == 0:
		current_liquid_sprite.modulate = color
	# If it is a new layer and not the first, duplicate Liquid
	# and add it to the scene to show the separation between layers
	elif is_new_layer:
		# Duplicate to create new layer (will have all parts visible)
		var new_liquid_sprite = current_liquid_sprite.duplicate()

		# Hide the top parts of the current layer (it's now covered by new layer)
		var current_liquid_top = current_liquid_sprite.get_node("LiquidTop")
		if current_liquid_top:
			current_liquid_top.visible = false

		var current_rim_top = current_liquid_sprite.get_node("Rim/LiquidRimTop")
		if current_rim_top:
			current_rim_top.visible = false

		# Add to the same parent as the current liquid sprite
		var parent = current_liquid_sprite.get_parent()
		parent.add_child(new_liquid_sprite)

		# Move the new layer to index 0 (render it behind previous layers)
		parent.move_child(new_liquid_sprite, 0)

		# Set its color
		new_liquid_sprite.modulate = color

		# Track it and switch to working with this one
		extra_liquid_sprites.append(new_liquid_sprite)
		current_liquid_sprite = new_liquid_sprite
	else:
		# Just update the color of current liquid sprite
		current_liquid_sprite.modulate = color

	# Add the liquid
	_set_liquid_amount(liquid_amount + 1, animate)

func mix(animate: bool = false) -> void:
	# If there are no layers or only one layer, nothing to mix
	if extra_liquid_sprites.is_empty():
		return

	# Collect all layer colors
	var colors: Array[Color] = []
	colors.append(liquid_sprite.modulate)
	for extra_liquid in extra_liquid_sprites:
		colors.append(extra_liquid.modulate)

	# Blend all colors together (average them)
	var blended_color = Color.BLACK
	for color in colors:
		blended_color += color
	blended_color /= float(colors.size())

	# Capture the position and scale of the topmost layer (current_liquid_sprite)
	var top_position = current_liquid_sprite.position
	var top_scale = current_liquid_sprite.scale

	# Fade out and clean up extra layers while the bottom expands
	for extra_liquid in extra_liquid_sprites:
		var fade_tween = create_tween()
		fade_tween.tween_property(extra_liquid, "modulate:a", 0.0, animation_duration)
		# Clean up this sprite when its fade finishes
		fade_tween.finished.connect(extra_liquid.queue_free)

	# Clear the array since sprites will be freed
	extra_liquid_sprites.clear()

	# Switch back to the original liquid sprite
	current_liquid_sprite = liquid_sprite

	# Restore top parts visibility immediately
	liquid_top.visible = true
	liquid_rim_top.visible = true

	# Animate the bottom liquid expanding up and changing color
	# This will emit animation_started and animation_finished signals
	_update_liquid_properties(liquid_sprite, top_position.y, top_scale, blended_color, animate)

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

	# Update liquid properties (color stays the same)
	_update_liquid_properties(current_liquid_sprite, target_y, target_scale, current_liquid_sprite.modulate, animate)

func _update_liquid_properties(sprite: Node2D, target_y: float, target_scale: Vector2, target_color: Color, animate: bool) -> void:
	"""Update a liquid sprite's position, scale, and optionally color. Can animate or set instantly."""
	if animate:
		# Kill any existing tween
		if tween:
			tween.kill()

		# Create new tween
		tween = create_tween()
		tween.set_parallel(true) # Animate position, scale, and color simultaneously

		# Emit animation started signal
		animation_started.emit()

		# Tween position, scale, and color
		tween.tween_property(sprite, "position:y", target_y, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "scale", target_scale, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(sprite, "modulate", target_color, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Emit animation finished signal when done
		tween.finished.connect(func(): animation_finished.emit(), CONNECT_ONE_SHOT)
	else:
		# Set values directly without animation
		sprite.position.y = target_y
		sprite.scale = target_scale
		sprite.modulate = target_color