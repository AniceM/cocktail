shader_type canvas_item;

// Wobble settings
uniform float wobble_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wobble_speed : hint_range(0.0, 5.0) = 2.0;
uniform int wave_count : hint_range(1, 8) = 1;

// Ellipse shape
uniform float ellipse_radius_x : hint_range(0.0, 1.0) = 0.426;
uniform float ellipse_radius_y : hint_range(0.0, 0.5) = 0.22;
uniform float ellipse_center_y : hint_range(0.0, 1.0) = 0.281;

// Glass expansion
uniform float expansion_slope : hint_range(0.0, 1.0) = 0.3;

// Colors
uniform vec4 liquid_color : source_color = vec4(0.9, 0.5, 0.2, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.5, 1.0);

// Rim settings
uniform float rim_thickness : hint_range(0.0, 0.05) = 0.015;
uniform float rim_blur : hint_range(0.001, 0.03) = 0.01;
uniform bool show_top_rim = true;
uniform bool show_bottom_rim = true;

// Visibility
uniform bool show_ellipse = true;
uniform bool show_fill = true;

// Depth Gradient
uniform float depth_darkening : hint_range(0.0, 0.5) = 0.2;

// Top clip (for stacking) - matches the ellipse of the layer above
uniform bool use_top_clip = false;
uniform float top_clip_center_y : hint_range(0.0, 1.0) = 0.3;
uniform float top_clip_radius_x : hint_range(0.0, 1.0) = 0.45;
uniform float top_clip_radius_y : hint_range(0.0, 0.5) = 0.15;


float get_sync_wobble(float x_offset) {
    return sin(x_offset * float(wave_count) * TAU + TIME * wobble_speed) * wobble_strength;
}

float ellipse_sdf(vec2 uv, vec2 radius) {
    vec2 p = uv / radius;
    return (length(p) - 1.0) * min(radius.x, radius.y);
}

void fragment() {
    vec2 center = vec2(0.5, ellipse_center_y);
    vec2 pos = UV - center;
    float wobble = get_sync_wobble(pos.x);
    
    // 1. Calculate the Top Oval Distance
    vec2 oval_pos = pos;
    oval_pos.y -= wobble;
    float dist = ellipse_sdf(oval_pos, vec2(ellipse_radius_x, ellipse_radius_y));
    
    // 2. Body fill - expanding cone from ellipse surface
    float x_norm = pos.x / ellipse_radius_x;
    float body_edge_y = ellipse_radius_y * sqrt(max(0.0, 1.0 - x_norm * x_norm));
    float surface_y = body_edge_y + wobble;

    // Expand outward as we go down (predetermined slope)
    float depth_below_surface = UV.y - (ellipse_center_y + surface_y);
    float allowed_width_at_depth = ellipse_radius_x + (depth_below_surface * expansion_slope);

    float x_norm_at_depth = abs(pos.x) / allowed_width_at_depth;
    bool in_body = (pos.y > surface_y) && (x_norm_at_depth < 1.0);
    
    // 3. Top clip ellipse (for stacking)
    bool clipped_by_top = false;
    if (use_top_clip && in_body) {
        vec2 top_clip_center = vec2(0.5, top_clip_center_y);
        vec2 top_clip_pos = UV - top_clip_center;
        float top_wobble = get_sync_wobble(top_clip_pos.x);
        top_clip_pos.y -= top_wobble;
        float top_clip_dist = ellipse_sdf(top_clip_pos, vec2(top_clip_radius_x, top_clip_radius_y));
        
        // Clip if inside the top ellipse
        if (top_clip_dist < 0.0) {
            clipped_by_top = true;
        }
    }
    
    // 4. Rim Masking - inward only
    float inner_edge = -rim_thickness;
    float outer_edge = 0.0;
    float rim_mask = smoothstep(inner_edge - rim_blur, inner_edge + rim_blur, dist) 
                   * (1.0 - smoothstep(outer_edge - rim_blur, outer_edge + rim_blur, dist));
    
    float top_rim = rim_mask * step(oval_pos.y, 0.0);
    float bottom_rim = rim_mask * step(0.0, oval_pos.y);
    
    // 5. Final Color Logic
    vec4 final_color = vec4(0.0);
    
    // Ellipse part (only if show_ellipse is true)
    bool in_ellipse = show_ellipse && dist < 0.0;
    
    // Fill part (only if show_fill is true and not clipped)
    bool in_fill = show_fill && in_body && !clipped_by_top;
	
	// Is the pixel inside the liquid?
    if (in_ellipse || in_fill) {
        final_color = liquid_color;
    }
	
	// Depth Darkening
	if (in_ellipse || in_fill) {
    	float depth = smoothstep(ellipse_center_y, 1.0, UV.y);
    	final_color = liquid_color * (1.0 - depth * depth_darkening);
	}
    
    // Apply rims based on toggles (only if ellipse is shown)
    if (show_ellipse) {
        if (show_bottom_rim && bottom_rim > 0.0) {
            final_color = mix(final_color, rim_color, bottom_rim);
        }
        if (show_top_rim && top_rim > 0.0) {
            final_color = mix(final_color, rim_color, top_rim);
        }
    }
    
    COLOR = final_color;
}