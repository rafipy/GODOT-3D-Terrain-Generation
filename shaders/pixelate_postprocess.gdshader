// Pixelate Post-Processing Shader - Godot 4.5


shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 10.0) = 4.0;

void vertex() {
	// Full-screen quad setup - positions vertices in clip space
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	// Calculate pixelated UV coordinates
	vec2 screen_size = vec2(textureSize(screen_texture, 0));
	vec2 pixel_scale = vec2(pixel_size) / screen_size;
	
	// Snap UV to pixel grid
	vec2 pixelated_uv = floor(SCREEN_UV / pixel_scale) * pixel_scale;
	
	// Sample the screen texture at pixelated coordinates
	vec4 color = texture(screen_texture, pixelated_uv);
	
	ALBEDO = color.rgb;
	ALPHA = 1.0;
}
