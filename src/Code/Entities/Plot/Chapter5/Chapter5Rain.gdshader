shader_type canvas_item;
render_mode unshaded;
uniform float elapsed = 0.0;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float drop_count = 180.0;
uniform vec4 rain_color : source_color = vec4(0.72, 0.86, 0.94, 0.5);
float hash(float n) { return fract(sin(n * 78.233) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	float column = floor(uv.x * drop_count);
	float speed = mix(0.45, 0.9, hash(column + 4.0));
	float x = fract(uv.x * drop_count + uv.y * 0.9);
	float y = fract(uv.y * 3.0 - elapsed * speed + hash(column));
	float density = smoothstep(hash(column + 17.0) * 0.92, hash(column + 17.0) * 0.92 + 0.08, intensity);
	float drop = (1.0 - smoothstep(0.06, 0.2, abs(x - 0.5))) * smoothstep(0.88, 0.96, y) * density;
	float cloud = sin(uv.x * 5.0 + elapsed * 0.06) * 0.5 + 0.5;
	vec3 tint = mix(vec3(0.14, 0.2, 0.26), rain_color.rgb, drop);
	COLOR = vec4(tint, max(drop * rain_color.a, (1.0 - uv.y) * 0.16 * cloud) * intensity);
}
