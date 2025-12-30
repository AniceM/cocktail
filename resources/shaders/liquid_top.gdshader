shader_type canvas_item;

// Wobble settings
uniform float wobble_strength : hint_range(0.0, 0.1) = 0.02;
uniform float wobble_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wave_count : hint_range(1.0, 8.0) = 3.0;

// Ellipse shape
uniform float ellipse_radius_x : hint_range(0.0, 1.0) = 0.45;
uniform float ellipse_radius_y : hint_range(0.0, 1.0) = 0.25;

// Colors
uniform vec4 liquid_color : source_color = vec4(0.9, 0.5, 0.2, 1.0);
uniform vec4 rim_color : source_color = vec4(1.0, 0.8, 0.5, 1.0);

// Rim settings
uniform float rim_thickness : hint_range(0.0, 0.05) = 0.015;
uniform bool show_top_rim = true;
uniform bool show_bottom_rim = true;

float get_wobble(float angle) {
    float wobble = sin(angle * wave_count + TIME * wobble_speed);
    wobble += sin(angle * (wave_count + 2.0) - TIME * wobble_speed * 1.3) * 0.5;
    return wobble * wobble_strength;
}

float ellipse_sdf(vec2 uv, vec2 radius) {
    vec2 p = uv / radius;
    return (length(p) - 1.0) * min(radius.x, radius.y);
}

void fragment() {
    vec2 ellipse_radius = vec2(ellipse_radius_x, ellipse_radius_y);
    vec2 center = vec2(0.5);
    vec2 pos = UV - center;
    float angle = atan(pos.y, pos.x);
    
    // Apply wobble
    float wobble = get_wobble(angle);
    vec2 wobbled_pos = pos * (1.0 + wobble);
    
    // Main liquid surface
    float dist = ellipse_sdf(wobbled_pos, ellipse_radius);
    
    // Single rim calculation
    float rim = smoothstep(rim_thickness, 0.0, abs(dist));
    
    // Soft blend at the sides (transition zone)
    float blend_zone = 0.5;
    float top_mask = smoothstep(blend_zone, -blend_zone, pos.y);
    float bottom_mask = smoothstep(-blend_zone, blend_zone, pos.y);
    
    float top_rim = rim * top_mask;
    float bottom_rim = rim * bottom_mask;
    
    // Combine
    vec4 final_color = vec4(0.0);
    
    // Fill liquid
    if (dist < 0.0) {
        final_color = liquid_color;
    }
    
    // Apply rims
    if (show_bottom_rim && bottom_rim > 0.0) {
        final_color = mix(final_color, rim_color, bottom_rim);
    }
    if (show_top_rim && top_rim > 0.0) {
        final_color = mix(final_color, rim_color, top_rim);
    }
    
    COLOR = final_color;
}