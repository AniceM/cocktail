shader_type canvas_item;

// Glow configuration
uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float glow_intensity : hint_range(0.0, 10.0) = 1.5;
uniform float glow_size : hint_range(0.0, 0.15) = 0.04;
uniform float pulse_speed : hint_range(0.0, 5.0) = 3.0;
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.9;

// Inner luminance
uniform float inner_glow_intensity : hint_range(0.0, 1.0) = 0.25;

// Optional shimmer - single band that sweeps across periodically
uniform bool enable_shimmer = true;
uniform float shimmer_interval : hint_range(1.0, 10.0) = 2.0; // Seconds between shimmers
uniform float shimmer_duration : hint_range(0.1, 2.0) = 1.0;  // How long the sweep takes
uniform float shimmer_width : hint_range(0.05, 0.3) = 0.25;   // Width of the shimmer band
uniform float shimmer_intensity : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float original_alpha = tex_color.a;

    // Pulse factor (0.0 to 1.0 oscillation)
    float pulse = (sin(TIME * pulse_speed) * 0.5 + 0.5) * pulse_amount + (1.0 - pulse_amount);

    // Sample surrounding pixels for outer glow
    float glow = 0.0;
    float current_glow_size = glow_size * (0.8 + 0.2 * pulse);

    // 8-direction sampling for glow detection
    for (float angle = 0.0; angle < 6.28318; angle += 0.785398) { // 8 samples
        vec2 offset = vec2(cos(angle), sin(angle)) * current_glow_size;
        glow += texture(TEXTURE, UV + offset).a;
    }
    glow /= 8.0;

    // Additional samples at half distance for smoother glow
    float inner_sample = 0.0;
    for (float angle = 0.0; angle < 6.28318; angle += 0.785398) {
        vec2 offset = vec2(cos(angle), sin(angle)) * current_glow_size * 0.5;
        inner_sample += texture(TEXTURE, UV + offset).a;
    }
    inner_sample /= 8.0;
    glow = max(glow, inner_sample * 1.2);

    // Create glow only where original is transparent but neighbors have alpha
    float outer_glow = glow * (1.0 - original_alpha) * glow_intensity * pulse;

    // Inner luminance pulse - brightens the badge itself
    float inner_pulse = pulse * inner_glow_intensity;

    // Shimmer effect - single band that sweeps across periodically
    float shimmer = 0.0;
    if (enable_shimmer) {
        // Calculate where we are in the shimmer cycle
        float cycle_time = mod(TIME, shimmer_interval);

        // Only shimmer during the active duration at the start of each cycle
        if (cycle_time < shimmer_duration) {
            // Band position moves from -width to 1+width (diagonal sweep)
            float band_pos = (cycle_time / shimmer_duration) * (1.0 + shimmer_width * 2.0) - shimmer_width;

            // Distance from current pixel (diagonal) to the band
            float pixel_pos = (UV.x + UV.y) * 0.5; // 0 to 1 diagonal
            float dist_to_band = abs(pixel_pos - band_pos);

            // Soft band falloff
            float band = 1.0 - smoothstep(0.0, shimmer_width, dist_to_band);
            shimmer = band * shimmer_intensity * original_alpha;
        }
    }

    // Combine effects
    vec3 final_color = tex_color.rgb;

    // Add inner glow to existing pixels
    final_color += glow_color.rgb * inner_pulse * original_alpha;

    // Add shimmer
    final_color += vec3(shimmer);

    // Mix in outer glow for transparent areas
    final_color = mix(final_color, glow_color.rgb, outer_glow);

    // Final alpha combines original + outer glow
    float final_alpha = max(original_alpha, outer_glow * 0.8);

    COLOR = vec4(final_color, final_alpha);
}
