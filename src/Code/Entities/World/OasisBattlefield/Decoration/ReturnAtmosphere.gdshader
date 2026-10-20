shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform vec4 matte_color : source_color = vec4(0.055, 0.04, 0.075, 1.0);
uniform float matte_strength : hint_range(0.0, 0.45, 0.005) = 0.18;
uniform float vignette_strength : hint_range(0.0, 0.3, 0.005) = 0.10;
uniform float guide_clear_strength : hint_range(0.0, 1.0, 0.01) = 0.72;

void fragment() {
	vec2 centered = UV - vec2(0.5, 0.52);
	float guide = 1.0 - smoothstep(0.12, 0.68, length(centered * vec2(0.72, 1.45)));
	float edge = smoothstep(0.32, 0.86, length(centered * vec2(0.9, 1.16)));
	float breathe = 0.985 + sin(TIME * 0.28) * 0.015;
	float alpha = matte_strength * (1.0 - guide * guide_clear_strength);
	alpha += vignette_strength * edge;
	COLOR = vec4(matte_color.rgb, clamp(alpha * matte_color.a * breathe, 0.0, 0.48));
}
