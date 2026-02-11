shader_type canvas_item;

group_uniforms Hologram_Colors;
uniform vec4 bg_color : source_color = vec4(0.0, 0.6, 1.0, 0.8);
uniform vec4 accent_color : source_color = vec4(0.0, 1.0, 0.8, 1.0);
uniform float color_shift_amount : hint_range(0.0, 0.1) = 0.02;

group_uniforms Scanlines;
uniform float scanline_count : hint_range(0.0, 200.0) = 150.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.1;
uniform float scanline_speed : hint_range(-5.0, 5.0) = -5.0;

group_uniforms Flicker;
uniform float flicker_speed : hint_range(0.0, 50.0) = 40.0;
uniform float flicker_intensity : hint_range(0.0, 0.5) = 0.01;

group_uniforms Glow;
uniform float edge_glow_width : hint_range(0.0, 0.3) = 0.08;
uniform float edge_glow_intensity : hint_range(0.0, 3.0) = 1.5;

group_uniforms Noise;
uniform float noise_intensity : hint_range(0.0, 0.15) = 0.03;
uniform float glitch_chance : hint_range(0.0, 1.0) = 0.02;
uniform float glitch_strength : hint_range(0.0, 0.05) = 0.01;

// Simple hash for noise
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;

    // --- GLITCH: occasional horizontal offset ---
    float time_block = floor(TIME * 12.0);
    float row_block = floor(uv.y * 20.0);
    float glitch_trigger = step(1.0 - glitch_chance, hash(vec2(time_block, row_block)));
    uv.x += glitch_trigger * (hash(vec2(time_block * 3.0, row_block)) - 0.5) * glitch_strength * 2.0;

    // --- SCANLINES ---
    float s_line = sin(uv.y * scanline_count + TIME * scanline_speed);
    s_line = s_line * scanline_intensity + (1.0 - scanline_intensity);

    // --- FLICKER ---
    float flicker = 1.0 + sin(TIME * flicker_speed) * flicker_intensity;
    // Add a subtle slow brightness drift
    flicker *= 1.0 + sin(TIME * 1.7) * 0.02;

    // --- CHROMATIC ABERRATION (color fringing) ---
    vec4 base = texture(TEXTURE, uv);
    float r_channel = texture(TEXTURE, uv + vec2(color_shift_amount, 0.0)).a;
    float b_channel = texture(TEXTURE, uv - vec2(color_shift_amount, 0.0)).a;
    float g_channel = base.a;

    // --- FILM GRAIN ---
    float grain = (hash(uv * 500.0 + fract(TIME * 7.0)) - 0.5) * noise_intensity;

    // --- EDGE GLOW: brighter near the panel edges ---
    float edge_x = smoothstep(0.0, edge_glow_width, uv.x) * smoothstep(0.0, edge_glow_width, 1.0 - uv.x);
    float edge_y = smoothstep(0.0, edge_glow_width, uv.y) * smoothstep(0.0, edge_glow_width, 1.0 - uv.y);
    float edge_mask = 1.0 - edge_x * edge_y; // 1 at edges, 0 in center
    vec3 glow = accent_color.rgb * edge_mask * edge_glow_intensity;

    // --- COMPOSITE ---
    vec3 holo = bg_color.rgb;
    holo *= s_line * flicker;
    holo += grain;
    holo += glow;

    // Apply chromatic aberration to alpha for that color-fringe look
    vec3 alpha_tint = vec3(r_channel, g_channel, b_channel);
    float final_alpha = base.a * bg_color.a;

    // Blend: use the chromatic channels to subtly tint the edges
    holo *= mix(vec3(1.0), alpha_tint / max(base.a, 0.001), color_shift_amount * 10.0);

    COLOR = vec4(holo, final_alpha);
}