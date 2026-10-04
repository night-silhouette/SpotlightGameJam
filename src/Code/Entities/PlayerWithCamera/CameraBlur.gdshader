shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float radius : hint_range(0.0, 16.0) = 0.0;
// 二维 5×5 高斯核；半径归零后整个节点隐藏，普通游戏不持续执行全屏采样。
void fragment() {
	vec4 sum = vec4(0.0);
	float total = 0.0;
	for (int x = -2; x <= 2; x++) {
		for (int y = -2; y <= 2; y++) {
			float weight = exp(-float(x*x + y*y) / 2.0);
			sum += texture(screen_texture, SCREEN_UV + vec2(float(x), float(y)) * SCREEN_PIXEL_SIZE * radius) * weight;
			total += weight;
		}
	}
	COLOR = vec4((sum / total).rgb, 1.0);
}
