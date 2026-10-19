shader_type canvas_item;
render_mode unshaded;

uniform vec4 mist_color : source_color = vec4(0.19, 0.13, 0.075, 1.0);
uniform float opacity : hint_range(0.0, 1.0) = 0.82;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.22;
uniform float fog_amount : hint_range(0.0, 0.5) = 0.12;
uniform float fog_scale : hint_range(0.5, 16.0) = 4.0;
uniform float fog_speed : hint_range(0.0, 2.0) = 0.08;

float hash(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 blend = fract(point);
	blend = blend * blend * (3.0 - 2.0 * blend);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, blend.x), mix(c, d, blend.x), blend.y);
}

void fragment() {
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float soft_box = smoothstep(0.0, edge_softness, edge_distance);
	vec2 drift = vec2(TIME * fog_speed, -TIME * fog_speed * 0.63);
	float fog = value_noise(UV * fog_scale + drift);
	float fog_modulation = mix(1.0 - fog_amount, 1.0, fog);
	// ColorRect 的 Color.A 是每个实例的透明度倍率，方便关卡中直接调整，不会被全局默认值覆盖。
	COLOR = vec4(mist_color.rgb, mist_color.a * opacity * COLOR.a * soft_box * fog_modulation);
}
