shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float blur_radius = 8.0;
uniform float blur_strength : hint_range(0.0, 1.0) = 1.0;
uniform float side_direction = -1.0;

void fragment() {
	vec2 radius = vec2(SCREEN_PIXEL_SIZE.x * blur_radius, 0.0);
	vec4 source = texture(screen_texture, SCREEN_UV);
	vec4 blurred = source * 0.28;
	blurred += texture(screen_texture, SCREEN_UV + radius * 0.35) * 0.20;
	blurred += texture(screen_texture, SCREEN_UV - radius * 0.35) * 0.20;
	blurred += texture(screen_texture, SCREEN_UV + radius * 0.70) * 0.12;
	blurred += texture(screen_texture, SCREEN_UV - radius * 0.70) * 0.12;
	blurred += texture(screen_texture, SCREEN_UV + radius) * 0.04;
	blurred += texture(screen_texture, SCREEN_UV - radius) * 0.04;

	float edge_mask = side_direction < 0.0 ? 1.0 - UV.x : UV.x;
	edge_mask = smoothstep(0.0, 1.0, edge_mask) * blur_strength;
	COLOR = mix(source, blurred, edge_mask);
}
