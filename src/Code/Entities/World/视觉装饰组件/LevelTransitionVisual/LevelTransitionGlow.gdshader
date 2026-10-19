shader_type canvas_item;
render_mode unshaded;

uniform vec4 glow_color : source_color = vec4(1.0, 0.92, 0.72, 1.0);
uniform float core_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float halo_opacity : hint_range(0.0, 1.0) = 0.72;
uniform float edge_softness : hint_range(0.01, 0.5) = 0.28;
uniform float pulse_strength : hint_range(0.0, 0.5) = 0.08;
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.7;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float edge_distance = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float soft_box = smoothstep(0.0, edge_softness, edge_distance);
	float distance_from_core = length(centered);
	float core = 1.0 - smoothstep(0.0, 0.82, distance_from_core);
	float halo = 1.0 - smoothstep(0.1, 1.25, distance_from_core);
	float pulse = 1.0 + sin(TIME * pulse_speed * 6.2831853) * pulse_strength;
	float alpha = mix(halo_opacity, core_opacity, core) * halo * soft_box * pulse;
	vec3 center_color = mix(glow_color.rgb, vec3(1.0), core * 0.72);
	COLOR = vec4(center_color, glow_color.a * clamp(alpha, 0.0, 1.0));
}
