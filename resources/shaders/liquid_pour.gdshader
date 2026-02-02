shader_type canvas_item;

// --- COLORS ---
uniform vec4 liquid_color : source_color = vec4(0.8, 0.4, 0.1, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.9, 0.6, 0.3, 1.0);

// --- ANIMATION CONTROLS ---
uniform float pour_progress : hint_range(0.0, 1.0) = 1.0;
uniform float flow_speed : hint_range(0.5, 5.0) = 2.0;

// --- SHAPE ---
uniform float width_top : hint_range(0.01, 0.3) = 0.1;
uniform float width_bottom : hint_range(0.01, 0.4) = 0.25;

// --- MOVEMENT ---
uniform float wobble_amount : hint_range(0.0, 0.1) = 0.02;
uniform float drip_frequency : hint_range(0.5, 5.0) = 1.5;
uniform float drip_size : hint_range(0.0, 0.15) = 0.06;
uniform float drip_length : hint_range(0.05, 0.3) = 0.12;
uniform float drip_speed : hint_range(0.5, 3.0) = 1.2;

// --- TOP CURVE (New) ---
// Bends the stream horizontally at the top before falling
uniform float curve_amount : hint_range(-1.0, 1.0) = 0.2; // Negative = left, Positive = right
uniform float curve_height : hint_range(0.05, 0.5) = 0.25; // How far down the curve extends
uniform float curve_power : hint_range(1.0, 4.0) = 2.0; // 1.0 = linear, higher = sharper bend

// --- FLOW PATTERN ---
uniform float flow_pattern_intensity : hint_range(0.0, 0.15) = 0.05;
uniform float flow_pattern_frequency : hint_range(10.0, 80.0) = 40.0;

// --- RIM HIGHLIGHT ---
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float rim_power : hint_range(1.0, 5.0) = 2.0;

// --- BOTTOM FADE ---
uniform float bottom_fade_start : hint_range(0.5, 1.0) = 0.85;
uniform float bottom_fade_strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    
    // --- 1. POUR PROGRESS ---
    if (uv.y > pour_progress) {
        discard;
    }
    float x_centered = uv.x - 0.5;
    
    // --- 2. TOP CURVE (New) ---
    // Offset x position based on how close we are to the top
    // Uses inverse power curve: strong offset at top, fading to zero
    if (uv.y < curve_height) {
        float curve_factor = 1.0 - (uv.y / curve_height); // 1.0 at top, 0.0 at curve_height
        curve_factor = pow(curve_factor, curve_power); // Apply power for sharper/softer bend
        x_centered -= curve_amount * curve_factor;
    }
    
    // --- 3. WOBBLE ---
    float wobble = sin(uv.y * 20.0 - TIME * flow_speed * 3.0) * wobble_amount * uv.y;
    x_centered += wobble;
    
    // --- 4. TAPER ---
    float base_width = mix(width_top, width_bottom, uv.y);
    
    // --- 5. DRIP BULGES ---
    float drip_extra = 0.0;
    if (drip_size > 0.001) {
        for (int i = 0; i < 3; i++) {
            float phase_offset = float(i) * 0.33;
            float drip_time = fract(TIME * drip_speed * (1.0 / drip_frequency) + phase_offset);
            
            float drip_y = drip_time;
            float dist_to_drip = abs(uv.y - drip_y);
            float bulge = smoothstep(drip_length, 0.0, dist_to_drip);
            float size_factor = drip_size * (0.7 + drip_y * 0.6);
            
            drip_extra += bulge * size_factor;
        }
    }
    
    float final_width = base_width + drip_extra;
    
    // --- 6. MASKING ---
    float edge_softness = final_width * 0.05;
    float half_width = final_width * 0.5;
    float stream_alpha = 1.0 - smoothstep(half_width - edge_softness, half_width + edge_softness, abs(x_centered));
    
    // --- 7. COLOR & FLOW PATTERN ---
    float flow_pattern = sin(uv.y * flow_pattern_frequency - TIME * flow_speed * 10.0) * flow_pattern_intensity;
    
    vec4 final_color = liquid_color;
    final_color.rgb += flow_pattern;
    
    // --- 8. RIM HIGHLIGHT ---
    float edge_dist = abs(x_centered) / max(half_width, 0.001);
    edge_dist = clamp(edge_dist, 0.0, 1.0);
    float rim = pow(edge_dist, rim_power) * stream_alpha;
    final_color.rgb = mix(final_color.rgb, highlight_color.rgb, rim * rim_intensity);
    
    // --- 9. BOTTOM FADE ---
    float relative_y = uv.y / pour_progress; // 0.0 at top, 1.0 at current pour end
    float bottom_fade = 1.0 - smoothstep(bottom_fade_start, 1.0, relative_y);
    bottom_fade = mix(1.0, bottom_fade, bottom_fade_strength);

    // --- 10. FINAL ALPHA ---
    final_color.a *= stream_alpha * bottom_fade;
    
    COLOR = final_color;
}