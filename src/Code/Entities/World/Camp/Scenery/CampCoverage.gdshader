shader_type canvas_item;
render_mode unshaded;
uniform bool foreground = false;
uniform float opacity = 1.0;
uniform float enabled = 1.0;
uniform vec2 player_world = vec2(-100000.0);
uniform float clear_radius = 100.0;
varying vec2 world_pixel;
void vertex() {
	world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	// 保留整张分层原画及不透明边缘，不再按地面截断植物和岩壁。
	COLOR.a *= enabled;
	if (foreground) {
		COLOR.a *= opacity;
	}
}
