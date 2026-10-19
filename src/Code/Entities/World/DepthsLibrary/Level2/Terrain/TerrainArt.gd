@tool
extends Node2D
## 读取各房间 Terrain，统一绘制蓝边黑芯地形；外侧填充仅用于美术，不改变碰撞。
const SURFACE = preload("res://Code/Entities/World/DepthsLibrary/Level2/Terrain/StoneSurface.gd")
const SETTINGS: Script = preload("res://Code/Autoloads/ExportSettings.gd")
const SETTINGS_SCENE: PackedScene = preload("res://Code/Autoloads/ExportSettings.tscn")
var _sources: Array[TileMapLayer] = []
var _mesh: Dictionary = {}
var _signature: int = 0
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
	var rooms := get_parent().get_node_or_null("Rooms")
	if rooms == null:
		_restore_sources()
		_sources.clear()
		_mesh.clear()
		queue_redraw()
		return
	var found: Array[TileMapLayer] = []
	var rectangles: Array[Rect2] = []
	for room in rooms.get_children():
		var terrain := room.get_node_or_null("Terrain") as TileMapLayer
		if terrain == null or terrain.tile_set == null:
			continue
		found.append(terrain)
		if not terrain.is_visible_in_tree():
			continue
		var cells := terrain.get_used_cells()
		var extra := int(_setting(&"level2_terrain_art_stairwell_left_extra_columns"))
		if room.name == &"LowerStairwell" and extra > 0:
			var outer: Array[Vector2i] = []
			var left := terrain.get_used_rect().position.x
			for cell in cells:
				if cell.x == left:
					for step in range(1, extra + 1):
						outer.append(cell + Vector2i.LEFT * step)
			cells.append_array(outer)
		var tile_size := Vector2(terrain.tile_set.tile_size)
		var local_transform := global_transform.affine_inverse() * terrain.global_transform
		for cell in cells:
			rectangles.append(local_transform * Rect2(terrain.map_to_local(cell) - tile_size * 0.5, tile_size))
	for terrain in _sources:
		if is_instance_valid(terrain) and not found.has(terrain):
			RenderingServer.canvas_item_set_visible(terrain.get_canvas_item(), terrain.visible)
	_sources = found
	rectangles.append_array(_build_exterior(rooms))
	rectangles.append_array(_death_rectangles())
	var signature := hash(rectangles)
	if signature != _signature or _mesh.is_empty():
		_signature = signature
		_mesh = SURFACE.Build(rectangles)
	_sync_source_visibility()
	queue_redraw()

func _sync_source_visibility() -> void:
	var active := _art_enabled()
	for terrain in _sources:
		if is_instance_valid(terrain):
			RenderingServer.canvas_item_set_visible(terrain.get_canvas_item(), terrain.visible and not active)

func _restore_sources() -> void:
	for terrain in _sources:
		if is_instance_valid(terrain):
			RenderingServer.canvas_item_set_visible(terrain.get_canvas_item(), terrain.visible)

func _draw() -> void:
	if _art_enabled():
		SURFACE.Draw(self, _mesh, 32.0 * float(_setting(&"level2_terrain_art_border_ratio")))

func _terrain_bounds(terrain: TileMapLayer) -> Rect2:
	if terrain == null or terrain.tile_set == null:
		return Rect2()
	var cells := terrain.get_used_rect()
	if not cells.has_area():
		return Rect2()
	var tile_size := Vector2(terrain.tile_set.tile_size)
	var rect := Rect2(terrain.map_to_local(cells.position) - tile_size * 0.5, Vector2(cells.size) * tile_size)
	return global_transform.affine_inverse() * terrain.global_transform * rect

func _death_rectangles() -> Array[Rect2]:
	var result: Array[Rect2] = []
	var boundary := get_parent().get_node_or_null("DeathBoundary") as CanvasItem
	if boundary == null or not boundary.is_visible_in_tree() or not bool(_setting(&"level2_death_boundary_enabled")):
		return result
	for child in boundary.get_children():
		var collider := child as CollisionShape2D
		if collider == null or collider.disabled or not collider.shape is RectangleShape2D:
			continue
		if collider.name == &"WeaveArchiveDeathWater" and not bool(_setting(&"level2_death_boundary_weave_visual_enabled")):
			continue
		if collider.name == &"SunStacksDeathWater" and not bool(_setting(&"level2_death_boundary_sun_visual_enabled")):
			continue
		if collider.name == &"MoonAqueductDeathWater" and not bool(_setting(&"level2_death_boundary_moon_visual_enabled")):
			continue
		var size := (collider.shape as RectangleShape2D).size
		var rect := Rect2(-size * 0.5, size)
		if collider.name == &"MoonAqueductDeathWater":
			rect.size.y += maxf(0.0, float(_setting(&"level2_death_boundary_moon_join_depth")))
		result.append(global_transform.affine_inverse() * collider.global_transform * rect)
	return result

