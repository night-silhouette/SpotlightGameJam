shader_type canvas_item;
render_mode unshaded;

// CanvasGroup 先合成全部 Boss 画面层，再统一扭曲，避免动画图集串帧及层间接缝。
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float effect_strength : hint_range(0.0, 1.0) = 0.65;
uniform float distortion_pixels : hint_range(0.0, 8.0) = 3.5;
uniform float flow_speed : hint_range(0.0, 3.0) = 0.65;
uniform float vein_strength : hint_range(0.0, 1.0) = 0.2;
uniform float tint_strength : hint_range(0.0, 1.0) = 0.12;
uniform vec4 corruption_color : source_color = vec4(0.24, 0.085, 0.31, 1.0);

varying vec2 entity_position;

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

void vertex() {
	entity_position = VERTEX;
}

void fragment() {
	float t = TIME * flow_speed;
	vec2 p = entity_position / 110.0;
	float drift = noise(p * 0.8 + vec2(t * 0.23, -t * 0.18));
	float detail = noise(p * 2.1 + vec2(-t * 0.14, t * 0.28));
	vec2 flow = vec2(
		sin(p.y * 2.8 + t * 1.2 + drift * 4.0),
		cos(p.x * 2.4 - t * 0.9 + detail * 3.0)
	);
	vec2 warp = flow * SCREEN_PIXEL_SIZE * distortion_pixels * effect_strength;
	vec4 body = textureLod(screen_texture, SCREEN_UV + warp, 0.0);
	// CanvasGroup 缓冲是预乘 alpha；还原后交回 Godot 的正常透明混合。
	vec3 source_rgb = body.rgb / max(body.a, 0.0001);
	float pulse = 0.5 + 0.5 * sin(t * 1.7 + drift * 5.0);
	float vein_field = noise(p * 2.8 + vec2(drift * 2.2, -t * 0.2));
	float veins = 1.0 - smoothstep(0.025, 0.09, abs(vein_field - 0.5));
	vec3 corrupted = mix(source_rgb, corruption_color.rgb * 0.42,
		tint_strength * effect_strength);
	corrupted *= 1.0 - effect_strength * (0.025 + 0.045 * pulse);
	corrupted += corruption_color.rgb * veins * vein_strength * effect_strength
		* (0.45 + 0.55 * pulse);
	COLOR *= vec4(corrupted, body.a);
}
