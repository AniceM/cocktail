extends Node2D

signal animation_started()
signal animation_finished()

# ============================================================================
# Visuals & References
# ============================================================================
@onready var liquid_rect: ColorRect = %LiquidRect
@onready var bubbles: GPUParticles2D = %Bubbles
@onready var droplets: GPUParticles2D = %Droplets

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
var splash_tween: Tween
var pour_animation_duration: float = 0.5
var wobble_idle_strength: float = 0
var wobble_peak_strength: float = 0.03
var wobble_idle_speed: float = 0.0
var wobble_peak_speed: float = 5.0
var wobble_spike_duration: float = 0.1
var wobble_recovery_duration: float = 3.5
var splash_peak_amplitude: float = 0.03
var splash_spike_duration: float = 0.1
var splash_pour_recovery_duration: float = 0.6 # A bit more than pour_animation_duration
var splash_mix_recovery_duration: float = 3.5

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

	# Make sure the particle systems are visible but not emitting yet
	bubbles.visible = true
	bubbles.emitting = false
	droplets.visible = true
	droplets.emitting = false

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

	# Clean up extra liquid rects
	_free_extra_liquid_rects()

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

	# Reparent droplets back to the original liquid rect before freeing extras
	if droplets.get_parent() != liquid_rect:
		droplets.get_parent().remove_child(droplets)
		liquid_rect.add_child(droplets)

	# Fade out extra layers while the bottom expands
	var fade_tween = create_tween().set_parallel(true)
	for extra_liquid in extra_liquid_rects:
		fade_tween.tween_property(extra_liquid, "modulate:a", 0.0, pour_animation_duration)

	# Clean up rects and reparent droplets when all fades finish
	fade_tween.finished.connect(_free_extra_liquid_rects)

	# Switch back to the original liquid rect
	current_liquid_rect = liquid_rect

	# Restore base shader to its original state
	_reset_base_shader_state()

	# Animate the bottom liquid expanding up and changing color
	# This will emit animation_started and animation_finished signals
	_update_liquid_properties(liquid_rect, top_position, top_scale, blended_color, animate, true)


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
	# Set rim color to black for now, it will be updated when _set_liquid_color is called
	base_shader.set_shader_parameter("rim_color", Color.BLACK)


# ============================================================================
# Shader Parameter Setters
# ============================================================================

func _set_liquid_color(shader: ShaderMaterial, color: Color) -> void:
	shader.set_shader_parameter("liquid_color", color)

	# Set the rim color to the same color, but darkened if color is light, lightened if dark
	var luma = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
	if luma > 0.5:
		shader.set_shader_parameter("rim_color", color.darkened(0.5))
	else:
		shader.set_shader_parameter("rim_color", color.lightened(0.5))

	# Calculate brightened splash color
	# This formula is equivalent to changing the "intensity" slider in the editor
	var intensity = 2
	var splash_color = (color.srgb_to_linear() * 2 ** intensity).linear_to_srgb()

	shader.set_shader_parameter("splash_color", splash_color)


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


func _set_splash_amplitude(shader: ShaderMaterial, amplitude: float) -> void:
	shader.set_shader_parameter("splash_amplitude", amplitude)


func _set_droplets_color(color: Color) -> void:
	"""Set the droplets particle color to match the liquid being poured (brightened)."""
	var droplets_material = droplets.process_material as ParticleProcessMaterial
	if droplets_material:
		# Use the same brightening formula as splash_color for consistency
		var intensity = 0.5
		var brightened_color = (color.srgb_to_linear() * 2 ** intensity).linear_to_srgb()
		droplets_material.color = brightened_color


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


