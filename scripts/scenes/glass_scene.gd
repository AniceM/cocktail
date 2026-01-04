extends Node2D

signal animation_started()
signal animation_finished()

# ============================================================================
# Visuals & References
# ============================================================================
@onready var liquid_sprite: Sprite2D = %LiquidSprite
@onready var liquid_layers: Node2D = %LiquidLayers
@onready var bubbles: GPUParticles2D = %Bubbles
@onready var droplets: GPUParticles2D = %DropletsGlobal
@onready var droplets_container: Node2D = %DropletsContainer

# Shader representing the liquid (top ellipse with a rim, and fill content below)
var base_shader: ShaderMaterial # Cached shader material for direct access

# ============================================================================
# Liquid State
# ============================================================================
var glass_resource: GlassType # The glass type being used
var glass_max_liquids: int = 4 # Maximum amount of liquids
var liquid_amount: int = 0 # Current amount of liquids

# Liquid fill level (ellipse_center_y) - normalized 0-1 in UV space
# UV space: 0.0 = top of texture, 1.0 = bottom of texture
# An empty glass has the ellipse pushed down past the visible area (center_y > 1.0, clamped)
# A full glass has center_y at max_fill_center_y (the lowest safe fill point)
var max_fill_center_y: float = 0.281
# Precalculated ellipse width at every possible ellipse_center_y
var width_lut: Array[float] = []
var width_lut_size: int = 256
# Cumulative volume at each Y position for volume-based interpolation
var volume_lut: Array[float] = []

# ============================================================================
# Animation State
# ============================================================================
var fill_tween: Tween
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
# Track all liquid sprites for cleanup
var extra_liquid_sprites: Array[Sprite2D] = []
var current_liquid: Sprite2D # The liquid sprite we're currently working with
var layer_to_fade: Sprite2D # The layer below current_liquid that should fade when pouring
const TOP_FADE_HEIGHT: float = 0.4 # The height of the fade at the top of the liquid (0.0 = top, 1.0 = bottom)

# ============================================================================
# Lifecycle
# ============================================================================

func _process(_delta: float) -> void:
	if fill_tween and not width_lut.is_empty():
		var sprite_shader = current_liquid.material as ShaderMaterial
		var center_y = sprite_shader.get_shader_parameter("ellipse_center_y") as float

		# 1. LUT Interpolation for Radius
		var float_index = center_y * (width_lut.size() - 1)
		var i_low = clampi(int(floor(float_index)), 0, width_lut.size() - 1)
		var i_high = clampi(int(ceil(float_index)), 0, width_lut.size() - 1)
		var weight = float_index - i_low

		var smooth_radius = lerp(width_lut[i_low], width_lut[i_high], weight)
		sprite_shader.set_shader_parameter("ellipse_radius_x", smooth_radius)

		# 2. DROPLET SYNC (Width & Position)
		var tex_w = liquid_sprite.texture.get_width()
		var tex_h = liquid_sprite.texture.get_height()
		
		# Calculate the actual world-space half-width of the liquid surface
		# We use a 0.9 multiplier so droplets spawn slightly inside the glass walls
		var splash_half_width = smooth_radius * tex_w * liquid_sprite.global_scale.x * 0.9
		
		# Update DropletsGlobal material (ensure you use %DropletsGlobal or the correct reference)
		var particle_material = %DropletsGlobal.process_material as ParticleProcessMaterial
		if particle_material:
			particle_material.emission_box_extents.x = splash_half_width

			# NEW: Tighten the splash when the glass is narrow
			# If smooth_radius is 0.1 (narrow), spread becomes ~12 degrees
			# If smooth_radius is 0.4 (wide), spread becomes ~48 degrees
			particle_material.spread = smooth_radius * 120.0
			
			# Also consider reducing radial accel or setting it to 0
			# particle_material.radial_accel_min = 0
			# particle_material.radial_accel_max = 0

		# 3. Update Position (Y-Sync)
		# UV 0.5 is the center of the sprite. Offset is distance from center.
		var uv_offset_from_center = center_y - 0.5
		var pixel_offset = uv_offset_from_center * tex_h * liquid_sprite.global_scale.y
		
		droplets_container.global_position.y = liquid_sprite.global_position.y + pixel_offset
			

func _ready() -> void:
	# Validate shader exists
	base_shader = liquid_sprite.material as ShaderMaterial
	if not base_shader:
		push_error("LiquidSprite does not have a ShaderMaterial!")
		return

	# Make sure the particle systems are visible but not emitting yet
	bubbles.visible = false # TODO: Fix them before assigning true
	bubbles.emitting = false
	droplets.visible = true
	droplets.emitting = false

	_initialize_positioning()
	_initialize_shader_state()
	current_liquid = liquid_sprite
	_set_liquid_amount(0, false)


