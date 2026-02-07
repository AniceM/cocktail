@tool
extends Node2D

## Tool script that auto-calculates glass height from mask textures
## and sets the glass_height uniform so the shader can auto-scale effects.
##
## Uses Godot's reflection system (_get_property_list, _set, _get) to dynamically
## expose shader parameters in the Inspector. Add new parameters by adding a single
## line to SHADER_PARAMS - no boilerplate setters needed.

# =============================================================================
# Shader Parameter Definitions
# =============================================================================
# Format: [shader_name, type, group, hint_string, default_value]
# - hint_string: for floats/ints use "min,max" or "min,max,step"
# - hint_string: for colors/vectors/bools, leave empty ""
const SHADER_PARAMS := [
	# Wobble
	["wobble_strength", TYPE_FLOAT, "Wobble", "0.0,0.1", 0.005],
	["wobble_speed", TYPE_FLOAT, "Wobble", "0.0,10.0", 2.0],
	["wobble_ripple_count", TYPE_INT, "Wobble", "1,8", 1],

	# Splash
	["splash_amplitude", TYPE_FLOAT, "Splash", "0.0,0.1", 0.0],
	["splash_frequency", TYPE_FLOAT, "Splash", "1.0,30.0", 22.0],
	["splash_speed", TYPE_FLOAT, "Splash", "0.5,20.0", 15.0],
	["splash_color", TYPE_COLOR, "Splash", "", Color(1.0, 1.0, 1.0, 0.4)],
	["wave_glow", TYPE_FLOAT, "Splash", "0.0,5.0", 4.0],

	# Noise
	["enable_noise", TYPE_BOOL, "Noise", "", true],
	["noise_strength", TYPE_FLOAT, "Noise", "0.0,1.0", 0.1],
	["noise_scale", TYPE_FLOAT, "Noise", "0.1,10.0", 3.0],
	["noise_scroll_speed", TYPE_VECTOR2, "Noise", "", Vector2(0.05, 0.1)],

	# Caustics
	["enable_caustics", TYPE_BOOL, "Caustics", "", true],
	["caustic_strength", TYPE_FLOAT, "Caustics", "0.0,5.0", 0.3],
	["caustic_scale", TYPE_FLOAT, "Caustics", "0.5,10.0", 6.0],
	["caustic_speed", TYPE_FLOAT, "Caustics", "0.0,2.0", 0.25],

	# Liquid Color
	["liquid_color", TYPE_COLOR, "Liquid Color", "", Color(0.9, 0.5, 0.2, 1.0)],

	# Surface & Specular
	["top_highlight", TYPE_FLOAT, "Surface & Specular", "0.0,0.5", 0.25],
	["top_highlight_falloff", TYPE_FLOAT, "Surface & Specular", "0.0,1.0", 0.3],
	["specular_color", TYPE_COLOR, "Surface & Specular", "", Color(1.0, 1.0, 1.0, 0.5)],
	["specular_strength", TYPE_FLOAT, "Surface & Specular", "0.0,2.0", 0.8],
	["specular_falloff_x", TYPE_FLOAT, "Surface & Specular", "0.5,20.0", 5.0],
	["specular_falloff_y", TYPE_FLOAT, "Surface & Specular", "0.5,5.0", 1.5],

	# Rim
	["rim_color", TYPE_COLOR, "Rim", "", Color(1.0, 0.8, 0.5, 1.0)],
	["rim_thickness", TYPE_FLOAT, "Rim", "0.0,0.05", 0.01],
	["rim_blur", TYPE_FLOAT, "Rim", "0.001,0.03", 0.01],

	# Fresnel
	["enable_fresnel", TYPE_BOOL, "Fresnel", "", true],
	["fresnel_color", TYPE_COLOR, "Fresnel", "", Color(1.0, 1.0, 1.0, 0.588)],
	["fresnel_width", TYPE_FLOAT, "Fresnel", "0.0,100.0", 20.0],
	["fresnel_falloff", TYPE_FLOAT, "Fresnel", "0.1,10.0", 5.0],

	# Subsurface
	["enable_subsurface", TYPE_BOOL, "Subsurface", "", true],
	["subsurface_color", TYPE_COLOR, "Subsurface", "", Color(0.113, 0.804, 0.894, 1.0)],
	["subsurface_strength", TYPE_FLOAT, "Subsurface", "0.0,1.0", 0.2],
	["subsurface_threshold", TYPE_FLOAT, "Subsurface", "0.0,150.0", 45.0],

	# Darkening
	["depth_darkening_range", TYPE_FLOAT, "Darkening", "0.0,1.0", 0.1],
	["depth_darkening_intensity", TYPE_FLOAT, "Darkening", "0.0,1.0", 0.5],
	["surface_darken_amount", TYPE_FLOAT, "Darkening", "0.0,1.0", 0.25],
	["side_darkening", TYPE_FLOAT, "Darkening", "0.0,1.0", 0.15],
	["center_darkening", TYPE_FLOAT, "Darkening", "0.0,1.0", 0.1],
]

# Storage for parameter values
var _param_values := {}

# Cached list of liquid sprites (rebuilt on calibrate)
var _cached_sprites: Array[Sprite2D] = []

# Lookup set for fast parameter name checking
var _param_names: Dictionary = {}

