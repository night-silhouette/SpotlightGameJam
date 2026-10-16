shader_type canvas_item;
render_mode unshaded;

uniform float upward_tiles_per_second = 0.75;
varying float local_y;

void vertex() {
	local_y = VERTEX.y;
}

void fragment() {
	COLOR = texture(TEXTURE, UV + vec2(0.0, TIME * upward_tiles_per_second));
	COLOR.a *= 0.7 * smoothstep(-4431.25, -4181.25, local_y);
}
