shader_type canvas_item;

// 场景中的值用于编辑器预览，运行时由 ExportSettings 设置。
uniform float repeat_width = 4831.0;
uniform float blend_width = 128.0;
uniform float seam_y_offset = 14.0;
varying vec2 source_pixel;
varying vec4 item_tint;

void vertex() {
	// 仅用于 centered=false、offset=0 的原尺寸装饰 Sprite2D。
	source_pixel = VERTEX;
	item_tint = COLOR;
}

void fragment() {
	vec2 source_uv = source_pixel * TEXTURE_PIXEL_SIZE;
	float width = min(blend_width, repeat_width);
	if (width > 0.0 && source_pixel.x < width) {
		// 材质分别设置绿色/浅黄色层的首尾高差，只在接头处补偿并逐渐归零。
		// 单次纹理采样避免交叉淡化产生双重半透明轮廓，不改变整层位置/比例。
		float compensation = seam_y_offset * (1.0 - smoothstep(0.0, width, source_pixel.x));
		source_uv.y -= compensation * TEXTURE_PIXEL_SIZE.y;
	}
	COLOR = texture(TEXTURE, source_uv) * item_tint;
}
