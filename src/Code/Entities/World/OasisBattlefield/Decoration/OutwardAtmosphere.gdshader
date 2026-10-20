shader_type canvas_item;
render_mode blend_add, unshaded;

uniform vec4 glow_color : source_color = vec4(0.47, 0.92, 0.42, 1.0);
uniform float glow_strength : hint_range(0.0, 0.35, 0.005) = 0.16;

void fragment() {
	float vertical_lift = 1.0 - smoothstep(0.05, 0.95, UV.y);
	float broad_patches = sin(UV.x * 31.4159 + sin(UV.x * 9.0) * 0.7) * 0.5 + 0.5;
	float breathe = 0.96 + sin(TIME * 0.42 + UV.x * 5.0) * 0.04;
	float strength = glow_strength * (0.42 + vertical_lift * 0.34 + broad_patches * 0.24) * breathe;
	COLOR = vec4(glow_color.rgb, strength);
}
