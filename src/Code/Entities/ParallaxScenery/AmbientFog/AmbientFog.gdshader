shader_type canvas_item;
render_mode unshaded, blend_mix;

// 雾的颜色、浓度和漂移速度。
uniform vec4 fog_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.35;
uniform vec2 drift_speed = vec2(0.025, 0.005);

varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	// 移动纹理的采样位置，让云团缓慢漂移。
	vec2 moving_uv = UV - TIME * drift_speed;
	float cloud = texture(TEXTURE, moving_uv).r;

	// 四周逐渐透明，隐藏方形边界。
	vec2 edge_distance = min(UV, vec2(1.0) - UV);
	float edge_fade = smoothstep(0.0, 0.18, edge_distance.x)
		* smoothstep(0.0, 0.18, edge_distance.y);

	// 暗处更透明，亮处形成薄雾。
	float opacity = smoothstep(0.25, 0.8, cloud)
		* density * edge_fade;

	COLOR = vec4(
		fog_color.rgb * sprite_tint.rgb,
		opacity * fog_color.a * sprite_tint.a
	);
}