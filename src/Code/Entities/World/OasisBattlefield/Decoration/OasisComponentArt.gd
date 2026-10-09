@tool
extends Node2D

## 第三关专用外观适配器：只读取父组件状态，不改变碰撞、伤害或移动。
const MOVING = preload("res://Art/Archived/platforms/movingplatform(1).png")
const BROKEN = preload("res://Art/Archived/platforms/brokenplatform_spritesheet.png")
const ROCKS = preload("res://Art/Archived/platforms/fallingrocks_spitesheet.png")
const SPIKE = preload("res://Art/Archived/platforms/spines.png")
const RUNE = preload("res://Art/Archived/platforms/waterpattern.png")
const TERRAIN = preload("res://Art/Archived/Tilemap/2.png")
const BREAK_REGIONS = [
	Rect2(150, 0, 450, 154), Rect2(595, 0, 450, 154),
	Rect2(1360, 0, 450, 154), Rect2(1975, 0, 450, 154),
	Rect2(2600, 0, 450, 154), Rect2(3180, 0, 432, 154)]
var _target: Node2D
var _kind: String
var _elapsed: float = 0.0
var _state_time: float = 0.0
var _last_state: int = -1
var _fluid_mix: float = 0.0

func _ready() -> void:
	_kind = str(get_meta("kind", "moving"))
	_target = get_node_or_null(NodePath(str(get_meta("target_path", "..")))) as Node2D
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	_elapsed += delta
	if not Engine.is_editor_hint() and (_kind == "crumble" or _kind == "stalactite"):
		var state: int = int(_target.get("current_state"))
		if state != _last_state:
			_last_state = state
			_state_time = 0.0
		_state_time += delta
	if _kind == "water":
		var fluid: bool = false if Engine.is_editor_hint() else bool(_target.get("is_fluid"))
		_fluid_mix = move_toward(_fluid_mix, 1.0 if fluid else 0.0, delta * 4.0)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(_target):
		return
	match _kind:
		"moving":
			var size: Vector2 = _target.get("platform_size")
			var height: float = size.x * 100.0 / 287.0
			draw_texture_rect_region(MOVING, Rect2(-size.x * 0.5, -size.y * 0.5, size.x, height), Rect2(87, 66, 287, 100))
		"block":
			var size: Vector2 = _target.get("platform_size")
			_draw_panel(Rect2(-size * 0.5, size), Rect2(2680, 2561, 1231, 1165), Color.WHITE)
		"crumble":
			_draw_crumble()
		"stalactite":
			var size: Vector2 = _target.get("stalactite_size")
			var frame: int = 0
			if _last_state == 1:
				frame = mini(int(_state_time / maxf(float(_target.get("shake_duration")), 0.01) * 4.0), 3)
			elif _last_state == 2:
				frame = int(_state_time * 12.0) % 4
			draw_texture_rect_region(ROCKS, Rect2(-size.x * 0.5, 0, size.x, size.y), Rect2(frame * 185, 0, 185, 264))
		"spikes", "rising":
			_draw_spikes()
		"water":
			_draw_water()

func _draw_crumble() -> void:
	var size: Vector2 = _target.get("platform_size")
	var frame: int = 0
	if _last_state == 1:
		frame = mini(int(_state_time / maxf(float(_target.get("crumble_delay")), 0.01) * 3.0), 2)
	elif _last_state == 2:
		frame = 3 + mini(int(_state_time / 0.25 * 3.0), 2)
		# 原组件重生阶段已开始淡入，改回完整帧；透明度仍由原组件控制。
		var visual: Node2D = _target.get_node("VisualRoot")
		if _state_time > 0.3 and visual.modulate.a > 0.05:
			frame = 0
	var region: Rect2 = BREAK_REGIONS[frame]
	var ratio: float = size.x / 416.0
	draw_texture_rect_region(BROKEN, Rect2(-225.0 * ratio, -size.y * 0.5 - 40.0 * ratio, region.size.x * ratio, 154.0 * ratio), region)

