extends Control
## 根据玩家所在区域，仅绘制另一个区域的黑幕。

@onready var _component: Node2D = $"../.."
@onready var _visible_region: Polygon2D = $VisibleRegion

func _process(_delta: float) -> void:
	_update_visible_region()

func _update_visible_region() -> void:
	_visible_region.hide()
	if _component.settings == null or not is_instance_valid(_component.player):
		return
	var player_position: Vector2 = _component.player.global_position
	var region_a: Polygon2D = _component.get_node("RegionA")
	var region_b: Polygon2D = _component.get_node("RegionB")
	var hidden_region: Polygon2D = null
	if Geometry2D.is_point_in_polygon(region_a.to_local(player_position) - region_a.offset, region_a.polygon):
		hidden_region = region_b
	elif Geometry2D.is_point_in_polygon(region_b.to_local(player_position) - region_b.offset, region_b.polygon):
		hidden_region = region_a
	if hidden_region == null:
		return
	var transform: Transform2D = _visible_region.get_global_transform_with_canvas().affine_inverse() * hidden_region.get_global_transform_with_canvas()
	var screen_polygon := PackedVector2Array()
	for point in hidden_region.polygon:
		screen_polygon.append(transform * (point + hidden_region.offset))
	_visible_region.polygon = screen_polygon
	_visible_region.color = _component.settings.mask_color
	_visible_region.show()
