shader_type canvas_item;
render_mode unshaded;

void fragment() {
	float sides = smoothstep(0.0, 0.23, UV.x) * (1.0 - smoothstep(0.77, 1.0, UV.x));
	float ends = smoothstep(0.0, 0.10, UV.y) * (1.0 - smoothstep(0.35, 1.0, UV.y));
	COLOR.a *= sides * ends;
}