func set_glass(glass: GlassType) -> void:
	"""Set the glass type for this scene."""
	glass_resource = glass
	glass_max_liquids = glass.capacity
	_initialize_positioning()
	# Disable auto_ellipse_width and always use LUT for performance
	_set_shader_parameter(base_shader, "auto_ellipse_width", false)
	# Pre-calculate ellipse width lookup table for smooth interpolation during animation
	_precalculate_width_lut()


func reset() -> void:
	# Switch to the original liquid sprite
	current_liquid = liquid_sprite

	# Clear the layer to fade
	layer_to_fade = null

	# Clean up extra liquid sprites
	_free_extra_liquid_sprites()

	# Restore base shader to its original state (top ellipse visible)
	_reset_base_shader_state()

	# Reset liquid amount
	_set_liquid_amount(0, false)

# ============================================================================
# Public API - Liquid Management
# ============================================================================

func add_liquid(color: Color, is_new_layer: bool, animate: bool = false) -> void:
	# For the first liquid, just use the existing Sprite2D
	if liquid_amount == 0:
		_set_liquid_color(base_shader, color)
	# If it is a new layer and not the first, duplicate Sprite2D
	# and add it to the scene to show the separation between layers
	elif is_new_layer:
		var new_liquid_sprite = _create_new_layer(color)
		current_liquid = new_liquid_sprite
	else:
		# Just update the color of current liquid sprite
		_set_liquid_color(current_liquid.material as ShaderMaterial, color)

	# Add the liquid (will trigger animation if animate=true)
	_set_liquid_amount(liquid_amount + 1, animate)


func mix(animate: bool = false) -> void:
	# If there are no layers or only one layer, nothing to mix
	if extra_liquid_sprites.is_empty():
		return

	# Collect all layer colors from shader parameters
	var colors: Array[Color] = []
	colors.append(_get_liquid_color(base_shader))

	for extra_liquid in extra_liquid_sprites:
		colors.append(_get_liquid_color(extra_liquid.material as ShaderMaterial))

	# Blend all colors together (average them)
	var blended_color = Color.BLACK
	for color in colors:
		blended_color += color
	blended_color /= float(colors.size())

	# Capture the current fill level BEFORE switching back to base
	var current_center_y = (current_liquid.material as ShaderMaterial).get_shader_parameter("ellipse_center_y") as float

	# Fade out extra layers
	var fade_tween = create_tween().set_parallel(true)
	for extra_liquid in extra_liquid_sprites:
		fade_tween.tween_property(extra_liquid, "modulate:a", 0.0, pour_animation_duration)

	# Clean up sprites and reparent droplets when all fades finish
	fade_tween.finished.connect(_free_extra_liquid_sprites)

	# Switch back to the original liquid sprite
	current_liquid = liquid_sprite

	# Clear the layer to fade
	layer_to_fade = null

	# Restore base shader to its original state
	_reset_base_shader_state()

	# Animate the bottom liquid changing color with the captured fill level
	# This will emit animation_started and animation_finished signals
	_update_liquid_properties(liquid_sprite, current_center_y, blended_color, animate, true)


# ============================================================================
# Initialization Helpers
# ============================================================================

func _initialize_positioning() -> void:
	# Set the max fill level from the glass resource if available
	if glass_resource:
		max_fill_center_y = glass_resource.max_fill_center_y
	else:
		# Default value if no glass is set
		max_fill_center_y = 0.281


func _initialize_shader_state() -> void:
	# Make sure the base shader is set up correctly
	_reset_base_shader_state()

	# Set initial wobble values to 0 and the set the rim color to black
	# We only do this once so it doesn't need to be inside reset_base_shader
	_set_shader_parameter(base_shader, "wobble_speed", wobble_idle_speed)
	_set_shader_parameter(base_shader, "wobble_strength", wobble_idle_strength)
	_set_shader_parameter(base_shader, "wobble_ripple_count", 1)
	# Set rim color to black for now, it will be updated when _set_liquid_color is called
	base_shader.set_shader_parameter("rim_color", Color.BLACK)
	# TODO: Give a default value for all parameters that the liquid doesn't care for


func _precalculate_width_lut() -> void:
	width_lut.clear()
	volume_lut.clear()
	var image = liquid_sprite.texture.get_image()
	var h = image.get_height()

	# First pass: build width_lut (top to bottom, matching UV.y order)
	for y in range(h):
		width_lut.append(_calculate_width_at_y(image, y))

	# Second pass: calculate volume from bottom to top
	# volume_lut[0] will be volume at Y=1.0 (bottom)
	# volume_lut[h-1] will be volume at Y=0.0 (top)
	# Volume is accumulated as the integral of cross-sectional area (width²)
	# Since width is the radius from center, area ∝ width² for a circular cross-section
	var accumulated_vol = 0.0
	for y in range(h - 1, -1, -1):
		var w = width_lut[y]
		accumulated_vol += w * w # Area of cross-section is proportional to radius²
		volume_lut.append(accumulated_vol)


