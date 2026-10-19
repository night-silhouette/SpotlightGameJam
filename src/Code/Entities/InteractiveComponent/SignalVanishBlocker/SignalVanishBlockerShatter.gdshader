shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float shard_size = 180.0;
uniform float scatter_distance = 6.0;
uniform float fall_distance = 36.0;
uniform float edge_width = 0.018;
uniform vec4 edge_color : source_color = vec4(0.19, 0.13, 0.075, 0.65);
varying vec2 stone_position;
float hash21(vec2 p) {
 p = fract(p * vec2(123.34, 456.21));
 p += dot(p, p + 45.32);
 return fract(p.x * p.y);
}
void vertex() {
 stone_position = VERTEX;
 // Uniform settling preserves TileMap geometry instead of stretching tile triangles.
 float settle = smoothstep(0.2, 1.0, progress);
 VERTEX += vec2(scatter_distance * 0.15, fall_distance) * settle * settle;
}
void fragment() {
 vec4 stone = texture(TEXTURE, UV) * COLOR;
 vec2 p = stone_position / max(shard_size, 1.0);
 vec2 cell = floor(p);
 vec2 local = fract(p);
 float nearest = 8.0;
 float second = 8.0;
 vec2 stone_id = vec2(0.0);
 for (int y = -1; y <= 1; y++) {
  for (int x = -1; x <= 1; x++) {
   vec2 neighbor = vec2(float(x), float(y));
   vec2 id = cell + neighbor;
   vec2 seed = vec2(hash21(id), hash21(id + 31.7));
   float d = length(neighbor + 0.2 + seed * 0.6 - local);
   if (d < nearest) {
    second = nearest;
    nearest = d;
    stone_id = id;
   } else {
    second = min(second, d);
   }
  }
 }
 float age = hash21(stone_id + 11.3);
 float phase = smoothstep(age * 0.26, 0.72 + age * 0.28, progress);
 float grain = hash21(floor(stone_position / max(shard_size * 0.035, 1.0)));
 float border = second - nearest;
 float crack = 1.0 - smoothstep(edge_width, edge_width + 0.025, border);
 float weathering = smoothstep(0.0, 0.28, phase);
 stone.rgb = mix(stone.rgb, stone.rgb * 0.72 + edge_color.rgb * 0.28,
  crack * weathering * edge_color.a);
 // Dark seams crumble first; the original stone then erodes into fine grains.
 float resistance = mix(grain, age, 0.3) - crack * 0.22;
 float erosion = smoothstep(resistance - 0.09, resistance + 0.09, phase * 1.3 - 0.15);
 stone.a *= 1.0 - erosion;
 if (progress >= 0.9999) { stone.a = 0.0; }
 COLOR = stone;
}
