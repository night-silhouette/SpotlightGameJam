@tool
extends Node2D
## 独立地形外观层：读取同地图各房间的 Terrain，只绘制美术，不创建或修改碰撞。
## 隐藏或移除此节点即可恢复灰盒；原 Terrain 的 Visible 属性不会被改写或保存。
const ATLAS: Texture2D = preload("res://Art/New/map2/2_grid665.png")
# 使用完整半透明款及石框的边缘、转角、黑芯；665 网格不是单块砖的边界。
const GLASS_SQUARE := Rect2(1, 464, 1521, 1527)
const GLASS_WIDE := Rect2(0, 5975, 2774, 2004)
const DARK_CORE := Rect2(1100, 3900, 256, 256)
const SETTINGS: Script = preload("res://Code/Autoloads/ExportSettings.gd")
const SETTINGS_SCENE: PackedScene = preload("res://Code/Autoloads/ExportSettings.tscn")
var _glass_enabled: bool = true
var _glass_max_rows: int = 2
var _border_ratio: float = 0.44
var _stairwell_left_extra_columns: int = 1
var _sources: Dictionary = {}
var _shaft_exterior: Array[Rect2] = []
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

func _setting(key: StringName) -> Variant:
	if not Engine.is_editor_hint():
		return ExportSettings.get(key)
	var state := SETTINGS_SCENE.get_state()
	for index in range(state.get_node_property_count(0)):
		if state.get_node_property_name(0, index) == key:
			return state.get_node_property_value(0, index)
	return SETTINGS.get_property_default_value(key)

func _art_enabled() -> bool:
	return is_visible_in_tree() and bool(_setting(&"level2_terrain_art_enabled"))

func _refresh_sources() -> void:
	var glass_enabled := bool(_setting(&"level2_terrain_art_glass_platforms"))
	var max_rows := int(_setting(&"level2_terrain_art_glass_max_rows"))
	var extra_columns := int(_setting(&"level2_terrain_art_stairwell_left_extra_columns"))
	var rebuild := glass_enabled != _glass_enabled or max_rows != _glass_max_rows or extra_columns != _stairwell_left_extra_columns
	_glass_enabled = glass_enabled
	_glass_max_rows = max_rows
	_stairwell_left_extra_columns = extra_columns
	_border_ratio = float(_setting(&"level2_terrain_art_border_ratio"))
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
		if rebuild or not _sources.has(terrain) or not _sources[terrain].has("glass_cells") or _sources[terrain].fingerprint != fingerprint:
			var cells := terrain.get_used_cells()
			# 只向竖井外侧加美术格，不调用 set_cell，也不改变井内边界或跳台。
			if room.name == &"LowerStairwell" and _stairwell_left_extra_columns > 0:
				var left_column := terrain.get_used_rect().position.x
				var outer_cells: Array[Vector2i] = []
				for cell in cells:
					if cell.x == left_column:
						for step in range(1, _stairwell_left_extra_columns + 1):
							outer_cells.append(cell + Vector2i.LEFT * step)
				cells.append_array(outer_cells)
			var occupied: Dictionary = {}
			for cell in cells:
				occupied[cell] = true
			var glass := _collect_glass(occupied)
			_sources[terrain] = {"fingerprint": fingerprint, "cells": cells, "occupied": occupied, "glass_cells": glass.cells, "glass_rects": glass.rects}
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

