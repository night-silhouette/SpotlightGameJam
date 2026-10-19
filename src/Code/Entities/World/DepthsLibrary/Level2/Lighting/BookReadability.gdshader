shader_type canvas_item;
uniform float edge_strength = 0.0;
uniform float edge_texels = 1.0;
uniform vec4 edge_color : source_color = vec4(0.60, 0.69, 0.77, 1.0);

void fragment() {
 // Keep the original silhouette and alpha; only tint its upper inner edge.
 vec2 above = UV - vec2(0.0, TEXTURE_PIXEL_SIZE.y * edge_texels);
 float above_alpha = above.y < 0.0 ? 0.0 : texture(TEXTURE, above).a;
 float upper_edge = clamp(COLOR.a - above_alpha, 0.0, 1.0);
 COLOR.rgb = mix(COLOR.rgb, max(COLOR.rgb, edge_color.rgb), upper_edge * edge_strength);
}
