// Toon/Cel-Shaded Terrain Shader - Godot 4.5
// Stylized look with color banding and stepped lighting

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

// Terrain color palette - height-based
uniform vec4 color_beach : source_color = vec4(0.89, 0.84, 0.65, 1.0);  // Sandy beach
uniform vec4 color_grass_low : source_color = vec4(0.50, 0.75, 0.35, 1.0);  // Bright grass
uniform vec4 color_grass_mid : source_color = vec4(0.35, 0.60, 0.25, 1.0);  // Mid grass
uniform vec4 color_forest : source_color = vec4(0.25, 0.45, 0.20, 1.0);  // Dark forest
uniform vec4 color_mountain : source_color = vec4(0.55, 0.50, 0.45, 1.0);  // Rocky
uniform vec4 color_peak : source_color = vec4(0.92, 0.92, 0.95, 1.0);  // Snow

// Height thresholds (absolute Y world coordinates)
uniform float height_beach : hint_range(-5.0, 10.0) = 2.0;
uniform float height_grass_low : hint_range(0.0, 20.0) = 8.0;
uniform float height_grass_mid : hint_range(5.0, 30.0) = 15.0;
uniform float height_forest : hint_range(10.0, 40.0) = 22.0;
uniform float height_mountain : hint_range(15.0, 50.0) = 30.0;
uniform float max_height : hint_range(20.0, 100.0) = 40.0;

// Toon shading parameters
uniform int shadow_steps : hint_range(2, 5) = 3;  // Number of discrete shadow levels
uniform float shadow_softness : hint_range(0.0, 0.2) = 0.05;
uniform float rim_light_power : hint_range(0.0, 10.0) = 3.0;
uniform vec4 rim_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.6;

// Slope detection for rocky areas
uniform float slope_threshold : hint_range(0.3, 0.9) = 0.6;

varying float vertex_height;
varying vec3 world_normal;


void vertex() {
	// Pass world-space height and normal to fragment
	vec4 world_pos = MODEL_MATRIX * vec4(VERTEX, 1.0);
	vertex_height = world_pos.y;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}


vec4 get_height_color(float height) {
	vec4 color;
	
	if (height < height_beach) {
		color = color_beach;
	} else if (height < height_grass_low) {
		float t = smoothstep(height_beach, height_grass_low, height);
		color = mix(color_beach, color_grass_low, t);
	} else if (height < height_grass_mid) {
		float t = smoothstep(height_grass_low, height_grass_mid, height);
		color = mix(color_grass_low, color_grass_mid, t);
	} else if (height < height_forest) {
		float t = smoothstep(height_grass_mid, height_forest, height);
		color = mix(color_grass_mid, color_forest, t);
	} else if (height < height_mountain) {
		float t = smoothstep(height_forest, height_mountain, height);
		color = mix(color_forest, color_mountain, t);
	} else {
		float t = smoothstep(height_mountain, max_height, height);
		color = mix(color_mountain, color_peak, t);
	}
	
	return color;
}


float toon_lighting(float ndotl) {
	// Create stepped lighting bands
	float light_intensity = ndotl * 0.5 + 0.5;  // Remap from [-1,1] to [0,1]
	
	// Quantize into discrete steps
	float step_size = 1.0 / float(shadow_steps);
	float stepped = floor(light_intensity / step_size) * step_size;
	
	// Add slight smoothing at band edges
	float smoothed = mix(stepped, light_intensity, shadow_softness);
	
	return clamp(smoothed, 0.1, 1.0);  // Minimum ambient
}


void fragment() {
	// Get base color from height
	vec4 base_color = get_height_color(vertex_height);
	
	// Detect steep slopes and blend with mountain color
	float slope = 1.0 - abs(dot(world_normal, vec3(0.0, 1.0, 0.0)));
	if (slope > slope_threshold) {
		float blend = smoothstep(slope_threshold, slope_threshold + 0.2, slope);
		base_color = mix(base_color, color_mountain, blend * 0.7);
	}
	
	// Calculate toon lighting
	vec3 light_dir = normalize(vec3(0.5, 1.0, 0.3));  // Default directional light
	float ndotl = dot(world_normal, light_dir);
	float light = toon_lighting(ndotl);
	
	// Rim lighting for edge highlights (toon style)
	vec3 view_dir = normalize(VIEW);
	float rim = 1.0 - max(dot(world_normal, view_dir), 0.0);
	rim = smoothstep(rim_threshold, 1.0, rim);
	rim = pow(rim, rim_light_power);
	
	// Combine lighting
	vec3 lit_color = base_color.rgb * light;
	lit_color += rim_color.rgb * rim * 0.3;
	
	ALBEDO = lit_color;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
	SPECULAR = 0.1;
}
