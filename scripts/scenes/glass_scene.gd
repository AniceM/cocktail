extends Node2D

signal animation_started()
signal animation_finished()

# ============================================================================
# Visuals & References
# ============================================================================
@onready var liquid_rect: ColorRect = %LiquidRect
@onready var bubbles: GPUParticles2D = %Bubbles

# Shader representing the liquid (top ellipse with a rim, and fill content below)
var base_shader: ShaderMaterial # Cached shader material for direct access

# ============================================================================
# Liquid State
# ============================================================================
var glass_resource: GlassType # The glass type being used
var glass_max_liquids: int = 4 # Maximum amount of liquids
var liquid_amount: int = 0 # Current amount of liquids

# Control Liquid positioning (all center-based, Y only)
# These values should be defined in the editor first
var full_glass_center_y: float = 0.0
var full_glass_scaling: float = 1
var first_liquid_center_y: float = -165.265
var first_liquid_scaling: float = 0.6

# Variables to help animating liquid increments
var add_liquid_center_y_increment: float = 0.0
var add_liquid_scaling: float = 0
var rect_size: Vector2 = Vector2.ZERO

# ============================================================================
# Animation State
# ============================================================================
var tween: Tween
var wobble_tween: Tween
var animation_duration: float = 0.5
var wobble_idle_strength: float = 0
var wobble_peak_strength: float = 0.03
var wobble_idle_speed: float = 0.0
var wobble_peak_speed: float = 5.0
var wobble_spike_duration: float = 0.1
var wobble_recovery_duration: float = 3.5

# ============================================================================
# Layer Management
# ============================================================================
# Track all liquid rects for cleanup
var extra_liquid_rects: Array[ColorRect] = []
var current_liquid_rect: ColorRect # The liquid rect we're currently working with


# ============================================================================
# Lifecycle
# ============================================================================

func _ready() -> void:
	# Validate shader exists
	base_shader = liquid_rect.material as ShaderMaterial
	if not base_shader:
		push_error("LiquidRect does not have a ShaderMaterial!")
		return

	_initialize_positioning()
	_initialize_shader_state()
	current_liquid_rect = liquid_rect
	_set_liquid_amount(0, false)


func set_glass(glass: GlassType) -> void:
	"""Set the glass type for this scene."""
	glass_resource = glass
	glass_max_liquids = glass.capacity
	_initialize_positioning()


func reset() -> void:
	# Switch to the original liquid rect
	current_liquid_rect = liquid_rect

	# Remove all duplicated liquid rects
	for extra_liquid in extra_liquid_rects:
		extra_liquid.queue_free()

	# Clear the array
	extra_liquid_rects.clear()

	# Restore base shader to its original state (top ellipse visible)
	_reset_base_shader_state()

	# Reset liquid amount
	_set_liquid_amount(0, false)

# ============================================================================
# Public API - Liquid Management
# ============================================================================

func add_liquid(color: Color, is_new_layer: bool, animate: bool = false) -> void:
	# For the first liquid, just use the existing ColorRect
	if liquid_amount == 0:
		_set_liquid_color(base_shader, color)
	# If it is a new layer and not the first, duplicate ColorRect
	# and add it to the scene to show the separation between layers
	elif is_new_layer:
		var new_liquid_rect = _create_new_layer(color)
		current_liquid_rect = new_liquid_rect
	else:
		# Just update the color of current liquid rect
		_set_liquid_color(current_liquid_rect.material as ShaderMaterial, color)

	# Add the liquid (will trigger animation if animate=true)
	_set_liquid_amount(liquid_amount + 1, animate)