func _calculate_width_at_y(image: Image, pixel_y: int) -> float:
	var center_x = 0.5
	var max_width = 0.5
	var img_w = image.get_width()

	for i in range(width_lut_size):
		var t = float(i) / width_lut_size
		var check_x = int((center_x + t * max_width) * img_w)
		if image.get_pixel(mini(check_x, img_w - 1), pixel_y).a < 0.5:
			return t * max_width
	return max_width


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


func _set_shader_parameter(shader: ShaderMaterial, param: String, value: Variant) -> void:
	shader.set_shader_parameter(param, value)


func _set_droplets_color(color: Color) -> void:
	"""Set the droplets particle color to match the liquid being poured (brightened)."""
	var droplets_material = droplets.process_material as ParticleProcessMaterial
	if droplets_material:
		# Use the same brightening formula as splash_color for consistency
		var intensity = 0.5
		var brightened_color = (color.srgb_to_linear() * 2 ** intensity).linear_to_srgb()
		droplets_material.color = brightened_color


func _reset_base_shader_state() -> void:
	# Visual Aspect
	_set_shader_parameter(base_shader, "show_ellipse", true)
	_set_shader_parameter(base_shader, "show_fill", true)
	_set_shader_parameter(base_shader, "use_top_clip", false)
	_set_shader_parameter(base_shader, "top_fade_height", 0.0)


# ============================================================================
# Layer Management Helpers
# ============================================================================

func _create_new_layer(color: Color) -> Sprite2D:
	# Duplicate to create new layer (will have all parts visible)
	var new_liquid_sprite = current_liquid.duplicate() as Sprite2D

	# Duplicate the shader material so changes don't affect other layers
	var current_shader = current_liquid.material as ShaderMaterial
	var new_shader = current_shader.duplicate() as ShaderMaterial
	new_liquid_sprite.material = new_shader

	# Set the color of the new layer
	_set_liquid_color(new_shader, color)

	# Hide the ellipse of the layer below and enable top clip
	_set_shader_parameter(current_shader, "show_ellipse", false)
	_set_shader_parameter(current_shader, "use_top_clip", true)

	# Mark the current layer as needing fade when animation runs
	layer_to_fade = current_liquid

	# Add to the liquid layers container
	liquid_layers.add_child(new_liquid_sprite)

	# Move the new layer to index 0 (render it behind previous layers)
	liquid_layers.move_child(new_liquid_sprite, 0)

	# Track it
	extra_liquid_sprites.append(new_liquid_sprite)

	return new_liquid_sprite


func _free_extra_liquid_sprites() -> void:
	"""Free all extra liquid sprites."""
	# Remove all duplicated liquid sprites
	for extra_liquid in extra_liquid_sprites:
		extra_liquid.queue_free()

	# Clear the array
	extra_liquid_sprites.clear()


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

	# Calculate target fill level
	var target_center_y = _calculate_center_y(amount)

	# Get current color from the current liquid sprite's shader
	var current_color = _get_liquid_color(current_liquid.material as ShaderMaterial)

	# Update liquid properties (color stays the same)
	_update_liquid_properties(current_liquid, target_center_y, current_color, animate, false)


func _calculate_center_y(amount: int) -> float:
	"""Calculate the ellipse center Y for a given liquid amount (0-glass_max_liquids).

	Note: ellipse_center_y uses UV coordinates where 0.0 is the top and 1.0 is the bottom.
	The volume_lut is built bottom-up (index 0 = Y=1.0, index size-1 = Y=0.0) for efficient
	volume-based filling. We binary search the volume_lut, then convert back to top-down UV coords.
	"""
	if amount == 0:
		return 1.0 # Empty glass (pushed below visible area)

	if volume_lut.is_empty():
		# Fallback to linear if volume LUT not ready
		var t = float(amount) / float(glass_max_liquids)
		return lerp(1.0, max_fill_center_y, t)

	# Find the volume at the max fill line
	# Since volume_lut is bottom-up, the index for max_fill_center_y (top-down) is:
	var max_fill_idx = clampi(int((1.0 - max_fill_center_y) * (volume_lut.size() - 1)), 0, volume_lut.size() - 1)
	var total_usable_volume = volume_lut[max_fill_idx]

	# Target volume is a percentage of usable volume
	var target_volume = (float(amount) / float(glass_max_liquids)) * total_usable_volume

	# Binary search to find the index in the bottom-up LUT
	var left = 0
	var right = volume_lut.size() - 1

	while left < right:
		var mid = int(float(left + right) / 2)
		if volume_lut[mid] < target_volume:
			left = mid + 1
		else:
			right = mid

	# Convert bottom-up index back to top-down UV coordinate
	# If index is 0, UV is 1.0 (bottom). If index is size-1, UV is 0.0 (top).
	var height_from_bottom = float(left) / float(volume_lut.size() - 1)
	var target_y = 1.0 - height_from_bottom

	return target_y


