shader_type canvas_item;
render_mode unshaded;

uniform float elapsed = 0.0;
uniform float strength : hint_range(0.0, 0.4) = 0.26;
uniform vec4 mist_color : source_color = vec4(0.65, 0.77, 0.88, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = UV * vec2(6.0, 2.3) - vec2(elapsed * 0.035, elapsed * 0.009);
	float folds = noise(p) * 0.65 + noise(p * 2.1 + vec2(8.0, elapsed * 0.02)) * 0.35;
	float edge = smoothstep(0.0, 0.13, UV.x) * (1.0 - smoothstep(0.87, 1.0, UV.x));
	float height = smoothstep(0.0, 0.45, UV.y) * (1.0 - smoothstep(0.72, 1.0, UV.y));
	float wisps = smoothstep(0.22, 0.8, folds);
	COLOR = vec4(mist_color.rgb, edge * height * wisps * strength * mist_color.a);
}