func _build_exterior(rooms: Node) -> Array[Rect2]:
	var result: Array[Rect2] = []
	var descent := rooms.get_node_or_null("DescentShaft/Terrain") as TileMapLayer
	var fountain := rooms.get_node_or_null("FountainShaft/Terrain") as TileMapLayer
	if bool(_setting(&"level2_terrain_art_shaft_exterior_enabled")) and _terrain_bounds(descent).has_area() and _terrain_bounds(fountain).has_area():
		var fall_bounds := _terrain_bounds(descent)
		var rise_bounds := _terrain_bounds(fountain)
		var width := maxf(0.0, float(_setting(&"level2_terrain_art_shaft_exterior_width")))
		var top := maxf(fall_bounds.position.y, rise_bounds.position.y)
		var bottom := minf(fall_bounds.end.y, rise_bounds.end.y)
		if width > 0.0:
			result.append(Rect2(fall_bounds.position - Vector2(width, 0), Vector2(width, fall_bounds.size.y)))
			if bottom > top:
				result.append(Rect2(rise_bounds.end.x, top, width, bottom - top))
		var gap := rise_bounds.position.x - fall_bounds.end.x
		if gap > 0.0 and bottom > top:
			result.append(Rect2(fall_bounds.end.x, top, gap, bottom - top))
	# 填满三个掉落区域周围的地图外侧；从死亡面高度开始，向下延伸供镜头取景。
	var death := _death_rectangles()
	var depth := maxf(0.0, float(_setting(&"level2_terrain_art_bottom_fill_depth")))
	var extent := Rect2()
	for terrain in _sources:
		var bounds := _terrain_bounds(terrain)
		if terrain.is_visible_in_tree() and bounds.has_area():
			extent = extent.merge(bounds) if extent.has_area() else bounds
	if not death.is_empty() and depth > 0.0 and extent.has_area():
		var top := death[0].position.y
		for rect in death:
			top = minf(top, rect.position.y)
		var margin := maxf(0.0, float(_setting(&"level2_terrain_art_shaft_exterior_width")))
		if extent.end.y + depth > top:
			result.append(Rect2(extent.position.x - margin, top, extent.size.x + margin * 2.0, extent.end.y + depth - top))
		var upper_height := maxf(0.0, float(_setting(&"level2_terrain_art_room_exterior_height")))
		var hub := rooms.get_node_or_null("Hub/Terrain") as TileMapLayer
		if upper_height > 0.0 and _terrain_bounds(hub).has_area():
			var ceiling := _terrain_bounds(hub).position.y
			if top > ceiling - upper_height:
				result.append(Rect2(extent.position.x - margin, ceiling - upper_height,
					extent.size.x + margin * 2.0, top - ceiling + upper_height))
	# 避让实际房间，不再用包含远处附属平台的地形包围盒挖空整片墙体。
	for room in rooms.get_children():
		var width := float(room.get_meta("width", 0.0))
		var height := float(room.get_meta("height", 720.0))
		var bounds: Rect2 = room.get_meta("scenery_bounds", Rect2(0, -64, width, height + 64))
		# 封闭房间按实际地板收口，避免地板下到死亡面之间留出一条灰带。
		if room.name in [&"RestArchive", &"ArchivePassage", &"WestPassage", &"EastPassage"]:
			var floor_terrain := room.get_node_or_null("Terrain") as TileMapLayer
			if _terrain_bounds(floor_terrain).has_area():
				var floor_bottom: float = room.to_local(to_global(_terrain_bounds(floor_terrain).end)).y
				bounds.size.y = minf(bounds.size.y, floor_bottom - bounds.position.y)
		if not bounds.has_area():
			continue
		var cut: Rect2 = global_transform.affine_inverse() * room.global_transform * bounds
		# 折返井背景比左墙内侧偏左几像素，填墙边界跟随砖墙，避免平台边出现小台阶。
		if room.name == &"LowerStairwell":
			var stair_terrain := room.get_node_or_null("Terrain") as TileMapLayer
			if _terrain_bounds(stair_terrain).has_area():
				var wall_end := stair_terrain.get_used_rect().position
				while stair_terrain.get_cell_source_id(wall_end) >= 0:
					wall_end.x += 1
				var edge := stair_terrain.map_to_local(wall_end) - Vector2(stair_terrain.tile_set.tile_size) * 0.5
				var inner_left := to_local(stair_terrain.to_global(edge)).x
				var inset := maxf(0.0, inner_left - cut.position.x)
				cut.position.x += inset
				cut.size.x -= inset
		# 竖井背景的末端早于大厅起点，避让范围要延伸进大厅，不能在井口留下横向填充条。
		if room.name in [&"DescentShaft", &"FountainShaft"]:
			var hub_room := rooms.get_node_or_null("Hub") as Node2D
			if hub_room != null:
				cut.size.y = maxf(cut.size.y, to_local(hub_room.global_position).y - cut.position.y)
		var clipped: Array[Rect2] = []
		for rect in result:
			clipped.append_array(_subtract_rect(rect, cut))
		result = clipped
	# 入口与下落井右墙相差一格；补在房间避让之后，消除外观上的台阶与背景接缝。
	var entry := rooms.get_node_or_null("EntryCollapse/Terrain") as TileMapLayer
	if bool(_setting(&"level2_terrain_art_entry_wall_aligned")) and _terrain_bounds(entry).has_area() and _terrain_bounds(descent).has_area():
		var entry_bounds := _terrain_bounds(entry)
		var descent_bounds := _terrain_bounds(descent)
		var tile_width := float(descent.tile_set.tile_size.x)
		var join := Rect2(descent_bounds.end.x - tile_width, entry_bounds.position.y,
			entry_bounds.end.x - descent_bounds.end.x, descent_bounds.position.y - entry_bounds.position.y)
		if join.has_area():
			result.append(join)
	return result

func _subtract_rect(rect: Rect2, cut: Rect2) -> Array[Rect2]:
	var pieces: Array[Rect2] = []
	# 编辑过程中空图层或分离的井道不应生成反向填充；不要用 abs() 把它变成额外墙面。
	if not rect.has_area():
		return pieces
	if not cut.has_area():
		pieces.append(rect)
		return pieces
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