func mix(animate: bool = false) -> void:
	# If there are no layers or only one layer, nothing to mix
	if extra_liquid_rects.is_empty():
		return

	# Collect all layer colors from shader parameters
	var colors: Array[Color] = []
	colors.append(_get_liquid_color(base_shader))

	for extra_liquid in extra_liquid_rects:
		colors.append(_get_liquid_color(extra_liquid.material as ShaderMaterial))

	# Blend all colors together (average them)
	var blended_color = Color.BLACK
	for color in colors:
		blended_color += color
	blended_color /= float(colors.size())

	# Capture the position and scale of the topmost layer (current_liquid_rect)
	var top_position = current_liquid_rect.position
	var top_scale = current_liquid_rect.scale

	# Fade out and clean up extra layers while the bottom expands
	for extra_liquid in extra_liquid_rects:
		var fade_tween = create_tween()
		fade_tween.tween_property(extra_liquid, "modulate:a", 0.0, animation_duration)
		# Clean up this rect when its fade finishes
		fade_tween.finished.connect(extra_liquid.queue_free)

	# Clear the array since rects will be freed
	extra_liquid_rects.clear()

	# Switch back to the original liquid rect
	current_liquid_rect = liquid_rect

	# Restore base shader to its original state
	_reset_base_shader_state()

	# Animate the bottom liquid expanding up and changing color
	# This will emit animation_started and animation_finished signals
	_update_liquid_properties(liquid_rect, top_position, top_scale, blended_color, animate)


# ============================================================================
# Initialization Helpers
# ============================================================================

func _initialize_positioning() -> void:
	# The "full glass" position and scale should be whatever is defined in the editor
	# Pivot is now at center, so position is already the center
	full_glass_scaling = liquid_rect.scale.x
	full_glass_center_y = liquid_rect.position.y

	# Cache the rect size (never changes)
	rect_size = liquid_rect.custom_minimum_size

	# Define the center position and scaling increments based on the capacity of the glass and the first liquid values
	add_liquid_center_y_increment = (full_glass_center_y - first_liquid_center_y) / (glass_max_liquids - 1)
	add_liquid_scaling = (full_glass_scaling - first_liquid_scaling) / (glass_max_liquids - 1)


func _initialize_shader_state() -> void:
	# Make sure the base shader is set up correctly
	_reset_base_shader_state()

	# Set initial wobble values to 0 and the set the rim color to black
	# We only do this once so it doesn't need to be inside reset_base_shader
	_set_wobble_speed(base_shader, wobble_idle_speed)
	_set_wobble_strength(base_shader, wobble_idle_strength)
	base_shader.set_shader_parameter("rim_color", Color.BLACK)


# ============================================================================
# Shader Parameter Setters
# ============================================================================

func _set_liquid_color(shader: ShaderMaterial, color: Color) -> void:
	shader.set_shader_parameter("liquid_color", color)


func _get_liquid_color(shader: ShaderMaterial) -> Color:
	return shader.get_shader_parameter("liquid_color") as Color


func _set_show_ellipse(shader: ShaderMaterial, should_show: bool) -> void:
	shader.set_shader_parameter("show_ellipse", should_show)


func _set_use_top_clip(shader: ShaderMaterial, use_clip: bool) -> void:
	shader.set_shader_parameter("use_top_clip", use_clip)


func _set_wobble_strength(shader: ShaderMaterial, strength: float) -> void:
	shader.set_shader_parameter("wobble_strength", strength)


func _set_wobble_speed(shader: ShaderMaterial, speed: float) -> void:
	shader.set_shader_parameter("wobble_speed", speed)


func _reset_base_shader_state() -> void:
	base_shader.set_shader_parameter("show_ellipse", true)
	base_shader.set_shader_parameter("show_fill", true)
	base_shader.set_shader_parameter("use_top_clip", false)


# ============================================================================
# Layer Management Helpers
# ============================================================================

func _create_new_layer(color: Color) -> ColorRect:
	# Duplicate to create new layer (will have all parts visible)
	var new_liquid_rect = current_liquid_rect.duplicate() as ColorRect

	# Duplicate the shader material so changes don't affect other layers
	var current_shader = current_liquid_rect.material as ShaderMaterial
	var new_shader = current_shader.duplicate() as ShaderMaterial
	new_liquid_rect.material = new_shader

	# Set the color of the new layer
	_set_liquid_color(new_shader, color)

	# Hide the ellipse of the layer below and enable top clip
	_set_show_ellipse(current_shader, false)
	_set_use_top_clip(current_shader, true)

	# Add to the same parent as the current liquid rect
	var parent = current_liquid_rect.get_parent()
	parent.add_child(new_liquid_rect)

	# Move the new layer to index 0 (render it behind previous layers)
	parent.move_child(new_liquid_rect, 0)

	# Track it
	extra_liquid_rects.append(new_liquid_rect)

	return new_liquid_rect