# 独立的一至两格厚矩形平台使用整段半透明外观；厚墙、井壁保持石框。
# 连在墙上的单格厚挑台也合并成条，不把整面竖墙变成透明材质。
func _collect_glass(occupied: Dictionary) -> Dictionary:
	var glass_cells: Dictionary = {}
	var glass_rects: Array[Rect2i] = []
	if not _glass_enabled:
		return {"cells": glass_cells, "rects": glass_rects}
	var seen: Dictionary = {}
	for start: Vector2i in occupied:
		if seen.has(start):
			continue
		var pending: Array[Vector2i] = [start]
		var component: Array[Vector2i] = []
		var low := start
		var high := start
		seen[start] = true
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			component.append(cell)
			low = low.min(cell)
			high = high.max(cell)
			for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var adjacent: Vector2i = cell + direction
				if occupied.has(adjacent) and not seen.has(adjacent):
					seen[adjacent] = true
					pending.append(adjacent)
		var size := high - low + Vector2i.ONE
		if size.y <= _glass_max_rows and size.x >= size.y and component.size() == size.x * size.y:
			glass_rects.append(Rect2i(low, size))
			for cell in component:
				glass_cells[cell] = true
	for cell: Vector2i in occupied:
		if glass_cells.has(cell) or occupied.has(cell + Vector2i.UP) or occupied.has(cell + Vector2i.DOWN):
			continue
		var left := cell
		while _is_thin_cell(left + Vector2i.LEFT, occupied, glass_cells):
			left += Vector2i.LEFT
		var end := left
		while _is_thin_cell(end, occupied, glass_cells):
			end += Vector2i.RIGHT
		if end.x - left.x < 2:
			continue
		glass_rects.append(Rect2i(left, Vector2i(end.x - left.x, 1)))
		for x in range(left.x, end.x):
			glass_cells[Vector2i(x, left.y)] = true
	return {"cells": glass_cells, "rects": glass_rects}

func _is_thin_cell(cell: Vector2i, occupied: Dictionary, glass_cells: Dictionary) -> bool:
	return occupied.has(cell) and not glass_cells.has(cell) and not occupied.has(cell + Vector2i.UP) and not occupied.has(cell + Vector2i.DOWN)

func _draw() -> void:
	if not _art_enabled():
		return
	_shaft_exterior = _build_shaft_exterior()
	for rect in _shaft_exterior:
		draw_texture_rect_region(ATLAS, rect, DARK_CORE)
	# 房间各自保存 Terrain，但相接的墙必须按整张地图判断外轮廓。
	# 用实际位置合并占用，避免两间房的并排井壁在柱子中间重复画蓝边。
	var map_occupied: Dictionary = {}
	var glass_strips: Array[Rect2] = []
	var grid_size := Vector2.ZERO
	for source in _sources:
		var terrain := source as TileMapLayer
		if not is_instance_valid(terrain) or not terrain.is_visible_in_tree() or terrain.tile_set == null:
			continue
		for cell: Vector2i in _sources[terrain].cells:
			map_occupied[_cell_key(terrain, cell)] = true
		var transform_to_art := global_transform.affine_inverse() * terrain.global_transform
		var tile_size := Vector2(terrain.tile_set.tile_size)
		grid_size = (transform_to_art * Rect2(Vector2.ZERO, tile_size)).size
		for cells: Rect2i in _sources[terrain].glass_rects:
			var rect := Rect2(terrain.map_to_local(cells.position) - tile_size * 0.5, Vector2(cells.size) * tile_size)
			glass_strips.append(transform_to_art * rect)
	glass_strips = _join_glass_strips(glass_strips, map_occupied, grid_size)
	# 石边只与同材质的黑芯地形合并；透明平台接在旁边时仍须保留完整石框。
	# 否则邻接判定会把接口当作墙体内部，留下缺失的一截蓝边。
	var stone_occupied: Dictionary = {}
	for key: Vector2i in map_occupied:
		if not _inside_glass_strip(Vector2(key) / 100.0, glass_strips):
			stone_occupied[key] = true
	for source in _sources:
		var terrain := source as TileMapLayer
		if not is_instance_valid(terrain) or not terrain.is_visible_in_tree() or terrain.tile_set == null:
			continue
		draw_set_transform_matrix(global_transform.affine_inverse() * terrain.global_transform)
		var tile_size := Vector2(terrain.tile_set.tile_size)
		var data: Dictionary = _sources[terrain]
		for cell: Vector2i in data.cells:
			var center := to_local(terrain.to_global(terrain.map_to_local(cell)))
			if _inside_glass_strip(center, glass_strips):
				continue
			var rect := Rect2(terrain.map_to_local(cell) - tile_size * 0.5, tile_size)
			_draw_stone(rect, cell, terrain, stone_occupied)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	# 横梁最后统一绘制，交接处不垫黑芯，也不叠加两层半透明素材。
	for rect in glass_strips:
		_draw_glass(rect)

func _inside_glass_strip(center: Vector2, strips: Array[Rect2]) -> bool:
	for rect in strips:
		if rect.has_point(center):
			return true
	return false