func _draw_spikes() -> void:
	var size: Vector2 = _target.get("spikes_size")
	var world_scale: Vector2 = global_transform.get_scale().abs()
	var count: int = maxi(2, int(ceil(size.x * world_scale.x / maxf(size.y * world_scale.y * 0.67, 8.0))))
	var step: float = size.x / float(count)
	var visible_height: float = size.y
	var top: float = -size.y
	if _kind == "rising":
		top = 0.0
		if not Engine.is_editor_hint():
			visible_height = clampf(-get_parent().position.y, 0.0, size.y)
	if visible_height <= 0.01:
		return
	# 天花板尖刺只翻转外观，并平移回原伤害矩形内。
	var ceiling: bool = _kind == "spikes" and bool(_target.get_meta("oasis_art_flip_v", false))
	if ceiling:
		draw_set_transform(Vector2(0, -size.y), 0.0, Vector2(1, -1))
	for index in range(count):
		draw_texture_rect_region(SPIKE,
			Rect2(-size.x * 0.5 + index * step, top, step + 0.05, visible_height),
			Rect2(116, 138, 236, 354.0 * visible_height / size.y))

	if ceiling:
		draw_set_transform(Vector2.ZERO)

func _draw_water() -> void:
	var size: Vector2 = _target.get("area_size")
	var bounds := Rect2(-size * 0.5, size)
	_draw_panel(bounds, Rect2(4056, 2623, 1104, 1120), Color(0.7, 0.85, 0.9, 1.0 - _fluid_mix))
	if _fluid_mix > 0.001:
		var opacity: float = 0.78
		var scroll_speed: float = 1.5
		if not Engine.is_editor_hint():
			opacity = ExportSettings.oasis_art_water_opacity
			scroll_speed = ExportSettings.oasis_art_water_scroll_speed
		_draw_panel(bounds, Rect2(1192, 3111, 1232, 1239), Color(0.7, 0.95, 1.0, _fluid_mix * opacity))
		for index in range(5):
			var progress: float = fposmod(float(index) / 5.0 + _elapsed * scroll_speed * 0.1, 1.0)
			var y: float = bounds.position.y + progress * size.y
			var points := PackedVector2Array()
			for point in range(13):
				var x: float = bounds.position.x + size.x * float(point) / 12.0
				points.append(Vector2(x, y + sin(float(point) * 0.65 + _elapsed * 2.0) * minf(size.y * 0.018, 3.0)))
			draw_polyline(points, Color(0.75, 1, 1, 0.16 * _fluid_mix), 0.8, true)
	var world_scale: Vector2 = global_transform.get_scale().abs()
	var world_size: Vector2 = size * world_scale
	var glyph_height: float = minf(62.0, minf(world_size.x * 0.85, world_size.y * 0.55))
	var glyph_size := Vector2(glyph_height * 286.0 / 510.0, glyph_height) / world_scale.max(Vector2(0.001, 0.001))
	var pulse: float = 0.85 + 0.15 * sin(_elapsed * 2.0)
	draw_texture_rect_region(RUNE, Rect2(-glyph_size * 0.5, glyph_size), Rect2(54, 69, 286, 510), Color(1, 1, 1, pulse))

func _draw_panel(bounds: Rect2, source: Rect2, tint: Color) -> void:
	var world_scale: Vector2 = global_transform.get_scale().abs().max(Vector2(0.001, 0.001))
	var edge: Vector2 = (Vector2(16, 16) / world_scale).min(bounds.size * 0.3)
	var dx = [bounds.position.x, bounds.position.x + edge.x, bounds.end.x - edge.x, bounds.end.x]
	var dy = [bounds.position.y, bounds.position.y + edge.y, bounds.end.y - edge.y, bounds.end.y]
	var sx = [source.position.x, source.position.x + 140, source.end.x - 140, source.end.x]
	var sy = [source.position.y, source.position.y + 140, source.end.y - 140, source.end.y]
	for row in range(3):
		for col in range(3):
			draw_texture_rect_region(TERRAIN, Rect2(dx[col], dy[row], dx[col+1]-dx[col], dy[row+1]-dy[row]), Rect2(sx[col], sy[row], sx[col+1]-sx[col], sy[row+1]-sy[row]), tint)