# ============================================================================
# Liquid State Management
# ============================================================================

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

	# Calculate target transform
	var transform_result = _calculate_liquid_transform(amount)
	var target_position = transform_result[0]
	var target_scale = transform_result[1]

	# Get current color from the current liquid rect's shader
	var current_color = _get_liquid_color(current_liquid_rect.material as ShaderMaterial)

	# Update liquid properties (color stays the same)
	_update_liquid_properties(current_liquid_rect, target_position, target_scale, current_color, animate)


func _calculate_liquid_transform(amount: int) -> Array[Vector2]:
	var target_center_y: float
	var target_scale: Vector2
	var target_position: Vector2

	# If glass has checkpoints for this amount, use them
	if glass_resource and amount > 0 and amount <= glass_resource.liquid_checkpoints.size():
		var checkpoint = glass_resource.liquid_checkpoints[amount - 1]
		target_center_y = checkpoint.x
		target_scale = Vector2(checkpoint.y, checkpoint.y)
	else:
		# Fall back to linear interpolation
		target_center_y = first_liquid_center_y + (add_liquid_center_y_increment * (amount - 1))
		target_scale = Vector2.ZERO if amount == 0 else Vector2(
			first_liquid_scaling + (add_liquid_scaling * (amount - 1)),
			first_liquid_scaling + (add_liquid_scaling * (amount - 1))
		)

	# Position is already center-based (pivot is at center)
	# X doesn't change, only Y changes
	target_position = Vector2(liquid_rect.position.x, target_center_y)

	return [target_position, target_scale]


# ============================================================================
# Animation
# ============================================================================

func _update_liquid_properties(rect: ColorRect, target_position: Vector2, target_scale: Vector2, target_color: Color, animate: bool) -> void:
	"""Update a liquid rect's position, scale, and shader color. Can animate or set instantly."""
	var rect_shader = rect.material as ShaderMaterial

	if animate:
		# Kill any existing tween
		if tween:
			tween.kill()

		# Create new tween
		tween = create_tween()
		tween.set_parallel(true) # Animate position, scale, and color simultaneously

		# Emit animation started signal
		animation_started.emit()

		# Start wobble animation (non-blocking; animation_finished signal doesn't wait for it)
		_animate_wobble()

		# Tween position and scale
		tween.tween_property(rect, "position", target_position, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(rect, "scale", target_scale, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Tween shader color parameter
		tween.tween_property(rect_shader, "shader_parameter/liquid_color", target_color, animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Emit animation finished signal when done
		tween.finished.connect(func(): animation_finished.emit(), CONNECT_ONE_SHOT)
	else:
		# Set values directly without animation
		rect.position = target_position
		rect.scale = target_scale
		_set_liquid_color(rect.material as ShaderMaterial, target_color)


func _animate_wobble() -> void:
	"""Animate wobble to peak, then recover after peak is reached."""
	# Kill any existing wobble tween
	if wobble_tween:
		wobble_tween.kill()

	wobble_tween = create_tween().set_parallel(true)

	for liquid in [liquid_rect] + extra_liquid_rects:
		var liquid_shader = liquid.material as ShaderMaterial
		# Set wobble speed
		_set_wobble_speed(liquid_shader, wobble_peak_speed)
		# Phase 1: Spike to peak over wobble_spike_duration
		var current_strength = liquid_shader.get_shader_parameter("wobble_strength") as float
		wobble_tween.tween_method(func(v): _set_wobble_strength(liquid_shader, v), current_strength, wobble_peak_strength, wobble_spike_duration)
		# Phase 2: Recover back to 0 after a delay
		wobble_tween.tween_method(func(v): _set_wobble_strength(liquid_shader, v), wobble_peak_strength, wobble_idle_strength, wobble_recovery_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(wobble_spike_duration + animation_duration)
		# Revert wobble speed
		wobble_tween.tween_callback(func():
			_set_wobble_speed(liquid_shader, wobble_idle_speed)
		).set_delay(wobble_spike_duration + animation_duration + wobble_recovery_duration)