# ============================================================================
# Animation
# ============================================================================

func _update_liquid_properties(sprite: Sprite2D, target_center_y: float, target_color: Color, animate: bool, is_mix: bool = false) -> void:
	"""Update a liquid sprite's fill level and shader color. Can animate or set instantly."""
	var sprite_shader = sprite.material as ShaderMaterial

	if animate:
		# Kill any existing tween
		if fill_tween:
			fill_tween.kill()

		# Create new tween
		fill_tween = create_tween()
		fill_tween.set_parallel(true) # Animate fill level and color simultaneously

		# Emit animation started signal
		animation_started.emit()

		# Start droplets emission for pours (not for mixes)
		if not is_mix:
			_set_droplets_color(target_color)
			droplets.emitting = true

		# Start wobble and splash animation (non-blocking; animation_finished signal doesn't wait for it)
		_animate_wobble()
		_animate_splash(is_mix)

		# Get current values to animate from
		var current_center_y = sprite_shader.get_shader_parameter("ellipse_center_y") as float
		var current_color = _get_liquid_color(sprite_shader)

		# Tween fill level (ellipse_center_y)
		fill_tween.tween_method(
			func(value: float): _set_shader_parameter(sprite_shader, "ellipse_center_y", value),
			current_center_y,
			target_center_y,
			pour_animation_duration
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Tween shader color parameter
		if target_color != current_color:
			fill_tween.tween_method(
				func(value: Color): _set_shader_parameter(sprite_shader, "liquid_color", value),
				current_color,
				target_color,
				pour_animation_duration
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Tween fade on the layer below (if one exists)
		if layer_to_fade:
			var fade_shader = layer_to_fade.material as ShaderMaterial
			fill_tween.tween_method(
				func(value: float): _set_shader_parameter(fade_shader, "top_fade_height", value),
				0.0,
				TOP_FADE_HEIGHT,
				pour_animation_duration
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

		# Emit animation finished signal when done
		fill_tween.finished.connect(func():
			# Stop droplet emission after pour animation finishes
			if not is_mix:
				droplets.emitting = false
			animation_finished.emit()
		, CONNECT_ONE_SHOT)
	else:
		# Set values directly without animation
		sprite_shader.set_shader_parameter("ellipse_center_y", target_center_y)
		_set_liquid_color(sprite_shader, target_color)


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
	for liquid in [liquid_sprite] + extra_liquid_sprites:
		var liquid_shader = liquid.material as ShaderMaterial
		# Set wobble speed
		_set_shader_parameter(liquid_shader, "wobble_speed", wobble_peak_speed)
		# Phase 1: Spike to peak over wobble_spike_duration
		var current_strength = liquid_shader.get_shader_parameter("wobble_strength") as float
		wobble_tween.tween_method(func(v): _set_shader_parameter(liquid_shader, "wobble_strength", v), current_strength, wobble_peak_strength, wobble_spike_duration)
		# Phase 2: Recover back to 0 after a delay
		wobble_tween.tween_method(func(v): _set_shader_parameter(liquid_shader, "wobble_strength", v), wobble_peak_strength, wobble_idle_strength, wobble_recovery_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(wobble_spike_duration + pour_animation_duration)
		# Revert wobble speed
		wobble_tween.tween_callback(func():
			_set_shader_parameter(liquid_shader, "wobble_speed", wobble_idle_speed)
		).set_delay(wobble_spike_duration + pour_animation_duration + wobble_recovery_duration)


func _animate_splash(is_mix: bool = false) -> void:
	"""Animate splash amplitude to peak, then recover after peak is reached."""
	# Kill any existing splash tween
	if splash_tween:
		splash_tween.kill()

	var recovery_time = splash_mix_recovery_duration if is_mix else splash_pour_recovery_duration
	splash_tween = create_tween().set_parallel(true)

	for liquid in [liquid_sprite] + extra_liquid_sprites:
		var liquid_shader = liquid.material as ShaderMaterial
		# Phase 1: Spike to peak over splash_spike_duration
		splash_tween.tween_method(func(v): _set_shader_parameter(liquid_shader, "splash_amplitude", v), 0.0, splash_peak_amplitude, splash_spike_duration)
		# Phase 2: Recover back to 0 after a delay
		splash_tween.tween_method(func(v): _set_shader_parameter(liquid_shader, "splash_amplitude", v), splash_peak_amplitude, 0.0, recovery_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(splash_spike_duration + pour_animation_duration)
