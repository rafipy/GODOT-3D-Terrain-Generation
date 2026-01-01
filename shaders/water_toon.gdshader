// Toon Style 3D Water Shader - Godot 4.5
// Based on Megalithium's shader (CC0 License)
// https://godotshaders.com/shader/toon-style-3d-water-shader-no-textures-needed/

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Water colors
uniform vec4 WATER_COL : source_color = vec4(0.04, 0.38, 0.88, 1.0);
uniform vec4 WATER2_COL : source_color = vec4(0.04, 0.35, 0.78, 1.0);
uniform vec4 FOAM_COL : source_color = vec4(0.8125, 0.9609, 0.9648, 1.0);

// Animation params
uniform float distortion_speed : hint_range(0.0, 5.0) = 2.0;
uniform vec2 tile = vec2(5.0, 5.0);
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wave_amplitude : hint_range(0.0, 2.0) = 0.5;
uniform float wave_frequency : hint_range(0.0, 5.0) = 1.5;

// Depth/transparency
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float water_transparency : hint_range(0.0, 1.0) = 0.8;
uniform float water_depth_factor : hint_range(0.0, 1.0) = 0.1;

// Foam settings
uniform float foam_width : hint_range(0.0, 2.0) = 0.5;
uniform float foam_edge_softness : hint_range(0.0, 0.5) = 0.05;
uniform float foam_distortion_speed : hint_range(0.0, 2.0) = 0.5;
uniform float foam_distortion_amount : hint_range(0.0, 0.5) = 0.1;

// Distance fade settings
uniform float fade_start : hint_range(0.0, 1000.0) = 150.0;
uniform float fade_end : hint_range(0.0, 2000.0) = 600.0;

const float TWOPI = 6.283185307;
const float SIXPI = 18.84955592;


float noise(vec2 uv) {
	return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}


float smooth_noise(vec2 uv) {
	vec2 id = floor(uv);
	vec2 f = fract(uv);
	
	float a = noise(id);
	float b = noise(id + vec2(1.0, 0.0));
	float c = noise(id + vec2(0.0, 1.0));
	float d = noise(id + vec2(1.0, 1.0));
	
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}


float calculate_foam(vec2 uv, float depth_diff, float time) {
	vec2 distorted_uv = uv + vec2(
		smooth_noise(uv * 5.0 + time * foam_distortion_speed) * foam_distortion_amount,
		smooth_noise(uv * 5.0 + 100.0 + time * foam_distortion_speed) * foam_distortion_amount
	);
	
	float foam_shape = smoothstep(0.0, foam_width, abs(depth_diff));
	foam_shape = smoothstep(foam_edge_softness, 0.0, foam_shape);
	foam_shape *= smooth_noise(distorted_uv * 10.0);
	
	return foam_shape;
}


float calculate_wave_height(vec2 position, float time) {
	float wave_x = sin(position.x * wave_frequency + time * wave_speed);
	float wave_y = cos(position.y * wave_frequency + time * wave_speed);
	return (wave_x + wave_y) * 0.5 * wave_amplitude;
}


void vertex() {
	vec4 world_position = MODEL_MATRIX * vec4(VERTEX, 1.0);
	float wave = calculate_wave_height(world_position.xz, TIME);
	VERTEX.y += wave;
}


float circ(vec2 pos, vec2 c, float s) {
	c = abs(pos - c);
	c = min(c, 1.0 - c);
	return smoothstep(0.0, 0.002, sqrt(s) - sqrt(dot(c, c))) * -1.0;
}


