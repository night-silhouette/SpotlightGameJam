shader_type canvas_item;

uniform float offset_x = 0.0;
uniform float surface_width = 665.0;
uniform float side_fade_width = 96.0;
uniform float side_blur_radius = 8.0;
uniform float side_blur_strength : hint_range(0.0, 1.0) = 1.0;

vec2 scroll_uv(vec2 uv) {
	uv.x = fract(uv.x + offset_x);
	return uv;
}

void fragment() {
	vec4 water_color = texture(TEXTURE, scroll_uv(UV));
	// TextureRect 使用平铺模式时，UV.x 会随拉伸宽度超过 1；先换算回整条水面的 0..1。
	float total_uv_width = max(surface_width * TEXTURE_PIXEL_SIZE.x, 0.0001);
	float surface_x = clamp(UV.x / total_uv_width, 0.0, 1.0);
	float side_distance = min(surface_x, 1.0 - surface_x) * max(surface_width, 1.0);
	float blur_zone = max(side_fade_width, 1.0);
	float edge_amount = 1.0 - smoothstep(0.0, blur_zone, side_distance);

	if (side_blur_radius > 0.0 && side_blur_strength > 0.0 && edge_amount > 0.0) {
		float radius_uv = side_blur_radius * TEXTURE_PIXEL_SIZE.x;
		vec4 blurred = texture(TEXTURE, scroll_uv(UV)) * 0.28;
		blurred += texture(TEXTURE, scroll_uv(UV + vec2(radius_uv * 0.35, 0.0))) * 0.20;
		blurred += texture(TEXTURE, scroll_uv(UV - vec2(radius_uv * 0.35, 0.0))) * 0.20;
		blurred += texture(TEXTURE, scroll_uv(UV + vec2(radius_uv * 0.70, 0.0))) * 0.12;
		blurred += texture(TEXTURE, scroll_uv(UV - vec2(radius_uv * 0.70, 0.0))) * 0.12;
		blurred += texture(TEXTURE, scroll_uv(UV + vec2(radius_uv, 0.0))) * 0.04;
		blurred += texture(TEXTURE, scroll_uv(UV - vec2(radius_uv, 0.0))) * 0.04;
		water_color = mix(water_color, blurred, edge_amount * side_blur_strength);
	}

	float side_alpha = side_fade_width > 0.0
		? smoothstep(0.0, side_fade_width, side_distance)
		: 1.0;
	water_color.a *= side_alpha;
	COLOR = water_color;
}
