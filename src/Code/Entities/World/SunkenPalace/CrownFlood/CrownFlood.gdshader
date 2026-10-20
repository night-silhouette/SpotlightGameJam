shader_type canvas_item;
render_mode unshaded;

uniform vec2 opening;
uniform float ceiling;
uniform float floor_y;
uniform float water_level;
uniform float jet_tip;
uniform float elapsed;
uniform bool pool_ready = false;
uniform vec4 water_color : source_color;
uniform vec4 foam_color : source_color;
uniform vec4 sand_color : source_color;
uniform float wave_height;
uniform float wave_length;
uniform float flow_speed;
uniform float foam_width;
uniform float detail_density;
varying vec2 local_point;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	local_point = VERTEX;
}

void fragment() {
	vec2 p = local_point;
	// x + time advects every crest and suspended grain to the left.
	float drift = p.x + elapsed * flow_speed;
	float wave = sin(drift / max(wave_length, 1.0)) * wave_height;
	wave += sin(drift / max(wave_length * 0.39, 1.0) + elapsed * 2.0) * wave_height * 0.3;
	float surface = water_level + wave;
	float pool = pool_ready ? smoothstep(surface - 1.0, surface + 2.0, p.y) : 0.0;
	float center = (opening.x + opening.y) * 0.5;
	float width = (opening.y - opening.x) * 0.5;
	float jet_edge = width * (0.80 + 0.10 * sin(p.y * 0.025 - elapsed * 9.0));
	float jet = (1.0 - smoothstep(jet_edge - 6.0, jet_edge, abs(p.x - center))) * step(ceiling, p.y) * (1.0 - smoothstep(jet_tip - 8.0, jet_tip, p.y));
	float streak = pow(0.5 + 0.5 * sin(p.x * 0.24 + sin(p.y * 0.017 - elapsed * 11.0)), 5.0);
	float current = pow(0.5 + 0.5 * sin(p.y * 0.18 + sin(drift * 0.023)), 9.0);
	float crest = (1.0 - smoothstep(0.0, max(foam_width, 0.1), abs(p.y - surface))) * pool;
	float impact = exp(-abs(p.x - center) / max(width, 1.0)) * exp(-abs(p.y - max(surface, jet_tip)) / max(foam_width * 3.0, 1.0));
	vec2 grain_uv = vec2(drift, p.y - elapsed * flow_speed * 0.08) / 22.0;
	vec2 cell = floor(grain_uv);
	float seed = hash(cell);
	float fleck = (1.0 - smoothstep(0.035, 0.10, length(fract(grain_uv) - vec2(hash(cell + 4.0), hash(cell + 8.0))))) * step(1.0 - detail_density, seed) * pool;
	float bottom_sand = smoothstep(floor_y - 85.0, floor_y, p.y) * fleck;
	float foam = clamp(crest * (0.6 + 0.4 * current) + impact * jet * 0.5 + streak * jet * 0.22 + current * pool * 0.10 + fleck * 0.55, 0.0, 1.0);
	vec4 water = mix(water_color, foam_color, foam);
	water = mix(water, sand_color, bottom_sand * 0.65);
	water.a *= max(pool, jet * 0.88);
	COLOR = water;
}
