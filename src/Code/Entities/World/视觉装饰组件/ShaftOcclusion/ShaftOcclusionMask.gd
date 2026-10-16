extends Control
## 在屏幕空间绘制区域及其补集，跟随相机移动与缩放，不遮挡高层 HUD。

@onready var _component: Node2D = $"../.."

func _draw() -> void:
	var settings = _component.settings
	if settings == null or not is_instance_valid(_component.player):
		return
	var region: Rect2 = settings.shaft_region
	if not region.has_area():
		return
	var screen := Rect2(Vector2.ZERO, get_viewport_rect().size)
	var transform: Transform2D = get_global_transform_with_canvas().affine_inverse() * _component.get_global_transform_with_canvas()
	var points := PackedVector2Array([
		transform * region.position,
		transform * Vector2(region.end.x, region.position.y),
		transform * region.end,
		transform * Vector2(region.position.x, region.end.y)
	])
	var inside: bool = region.has_point(_component.to_local(_component.player.global_position))
	if not inside:
		draw_colored_polygon(points, settings.mask_color)
		return
	# 将视口沿井的四条边依次裁切；每次舍弃的部分恰好组成井外区域。
	var remaining := PackedVector2Array([
		screen.position, Vector2(screen.end.x, 0), screen.end, Vector2(0, screen.end.y)
	])
	var orientation: float = (points[1] - points[0]).cross(points[2] - points[1])
	for index in range(4):
		var start: Vector2 = points[index]
		var end: Vector2 = points[(index + 1) % 4]
		var outside := _clip(remaining, start, end, orientation, false)
		if outside.size() >= 3:
			draw_colored_polygon(outside, settings.mask_color)
		remaining = _clip(remaining, start, end, orientation, true)
		if remaining.is_empty():
			break

func _clip(polygon: PackedVector2Array, start: Vector2, end: Vector2, orientation: float, keep_inside: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon.is_empty():
		return result
	var previous: Vector2 = polygon[-1]
	var previous_distance: float = (end - start).cross(previous - start) * signf(orientation)
	for current in polygon:
		var distance: float = (end - start).cross(current - start) * signf(orientation)
		var current_kept: bool = (distance >= 0.0) == keep_inside
		var previous_kept: bool = (previous_distance >= 0.0) == keep_inside
		if current_kept != previous_kept:
			result.append(previous.lerp(current, previous_distance / (previous_distance - distance)))
		if current_kept:
			result.append(current)
		previous = current
		previous_distance = distance
	return result
