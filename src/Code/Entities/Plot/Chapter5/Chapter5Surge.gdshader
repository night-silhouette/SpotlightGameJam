shader_type canvas_item;
render_mode unshaded;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float elapsed = 0.0;
uniform vec4 water_color : source_color = vec4(0.64, 0.82, 0.88, 1.0);
void fragment() {
	vec2 p = UV - vec2(0.5, 0.92);
	p.x *= 1.5;
	float wave = sin(UV.x * 24.0 + elapsed * 4.0) * 0.045 + sin(UV.x * 53.0 - elapsed * 3.0) * 0.02;
	float front = progress * 2.1 - length(p) + wave;
	float cover = smoothstep(0.0, 0.07, front);
	float foam = (1.0 - smoothstep(0.07, 0.2, front)) * cover;
	float flow = sin(length(p) * 48.0 - elapsed * 7.0 + sin(UV.x * 18.0));
	vec3 water = water_color.rgb * (0.72 + flow * 0.09);
	COLOR = vec4(mix(water, vec3(0.9, 0.97, 1.0), foam * 0.85), cover);
}
