shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float shard_size : hint_range(16.0, 512.0) = 180.0;
uniform float scatter_distance : hint_range(0.0, 512.0) = 90.0;
uniform float fall_distance : hint_range(0.0, 1024.0) = 240.0;
uniform float edge_width : hint_range(0.0, 0.25) = 0.08;
uniform vec4 edge_color : source_color = vec4(0.94, 0.72, 0.39, 1.0);

varying vec2 original_local_position;

float hash21(vec2 value) {
	value = fract(value * vec2(123.34, 456.21));
	value += dot(value, value + 45.32);
	return fract(value.x * value.y);
}

vec3 shard_data(vec2 local_position) {
	vec2 grid_position = local_position / max(shard_size, 1.0);
	vec2 cell = floor(grid_position);
	vec2 within_cell = fract(grid_position);
	float triangle = step(1.0, within_cell.x + within_cell.y);
	float random_value = hash21(cell * 2.0 + vec2(triangle, triangle * 7.0));
	return vec3(cell, random_value);
}

float shard_progress(float random_value) {
	float start = mix(0.02, 0.68, random_value);
	return clamp((progress - start) / max(1.0 - start, 0.001), 0.0, 1.0);
}

void vertex() {
	original_local_position = VERTEX;
	vec3 data = shard_data(VERTEX + vec2(shard_size * 0.37));
	float local_progress = shard_progress(data.z);
	float direction = mix(-1.0, 1.0, hash21(data.xy + 19.17));
	float rotation_bias = mix(-0.35, 0.35, hash21(data.xy + 61.73));
	VERTEX.x += direction * scatter_distance * local_progress;
	VERTEX.x += rotation_bias * fall_distance * local_progress * local_progress;
	VERTEX.y += fall_distance * local_progress * local_progress;
}

void fragment() {
	vec4 base_color = texture(TEXTURE, UV) * COLOR;
	if (base_color.a <= 0.001) {
		discard;
	}

	vec2 grid_position = original_local_position / max(shard_size, 1.0);
	vec2 within_cell = fract(grid_position);
	vec3 data = shard_data(original_local_position);
	float local_progress = shard_progress(data.z);

	float cell_border = min(min(within_cell.x, 1.0 - within_cell.x), min(within_cell.y, 1.0 - within_cell.y));
	float diagonal_border = abs(within_cell.x + within_cell.y - 1.0) * 0.7071;
	float fracture_distance = min(cell_border, diagonal_border);
	float fracture = 1.0 - smoothstep(0.0, edge_width, fracture_distance);
	float active_edge = fracture * smoothstep(0.0, 0.18, local_progress) * (1.0 - smoothstep(0.72, 1.0, local_progress));
	base_color.rgb = mix(base_color.rgb, edge_color.rgb, active_edge * edge_color.a);
	base_color.a *= 1.0 - smoothstep(0.58, 1.0, local_progress);

	if (base_color.a <= 0.001 || progress >= 0.9999) {
		discard;
	}
	COLOR = base_color;
}
