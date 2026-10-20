shader_type canvas_item;
render_mode blend_add, unshaded;

uniform float edge_softness : hint_range(0.01, 0.5) = 0.22;

void fragment() {
	float left_edge = smoothstep(0.0, edge_softness, UV.x);
	float right_edge = smoothstep(0.0, edge_softness, 1.0 - UV.x);
	float vertical_fade = 1.0 - smoothstep(0.05, 1.0, UV.y);
	float strength = left_edge * right_edge * vertical_fade;
	COLOR = vec4(COLOR.rgb, COLOR.a * strength);
}
