shader_type canvas_item;

uniform float offset_x = 0.0;

void fragment() {
	vec2 uv = UV;
	uv.x = fract(uv.x + offset_x);
	COLOR = texture(TEXTURE, uv);
}
