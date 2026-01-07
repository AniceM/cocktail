shader_type canvas_item;

// ============================================================================
// Textures
// ============================================================================
// Mask texture determines the shape of the glass (white = fillable, black = empty)
uniform sampler2D mask_texture : hint_default_white;
// Signed Distance Field texture used for "distance to edge" calculations
// Allows us to know how close a pixel is to the side of the glass
uniform sampler2D sdf_texture : hint_default_white;

// ============================================================================
// Geometry & Shape
// ============================================================================
uniform bool auto_ellipse_width = false; // If true, calculates width from mask_texture
uniform float ellipse_width_scale : hint_range(0.8, 1.0) = 1.0; // Scale factor for auto-calculated width (use < 1 to shrink ellipse from glass edges)
uniform float ellipse_ratio : hint_range(0.0, 1.0) = 0.5; // Height/Width ratio of the surface ellipse
uniform float ellipse_center_y : hint_range(0.0, 1.0) = 0.281; // 0.0=Top, 1.0=Bottom
uniform float ellipse_radius_x : hint_range(0.0, 1.0) = 0.426; // Width of the liquid surface

// Top clip (for stacking layers)
// Used when this liquid is BELOW another liquid layer
uniform bool use_top_clip = false;
uniform float top_clip_center_y : hint_range(0.0, 1.0) = 0.3;
uniform float top_clip_radius_x : hint_range(0.0, 1.0) = 0.45;
uniform float top_clip_radius_y : hint_range(0.0, 0.5) = 0.15;

// ============================================================================
// Animation (Wobble & Wave/Splash)
// ============================================================================
// "Wobble" simulates the main liquid sloshing movement
uniform float wobble_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wobble_speed : hint_range(0.0, 10.0) = 2.0;
uniform int wobble_ripple_count : hint_range(1, 8) = 1; // Number of wobble ripples across liquid width

// "Splash" simulates ripples/waves during pouring
uniform float splash_amplitude : hint_range(0.0, 0.1) = 0.0;
uniform float splash_frequency : hint_range(1.0, 30.0) = 22.0;
uniform float splash_speed : hint_range(0.5, 20.0) = 15.0;
uniform vec4 splash_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform float wave_glow : hint_range(0.0, 2.0) = 0.5; // Brightness multiplier for wave highlights

// Noise / Texture
// Adds a scrolling noise texture to simulate particles/pulp/ imperfection
uniform bool enable_noise = false;
uniform sampler2D noise_texture : hint_default_black, repeat_enable;
uniform float noise_strength : hint_range(0.0, 1.0) = 0.1;
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0;
uniform vec2 noise_scroll_speed = vec2(0.05, 0.1);

// Caustics (Simulated Light Refraction)
// Creates animated light patterns like sunlight through water
uniform bool enable_caustics = false;
uniform float caustic_strength : hint_range(0.0, 5.0) = 0.3;
uniform float caustic_scale : hint_range(0.5, 10.0) = 2.0;
uniform float caustic_speed : hint_range(0.0, 2.0) = 0.25;


// ============================================================================
// Visual Styling
// ============================================================================
// Base Color
uniform vec4 liquid_color : source_color = vec4(0.9, 0.5, 0.2, 1.0);

// Surface & Specular
// Highlights that appear on the top "surface ellipse" of the liquid
uniform float top_highlight : hint_range(0.0, 0.5) = 0.25;
uniform float top_highlight_falloff : hint_range(0.0, 1.0) = 0.3; // Distance range for surface highlight fade
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float specular_strength : hint_range(0.0, 2.0) = 0.8;
uniform float specular_falloff_x : hint_range(0.5, 20.0) = 5.0; // Horizontal sharpness (higher = narrower)
uniform float specular_falloff_y : hint_range(0.5, 5.0) = 1.5; // Vertical stretch (lower = longer)

// Rim
// The subtle line around the edge of the surface ellipse
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float rim_thickness : hint_range(0.0, 0.05) = 0.01;
uniform float rim_blur : hint_range(0.001, 0.03) = 0.01;