# =============================================================================
# Actions (kept as regular @export)
# =============================================================================
@export_group("Actions")
## Press to recalculate all glass heights and update shaders
@export var calibrate: bool = false:
	set(value):
		if value and Engine.is_editor_hint():
			_calibrate_all_glasses()

@export_group("Debug")
## Shows calculated heights for each glass
@export var debug_info: Array[String] = []


# =============================================================================
# Initialization
# =============================================================================
func _init() -> void:
	# Build lookup set and initialize defaults
	for param in SHADER_PARAMS:
		var param_name: String = param[0]
		_param_names[param_name] = true
		_param_values[param_name] = param[4] # default value


# =============================================================================
# Reflection System (replaces @export boilerplate)
# =============================================================================
func _get_property_list() -> Array[Dictionary]:
	var props: Array[Dictionary] = []
	var current_group := ""

	for param in SHADER_PARAMS:
		var param_name: String = param[0]
		var type: int = param[1]
		var group: String = param[2]
		var hint_string: String = param[3]

		# Add group separator when group changes
		if group != current_group:
			props.append({
				"name": group,
				"type": TYPE_NIL,
				"usage": PROPERTY_USAGE_GROUP
			})
			current_group = group

		# Determine hint type based on value type
		var hint := PROPERTY_HINT_NONE
		if type in [TYPE_FLOAT, TYPE_INT] and hint_string != "":
			hint = PROPERTY_HINT_RANGE

		# Add the actual property
		props.append({
			"name": param_name,
			"type": type,
			"hint": hint,
			"hint_string": hint_string if hint == PROPERTY_HINT_RANGE else "",
			"usage": PROPERTY_USAGE_DEFAULT
		})

	return props


func _set(property: StringName, value: Variant) -> bool:
	if property in _param_names:
		_param_values[property] = value
		if Engine.is_editor_hint():
			_apply_to_all(String(property), value)
		return true
	return false


func _get(property: StringName) -> Variant:
	if property in _param_names:
		return _param_values.get(property)
	return null


func _property_can_revert(property: StringName) -> bool:
	return property in _param_names


func _property_get_revert(property: StringName) -> Variant:
	# Find the default value in SHADER_PARAMS
	for param in SHADER_PARAMS:
		if param[0] == property:
			return param[4] # default value
	return null


# =============================================================================
# Calibration
# =============================================================================
func _calibrate_all_glasses() -> void:
	debug_info.clear()
	var glasses_found := 0

	# Rebuild the cached sprites list
	_cached_sprites = _find_liquid_sprites(self)

	if _cached_sprites.is_empty():
		debug_info.append("No liquid sprites found")
		Log.msg(self, "No liquid sprites found")
		return

	for sprite in _cached_sprites:
		var result := _calibrate_glass(sprite)
		if not result.is_empty():
			glasses_found += 1
			debug_info.append(result)

	# Apply all current parameter values to the newly found sprites
	_apply_all_parameters()

	Log.msg(self, "Calibrated %d glasses" % glasses_found)


func _apply_all_parameters() -> void:
	for param in SHADER_PARAMS:
		var param_name: String = param[0]
		if param_name in _param_values:
			_apply_to_all(param_name, _param_values[param_name])


func _find_liquid_sprites(node: Node) -> Array[Sprite2D]:
	var result: Array[Sprite2D] = []

	for child in node.get_children():
		if child is Sprite2D:
			var mat := child.material as ShaderMaterial
			if mat and mat.shader:
				# Check if it has our liquid shader uniforms
				if mat.get_shader_parameter("mask_texture") != null:
					result.append(child)

		# Recurse into children
		result.append_array(_find_liquid_sprites(child))

	return result


func _calibrate_glass(sprite: Sprite2D) -> String:
	var mat := sprite.material as ShaderMaterial
	if not mat:
		return ""

	var mask_texture: Texture2D = mat.get_shader_parameter("mask_texture")
	if not mask_texture:
		return ""

	# Get the image data from the mask texture
	var image := mask_texture.get_image()
	if not image:
		push_warning("LiquidShaderCalibrator: Could not get image from mask texture for %s" % sprite.name)
		return ""

	# Find bottom Y of white pixels
	var bottom_y := _find_mask_bottom(image)
	if bottom_y < 0:
		return ""

	# Get current ellipse_center_y (liquid surface)
	var center_y: float = mat.get_shader_parameter("ellipse_center_y")

	# Set the glass uniforms
	mat.set_shader_parameter("glass_bottom_y", bottom_y)

	var info := "%s: bottom=%.3f, surface=%.3f" % [
		sprite.name, bottom_y, center_y
	]
	Log.msg(self, info)
	return info


# =============================================================================
# Parameter Application
# =============================================================================
func _apply_to_all(param_name: String, value: Variant) -> void:
	for sprite in _cached_sprites:
		var mat := sprite.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter(param_name, value)


# =============================================================================
# Helpers
# =============================================================================
func _find_mask_bottom(image: Image) -> float:
	## Returns bottom_y in normalized 0-1 coordinates
	## Returns -1 if no white pixels found
	var width := image.get_width()
	var height := image.get_height()

	# Scan from bottom to find last white pixel
	for y in range(height - 1, -1, -1):
		for x in range(width):
			var pixel := image.get_pixel(x, y)
			if pixel.r > 0.5: # White pixel found
				return float(y) / float(height)

	return -1.0
