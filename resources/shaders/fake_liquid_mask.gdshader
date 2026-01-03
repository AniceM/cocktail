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
uniform float ellipse_ratio : hint_range(0.1, 1.0) = 0.5; // Height/Width ratio of the surface ellipse
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
uniform float wobble_speed : hint_range(0.0, 5.0) = 2.0;

// "Splash" simulates ripples/waves during pouring
uniform float splash_amplitude : hint_range(0.0, 0.1) = 0.0;
uniform float splash_frequency : hint_range(1.0, 30.0) = 22.0;
uniform float splash_speed : hint_range(0.5, 20.0) = 15.0;
uniform vec4 splash_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);

// Wave settings (visual detail on the wobble/splash)
uniform int wave_count : hint_range(1, 8) = 1;
uniform float wave_glow : hint_range(0.0, 2.0) = 0.5;

// ============================================================================
// Visual Styling
// ============================================================================
// Base Color
uniform vec4 liquid_color : source_color = vec4(0.9, 0.5, 0.2, 1.0);

// Surface & Specular
// Highlights that appear on the top "surface ellipse" of the liquid
uniform float top_highlight : hint_range(0.0, 0.5) = 0.25;
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 0.5);
uniform float specular_strength : hint_range(0.0, 2.0) = 0.5;

// Rim
// The subtle line around the edge of the surface ellipse
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float rim_thickness : hint_range(0.0, 0.05) = 0.015;
uniform float rim_blur : hint_range(0.001, 0.03) = 0.01;

// Fresnel / Edge Glow
// Glow appearing at the sides of the glass body
uniform bool enable_fresnel = true;
uniform vec4 fresnel_color : source_color = vec4(1.0, 1.0, 1.0, 0.588);
uniform float fresnel_width : hint_range(0.0, 100.0) = 55.0;
uniform float fresnel_falloff : hint_range(0.1, 10.0) = 5.0;

// Darkening / Depth
// Various darkening factors to make the liquid look 3D/volumetric
uniform float depth_darkening : hint_range(0.0, 0.5) = 0.2; // Darker at the bottom
uniform float surface_darken_amount : hint_range(0.0, 1.0) = 0.25; // Darken the flat surface disc
uniform float side_darkening : hint_range(0.0, 1.0) = 0.15; // Darken edges (glass thickness)
uniform float center_darkening : hint_range(0.0, 1.0) = 0.1; // "Core" darkening

// ============================================================================
// Visibility Toggles
// ============================================================================
uniform bool show_ellipse = true; // Show the top surface
uniform bool show_fill = true; // Show the volume below surface
uniform bool show_top_rim = true; // Show rim on the upper half of the ellipse
uniform bool show_bottom_rim = true; // Show rim on the lower half of the ellipse


float get_sync_wobble(float x_offset) {
	// Simple sine wave based on time and x-position
	// Multiplied by wave_count to allow more "ripples" across the width
	return sin(x_offset * float(wave_count) * TAU + TIME * wobble_speed) * wobble_strength;
}

float ellipse_sdf(vec2 uv, vec2 radius) {
	// Signed Distance Field for an ellipse
	// returns < 0 inside the ellipse, > 0 outside
	vec2 p = uv / radius;
	return (length(p) - 1.0) * min(radius.x, radius.y);
}

// Calculates the "Glow" at the edges using the SDF texture
float calculate_fresnel_glow(sampler2D sdf, vec2 uv, float width, float falloff) {
	float sdf_value = texture(sdf, uv).r * 255.0 - 128.0;
	float distance_from_edge = abs(sdf_value);
	float normalized_dist = distance_from_edge / max(width, 0.001);
	return pow(smoothstep(1.0, 0.0, normalized_dist), falloff);
}