// Fresnel / Edge Glow
// Glow appearing at the sides of the glass body
uniform bool enable_fresnel = true;
uniform vec4 fresnel_color : source_color = vec4(1.0, 1.0, 1.0, 0.588);
uniform float fresnel_width : hint_range(0.0, 100.0) = 55.0;
uniform float fresnel_falloff : hint_range(0.1, 10.0) = 5.0;

// Subsurface Scattering
// Simulates light passing through thin liquid areas (backlight effect)
uniform bool enable_subsurface = false;
uniform vec4 subsurface_color : source_color = vec4(1.0, 0.6, 0.3, 1.0);
uniform float subsurface_strength : hint_range(0.0, 1.0) = 0.2;
uniform float subsurface_threshold : hint_range(0.0, 150.0) = 80.0; // Distance threshold for "thin" areas

// Darkening / Depth
// Various darkening factors to make the liquid look 3D/volumetric
uniform float depth_darkening : hint_range(0.0, 10.0) = 0.2; // Darker at the bottom
uniform float surface_darken_amount : hint_range(0.0, 1.0) = 0.25; // Darken the flat surface disc
uniform float side_darkening : hint_range(0.0, 1.0) = 0.15; // Darken edges (glass thickness)
uniform float center_darkening : hint_range(0.0, 1.0) = 0.1; // "Core" darkening

// ============================================================================
// Layer Blending
// ============================================================================
// Fade the top of the fill to blend smoothly with layers above
uniform float top_fade_height : hint_range(0.0, 0.5) = 0.0; // Height of fade zone from surface
uniform bool top_fade_compensation = true; // If true, visually raises the liquid to compensate for transparency volume loss

// ============================================================================
// Visibility Toggles
// ============================================================================
uniform bool show_ellipse = true; // Show the top surface
uniform bool show_fill = true; // Show the volume below surface
uniform bool show_top_rim = true; // Show rim on the upper half of the ellipse
uniform bool show_bottom_rim = true; // Show rim on the lower half of the ellipse

// ============================================================================
// Constants (Named Magic Numbers for Clarity)
// ============================================================================
const float NOISE_COLOR_BLEND_STRENGTH = 0.2; // How much noise affects base liquid color
const float SUBSURFACE_COLOR_MIX = 0.3; // How much liquid color mixes with subsurface color
const float SPECULAR_WOBBLE_INFLUENCE = 0.5; // How much wobble affects highlight position
const float RIPPLE_SPLASH_MIX_INTENSITY = 10.0; // Intensity of ripple color mixing
const float RIPPLE_GLOW_MULTIPLIER = 15.0; // Brightness multiplier for ripple glow
const float FRESNEL_ELLIPSE_FADE_RANGE = 0.75; // Fade distance for Fresnel near surface ellipse (in ellipse heights)

// ============================================================================
// Animation Helpers
// ============================================================================

float get_sync_wobble(float x_offset) {
	// Simple sine wave based on time and x-position
	// Multiplied by wobble_ripple_count to allow more "ripples" across the width
	return sin(x_offset * float(wobble_ripple_count) * TAU + TIME * wobble_speed) * wobble_strength;
}

float calculate_ripple_factor(vec2 pos, float radius_x, float ellipse_radius_y, float wobble) {
	// Calculate multi-layered ripple/splash effect
	if (splash_amplitude <= 0.0) {
		return 0.0;
	}

	vec2 ripple_uv = pos / vec2(radius_x, ellipse_radius_y);
	float r_dist = length(ripple_uv);

	// Multiple wave frequencies for complex ripples
	float wave1 = sin(r_dist * splash_frequency - TIME * splash_speed);
	float wave2 = sin(r_dist * splash_frequency * 1.5 - TIME * splash_speed * 0.8);
	float wave3 = sin(r_dist * splash_frequency * 2.3 - TIME * splash_speed * 0.6);

	// Combine waves with different weights
	float ripple_wave = (wave1 * 0.6 + wave2 * 0.3 + wave3 * 0.1) * 0.5 + 0.5;

	// Exponential falloff for more realistic decay
	float ripple_fade = exp(-r_dist * 2.0);

	// Edge fade: ripples fade out before reaching the ellipse boundary
	// Account for wobble by offsetting the y position before calculating distance
	vec2 wobbled_pos = pos;
	wobbled_pos.y -= wobble;
	vec2 wobbled_uv = wobbled_pos / vec2(radius_x, ellipse_radius_y);
	float wobbled_dist = length(wobbled_uv);
	// wobbled_dist approaches 1.0 at the ellipse edge, so we fade from 0.7 to 1.0
	float edge_fade = smoothstep(1.0, 0.7, wobbled_dist);

	return ripple_wave * ripple_fade * edge_fade * splash_amplitude;
}

