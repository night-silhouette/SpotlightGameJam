extends Node2D
## 第二关分区控制：连续房间正常跟随，深井锁横向；通过现有 SignalBus 请求镜头。
## 与地图同一父节点摆放；地图可整体平移。竖井读取房间位置，其余边界对应当前灰盒布局。
@onready var _map: Node2D = $"../Level2Map"
@onready var _rig: Node2D = $"../Level2PlayerWithCamera"
@onready var _player: CharacterBody2D = $"../Level2PlayerWithCamera/Player"
@onready var _shaft_target: Marker2D = $ShaftFollowTarget
var current_zone: StringName = &""
var _shaft_rect: Rect2 = Rect2()

func _ready() -> void:
	SignalBus.PlayerRespawned.connect(_on_respawned)
	call_deferred("_refresh_after_spawn")

func _physics_process(_delta: float) -> void:
	_update_zone(false)
	$ShaftOcclusion/Mask.queue_redraw()

func _update_zone(force: bool) -> void:
	var point: Vector2 = _map.to_local(_player.global_position)
	var rooms: Node2D = _map.get_node("Rooms")
	var fall_room: Node2D = rooms.get_node("DescentShaft")
	var water_room: Node2D = rooms.get_node("FountainShaft")
	var fall_bounds := Rect2(fall_room.position, Vector2(280, 2620))
	var water_bounds := Rect2(water_room.position, Vector2(180, 2740))
	var zone: StringName = &"main"
	var mode: StringName = &"normal"
	var bounds := Rect2(Vector2(-4330, -480), Vector2(8460, 1340))
	_shaft_rect = Rect2()
	if water_bounds.has_point(point):
		zone = &"ascent"
		mode = &"descent"
		_shaft_rect = water_bounds
	elif fall_bounds.grow_individual(24, 0, 24, 0).has_point(point):
		zone = &"descent"
		mode = &"descent"
		_shaft_rect = fall_bounds
	elif point.y < -80:
		# 入口与地表出口高度不同，不能共用上边界。
		var upper_room: Node2D = rooms.get_node("EntryCollapse")
		zone = &"entry"
		if point.x >= water_room.position.x:
			upper_room = rooms.get_node("SurfaceExit")
			zone = &"surface"
		bounds = Rect2(upper_room.position + Vector2(-30, -80),
			Vector2(float(upper_room.get_meta("width")) + 60.0, 1100))
	elif point.y > 800 or (point.y > 600 and point.x >= 1050 and point.x < 1650):
		zone = &"lower"
		bounds = Rect2(Vector2(600, -480), Vector2(3300, 2810))
	if _shaft_rect.has_area():
		_shaft_target.global_position = _map.to_global(Vector2(_shaft_rect.get_center().x, point.y))
		bounds = Rect2(Vector2(_shaft_rect.get_center().x - 800, -3420), Vector2(1600, 4280))
	if not force and zone == current_zone:
		return
	current_zone = zone
	var options: Dictionary = {"intro": false, "bounds": Rect2(_map.to_global(bounds.position), bounds.size)}
	if mode == &"descent":
		options["follow_target"] = _shaft_target
		options["level2_ascent"] = zone == &"ascent"
	SignalBus.CameraShotRequested.emit(_player, mode, options)

func _on_respawned(_position: Vector2) -> void:
	call_deferred("_refresh_after_spawn")

func _refresh_after_spawn() -> void:
	_update_zone(true)
	_rig.SnapToPlayer()

## 返回当前竖井需要露出的世界矩形；空矩形表示不遮挡。
func GetShaftOpening() -> Rect2:
	if not ExportSettings.level2_camera_shaft_occlusion or not _shaft_rect.has_area():
		return Rect2()
	var margin: float = maxf(0.0, ExportSettings.level2_camera_wall_margin)
	return Rect2(_map.to_global(_shaft_rect.position - Vector2(margin, 0)),
		_shaft_rect.size + Vector2(margin * 2, 0))

## 返回井口附近逐渐显隐的遮挡强度，避免跨区突然变黑。
func GetOcclusionOpacity() -> float:
	if not _shaft_rect.has_area():
		return 0.0
	var point: Vector2 = _map.to_local(_player.global_position)
	var edge_distance: float = minf(point.y - _shaft_rect.position.y, _shaft_rect.end.y - point.y)
	return clampf(edge_distance / maxf(1.0, ExportSettings.level2_camera_occlusion_fade), 0.0, 1.0)

## 返回入口/出口的可见开口；遮挡墙外空白，不封闭下方井口。
func GetUpperRoomOpening() -> Rect2:
	var room: Node2D
	if current_zone == &"entry":
		room = _map.get_node("Rooms/EntryCollapse")
	elif current_zone == &"surface":
		room = _map.get_node("Rooms/SurfaceExit")
	else:
		return Rect2()
	return Rect2(room.to_global(Vector2(-30, -80)),
		Vector2(float(room.get_meta("width")) + 60.0, 1100))