// Darkens the liquid near the glass edges to simulate absorption/thickness
float calculate_side_darkening(sampler2D sdf, vec2 uv, float strength) {
	float sdf_value = texture(sdf, uv).r * 255.0 - 128.0;
	float distance_from_edge = abs(sdf_value);
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

// Scans the mask texture to find how wide the glass is at a specific Y level
float find_ellipse_radius_x(sampler2D mask, float center_y) {
	float max_width = 0.0;
	// We scan only 64 steps for performance, sufficient for smooth shapes
	for (int x = 0; x <= 64; x++) {
		float norm_x = float(x) / 64.0;
		float sample_value = texture(mask, vec2(norm_x, center_y)).r;
		if (sample_value > 0.5) {
			max_width = abs(norm_x - 0.5);
		}
	}
	return max_width;
}

void fragment() {
	// 1. Initial Setup
	// ========================================================================
	float mask_value = texture(mask_texture, UV).r;

	// Calculate the radius (width/2) of our surface ellipse
	float radius_x = auto_ellipse_width ? find_ellipse_radius_x(mask_texture, ellipse_center_y) : ellipse_radius_x;
	float ellipse_radius_y = radius_x * ellipse_ratio;

	// If the liquid level is below the bottom of the mask, draw nothing
	bool glass_is_empty = ellipse_center_y + ellipse_radius_y > 1.0;
	if (glass_is_empty) {
		discard;
	}

	// Clamp ensures the ellipse never draws partially off-texture
	float clamped_center_y = clamp(ellipse_center_y, ellipse_radius_y, 1.0 - ellipse_radius_y);
	vec2 center = vec2(0.5, clamped_center_y);
	vec2 pos = UV - center;

	// Pre-calculate normalized X coordinates used for logic/shading
	// x_norm_signed: -1.0 (left) to 1.0 (right)
	// x_norm_abs:     0.0 (center) to 1.0 (edge)
	float x_norm_signed = pos.x / radius_x;       
	float x_norm_abs = abs(x_norm_signed);        

	// 2. Animation Calculations
	// ========================================================================
	float wobble = get_sync_wobble(pos.x);
	
	// Ripple/Splash logic (only active if splash_amplitude > 0)
	float ripple_factor = 0.0;
	if (splash_amplitude > 0.0) {
		vec2 ripple_uv = pos / vec2(radius_x, ellipse_radius_y);
		float r_dist = length(ripple_uv);
		// Create a ring wave effect moving outward
		float ripple_wave = 0.5 + 0.5 * sin(r_dist * splash_frequency - TIME * splash_speed);
		float ripple_fade = smoothstep(1.0, 0.0, r_dist);
		ripple_factor = ripple_wave * ripple_fade * splash_amplitude;
	}

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
	// Pixel is in the body if: inside mask AND below the surface curve AND horizontally inside the radius
	bool in_body = inside_mask && (pos.y > surface_y_wobbled) && (x_norm_abs < 1.0);

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
	bool in_ellipse = show_ellipse && dist_surface < 0.0;
	bool in_fill = show_fill && in_body && !clipped_by_top;

	// 5. Coloring
	// ========================================================================
	vec4 final_color = vec4(0.0);

	if (in_ellipse || in_fill) {
		final_color = liquid_color;

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
			// We reuse 'surface_y_wobbled' calculated earlier!
			float dist_to_surface = clamp((surface_y_wobbled - pos.y) / ellipse_radius_y, 0.0, 1.0);
			float surface_proximity = 1.0 - smoothstep(0.0, 0.3, dist_to_surface);
			final_color.rgb += surface_proximity * top_highlight * final_color.rgb;
			
			// Fresnel Glow (Edge highlighting)
			if (enable_fresnel) {
				float fresnel_val = calculate_fresnel_glow(sdf_texture, UV, fresnel_width, fresnel_falloff);
				final_color.rgb += fresnel_val * fresnel_color.rgb * fresnel_color.a;
			}
		}

		// --- Surface Lighting (Ellipse) ---
		if (in_ellipse) {
			// Base surface darkening (often liquid surfaces look slightly different than the volume)
			final_color.rgb *= (1.0 - surface_darken_amount);

			// Specular Highlight (Reflection)
			// Strongest at center (viewing angle perpendicular), falls off at sides
			float fresnel = pow(abs(cos(x_norm_signed * PI * 0.5)), 2.0);
			// Soften specular near the rim
			float rim_proximity = smoothstep(0.05, -0.02, dist_surface);
			
			float specular = fresnel * rim_proximity * specular_strength;
			final_color.rgb += specular * specular_color.rgb;

			// Wave Glow (Brightens the peaks of ripples)
			if (ripple_factor > 0.0) {
				final_color = mix(final_color, splash_color, ripple_factor * 10.0);
				final_color.rgb += (ripple_factor * 15.0) * wave_glow * final_color.rgb;
			}
		}
	}

	// 6. Rims Application
	// ========================================================================
	if (show_ellipse) {
		// Calculate rim mask using smoothstep for antialiased edges
		float inner_edge = -rim_thickness;
		// Creates a ring between inner_edge and 0.0
		float rim_mask = smoothstep(inner_edge - rim_blur, inner_edge + rim_blur, dist_surface)
					   * (1.0 - smoothstep(-rim_blur, rim_blur, dist_surface));

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