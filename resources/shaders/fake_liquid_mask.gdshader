shader_type canvas_item;

// Mask texture (the glass shape)
uniform sampler2D mask_texture : hint_default_white;

// Wobble settings
uniform float wobble_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wobble_speed : hint_range(0.0, 5.0) = 2.0;

// Wave settings
uniform int wave_count : hint_range(1, 8) = 1;
uniform float wave_glow : hint_range(0.0, 2.0) = 0.5;

// Splash/Ripple settings (Animate splash_amplitude to see the effect!)
uniform float splash_amplitude : hint_range(0.0, 0.1) = 0.0;
uniform float splash_frequency : hint_range(1.0, 30.0) = 22.0;
uniform float splash_speed : hint_range(0.5, 20.0) = 15.0;
uniform vec4 splash_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);

// Ellipse shape
uniform float ellipse_ratio : hint_range(0.1, 1.0) = 0.5;
uniform float ellipse_center_y : hint_range(0.0, 1.0) = 0.281;
uniform bool auto_ellipse_width = false;
uniform float ellipse_radius_x : hint_range(0.0, 1.0) = 0.426;

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

// Darkening
uniform float depth_darkening : hint_range(0.0, 0.5) = 0.2;
uniform float surface_darken_amount : hint_range(0.0, 1.0) = 0.2;

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

float find_ellipse_radius_x(sampler2D mask, float center_y) {
    // Sample the mask texture horizontally at the given center Y to find the ellipse width
    // Returns the normalized distance from center (0.5) to the edge
    float max_width = 0.0;

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
    // Sample the mask to see if we're in a valid region
    float mask_value = texture(mask_texture, UV).r;

    // Determine ellipse radius X: either auto-calculated from mask or pre-calculated via LUT
    float radius_x = auto_ellipse_width ? find_ellipse_radius_x(mask_texture, ellipse_center_y) : ellipse_radius_x;

    // Calculate ellipse radius Y from the ratio
    float ellipse_radius_y = radius_x * ellipse_ratio;

    // Check if there's enough vertical space at the bottom for the ellipse
    // If not, the glass is effectively empty and nothing should render
    bool glass_is_empty = ellipse_center_y + ellipse_radius_y > 1.0;
    if (glass_is_empty) {
        discard;
    }

    // Clamp ellipse center Y so the entire ellipse stays visible
    float clamped_center_y = clamp(ellipse_center_y, ellipse_radius_y, 1.0 - ellipse_radius_y);

    vec2 center = vec2(0.5, clamped_center_y);
    vec2 pos = UV - center;

    float wobble = get_sync_wobble(pos.x);

    // Calculate Ripples (normalized to ellipse shape)
    float ripple_factor = 0.0;
    if (splash_amplitude > 0.0) {
        vec2 ripple_uv = pos / vec2(radius_x, ellipse_radius_y);
        float r_dist = length(ripple_uv);
        float ripple_wave = 0.5 + 0.5 * sin(r_dist * splash_frequency - TIME * splash_speed);
        float ripple_fade = smoothstep(1.0, 0.0, r_dist);
        ripple_factor = ripple_wave * ripple_fade * splash_amplitude;
    }

    // 1. Calculate the Top Oval Distance
    vec2 oval_pos = pos;
    oval_pos.y -= (wobble + ripple_factor);
    float dist = ellipse_sdf(oval_pos, vec2(radius_x, ellipse_radius_y));

    // 2. Body fill - based on the ellipse at current depth
    float x_norm = pos.x / radius_x;
    float body_edge_y = ellipse_radius_y * sqrt(max(0.0, 1.0 - x_norm * x_norm));
    float surface_y = body_edge_y + wobble;

    // Check if inside mask for fill only
    bool inside_mask = mask_value > 0.5;
    bool in_body = inside_mask && (pos.y > surface_y) && (abs(pos.x) < radius_x);

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

    // Ellipse part (only if show_ellipse is true) - renders regardless of mask
    bool in_ellipse = show_ellipse && dist < 0.0;

    // Fill part (only if show_fill is true, inside mask, and not clipped)
    bool in_fill = show_fill && in_body && !clipped_by_top;

    // Is the pixel inside the liquid?
    if (in_ellipse || in_fill) {
        final_color = liquid_color;

        // Depth Darkening
        float depth = smoothstep(ellipse_center_y, 1.0, UV.y);
        final_color.rgb *= (1.0 - depth * depth_darkening);

        // Surface darkening on the ellipse (top surface)
        if (in_ellipse) {
            final_color.rgb *= (1.0 - surface_darken_amount);
            // Wave glow: brighten ripple highlights
            if (ripple_factor > 0.0) {
                final_color.rgb += (ripple_factor * 15.0) * wave_glow * final_color.rgb;
            }
        }

        // Apply ripple highlights
        if (in_ellipse && ripple_factor > 0.0) {
            final_color = mix(final_color, splash_color, ripple_factor * 10.0);
        }
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