func _join_glass_strips(strips: Array[Rect2], occupied: Dictionary, grid_size: Vector2) -> Array[Rect2]:
	if grid_size.x <= 0.0 or grid_size.y <= 0.0:
		return strips
	strips.sort_custom(func(a: Rect2, b: Rect2) -> bool:
		return a.position.x < b.position.x)
	var joined: Array[Rect2] = []
	for rect in strips:
		var merged := false
		for index in range(joined.size()):
			var left := joined[index]
			if not is_equal_approx(left.position.y, rect.position.y) or not is_equal_approx(left.size.y, rect.size.y):
				continue
			# 只覆盖横梁之间真实存在的墙柱，不跨越井口、缺口或空中跳跃间距。
			var solid := true
			var x := left.end.x + grid_size.x * 0.5
			while x < rect.position.x and solid:
				var y := rect.position.y + grid_size.y * 0.5
				while y < rect.end.y:
					if not occupied.has(Vector2i((Vector2(x, y) * 100.0).round())):
						solid = false
						break
					y += grid_size.y
				x += grid_size.x
			if solid:
				joined[index] = left.merge(rect)
				merged = true
				break
		if not merged:
			joined.append(rect)
	return joined

func _cell_key(terrain: TileMapLayer, cell: Vector2i) -> Vector2i:
	# 保留到百分之一像素，消除父节点变换的浮点误差，不跨空格补墙。
	var center := to_local(terrain.to_global(terrain.map_to_local(cell)))
	return Vector2i((center * 100.0).round())

func _terrain_bounds(terrain: TileMapLayer) -> Rect2:
	var cells := terrain.get_used_rect()
	var tile_size := Vector2(terrain.tile_set.tile_size)
	var rect := Rect2(terrain.map_to_local(cells.position) - tile_size * 0.5, Vector2(cells.size) * tile_size)
	return (global_transform.affine_inverse() * terrain.global_transform) * rect

func _build_shaft_exterior() -> Array[Rect2]:
	var result: Array[Rect2] = []
	if not bool(_setting(&"level2_terrain_art_shaft_exterior_enabled")):
		return result
	var rooms := get_parent().get_node_or_null("Rooms")
	if rooms == null:
		return result
	var descent := rooms.get_node_or_null("DescentShaft/Terrain") as TileMapLayer
	var fountain := rooms.get_node_or_null("FountainShaft/Terrain") as TileMapLayer
	if descent == null or fountain == null or not _sources.has(descent) or not _sources.has(fountain):
		return result
	if not descent.is_visible_in_tree() or not fountain.is_visible_in_tree():
		return result
	var fall_bounds := _terrain_bounds(descent)
	var fountain_bounds := _terrain_bounds(fountain)
	var width := maxf(0.0, float(_setting(&"level2_terrain_art_shaft_exterior_width")))
	if width <= 0.0:
		return result
	# 只延伸外侧灰区，不往下落井或喷泉井内部添加任何美术或碰撞。
	result.append(Rect2(fall_bounds.position - Vector2(width, 0), Vector2(width, fall_bounds.size.y)))
	var top := maxf(fall_bounds.position.y, fountain_bounds.position.y)
	var bottom := minf(fall_bounds.end.y, fountain_bounds.end.y)
	var gap := fountain_bounds.position.x - fall_bounds.end.x
	if gap > 0.0 and bottom > top:
		result.append(Rect2(fall_bounds.end.x, top, gap, bottom - top))
	result.append(Rect2(fountain_bounds.end.x, top, width, bottom - top))
	# 切除其他房间的范围，特别是上方入口房间和下方大厅，避免盖住可游玩区域。
	for room in rooms.get_children():
		if room == descent.get_parent() or room == fountain.get_parent():
			continue
		var bounds: Rect2 = room.get_meta("scenery_bounds", Rect2(Vector2.ZERO, Vector2(float(room.get_meta("width", 0.0)), float(room.get_meta("height", 0.0)))))
		bounds = (global_transform.affine_inverse() * room.global_transform) * bounds
		var cuts: Array[Rect2] = []
		if bounds.has_area():
			cuts.append(bounds)
		var terrain := room.get_node_or_null("Terrain") as TileMapLayer
		if terrain != null and terrain.tile_set != null and not terrain.get_used_cells().is_empty():
			cuts.append(_terrain_bounds(terrain))
		# 房间主体与偏远的附属平台分开避让，不能把两者之间的灰区也挖空。
		for cut in cuts:
			var clipped: Array[Rect2] = []
			for rect in result:
				clipped.append_array(_subtract_rect(rect, cut))
			result = clipped
	return result

