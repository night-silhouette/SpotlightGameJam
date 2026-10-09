@tool
extends Node2D

## TileMap 场景图块；根据四邻接选择石块边缘，只绘制外观。
const ATLAS = preload("res://Art/Archived/Tilemap/2.png")

func _ready() -> void:
	var layer := get_parent() as TileMapLayer
	if layer and not layer.changed.is_connected(queue_redraw):
		layer.changed.connect(queue_redraw)
	queue_redraw()

func _draw() -> void:
	var layer := get_parent() as TileMapLayer
	if not layer:
		return
	var cell: Vector2i = layer.local_to_map(position)
	var left: bool = layer.get_cell_source_id(cell + Vector2i.LEFT) < 0
	var right: bool = layer.get_cell_source_id(cell + Vector2i.RIGHT) < 0
	var top: bool = layer.get_cell_source_id(cell + Vector2i.UP) < 0
	var bottom: bool = layer.get_cell_source_id(cell + Vector2i.DOWN) < 0
	var source := Rect2(162, 328, 1536, 512)
	if bool(get_meta("glazed", false)):
		source = Rect2(4056, 2623, 1104, 1120)
	var center: Vector2 = source.get_center() - Vector2(70, 70)
	var dx = [-128.0, -64.0, 64.0, 128.0]
	var dy = [-216.0 if top else -128.0, -76.0 if top else -64.0, 156.0 if bottom else 64.0, 296.0 if bottom else 128.0]
	var sx = [source.position.x if left else center.x, center.x, source.end.x - 140.0 if right else center.x]
	var sy = [source.position.y if top else center.y, center.y, source.end.y - 140.0 if bottom else center.y]
	for row in range(3):
		for col in range(3):
			draw_texture_rect_region(ATLAS, Rect2(dx[col], dy[row], dx[col+1]-dx[col], dy[row+1]-dy[row]), Rect2(sx[col], sy[row], 140, 140))

	# 竖向边缘沿用横向石沿，旋转绘制，避免墙面只剩纯色条。
	if not bool(get_meta("glazed", false)):
		var y_start: float = dy[0]
		var y_end: float = dy[3]
		if left:
			draw_set_transform(Vector2(-128, y_end), -PI * 0.5)
			draw_texture_rect_region(ATLAS, Rect2(0, 0, y_end-y_start, 64), Rect2(674, 328, 256, 140))
		if right:
			draw_set_transform(Vector2(128, y_start), PI * 0.5)
			draw_texture_rect_region(ATLAS, Rect2(0, 0, y_end-y_start, 64), Rect2(674, 328, 256, 140))
		draw_set_transform(Vector2.ZERO)
