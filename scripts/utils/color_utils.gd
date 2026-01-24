class_name ColorUtils
extends RefCounted

enum ColorName {
	NONE,
	RED,
	ORANGE,
	YELLOW,
	GREEN,
	CYAN,
	BLUE,
	PURPLE,
	PINK,
	WHITE,
	BLACK,
	GRAY
}

# Check if a color matches a given color name
# tolerance: degrees of hue variance allowed (default 30)
static func matches_color_name(color: Color, color_name: ColorName, tolerance: float = 30.0) -> bool:
	var hue = color.h * 360.0  # Godot's h is 0-1, convert to degrees
	var saturation = color.s
	var value = color.v

	match color_name:
		ColorName.BLACK:
			return value < 0.4
		ColorName.WHITE:
			return value > 0.85 and saturation < 0.2
		ColorName.GRAY:
			return saturation < 0.3 and value >= 0.4 and not (value > 0.85 and saturation < 0.2)
		ColorName.RED:
			# Red wraps around 0/360
			return value >= 0.4 and saturation >= 0.3 and (hue < tolerance or hue > (360.0 - tolerance))
		ColorName.ORANGE:
			return value >= 0.4 and saturation >= 0.3 and _in_hue_range(hue, 30, tolerance)
		ColorName.YELLOW:
			return value >= 0.4 and saturation >= 0.3 and _in_hue_range(hue, 60, tolerance)
		ColorName.GREEN:
			return value >= 0.4 and saturation >= 0.3 and _in_hue_range(hue, 120, tolerance)
		ColorName.CYAN:
			return value >= 0.4 and saturation >= 0.3 and _in_hue_range(hue, 180, tolerance)
		ColorName.BLUE:
			return value >= 0.4 and saturation >= 0.3 and _in_hue_range(hue, 240, tolerance)
		ColorName.PURPLE:
			return value >= 0.4 and saturation >= 0.3 and _in_hue_range(hue, 280, tolerance)
		ColorName.PINK:
			return value >= 0.4 and saturation >= 0.3 and _in_hue_range(hue, 330, tolerance)
		ColorName.NONE:
			return false

	return false

static func _in_hue_range(hue: float, target: float, tolerance: float) -> bool:
	return abs(hue - target) <= tolerance

# Check if two colors are similar (useful for monochrome checks)
static func colors_similar(color1: Color, color2: Color, hue_tolerance: float = 30.0, sat_val_tolerance: float = 0.2) -> bool:
	var hue_diff = abs(color1.h * 360.0 - color2.h * 360.0)
	# Handle hue wraparound (e.g., 350 and 10 are close)
	if hue_diff > 180.0:
		hue_diff = 360.0 - hue_diff

	var sat_diff = abs(color1.s - color2.s)
	var val_diff = abs(color1.v - color2.v)

	return hue_diff <= hue_tolerance and sat_diff <= sat_val_tolerance and val_diff <= sat_val_tolerance

# Check if colors form a gradient toward a target color
# Returns true if each layer gets progressively closer to the target
static func is_gradient_toward(layer_colors: Array[Color], target_color_name: ColorName) -> bool:
	if layer_colors.size() < 2:
		return false

	# Get the target hue
	var target_hue = _get_color_name_hue(target_color_name)
	if target_hue < 0:
		return false

	# Check if hue gets progressively closer to target
	var prev_distance = 999.0
	for color in layer_colors:
		var current_hue = color.h * 360.0
		var distance = _hue_distance(current_hue, target_hue)

		if distance > prev_distance:
			return false  # Getting farther away
		prev_distance = distance

	return true

static func _get_color_name_hue(color_name: ColorName) -> float:
	match color_name:
		ColorName.RED: return 0.0
		ColorName.ORANGE: return 30.0
		ColorName.YELLOW: return 60.0
		ColorName.GREEN: return 120.0
		ColorName.CYAN: return 180.0
		ColorName.BLUE: return 240.0
		ColorName.PURPLE: return 280.0
		ColorName.PINK: return 330.0
	return -1.0  # Invalid

static func _hue_distance(hue1: float, hue2: float) -> float:
	var diff = abs(hue1 - hue2)
	if diff > 180.0:
		diff = 360.0 - diff
	return diff

# Get all matching color names for a given color
# Every color will match at least one name (no NONE results)
static func get_matching_color_names(color: Color, tolerance: float = 30.0) -> Array[ColorName]:
	var matches: Array[ColorName] = []
	var hue = color.h * 360.0
	var saturation = color.s
	var value = color.v

	# Partition the color space completely:
	# 1. BLACK - very dark colors (perceptually black to human eyes)
	if value < 0.4:
		matches.append(ColorName.BLACK)
		return matches

	# 2. WHITE - very bright + desaturated colors
	if value > 0.85 and saturation < 0.2:
		matches.append(ColorName.WHITE)
		return matches

	# 3. GRAY - desaturated colors (not white or black)
	if saturation < 0.3:
		matches.append(ColorName.GRAY)
		return matches

	# 4. HUE-BASED - everything else maps to nearest hue(s)
	var hue_map = {
		ColorName.RED: 0.0,
		ColorName.ORANGE: 30.0,
		ColorName.YELLOW: 60.0,
		ColorName.GREEN: 120.0,
		ColorName.CYAN: 180.0,
		ColorName.BLUE: 240.0,
		ColorName.PURPLE: 280.0,
		ColorName.PINK: 330.0
	}

	for color_name in hue_map:
		var target_hue = hue_map[color_name]
		var distance = _hue_distance(hue, target_hue)
		if distance <= tolerance:
			matches.append(color_name)

	# Safety fallback: if somehow no hue matched, return closest
	if matches.is_empty():
		var min_distance = 999.0
		var closest = ColorName.RED
		for color_name in hue_map:
			var distance = _hue_distance(hue, hue_map[color_name])
			if distance < min_distance:
				min_distance = distance
				closest = color_name
		matches.append(closest)

	return matches

# Get the closest matching color name for a given color (returns first match)
static func get_closest_color_name(color: Color) -> ColorName:
	var matches = get_matching_color_names(color)
	return matches[0] if matches.size() > 0 else ColorName.NONE