// ============================================================================
// Geometry & Shape Helpers
// ============================================================================

float ellipse_sdf(vec2 uv, vec2 radius) {
	// Signed Distance Field for an ellipse
	// returns < 0 inside the ellipse, > 0 outside
	vec2 p = uv / radius;
	return (length(p) - 1.0) * min(radius.x, radius.y);
}

// Decodes SDF texture value to pixel distance from edge
float decode_sdf(sampler2D sdf, vec2 uv) {
	float sdf_value = texture(sdf, uv).r * 255.0 - 128.0;
	return abs(sdf_value);
}

// Calculates the "Glow" at the edges using the SDF texture
float calculate_fresnel_glow(sampler2D sdf, vec2 uv, float width, float falloff) {
	float distance_from_edge = decode_sdf(sdf, uv);
	float normalized_dist = distance_from_edge / max(width, 0.001);
	return pow(smoothstep(1.0, 0.0, normalized_dist), falloff);
}

// ============================================================================
// Lighting & Shading Helpers
// ============================================================================

// Darkens the liquid near the glass edges to simulate absorption/thickness
float calculate_side_darkening(sampler2D sdf, vec2 uv, float strength) {
	float distance_from_edge = decode_sdf(sdf, uv);
	// 150.0 is an arbitrary "pixel distance" range for the effect
	return smoothstep(150.0, 0.0, distance_from_edge) * strength;
}

// Darkens the center of the liquid column
float calculate_center_darkening(float x_abs_norm, float strength) {
	// x_abs_norm: 0 at center, 1 at sides
	float thickness = 1.0 - x_abs_norm;
	float darkening = pow(thickness, 2.0) * strength;
	return 1.0 - darkening;
}

// Calculates caustic light patterns (animated refraction effect)
vec3 calculate_caustics(sampler2D noise, vec2 uv, float x_abs_norm, float center_y) {
	if (!enable_caustics || !enable_noise) {
		return vec3(0.0);
	}

	// Sample noise twice with different offsets to create interference pattern
	vec2 caustic_uv1 = uv * caustic_scale + TIME * caustic_speed * vec2(0.3, 0.5);
	vec2 caustic_uv2 = uv * caustic_scale - TIME * caustic_speed * vec2(0.5, 0.3);
	float caustic1 = texture(noise, caustic_uv1).r;
	float caustic2 = texture(noise, caustic_uv2).r;

	// Multiply and threshold to create concentrated light patterns
	float caustic = pow(caustic1 * caustic2, 2.0);

	// Apply stronger near bottom (light travels through more liquid)
	float depth_influence = smoothstep(center_y, 1.0, uv.y);

	// Reduce caustics near edges (less refraction at glass walls)
	float edge_fade = 1.0 - smoothstep(0.6, 1.0, x_abs_norm);

	return vec3(caustic * caustic_strength * depth_influence * edge_fade);
}

// Calculates subsurface scattering glow (backlight through thin liquid)
vec3 calculate_subsurface(sampler2D sdf, vec2 uv, vec3 base_color) {
	if (!enable_subsurface) {
		return vec3(0.0);
	}

	// Use SDF to find thin areas (close to edges)
	float distance_from_edge = decode_sdf(sdf, uv);
	float thinness = smoothstep(subsurface_threshold, 0.0, distance_from_edge);

	// Add warm glow in thin regions, mix with liquid color for harmony
	vec3 sss_color = mix(subsurface_color.rgb, base_color, SUBSURFACE_COLOR_MIX);
	return thinness * subsurface_strength * sss_color;
}

