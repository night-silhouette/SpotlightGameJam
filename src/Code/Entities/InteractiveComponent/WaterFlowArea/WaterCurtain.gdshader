shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 deep_color : source_color = vec4(0.08, 0.42, 0.62, 0.68);
uniform vec4 light_color : source_color = vec4(0.32, 0.83, 0.91, 0.72);
uniform float flow_speed : hint_range(0.1, 5.0) = 1.0;
uniform float detail_scale : hint_range(0.25, 3.0) = 1.0;
uniform vec2 curtain_size = vec2(160.0, 240.0);
uniform vec2 impact_position = vec2(0.5, 0.5);
uniform float impact_strength : hint_range(0.0, 1.0) = 0.0;

varying vec2 local_pos;

float hash21(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise2(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), f.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 size = max(curtain_size, vec2(1.0));
	vec2 pixel = UV * size;
	float t = TIME * flow_speed;
	vec2 impact_delta = (UV - impact_position) * size;
	float impact_width = 26.0;
	float impact_height = 36.0;
	float spread = exp(-pow(impact_delta.y / impact_height, 2.0)) * impact_strength;
	float opening = exp(-pow(impact_delta.x / impact_width, 2.0)) * spread;
	float wake = exp(-pow(impact_delta.x / 30.0, 2.0)) *
		smoothstep(-16.0, 12.0, impact_delta.y) * (1.0 - smoothstep(40.0, 95.0, impact_delta.y)) * impact_strength;

	vec2 p = local_pos * detail_scale;
	p.x -= sign(impact_delta.x) * spread * 19.0 * exp(-pow(impact_delta.x / 38.0, 2.0));
	p.x += sin(impact_delta.y * 0.12 - t * 2.0) * wake * 4.0;
	p.y += wake * 8.0;
	float drift = noise2(vec2(p.x * 0.018, p.y * 0.011 - t * 0.35));
	float warped_x = p.x + (drift - 0.5) * 18.0 + sin(p.y * 0.013 - t * 1.7) * 3.5;
	float streaks = sin(warped_x * 0.11 + sin(warped_x * 0.037) * 2.0 + p.y * 0.012 - t * 2.2);
	float fine = sin(warped_x * 0.29 + p.y * 0.028 - t * 3.4);
	float waves = sin(p.y * 0.074 - t * 4.0 + warped_x * 0.023);
	float turbulence = noise2(vec2(warped_x * 0.055, p.y * 0.048 - t * 1.8));
	float highlight = smoothstep(0.42, 0.92, streaks * 0.47 + fine * 0.17 + waves * 0.16 + turbulence * 0.48);
	vec3 color = mix(deep_color.rgb, light_color.rgb, clamp(0.2 + highlight * 0.78 + waves * 0.08, 0.0, 1.0));
	float glint = pow(max(0.0, fine * waves), 7.0) * 0.27;
	color = mix(color, vec3(0.85, 0.98, 1.0), glint);

	float edge_wave = sin(pixel.y * 0.055 - t * 2.2) * 2.0 + sin(pixel.y * 0.13 - t * 3.5) * 1.1;
	float edge_noise = (noise2(vec2(pixel.y * 0.045 - t * 0.45, 3.7)) - 0.5) * 3.0;
	float left_edge = 3.5 + edge_wave + edge_noise;
	float right_edge = 3.5 - edge_wave + edge_noise;
	float from_edge = min(pixel.x - left_edge, size.x - pixel.x - right_edge);
	float edge_mask = smoothstep(-1.0, 2.5, from_edge);
	float rim = exp(-pow((from_edge - 4.0) / 3.5, 2.0));
	float lip = exp(-pow((abs(impact_delta.x) - impact_width) / 9.0, 2.0)) * spread;
	color = mix(color, vec3(0.82, 0.97, 1.0), clamp(rim * (0.38 + highlight * 0.25) + lip * 0.7, 0.0, 0.85));

	float top_ripple = (noise2(vec2(pixel.x * 0.045, t * 0.3)) - 0.5) * 4.0 + sin(pixel.x * 0.075 + t * 1.1) * 1.5;
	float bottom_ripple = (noise2(vec2(pixel.x * 0.035, -t * 0.4 + 9.0)) - 0.5) * 7.0 + sin(pixel.x * 0.09 - t * 1.8) * 2.0;
	float top_fade = smoothstep(0.0, min(14.0, size.y * 0.28), pixel.y - 3.0 - top_ripple);
	float bottom_fade = smoothstep(0.0, min(23.0, size.y * 0.35), size.y - pixel.y - 3.0 - bottom_ripple);
	float boundary_mask = top_fade * bottom_fade;
	float alpha = mix(deep_color.a, light_color.a, highlight) * (0.76 + turbulence * 0.22);
	alpha = clamp(alpha + rim * 0.17 + lip * 0.16 - opening * 0.58 - wake * 0.18, 0.0, 1.0) * edge_mask * boundary_mask;
	COLOR = vec4(color, alpha);
}
