shader_type canvas_item;
render_mode unshaded;

// 将 Boss 主体的矩形右边缘打散，使触手像从同一团腐化物中自然伸出。
uniform float edge_fade_ratio : hint_range(0.001, 1.0) = 0.31;
uniform float edge_breakup : hint_range(0.0, 1.0) = 0.72;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), f.x),
		mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0)), f.x), f.y);
}

void fragment() {
	float fade_distance = clamp((1.0 - UV.x) / max(edge_fade_ratio, 0.001), 0.0, 1.0);
	float broad_noise = noise(vec2(UV.y * 18.0, UV.x * 5.0));
	float detail_noise = noise(vec2(UV.y * 47.0 + 13.7, UV.x * 11.0 - 4.2));
	float contour = mix(0.5, broad_noise * 0.72 + detail_noise * 0.28, edge_breakup);
	float dissolve_mask = smoothstep(contour - 0.14, contour + 0.14, fade_distance);
	COLOR.a *= dissolve_mask;
}