func _subtract_rect(rect: Rect2, cut: Rect2) -> Array[Rect2]:
	var pieces: Array[Rect2] = []
	var overlap := rect.intersection(cut)
	if not overlap.has_area():
		pieces.append(rect)
		return pieces
	for piece in [Rect2(rect.position.x, rect.position.y, rect.size.x, overlap.position.y - rect.position.y),
		Rect2(rect.position.x, overlap.end.y, rect.size.x, rect.end.y - overlap.end.y),
		Rect2(rect.position.x, overlap.position.y, overlap.position.x - rect.position.x, overlap.size.y),
		Rect2(overlap.end.x, overlap.position.y, rect.end.x - overlap.end.x, overlap.size.y)]:
		if piece.has_area():
			pieces.append(piece)
	return pieces

func _stone_neighbor_exists(terrain: TileMapLayer, cell: Vector2i, occupied: Dictionary) -> bool:
	var key := _cell_key(terrain, cell)
	return occupied.has(key) or _inside_glass_strip(Vector2(key) / 100.0, _shaft_exterior)

func _draw_stone(rect: Rect2, cell: Vector2i, terrain: TileMapLayer, occupied: Dictionary) -> void:
	# 黑芯只填实际存在的地形格，绝不填房间空白或封住井口。
	draw_texture_rect_region(ATLAS, rect, DARK_CORE)
	var top := not _stone_neighbor_exists(terrain, cell + Vector2i.UP, occupied)
	var bottom := not _stone_neighbor_exists(terrain, cell + Vector2i.DOWN, occupied)
	var left := not _stone_neighbor_exists(terrain, cell + Vector2i.LEFT, occupied)
	var right := not _stone_neighbor_exists(terrain, cell + Vector2i.RIGHT, occupied)
	var border := minf(rect.size.x, rect.size.y) * _border_ratio
	var map_position := to_local(terrain.to_global(rect.position))
	if top:
		_draw_stone_edge(Rect2(rect.position, Vector2(rect.size.x, border)), Rect2(461, 2959, 2034, 460), true, map_position.x)
	if bottom:
		_draw_stone_edge(Rect2(rect.position.x, rect.end.y - border, rect.size.x, border), Rect2(461, 4859, 2034, 460), true, map_position.x)
	if left:
		_draw_stone_edge(Rect2(rect.position, Vector2(border, rect.size.y)), Rect2(1, 3419, 460, 1440), false, map_position.y)
	if right:
		_draw_stone_edge(Rect2(rect.end.x - border, rect.position.y, border, rect.size.y), Rect2(2495, 3419, 460, 1440), false, map_position.y)
	# 两条边相交时用原画的整块转角，避免重复贴边产生十字接缝。
	if top and left:
		draw_texture_rect_region(ATLAS, Rect2(rect.position, Vector2.ONE * border), Rect2(1, 2959, 460, 460))
	if top and right:
		draw_texture_rect_region(ATLAS, Rect2(rect.end.x - border, rect.position.y, border, border), Rect2(2495, 2959, 460, 460))
	if bottom and left:
		draw_texture_rect_region(ATLAS, Rect2(rect.position.x, rect.end.y - border, border, border), Rect2(1, 4859, 460, 460))
	if bottom and right:
		draw_texture_rect_region(ATLAS, Rect2(rect.end - Vector2.ONE * border, Vector2.ONE * border), Rect2(2495, 4859, 460, 460))

func _draw_stone_edge(destination: Rect2, sample: Rect2, horizontal: bool, phase: float) -> void:
	# 以地图坐标延续纹理，不在每一格或房间边界重新起头。
	var pieces := _stone_edge_pieces(destination, sample, horizontal, phase)
	for index in range(0, pieces.size(), 2):
		draw_texture_rect_region(ATLAS, pieces[index], pieces[index + 1])