float waterlayer(vec2 uv) {
	uv = mod(uv, 1.0);
	float ret = 1.0;
	
	ret += circ(uv, vec2(0.37378, 0.277169), 0.0268181);
	ret += circ(uv, vec2(0.0317477, 0.540372), 0.0193742);
	ret += circ(uv, vec2(0.430044, 0.882218), 0.0232337);
	ret += circ(uv, vec2(0.641033, 0.695106), 0.0117864);
	ret += circ(uv, vec2(0.0146398, 0.0791346), 0.0299458);
	ret += circ(uv, vec2(0.43871, 0.394445), 0.0289087);
	ret += circ(uv, vec2(0.909446, 0.878141), 0.028466);
	ret += circ(uv, vec2(0.310149, 0.686637), 0.0128496);
	ret += circ(uv, vec2(0.928617, 0.195986), 0.0152041);
	ret += circ(uv, vec2(0.0438506, 0.868153), 0.0268601);
	ret += circ(uv, vec2(0.308619, 0.194937), 0.00806102);
	ret += circ(uv, vec2(0.349922, 0.449714), 0.00928667);
	ret += circ(uv, vec2(0.0449556, 0.953415), 0.023126);
	ret += circ(uv, vec2(0.117761, 0.503309), 0.0151272);
	ret += circ(uv, vec2(0.563517, 0.244991), 0.0292322);
	ret += circ(uv, vec2(0.566936, 0.954457), 0.00981141);
	ret += circ(uv, vec2(0.0489944, 0.200931), 0.0178746);
	ret += circ(uv, vec2(0.569297, 0.624893), 0.0132408);
	ret += circ(uv, vec2(0.298347, 0.710972), 0.0114426);
	ret += circ(uv, vec2(0.878141, 0.771279), 0.00322719);
	ret += circ(uv, vec2(0.629598, 0.295629), 0.0198736);
	ret += circ(uv, vec2(0.334357, 0.266278), 0.0187145);
	ret += circ(uv, vec2(0.918044, 0.968163), 0.0182928);
	ret += circ(uv, vec2(0.514847, 0.865444), 0.00623523);
	ret += circ(uv, vec2(0.71403, 0.576945), 0.0215641);
	ret += circ(uv, vec2(0.748873, 0.413325), 0.0110795);
	ret += circ(uv, vec2(0.0623365, 0.896713), 0.0236203);
	ret += circ(uv, vec2(0.647463, 0.654349), 0.0188713);
	ret += circ(uv, vec2(0.428928, 0.382426), 0.0298806);
	ret += circ(uv, vec2(0.525104, 0.572233), 0.0141796);
	ret += circ(uv, vec2(0.431526, 0.911372), 0.0213234);
	ret += circ(uv, vec2(0.514523, 0.243263), 0.0270685);
	ret += circ(uv, vec2(0.502214, 0.47269), 0.0234534);
	ret += circ(uv, vec2(0.693271, 0.431469), 0.0246533);
	ret += circ(uv, vec2(0.415, 0.884418), 0.0271696);
	ret += circ(uv, vec2(0.638585, 0.646019), 0.0206129);
	ret += circ(uv, vec2(0.99871, 0.583864), 0.0107329);
	ret += circ(uv, vec2(0.0761895, 0.16327), 0.0145935);
	ret += circ(uv, vec2(0.949386, 0.802936), 0.0100873);
	ret += circ(uv, vec2(0.896854, 0.803707), 0.013969);
	ret += circ(uv, vec2(0.506365, 0.531118), 0.0144016);
	ret += circ(uv, vec2(0.408806, 0.894771), 0.0243923);
	ret += circ(uv, vec2(0.987324, 0.146545), 0.0288391);
	
	return max(ret, 0.0);
}


vec4 water(vec2 uv, vec3 cdir, float iTime) {
	uv *= vec2(0.25);

	vec2 a = 0.025 * cdir.xz / cdir.y;
	float h = sin(uv.x + iTime);
	uv += a * h;
	h = sin(0.841471 * uv.x - 0.540302 * uv.y + iTime);
	uv += a * h;

	float d1 = mod(uv.x + uv.y, TWOPI);
	float d2 = mod((uv.x + uv.y + 0.25) * 1.3, SIXPI);
	d1 = iTime * 0.07 + d1;
	d2 = iTime * 0.5 + d2;
	vec2 dist = vec2(
		sin(d1) * 0.15 + sin(d2) * 0.05,
		cos(d1) * 0.15 + cos(d2) * 0.05
	);

	vec4 ret = mix(WATER_COL, WATER2_COL, waterlayer(uv + dist.xy));
	ret = mix(ret, FOAM_COL, waterlayer(vec2(1.0) - uv - dist.yx));
	return ret;
}


void fragment() {
	vec4 water_color = water(UV * tile, vec3(0, 1, 0), TIME * distortion_speed);
	
	// Calculate distance from camera to water fragment
	vec4 world_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 camera_pos = INV_VIEW_MATRIX[3].xyz;
	float distance_to_camera = length(world_pos.xyz - camera_pos);
	
	// Calculate distance fade factor
	float fade_factor = clamp((distance_to_camera - fade_start) / (fade_end - fade_start), 0.0, 1.0);
	fade_factor = smoothstep(0.0, 1.0, fade_factor);
	
	float scene_depth = texture(DEPTH_TEXTURE, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, scene_depth);
	vec4 view_coords = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view_coords.xyz /= view_coords.w;
	float linear_scene_depth = -view_coords.z;
	
	vec4 water_world_pos = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 water_view_pos = VIEW_MATRIX * water_world_pos;
	float linear_water_depth = -water_view_pos.z;
	
	float depth_diff = linear_scene_depth - linear_water_depth;
	
	// Only render water effects if looking from above (camera above water level)
	// This prevents glitching when viewing terrain from below water plane
	bool camera_above_water = camera_pos.y > water_world_pos.y;
	
	if (!camera_above_water || depth_diff < 0.001) {
		// Discard fragments below water or when camera is underwater
		discard;
	}
	
	float foam = calculate_foam(UV, depth_diff, TIME);
	float water_opacity = clamp(depth_diff * water_depth_factor, 0.0, 1.0);
	
	vec4 background = texture(SCREEN_TEXTURE, SCREEN_UV);
	vec4 final_color = mix(background, water_color, water_opacity * water_transparency);
	final_color = mix(final_color, FOAM_COL, foam);
	
	// Apply distance fade to alpha
	ALBEDO = final_color.rgb;
	ALPHA = final_color.a * (1.0 - fade_factor);
}
