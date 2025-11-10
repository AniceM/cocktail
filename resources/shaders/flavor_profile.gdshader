shader_type canvas_item;

// The 6 stat values (0.0 to 1.0)
uniform float stat_0 : hint_range(0.0, 1.0) = 0.5;
uniform float stat_1 : hint_range(0.0, 1.0) = 0.5;
uniform float stat_2 : hint_range(0.0, 1.0) = 0.5;
uniform float stat_3 : hint_range(0.0, 1.0) = 0.5;
uniform float stat_4 : hint_range(0.0, 1.0) = 0.5;
uniform float stat_5 : hint_range(0.0, 1.0) = 0.5;

// Base color for the center/whole shape
uniform vec4 base_color : source_color = vec4(0.3, 0.5, 0.8, 0.7);

// Colors for each of the 6 vertices/categories
uniform vec4 vertex_color_0 : source_color = vec4(1.0, 0.3, 0.3, 1.0); // Red
uniform vec4 vertex_color_1 : source_color = vec4(1.0, 0.8, 0.3, 1.0); // Yellow
uniform vec4 vertex_color_2 : source_color = vec4(0.3, 1.0, 0.3, 1.0); // Green
uniform vec4 vertex_color_3 : source_color = vec4(0.3, 0.8, 1.0, 1.0); // Cyan
uniform vec4 vertex_color_4 : source_color = vec4(0.3, 0.3, 1.0, 1.0); // Blue
uniform vec4 vertex_color_5 : source_color = vec4(1.0, 0.3, 1.0, 1.0); // Magenta

// Minimum size of the polygon (when all stats are 0)
uniform float min_size : hint_range(0.0, 0.5) = 0.1;

// How far from vertices the color starts to appear (0.0 = at center, 1.0 = only at vertex)
uniform float gradient_start : hint_range(0.0, 1.0) = 0.6;

// How much the vertex colors influence the base color at the vertices
uniform float color_influence : hint_range(0.0, 1.0) = 0.8;

// Visual enhancements
uniform float edge_softness : hint_range(0.0, 0.1) = 0.02;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 5.0) = 1.0;
uniform float pulse_amount : hint_range(0.0, 0.3) = 0.1;

// Rotation offset (in radians)
uniform float rotation_offset : hint_range(0.0, 6.28318) = 1.5708;

const float TWO_PI = 6.28318530718;

float get_stat_value(int index) {
    if (index == 0) return stat_0;
    if (index == 1) return stat_1;
    if (index == 2) return stat_2;
    if (index == 3) return stat_3;
    if (index == 4) return stat_4;
    return stat_5;
}

vec4 get_vertex_color(int index) {
    if (index == 0) return vertex_color_0;
    if (index == 1) return vertex_color_1;
    if (index == 2) return vertex_color_2;
    if (index == 3) return vertex_color_3;
    if (index == 4) return vertex_color_4;
    return vertex_color_5;
}

vec2 get_vertex_position(int index, float pulse) {
    float angle = (float(index) * TWO_PI / 6.0) + rotation_offset;
    float stat = get_stat_value(index);
    
    // Apply minimum size and then scale to full range
    float adjusted_stat = min_size + (stat * (1.0 - min_size));
    adjusted_stat = adjusted_stat * (1.0 + pulse);
    
    return vec2(cos(angle), sin(angle)) * adjusted_stat * 0.5;
}

float get_vertex_angle(int index) {
    return (float(index) * TWO_PI / 6.0) + rotation_offset;
}

float sign_of_triangle(vec2 p, vec2 a, vec2 b) {
    return (p.x - b.x) * (a.y - b.y) - (a.x - b.x) * (p.y - b.y);
}

bool point_in_triangle(vec2 p, vec2 a, vec2 b, vec2 c) {
    float d1 = sign_of_triangle(p, a, b);
    float d2 = sign_of_triangle(p, b, c);
    float d3 = sign_of_triangle(p, c, a);
    
    bool has_neg = (d1 < 0.0) || (d2 < 0.0) || (d3 < 0.0);
    bool has_pos = (d1 > 0.0) || (d2 > 0.0) || (d3 > 0.0);
    
    return !(has_neg && has_pos);
}

float distance_to_segment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

void fragment() {
    vec2 pos = UV - 0.5;
    
    float pulse = sin(TIME * pulse_speed) * pulse_amount;
    
    vec2 center = vec2(0.0, 0.0);
    bool inside = false;
    float min_edge_dist = 1000.0;
    
    // Check if inside polygon
    for (int i = 0; i < 6; i++) {
        vec2 v1 = get_vertex_position(i, pulse);
        vec2 v2 = get_vertex_position((i + 1) % 6, pulse);
        
        if (point_in_triangle(pos, center, v1, v2)) {
            inside = true;
        }
        
        float edge_dist = distance_to_segment(pos, v1, v2);
        min_edge_dist = min(min_edge_dist, edge_dist);
    }
    
    if (inside) {
        // Start with base color
        vec4 final_color = base_color;
        
        // Calculate influence from each vertex
        vec4 color_accumulator = vec4(0.0);
        float weight_sum = 0.0;
        
        for (int i = 0; i < 6; i++) {
            vec2 vertex_pos = get_vertex_position(i, pulse);
            float vertex_angle = get_vertex_angle(i);
            vec2 vertex_direction = vec2(cos(vertex_angle), sin(vertex_angle));
            
            float max_distance = length(vertex_pos);
            
            // Distance to this specific vertex
            float distance_to_vertex = distance(pos, vertex_pos);
            
            // Distance from center
            float distance_from_center = length(pos);
            
            // How close are we to this vertex? (0 = at vertex, 1 = at center)
            float normalized_distance = distance_to_vertex / (max_distance + 0.001);
            
            // Only apply gradient in the outer portion (controlled by gradient_start)
            float gradient_factor = smoothstep(gradient_start, 1.0, 1.0 - normalized_distance);
            
            // Check alignment with vertex direction (to avoid bleeding into other sectors)
            float alignment = max(0.0, dot(normalize(pos + vec2(0.001)), vertex_direction));
            
            // Stat value affects intensity (use original stat value, not adjusted)
            float stat = get_stat_value(i);
            
            // Combine all factors
            float influence = gradient_factor * alignment * stat;
            
            color_accumulator += get_vertex_color(i) * influence;
            weight_sum += influence;
        }
        
        // Blend the vertex colors into the base color
        if (weight_sum > 0.0) {
            vec4 vertex_blend = color_accumulator / weight_sum;
            final_color = mix(base_color, vertex_blend, color_influence * weight_sum);
        }
        
        // Soft edge fade
        float edge_fade = smoothstep(0.0, edge_softness, min_edge_dist);
        
        // Add glow effect
        float glow = (1.0 - edge_fade) * glow_intensity;
        final_color.rgb += vec3(glow);
        
        // Apply edge fade to alpha
        final_color.a *= edge_fade;
        
        COLOR = final_color;
    } else {
        COLOR = vec4(0.0);
    }
}