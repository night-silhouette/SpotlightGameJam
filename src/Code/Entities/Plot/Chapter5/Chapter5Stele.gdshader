shader_type canvas_item;
render_mode unshaded;
uniform float elapsed = 0.0;
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform vec2 texture_scale = vec2(1.0);
void vertex() {
	VERTEX *= texture_scale;
}
void fragment() {
	vec4 stone = texture(TEXTURE, UV);
	float mist = exp(-pow((UV.x - (0.5 + sin(elapsed * 0.35) * 0.25)) * 5.0, 2.0)) * sin(UV.y * 3.14159) * 0.32 * wetness;
	vec2 cells = vec2(UV.x * 22.0, UV.y * 12.0 + elapsed * 0.6);
	vec2 bead = fract(cells) - vec2(0.5, 0.35);
	float drops = (1.0 - smoothstep(0.025, 0.075, length(bead * vec2(1.0, 0.5)))) * 0.12;
	stone.rgb = mix(stone.rgb * (1.0 - wetness * 0.025), vec3(0.65, 0.76, 0.8), drops * wetness);
	// Composite mist over the stone, including transparent pixels inside its canvas.
	float alpha = stone.a + mist * (1.0 - stone.a);
	vec3 premultiplied = stone.rgb * stone.a * (1.0 - mist) + vec3(0.76, 0.9, 1.0) * mist;
	COLOR = vec4(premultiplied / max(alpha, 0.0001), alpha);
}
