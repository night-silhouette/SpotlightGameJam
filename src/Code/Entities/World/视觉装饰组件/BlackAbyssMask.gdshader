shader_type canvas_item;
render_mode unshaded;

// 挂到 ColorRect 或 Polygon2D 的 ShaderMaterial 上：上缘透明，向下逐渐沉入黑色深渊。
// silhouette_visibility 会为被遮住的人物和场景保留剪影，避免完全消失。
uniform vec4 abyss_color : source_color = vec4(0.002, 0.004, 0.008, 1.0);
uniform vec4 dark_glow_color : source_color = vec4(0.045, 0.065, 0.095, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.88;
uniform float silhouette_visibility : hint_range(0.0, 0.6) = 0.2;
uniform float fade_start : hint_range(0.0, 1.0) = 0.04;
uniform float solid_start : hint_range(0.0, 1.0) = 0.58;
uniform float side_fade : hint_range(0.0, 0.5) = 0.08;

uniform float edge_roughness : hint_range(0.0, 0.3) = 0.055;
uniform float fog_amount : hint_range(0.0, 0.5) = 0.09;
uniform float fog_scale : hint_range(0.5, 20.0) = 5.0;
uniform float fog_speed : hint_range(0.0, 1.0) = 0.045;
uniform float dark_glow_strength : hint_range(0.0, 1.0) = 0.24;
uniform float ray_strength : hint_range(0.0, 0.5) = 0.1;
uniform float ray_scale : hint_range(2.0, 40.0) = 16.0;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	float bottom_left = hash(cell);
	float bottom_right = hash(cell + vec2(1.0, 0.0));
	float top_left = hash(cell + vec2(0.0, 1.0));
	float top_right = hash(cell + vec2(1.0, 1.0));
	return mix(
		mix(bottom_left, bottom_right, local.x),
		mix(top_left, top_right, local.x),
		local.y
	);
}

float layered_noise(vec2 point) {
	float noise_value = value_noise(point) * 0.62;
	noise_value += value_noise(point * 2.07 + vec2(3.1, 7.4)) * 0.26;
	noise_value += value_noise(point * 4.13 + vec2(9.2, 1.7)) * 0.12;
	return noise_value;
}

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	vec2 drift = vec2(TIME * fog_speed, -TIME * fog_speed * 0.73);
	float fog = layered_noise(UV * fog_scale + drift);

	// 噪声只打散渐变边界，不会让已经沉入的底部变透。
	float rough_edge = (fog - 0.5) * edge_roughness;
	float depth = smoothstep(fade_start + rough_edge, max(solid_start, fade_start + 0.001), UV.y);

	float horizontal_mask = 1.0;
	if (side_fade > 0.0) {
		horizontal_mask = smoothstep(0.0, side_fade, UV.x);
		horizontal_mask *= smoothstep(0.0, side_fade, 1.0 - UV.x);
	}

	float fog_modulation = mix(1.0 - fog_amount, 1.0, fog);

	// 竖向拉长的噪声形成缓慢流动的暗色光束，只打开暗部层次，不变成明亮发光。
	vec2 ray_uv = vec2(UV.x * ray_scale, UV.y * 1.35 - TIME * fog_speed * 0.45);
	float rays = pow(value_noise(ray_uv), 4.0);
	rays *= 1.0 - smoothstep(0.2, 1.0, depth);
	float transition_glow = 4.0 * depth * (1.0 - depth);
	float dark_glow = clamp(transition_glow * dark_glow_strength + rays * ray_strength, 0.0, 1.0);

	float alpha = source.a * abyss_color.a * opacity * depth * horizontal_mask * fog_modulation;
	alpha *= mix(1.0, 0.86, dark_glow);
	alpha = min(alpha, 1.0 - silhouette_visibility);
	vec3 final_color = mix(abyss_color.rgb, dark_glow_color.rgb, dark_glow);
	COLOR = vec4(final_color, alpha);
}
