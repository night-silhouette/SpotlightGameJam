shader_type canvas_item;
render_mode unshaded;

// Local sampling keeps the image inside its room's Control clip, even with parallax.
uniform bool vertical_layout = false;
uniform float artwork_height = 800.0;
uniform float shaft_width = 280.0;
uniform vec2 scroll_pixels = vec2(0.0);
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform bool foreground = false;
uniform vec2 player_pixels = vec2(-10000.0);
uniform float clear_radius = 100.0;
varying vec2 local_pixel;
varying vec4 vertex_tint;

void vertex() {
	local_pixel = VERTEX;
	vertex_tint = COLOR;
}

void fragment() {
	vec2 source_size = vec2(textureSize(TEXTURE, 0));
	float art_scale = vertical_layout ? shaft_width / source_size.x : artwork_height / source_size.y;
	vec2 unit_size = source_size * art_scale;
	vec2 uv = (local_pixel + scroll_pixels) / unit_size;
	if (vertical_layout) {
		uv.x = clamp(uv.x, 0.001, 0.999);
		uv.y = fract(uv.y);
	} else {
		uv.x = fract(uv.x);
		uv.y = clamp(uv.y, 0.001, 0.999);
	}
	vec4 tex = texture(TEXTURE, uv);
	// Short edge blend accommodates the supplied layers whose edge pixels differ.
	float along = vertical_layout ? uv.y : uv.x;
	vec2 edge_uv = vertical_layout ? vec2(uv.x, 0.001) : vec2(0.001, uv.y);
	tex = mix(tex, texture(TEXTURE, edge_uv), smoothstep(0.975, 1.0, along));
	COLOR = tex * vertex_tint;
	COLOR.a *= opacity;
}