// Calculates surface specular highlight (reflection on liquid surface)
float calculate_surface_specular(vec2 pos, float x_norm_abs, float ellipse_radius_y, float wobble, float noise_val, float dist_surface) {
	// (OLD VERSION - Simple specular)
	// Strongest at center (viewing angle perpendicular), falls off at sides
	// float fresnel = pow(abs(cos(x_norm_signed * PI * 0.5)), 2.0);
	//
	// // Use noise to break up the specular highlight slightly (Surface imperfection)
	// if (enable_noise) {
	// 	fresnel *= (0.8 + 0.4 * noise_val); // Varies from 0.8 to 1.2
	// }

	// (CURRENT VERSION - Anisotropic specular with elongated highlight)
	float specular_x = pow(1.0 - x_norm_abs, specular_falloff_x); // Horizontal sharpness
	float specular_y = pow(abs(pos.y / ellipse_radius_y), specular_falloff_y); // Vertical stretch
	float fresnel = specular_x * (1.0 - specular_y);

	// Offset highlight position based on wobble for realism
	float highlight_offset = wobble * SPECULAR_WOBBLE_INFLUENCE;
	fresnel *= smoothstep(0.4, -0.1, pos.y - highlight_offset);

	// Use noise to break up the specular highlight slightly (Surface imperfection)
	if (enable_noise) {
		fresnel *= (0.7 + 0.6 * noise_val);
	}

	// Soften specular near the rim
	float rim_proximity = smoothstep(0.05, -0.02, dist_surface);

	return fresnel * rim_proximity * specular_strength;
}

// Scans the mask texture to find how wide the glass is at a specific Y level
// Scans outward from center to find the first non-white pixel on the right side
float find_width_at_y(sampler2D mask, float y) {
	// Scan from center (0.5) outward to the right edge (1.0)
	// 128 steps for better precision (~0.4% per step)
	for (int i = 0; i <= 128; i++) {
		float offset = float(i) / 256.0; // 0.0 to 0.5
		float sample_x = 0.5 + offset;
		float sample_value = texture(mask, vec2(sample_x, y)).r;
		if (sample_value < 0.5) {
			// Found the edge - return the last valid width
			return offset;
		}
	}
	return 0.5; // Full width if no edge found
}

// Finds the ellipse radius at the given center_y, scaled by ellipse_width_scale
float find_ellipse_radius_x(sampler2D mask, float center_y) {
	float width = find_width_at_y(mask, center_y);
	return width * ellipse_width_scale;
}

