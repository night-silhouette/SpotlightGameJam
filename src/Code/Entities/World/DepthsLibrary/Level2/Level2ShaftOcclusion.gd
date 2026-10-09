extends Control
## 竖井及上层房间墙外的暗色岩层遮挡；不新增碰撞、不改变跳跃空间。
@onready var _director: Node2D = $"../.."

func _draw() -> void:
	_draw_upper_room_exterior()
	var opening: Rect2 = _director.GetShaftOpening()
	if not opening.has_area():
		return
	var transform: Transform2D = get_viewport().get_canvas_transform()
	var top_left: Vector2 = transform * opening.position
	var bottom_right: Vector2 = transform * opening.end
	var screen: Vector2 = get_viewport_rect().size
	var top: float = clampf(top_left.y, 0.0, screen.y)
	var bottom: float = clampf(bottom_right.y, 0.0, screen.y)
	if bottom <= top:
		return
	var tint := Color(0.025, 0.04, 0.055, _director.GetOcclusionOpacity())
	var left: float = clampf(top_left.x, 0.0, screen.x)
	var right: float = clampf(bottom_right.x, 0.0, screen.x)
	draw_rect(Rect2(0, top, left, bottom - top), tint)
	draw_rect(Rect2(right, top, screen.x - right, bottom - top), tint)

func _draw_upper_room_exterior() -> void:
	var opening: Rect2 = _director.GetUpperRoomOpening()
	if not opening.has_area():
		return
	var canvas: Transform2D = get_viewport().get_canvas_transform()
	var top_left: Vector2 = canvas * opening.position
	var bottom_right: Vector2 = canvas * opening.end
	var screen: Vector2 = get_viewport_rect().size
	var left: float = clampf(top_left.x, 0.0, screen.x)
	var right: float = clampf(bottom_right.x, 0.0, screen.x)
	var top: float = clampf(top_left.y, 0.0, screen.y)
	var tint := Color(0.025, 0.04, 0.055, 1.0)
	# 只遮挡顶板外和左右墙外，底部开口保留给连续下落/上升。
	draw_rect(Rect2(0, 0, screen.x, top), tint)
	draw_rect(Rect2(0, top, left, screen.y - top), tint)
	draw_rect(Rect2(right, top, screen.x - right, screen.y - top), tint)
