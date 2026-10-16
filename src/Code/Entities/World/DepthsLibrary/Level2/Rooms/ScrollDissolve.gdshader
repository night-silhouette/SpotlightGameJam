shader_type canvas_item;

uniform sampler2D noise_texture : repeat_disable;
uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float edge_width : hint_range(0.001, 0.15) = 0.04;
uniform vec4 edge_color : source_color = vec4(0.5, 0.85, 1.0, 1.0);

void fragment() {
	vec4 base = COLOR;
	float noise_value = texture(noise_texture, UV).r;

	// 保证 0 时完整显示，1 时完全消失。
	float threshold = mix(-edge_width, 1.0, dissolve_progress);
	float remaining = smoothstep(
		threshold, threshold + edge_width, noise_value
	);

	float edge = 1.0 - smoothstep(
		threshold + edge_width,
		threshold + edge_width * 2.0,
		noise_value
	);

	float active = step(0.0001, dissolve_progress);
	base.rgb = mix(base.rgb, edge_color.rgb,
		edge * active * edge_color.a);
	base.a *= remaining;

	COLOR = base;
}