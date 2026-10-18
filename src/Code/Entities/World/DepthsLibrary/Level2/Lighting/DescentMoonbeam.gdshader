shader_type canvas_item;
render_mode unshaded, blend_add;

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
	// 横向细分明暗光路；纵向缓慢漂移的密度模拟雾尘散射。
	float drift = TIME * 0.025;
	float rays = noise(vec2(UV.x * 16.0 + sin(TIME * 0.12) * 0.3, 2.0));
	rays = smoothstep(0.12, 0.88, rays);
	float mist = noise(vec2(UV.x * 5.0, UV.y * 13.0 - drift));
	float fine_mist = noise(vec2(UV.x * 17.0 + drift, UV.y * 55.0 - drift * 2.0));
	float sides = smoothstep(0.0, 0.30, UV.x) * (1.0 - smoothstep(0.70, 1.0, UV.x));
	// 全井保持连续长条光路，仅在穿过下方出口后柔和消散。
	float depth = smoothstep(0.0, 0.004, UV.y) * (1.0 - smoothstep(0.88, 1.0, UV.y));
	float scatter = (0.30 + rays * 1.25) * (0.75 + mist * 0.30 + fine_mist * 0.08);
	COLOR.a *= sides * depth * scatter;
}