func _stone_edge_pieces(destination: Rect2, sample: Rect2, horizontal: bool, phase: float) -> Array[Rect2]:
	# 厚度确定唯一缩放比例；沿长度方向重复，末尾裁切，X/Y 始终相等。
	var pieces: Array[Rect2] = []
	var scale_factor := destination.size.y / sample.size.y if horizontal else destination.size.x / sample.size.x
	var length := destination.size.x if horizontal else destination.size.y
	var source_length := sample.size.x if horizontal else sample.size.y
	if scale_factor <= 0.0 or source_length <= 0.0:
		return pieces
	var offset := 0.0
	var source_offset := fposmod(phase / scale_factor, source_length)
	while offset < length - 0.00001:
		var piece_length := minf(length - offset, (source_length - source_offset) * scale_factor)
		var target := destination
		var region := sample
		if horizontal:
			target.position.x += offset
			target.size.x = piece_length
			region.position.x += source_offset
			region.size.x = piece_length / scale_factor
		else:
			target.position.y += offset
			target.size.y = piece_length
			region.position.y += source_offset
			region.size.y = piece_length / scale_factor
		pieces.append(target)
		pieces.append(region)
		offset += piece_length
		source_offset = 0.0
	return pieces

func _draw_glass(rect: Rect2) -> void:
	var death_join := _death_join_rect()
	var region := GLASS_WIDE if rect.size.x > rect.size.y * 1.2 else GLASS_SQUARE
	var cap := minf(10.0, minf(rect.size.x, rect.size.y) * 0.3)
	var source_cap := 300.0
	var dx := [rect.position.x, rect.position.x + cap, rect.end.x - cap, rect.end.x]
	var dy := [rect.position.y, rect.position.y + cap, rect.end.y - cap, rect.end.y]
	var sx := [region.position.x, region.position.x + source_cap, region.end.x - source_cap, region.end.x]
	var sy := [region.position.y, region.position.y + source_cap, region.end.y - source_cap, region.end.y]
	# 九宫格保留圆角与亮边；中段延展，原图约 70% 的透明度原样保留。
	for y in range(3):
		for x in range(3):
			var destination := Rect2(dx[x], dy[y], dx[x + 1] - dx[x], dy[y + 1] - dy[y])
			var sample := Rect2(sx[x], sy[y], sx[x + 1] - sx[x], sy[y + 1] - sy[y])
			_draw_glass_sample(destination, sample, death_join)

func _death_join_rect() -> Rect2:
	# 读取同地图的布局，仅裁掉重复外观，不修改任何机关或碰撞状态。
	if not bool(_setting(&"level2_death_boundary_enabled")):
		return Rect2()
	var boundary := get_parent().get_node_or_null("DeathBoundary") as CanvasItem
	if boundary == null or not boundary.is_visible_in_tree():
		return Rect2()
	var collider := boundary.get_node_or_null("MoonAqueductDeathWater") as CollisionShape2D
	if collider == null or collider.disabled or not collider.shape is RectangleShape2D:
		return Rect2()
	var depth := maxf(0.0, float(_setting(&"level2_death_boundary_moon_join_depth")))
	var shape := collider.shape as RectangleShape2D
	var extension := Rect2(Vector2(-shape.size.x * 0.5, shape.size.y * 0.5), Vector2(shape.size.x, depth))
	return global_transform.affine_inverse() * collider.global_transform * extension

func _draw_glass_sample(destination: Rect2, sample: Rect2, exclusion: Rect2) -> void:
	var overlap := destination.intersection(exclusion)
	if not overlap.has_area():
		draw_texture_rect_region(ATLAS, destination, sample)
		return
	# 衔接部分由 DeathBoundary 一次绘制，避免双重透明叠加及两条接缝描边。
	var pieces: Array[Rect2] = [
		Rect2(destination.position, Vector2(destination.size.x, overlap.position.y - destination.position.y)),
		Rect2(Vector2(destination.position.x, overlap.end.y), Vector2(destination.size.x, destination.end.y - overlap.end.y)),
		Rect2(Vector2(destination.position.x, overlap.position.y), Vector2(overlap.position.x - destination.position.x, overlap.size.y)),
		Rect2(Vector2(overlap.end.x, overlap.position.y), Vector2(destination.end.x - overlap.end.x, overlap.size.y)),
	]
	for piece in pieces:
		if not piece.has_area():
			continue
		var source := Rect2(sample.position + (piece.position - destination.position) / destination.size * sample.size, piece.size / destination.size * sample.size)
		draw_texture_rect_region(ATLAS, piece, source)