void fragment() {
	// 1. Initial Setup
	// ========================================================================
	float mask_value = texture(mask_texture, UV).r;

	// Calculate the base radius (width/2) of our surface ellipse at the static center
	float radius_x = auto_ellipse_width ? find_ellipse_radius_x(mask_texture, ellipse_center_y) : ellipse_radius_x;
	float ellipse_radius_y = radius_x * ellipse_ratio;

	// Visual Compensation for Fade
	// If fade is active, the top of the liquid becomes transparent, reducing visual volume.
	// We offset the center Y upwards to compensate.
	float adjusted_center_y = ellipse_center_y;
	if (top_fade_compensation && top_fade_height > 0.0) {
		// Heuristic: move up by half the fade height relative to the ellipse height
		adjusted_center_y -= top_fade_height * ellipse_radius_y * 0.5;
	}

	// If the liquid level is below the bottom of the mask, draw nothing
	bool glass_is_empty = adjusted_center_y + ellipse_radius_y > 1.0;
	if (glass_is_empty) {
		discard;
	}

	// Clamp ensures the ellipse never draws partially off-texture
	float clamped_center_y = clamp(adjusted_center_y, ellipse_radius_y, 1.0 - ellipse_radius_y);
	vec2 center = vec2(0.5, clamped_center_y);
	vec2 pos = UV - center;

	// Pre-calculate normalized X coordinates used for logic/shading
	// x_norm_signed: -1.0 (left) to 1.0 (right)
	// x_norm_abs:     0.0 (center) to 1.0 (edge)
	float x_norm_signed = pos.x / radius_x;
	float x_norm_abs = abs(x_norm_signed);

	// 2. Animation Calculations
	// ========================================================================
	// Attenuate wobble near the ellipse edges to keep them anchored to the glass walls
	float edge_attenuation = 1.0 - smoothstep(0.7, 1.0, x_norm_abs);
	float wobble = get_sync_wobble(pos.x) * edge_attenuation;
	float ripple_factor = calculate_ripple_factor(pos, radius_x, ellipse_radius_y, wobble);

	// 3. Shape Definitions
	// ========================================================================

	// A. Define the Top Surface Oval
	vec2 oval_pos = pos;
	oval_pos.y -= (wobble + ripple_factor); // Apply animations to surface position

	float dist_surface = ellipse_sdf(oval_pos, vec2(radius_x, ellipse_radius_y));

	// B. Define the Body (Fill Volume)
	// We need to know EXACTLY where the surface line is at this X position
	// The formula comes from the equation of an ellipse: y = b * sqrt(1 - x^2/a^2)
	float surface_curve_y = ellipse_radius_y * sqrt(max(0.0, 1.0 - x_norm_signed * x_norm_signed));
	float surface_y_wobbled = surface_curve_y + wobble;
	
	bool inside_mask = mask_value > 0.5;
	// Pixel is in the body if: inside mask AND below the surface curve
	bool in_body = inside_mask && (pos.y > surface_y_wobbled);

	// C. Top Clip Logic (Masking for Layers)
	// If this liquid is covered by another layer, we subtract the top layer's shape
	bool clipped_by_top = false;
	if (use_top_clip && in_body) {
		vec2 top_clip_center = vec2(0.5, top_clip_center_y);
		vec2 top_clip_pos = UV - top_clip_center;
		float top_wobble = get_sync_wobble(top_clip_pos.x);
		top_clip_pos.y -= top_wobble;
		// Reuse existing SDF function to check if we are "inside" the layer above us
		if (ellipse_sdf(top_clip_pos, vec2(top_clip_radius_x, top_clip_radius_y)) < 0.0) {
			clipped_by_top = true;
		}
	}

	// 4. Region Checks
	// ========================================================================
	bool in_ellipse = show_ellipse && dist_surface < 0.0 && inside_mask;
	bool in_fill = show_fill && in_body && !clipped_by_top;

	// 5. Coloring
	// ========================================================================
	vec4 final_color = vec4(0.0);

	if (in_ellipse || in_fill) {
		final_color = liquid_color;

		// Noise sampling (scrolling texture)
		float noise_val = 0.0;
		if (enable_noise) {
			vec2 noise_uv = UV * noise_scale + TIME * noise_scroll_speed;
			noise_val = texture(noise_texture, noise_uv).r;

			// Apply noise texture to the base color (Texture / Particles effect)
			// We use an Overlay-like blend to keep colors vibrant
			// value < 0.5 darkens, value > 0.5 lightens
			float noise_mix = (noise_val - 0.5) * 2.0; // -1 to 1
			final_color.rgb += noise_mix * noise_strength * NOISE_COLOR_BLEND_STRENGTH;
		} 

		// --- Volume Lighting (Body) ---
		if (in_fill) {
			// Depth Darkening (vertical gradient, darker at bottom)
			float depth_factor = smoothstep(ellipse_center_y, 1.0, UV.y);
			final_color.rgb *= (1.0 - depth_factor * depth_darkening);

			// Side Darkening (SDF based, darker near glass walls)
			float side_dark = calculate_side_darkening(sdf_texture, UV, side_darkening);
			final_color.rgb *= (1.0 - side_dark);

			// Center Core (Simulate light absorption in the thickest part)
			final_color.rgb *= calculate_center_darkening(x_norm_abs, center_darkening);

			// Surface Proximity Highlight (Light entering from top)
			// Brightens the liquid just below the surface line
			// We use the glass depth (from surface to bottom) as the normalization factor
			float glass_depth = 1.0 - clamped_center_y; // Depth from surface to bottom of UV space
			float dist_to_surface = clamp((pos.y - surface_y_wobbled) / glass_depth, 0.0, 1.0);
			float surface_proximity = 1.0 - smoothstep(0.0, top_highlight_falloff, dist_to_surface);
			final_color.rgb += surface_proximity * top_highlight * final_color.rgb;
			
			// Fresnel Glow (Edge highlighting)
			if (enable_fresnel) {
				float fresnel_val = calculate_fresnel_glow(sdf_texture, UV, fresnel_width, fresnel_falloff);

				// Fade out Fresnel as we approach the surface ellipse from below to avoid harsh cutoff
				// We calculate vertical distance to the surface ellipse edge in normalized space
				float vertical_dist_to_ellipse = abs(pos.y - surface_y_wobbled) / ellipse_radius_y;
				// Fade based on distance to ellipse (0 = at surface, 1+ = below)
				float ellipse_fade = smoothstep(0.0, FRESNEL_ELLIPSE_FADE_RANGE, vertical_dist_to_ellipse);

				final_color.rgb += fresnel_val * fresnel_color.rgb * fresnel_color.a * ellipse_fade;
			}

			// Caustics (Animated light refraction patterns)
			final_color.rgb += calculate_caustics(noise_texture, UV, x_norm_abs, ellipse_center_y);

			// Subsurface Scattering (Backlight effect in thin liquid areas)
			final_color.rgb += calculate_subsurface(sdf_texture, UV, final_color.rgb);

			// Top Fade for Layer Blending
			// Fade alpha at the top of the fill to blend smoothly with layers above
			if (top_fade_height > 0.0) {
				float distance_from_surface = clamp((pos.y - surface_y_wobbled) / ellipse_radius_y, 0.0, 1.0);
				float fade = mix(0.1, 1.0, smoothstep(0.0, top_fade_height, distance_from_surface));
				final_color.a *= fade;
			}
		}

		// --- Surface Lighting (Ellipse) ---
		if (in_ellipse) {
			// Base surface darkening (often liquid surfaces look slightly different than the volume)
			final_color.rgb *= (1.0 - surface_darken_amount);

			// Specular Highlight (Reflection)
			float specular = calculate_surface_specular(pos, x_norm_abs, ellipse_radius_y, wobble, noise_val, dist_surface);
			final_color.rgb += specular * specular_color.rgb;

			// Wave Glow (Brightens the peaks of ripples)
			if (ripple_factor > 0.0) {
				final_color = mix(final_color, splash_color, ripple_factor * RIPPLE_SPLASH_MIX_INTENSITY);
				final_color.rgb += (ripple_factor * RIPPLE_GLOW_MULTIPLIER) * wave_glow * final_color.rgb;
			}
		}
	}

	// 6. Rims Application
	// ========================================================================
	if (show_ellipse) {
		// Normalize rim parameters by the ellipse's min radius so they work consistently across glass shapes
		float min_radius = min(radius_x, ellipse_radius_y);
		float scaled_rim_thickness = rim_thickness * min_radius;
		float scaled_rim_blur = rim_blur * min_radius;

		// Calculate rim mask using smoothstep for antialiased edges
		float inner_edge = -scaled_rim_thickness;
		// Creates a ring between inner_edge and 0.0
		float rim_mask = smoothstep(inner_edge - scaled_rim_blur, inner_edge + scaled_rim_blur, dist_surface)
					   * (1.0 - smoothstep(-scaled_rim_blur, scaled_rim_blur, dist_surface));

		if (show_bottom_rim) {
			// step(0.0, oval_pos.y) selects only the bottom half
			float bottom_strength = rim_mask * step(0.0, oval_pos.y);
			final_color = mix(final_color, rim_color, bottom_strength);
		}
		if (show_top_rim) {
			// step(oval_pos.y, 0.0) selects only the top half
			float top_strength = rim_mask * step(oval_pos.y, 0.0);
			final_color = mix(final_color, rim_color, top_strength);
		}
	}

	COLOR = final_color;
}