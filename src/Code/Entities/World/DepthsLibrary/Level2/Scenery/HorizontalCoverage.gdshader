shader_type canvas_item;
render_mode unshaded;
// Trim floor coverage and shaft openings; sample the supplied artwork unchanged.
uniform vec4 world_bounds = vec4(-100000.0, -100000.0, 100000.0, 100000.0);
uniform vec4 descent_bounds = vec4(0.0);
uniform vec4 stairwell_bounds = vec4(0.0);
uniform vec4 fountain_bounds = vec4(0.0);
uniform bool foreground = false;
uniform float opacity = 1.0;
uniform vec2 player_world = vec2(-100000.0);
uniform float clear_radius = 100.0;
// Optional overlap fade for the shaft's native vertical repeats; floors leave this at zero.
uniform float vertical_loop_fade = 0.0;
varying vec2 world_pixel;
bool inside_bounds(vec2 point, vec4 bounds) {
 return point.x >= bounds.x && point.y >= bounds.y && point.x < bounds.z && point.y < bounds.w;
}
void vertex() {
 world_pixel = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
 if (vertical_loop_fade > 0.0) {
  COLOR.a *= smoothstep(0.0, vertical_loop_fade, UV.y) * (1.0 - smoothstep(1.0 - vertical_loop_fade, 1.0, UV.y));
 }
 if (world_pixel.x < world_bounds.x || world_pixel.y < world_bounds.y || world_pixel.x > world_bounds.z || world_pixel.y > world_bounds.w) { discard; }
 // Shafts own their background pixels, including transparent decorative layers.
 // Apply to all horizontal layers so the bridge/foreground cannot cross a shaft.
 if (inside_bounds(world_pixel, descent_bounds) || inside_bounds(world_pixel, stairwell_bounds) || inside_bounds(world_pixel, fountain_bounds)) { discard; }
 if (foreground) {
  COLOR.a *= opacity * mix(0.12, 1.0, smoothstep(clear_radius * 0.35, max(clear_radius, 0.01), distance(world_pixel, player_world)));
 }
}