func _free_extra_liquid_rects() -> void:
	"""Reparent droplets and free all extra liquid rects."""
	# Reparent droplets back to the original liquid rect before freeing extras
	if droplets.get_parent() != liquid_rect:
		droplets.get_parent().remove_child(droplets)
		liquid_rect.add_child(droplets)

	# Remove all duplicated liquid rects
	for extra_liquid in extra_liquid_rects:
		extra_liquid.queue_free()

	# Clear the array
	extra_liquid_rects.clear()


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
	else:
		bubbles.emitting = false

	# Calculate target transform
	var transform_result = _calculate_liquid_transform(amount)
	var target_position = transform_result[0]
	var target_scale = transform_result[1]

	# Get current color from the current liquid rect's shader
	var current_color = _get_liquid_color(current_liquid_rect.material as ShaderMaterial)

	# Update liquid properties (color stays the same)
	_update_liquid_properties(current_liquid_rect, target_position, target_scale, current_color, animate, false)


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

func _update_liquid_properties(rect: ColorRect, target_position: Vector2, target_scale: Vector2, target_color: Color, animate: bool, is_mix: bool = false) -> void:
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

		# Start droplets emission for pours (not for mixes)
		if not is_mix:
			_set_droplets_color(target_color)
			droplets.emitting = true
			# If we are pouring a new layer, reparent droplets
			if droplets.get_parent() != rect:
				droplets.get_parent().remove_child(droplets)
				rect.add_child(droplets)

		# Start wobble and splash animation (non-blocking; animation_finished signal doesn't wait for it)
		_animate_wobble()
		_animate_splash(is_mix)

		# Tween position and scale
		tween.tween_property(rect, "position", target_position, pour_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(rect, "scale", target_scale, pour_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Tween shader color parameter
		tween.tween_property(rect_shader, "shader_parameter/liquid_color", target_color, pour_animation_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Emit animation finished signal when done
		tween.finished.connect(func():
			# Stop droplet emission after pour animation finishes
			if not is_mix:
				droplets.emitting = false
			animation_finished.emit()
		, CONNECT_ONE_SHOT)
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

	# We will animate the wobbling effect by changing the speed and strength
	# Wobble speed CANNOT be tweened, because the shader uses TIME, and TIME * wobble_speed changes dramatically between frames
	# It needs to stay constant for the duration of the animation.
	# Wobble strength however can be tweened.
	for liquid in [liquid_rect] + extra_liquid_rects:
		var liquid_shader = liquid.material as ShaderMaterial
		# Set wobble speed
		_set_wobble_speed(liquid_shader, wobble_peak_speed)
		# Phase 1: Spike to peak over wobble_spike_duration
		var current_strength = liquid_shader.get_shader_parameter("wobble_strength") as float
		wobble_tween.tween_method(func(v): _set_wobble_strength(liquid_shader, v), current_strength, wobble_peak_strength, wobble_spike_duration)
		# Phase 2: Recover back to 0 after a delay
		wobble_tween.tween_method(func(v): _set_wobble_strength(liquid_shader, v), wobble_peak_strength, wobble_idle_strength, wobble_recovery_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(wobble_spike_duration + pour_animation_duration)
		# Revert wobble speed
		wobble_tween.tween_callback(func():
			_set_wobble_speed(liquid_shader, wobble_idle_speed)
		).set_delay(wobble_spike_duration + pour_animation_duration + wobble_recovery_duration)


func _animate_splash(is_mix: bool = false) -> void:
	"""Animate splash amplitude to peak, then recover after peak is reached."""
	# Kill any existing splash tween
	if splash_tween:
		splash_tween.kill()

	var recovery_time = splash_mix_recovery_duration if is_mix else splash_pour_recovery_duration
	splash_tween = create_tween().set_parallel(true)

	for liquid in [liquid_rect] + extra_liquid_rects:
		var liquid_shader = liquid.material as ShaderMaterial
		# Phase 1: Spike to peak over splash_spike_duration
		splash_tween.tween_method(func(v): _set_splash_amplitude(liquid_shader, v), 0.0, splash_peak_amplitude, splash_spike_duration)
		# Phase 2: Recover back to 0 after a delay
		splash_tween.tween_method(func(v): _set_splash_amplitude(liquid_shader, v), splash_peak_amplitude, 0.0, recovery_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(splash_spike_duration + pour_animation_duration)
