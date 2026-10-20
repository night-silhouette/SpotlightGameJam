shader_type canvas_item;
render_mode unshaded;

uniform vec2 clip_min = vec2(-100000.0);
uniform vec2 clip_max = vec2(100000.0);
varying vec2 world_pixel;

void vertex() {
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (world_pixel.x < clip_min.x || world_pixel.x > clip_max.x
			|| world_pixel.y < clip_min.y || world_pixel.y > clip_max.y) {
		COLOR.a = 0.0;
	}
}
