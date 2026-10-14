@tool
extends Node2D
## 独立地形外观层：读取同地图各房间的 Terrain，只绘制美术，不创建或修改碰撞。
## 隐藏或移除此节点即可恢复灰盒；原 Terrain 的 Visible 属性不会被改写或保存。
const ATLAS: Texture2D = preload("res://Art/New/map2/2_grid665.png")
# 原图的 665 网格横跨整段素材，不能把每格直接当作一块完整砖。
# 从石边内部取四块完整裂纹砖；只引用原图，不生成或改写美术文件。
const STONE_REGIONS: Array[Rect2] = [
	Rect2(256, 2408, 222, 222),
	Rect2(488, 2408, 222, 222),
	Rect2(720, 2408, 222, 222),
	Rect2(950, 2408, 222, 222),
]
var _sources: Dictionary = {}
var _poll_left: float = 0.0

func _ready() -> void:
	_refresh_sources()

func _exit_tree() -> void:
	_restore_sources()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		_sync_source_visibility()
		queue_redraw()

func _process(delta: float) -> void:
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = 0.25
		_refresh_sources()

func _art_enabled() -> bool:
	return is_visible_in_tree() and (Engine.is_editor_hint() or ExportSettings.level2_terrain_art_enabled)

func _refresh_sources() -> void:
	var rooms := get_parent().get_node_or_null("Rooms")
	if rooms == null:
		_restore_sources()
		_sources.clear()
		return
	var found: Array[TileMapLayer] = []
	for room in rooms.get_children():
		var terrain := room.get_node_or_null("Terrain") as TileMapLayer
		if terrain == null or terrain.tile_set == null:
			continue
		found.append(terrain)
		var fingerprint := hash(terrain.tile_map_data)
		if not _sources.has(terrain) or _sources[terrain].fingerprint != fingerprint:
			var cells := terrain.get_used_cells()
			var occupied: Dictionary = {}
			for cell in cells:
				occupied[cell] = true
			_sources[terrain] = {"fingerprint": fingerprint, "cells": cells, "occupied": occupied}
	for terrain in _sources.keys():
		if not is_instance_valid(terrain):
			_sources.erase(terrain)
		elif not found.has(terrain):
			RenderingServer.canvas_item_set_visible(terrain.get_canvas_item(), terrain.visible)
			_sources.erase(terrain)
	_sync_source_visibility()
	queue_redraw()

func _sync_source_visibility() -> void:
	var active := _art_enabled()
	for terrain in _sources:
		if is_instance_valid(terrain):
			# 仅改变渲染服务器状态，避免编辑器把 visible=false 写进房间场景。
			RenderingServer.canvas_item_set_visible(terrain.get_canvas_item(), terrain.visible and not active)

func _restore_sources() -> void:
	for terrain in _sources:
		if is_instance_valid(terrain):
			RenderingServer.canvas_item_set_visible(terrain.get_canvas_item(), terrain.visible)

func _draw() -> void:
	if not _art_enabled():
		return
	for source in _sources:
		var terrain := source as TileMapLayer
		if not is_instance_valid(terrain) or not terrain.is_visible_in_tree() or terrain.tile_set == null:
			continue
		draw_set_transform_matrix(global_transform.affine_inverse() * terrain.global_transform)
		var tile_size := Vector2(terrain.tile_set.tile_size)
		var occupied: Dictionary = _sources[terrain].occupied
		for cell: Vector2i in _sources[terrain].cells:
			var rect := Rect2(terrain.map_to_local(cell) - tile_size * 0.5, tile_size)
			var variation := posmod(cell.x * 7 + cell.y * 13, STONE_REGIONS.size())
			var top := not occupied.has(cell + Vector2i.UP)
			var bottom := not occupied.has(cell + Vector2i.DOWN)
			var left := not occupied.has(cell + Vector2i.LEFT)
			var right := not occupied.has(cell + Vector2i.RIGHT)
			var tint := Color.WHITE if top or bottom or left or right else Color(0.72, 0.78, 0.8)
			draw_texture_rect_region(ATLAS, rect, STONE_REGIONS[variation], tint)
			# 微弱的亮顶、暗底强调实际可落脚边缘，不改变轮廓。
			if top:
				draw_line(rect.position + Vector2(0, 0.75), Vector2(rect.end.x, rect.position.y + 0.75), Color(0.7, 0.86, 0.88, 0.55), 1.5)
			if bottom:
				draw_line(Vector2(rect.position.x, rect.end.y - 0.75), rect.end - Vector2(0, 0.75), Color(0.06, 0.12, 0.16, 0.65), 1.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)
