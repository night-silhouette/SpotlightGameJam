shader_type canvas_item;
render_mode unshaded;

uniform sampler2D group_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float fade_width_pixels : hint_range(0.0, 480.0, 1.0) = 240.0;
uniform float fade_height_pixels : hint_range(0.0, 480.0, 1.0) = 180.0;

void fragment() {
	vec4 group_color = textureLod(group_texture, SCREEN_UV, 0.0);
	float feather = 1.0;

	if (group_color.a > 0.0001) {
		const int SAMPLE_RADIUS = 6;
		if (fade_width_pixels > 0.0) {
			float horizontal_alpha_sum = 0.0;
			for (int sample_index = -SAMPLE_RADIUS; sample_index <= SAMPLE_RADIUS; sample_index++) {
				float offset_ratio = float(sample_index) / float(SAMPLE_RADIUS);
				vec2 sample_uv = SCREEN_UV + vec2(
					offset_ratio * fade_width_pixels * SCREEN_PIXEL_SIZE.x,
					0.0
				);
				horizontal_alpha_sum += textureLod(group_texture, sample_uv, 0.0).a;
			}
			float horizontal_average_alpha = horizontal_alpha_sum / float(SAMPLE_RADIUS * 2 + 1);
			feather = min(feather, smoothstep(0.5, 1.0, horizontal_average_alpha));
		}

		if (fade_height_pixels > 0.0) {
			float vertical_alpha_sum = 0.0;
			for (int sample_index = -SAMPLE_RADIUS; sample_index <= SAMPLE_RADIUS; sample_index++) {
				float offset_ratio = float(sample_index) / float(SAMPLE_RADIUS);
				vec2 sample_uv = SCREEN_UV + vec2(
					0.0,
					offset_ratio * fade_height_pixels * SCREEN_PIXEL_SIZE.y
				);
				vertical_alpha_sum += textureLod(group_texture, sample_uv, 0.0).a;
			}
			float vertical_average_alpha = vertical_alpha_sum / float(SAMPLE_RADIUS * 2 + 1);
			feather = min(feather, smoothstep(0.5, 1.0, vertical_average_alpha));
		}
	}

	if (group_color.a > 0.0001) {
		group_color.rgb /= group_color.a;
	}
	group_color.a *= feather;
	COLOR *= group_color;
}
