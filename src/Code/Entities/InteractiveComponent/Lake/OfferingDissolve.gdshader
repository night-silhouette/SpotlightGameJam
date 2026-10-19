shader_type canvas_item;
render_mode unshaded;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 cell = floor(UV * 90.0);
	float noise = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float remaining = smoothstep(progress - 0.08, progress + 0.08, noise);
	COLOR = vec4(tex.rgb, tex.a * remaining * (1.0 - progress));
}
