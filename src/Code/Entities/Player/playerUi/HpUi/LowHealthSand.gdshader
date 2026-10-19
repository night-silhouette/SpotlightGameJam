shader_type canvas_item;
render_mode unshaded;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float elapsed = 0.0;
uniform float max_opacity = 0.62;
uniform float edge_width = 0.18;
uniform float pulse_speed = 0.32;
uniform float pulse_amount = 0.06;
uniform float grain_size = 1.4;
uniform float flow_speed = 12.0;
uniform vec4 sand_color : source_color = vec4(0.76, 0.59, 0.32, 1.0);
uniform vec4 dark_color : source_color = vec4(0.19, 0.13, 0.075, 1.0);

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
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	float short_side = min(screen_size.x, screen_size.y);
	vec2 edge_pixels = min(UV, vec2(1.0) - UV) * screen_size;
	float distance_to_edge = min(edge_pixels.x, edge_pixels.y) / short_side;
	float width = clamp(edge_width, 0.0, 0.18) * mix(0.55, 1.0, intensity);
	// 硬边界外完全透明；噪声只向边界内部侵蚀，不能侵入中央视野。
	if (distance_to_edge >= width || intensity <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		vec2 p = UV * screen_size;
		vec2 flow = vec2(elapsed * flow_speed * 0.35, -elapsed * flow_speed);
		float erosion = noise((p + flow * 0.25) / (short_side * 0.045));
		float local_width = width * mix(0.58, 1.0, erosion);
		float rim = 1.0 - smoothstep(0.0, local_width, distance_to_edge);
		float grains = noise((p + flow) / max(grain_size, 0.5));
		float flecks = smoothstep(0.62, 0.9, grains);
		float dust = mix(0.45, 1.0, grains) + flecks * 0.18;
		float pulse = 1.0 - clamp(pulse_amount, 0.0, 0.15) *
			(0.5 + 0.5 * sin(elapsed * pulse_speed * 6.283185));
		vec4 sand = mix(dark_color, sand_color, smoothstep(0.2, 0.82, grains));
		float alpha = clamp(rim * dust * intensity * max_opacity * pulse * sand.a, 0.0, max_opacity);
		COLOR = vec4(sand.rgb, alpha);
	}
}
