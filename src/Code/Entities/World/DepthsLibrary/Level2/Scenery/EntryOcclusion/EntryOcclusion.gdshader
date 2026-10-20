shader_type canvas_item;

uniform vec4 entry_bounds = vec4(0.0);
uniform float conceal_amount : hint_range(0.0, 1.0) = 0.0;
varying vec2 world_pixel;

void vertex() {
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	bool in_entry = world_pixel.x >= entry_bounds.x && world_pixel.x < entry_bounds.z
		&& world_pixel.y >= entry_bounds.y && world_pixel.y < entry_bounds.w;
	if (in_entry) {
		COLOR.a *= 1.0 - conceal_amount;
	}
}
