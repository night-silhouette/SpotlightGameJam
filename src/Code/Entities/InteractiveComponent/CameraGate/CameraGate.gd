@tool
extends Area2D

## 禁止镜头越过的边；左/右使用水平检测，上/下使用垂直检测，由关卡实例指定。
@export_enum("左:0", "上:1", "右:2", "下:3") var blocked_side: int = SIDE_RIGHT
## 仅此路径所指的 Player 能开启本门；关卡实例中显式指定。
@export var player_path: NodePath
## 开启时完整越过检测区域后永久解锁；关闭时越过检测区域远端边缘才平滑切换，区域内保持原侧。
@export var one_shot: bool = true

var _unlocked: bool = false
var _side: int = -1
var _editor_transition_rect := Rect2()


func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(true)
		_refresh_editor_transition_preview()
		return
	set_process(false)
	SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)
	SignalBus.PlayerRespawned.connect(_on_player_respawned)
	call_deferred("_broadcast_state")


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_refresh_editor_transition_preview()


func _draw() -> void:
	if not Engine.is_editor_hint() or not _editor_transition_rect.has_area():
		return
	draw_rect(_editor_transition_rect, Color(1.0, 0.45, 0.08, 0.3), true)
	draw_rect(_editor_transition_rect, Color(1.0, 0.55, 0.12, 0.9), false, 2.0)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if is_instance_valid(player):
		SignalBus.CameraGateChanged.emit(player, self, false, blocked_side, 0.0)
		if not one_shot:
			SignalBus.CameraGateSideRemoved.emit(player, self)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _side == -1 or (one_shot and _unlocked):
		return
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if not is_instance_valid(player):
		return
	var coordinate: float = player.global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else player.global_position.x
	var boundary: float = global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else global_position.x
	var bounds: Rect2 = _get_transition_bounds(_runtime_camera_view_size())
	if not bounds.has_area():
		return
	var minimum: float = bounds.position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else bounds.position.x
	var maximum: float = bounds.end.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else bounds.end.x
	var orthogonal_coordinate: float = player.global_position.x if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else player.global_position.y
	var orthogonal_minimum: float = bounds.position.x if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else bounds.position.y
	var orthogonal_maximum: float = bounds.end.x if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else bounds.end.y
	# 两个边缘构成滞回区；人物在区域内往返时不改变镜头所在侧。
	var side: int = _side_beyond_bounds(coordinate, minimum, maximum)
	# 从门的上方或下方绕行时只同步侧别，不播放黑幕或推镜；迁移只发生在门的实际跨度内。
	if orthogonal_coordinate < orthogonal_minimum or orthogonal_coordinate > orthogonal_maximum:
		if side != _side:
			_side = side
			if not one_shot:
				SignalBus.CameraGateSideChanged.emit(player, self, side, boundary, true)
		return
	if side != _side:
		SignalBus.CameraGateFadeRequested.emit(player, self)
		if one_shot:
			_unlocked = true
			_side = -1
			SignalBus.CameraGateChanged.emit(player, self, false, blocked_side, boundary)
		else:
			_side = side
			SignalBus.CameraGateSideChanged.emit(player, self, side, boundary, false)


func _get_detection_bounds() -> Rect2:
	var bounds := Rect2()
	var has_bounds: bool = false
	for child: Node in get_children():
		if not child is CollisionShape2D:
			continue
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision.disabled or collision.shape == null:
			continue
		var shape_bounds: Rect2 = collision.global_transform * collision.shape.get_rect()
		bounds = bounds.merge(shape_bounds) if has_bounds else shape_bounds
		has_bounds = true
	return bounds


func _get_transition_bounds(camera_view_size: Vector2) -> Rect2:
	var bounds := _get_detection_bounds()
	if not bounds.has_area():
		return bounds
	var center := bounds.get_center()
	# 左右门使用一个镜头高的竖向转换带；上下门使用一个镜头宽的横向转换带。
	if blocked_side in [SIDE_LEFT, SIDE_RIGHT]:
		bounds.position.y = center.y - camera_view_size.y * 0.5
		bounds.size.y = camera_view_size.y
	else:
		bounds.position.x = center.x - camera_view_size.x * 0.5
		bounds.size.x = camera_view_size.x
	return bounds


func _runtime_camera_view_size() -> Vector2:
	var view_size := get_viewport_rect().size
	var camera := get_viewport().get_camera_2d()
	if is_instance_valid(camera):
		var zoom := camera.zoom.abs()
		view_size.x /= maxf(zoom.x, 0.05)
		view_size.y /= maxf(zoom.y, 0.05)
	return view_size


func _editor_camera_view_size() -> Vector2:
	# 项目未覆写设计视口时使用 Godot 4 的默认 1152x648；运行时会读取真实视口与 Zoom。
	var width := float(ProjectSettings.get_setting("display/window/size/viewport_width", 1152))
	var height := float(ProjectSettings.get_setting("display/window/size/viewport_height", 648))
	return Vector2(maxf(width, 1.0), maxf(height, 1.0))


func _refresh_editor_transition_preview() -> void:
	var world_bounds := _get_transition_bounds(_editor_camera_view_size())
	var local_bounds := global_transform.affine_inverse() * world_bounds if world_bounds.has_area() else Rect2()
	if local_bounds.is_equal_approx(_editor_transition_rect):
		return
	_editor_transition_rect = local_bounds
	queue_redraw()


func _side_beyond_bounds(coordinate: float, minimum: float, maximum: float) -> int:
	if coordinate < minimum:
		return SIDE_BOTTOM if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else SIDE_RIGHT
	if coordinate > maximum:
		return SIDE_TOP if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else SIDE_LEFT
	return _side


func _side_for_player(coordinate: float, boundary: float) -> int:
	var blocked_on_positive: bool = blocked_side in [SIDE_RIGHT, SIDE_BOTTOM]
	if (coordinate < boundary) == blocked_on_positive:
		return blocked_side
	return (blocked_side + 2) % 4


func _broadcast_state() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if not is_instance_valid(player):
		push_warning("CameraGate: configure player_path to the target Player node.")
		return
	var boundary: float = global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else global_position.x
	var coordinate: float = player.global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else player.global_position.x
	if not one_shot:
		_side = _side_for_player(coordinate, boundary)
		SignalBus.CameraGateSideChanged.emit(player, self, _side, boundary, true)
	else:
		_side = -1 if _unlocked else _side_for_player(coordinate, boundary)
		SignalBus.CameraGateChanged.emit(player, self, not _unlocked, blocked_side, boundary)


func _on_save_slot_loaded(_slot_index: int) -> void:
	_broadcast_state()


func _on_player_respawned(_respawn_position: Vector2) -> void:
	# 重生是位置重置，不是实际跨门；同时清除消费者中未完成的推镜。
	_broadcast_state()


## 导出门的一次性解锁状态；返回字典供 SaveManager 按场景节点路径保存。
func ExportSaveData() -> Dictionary:
	return {"unlocked": _unlocked if one_shot else false}


## 从存档恢复一次性解锁状态；data 为该门的保存字典，非一次性门依玩家当前位置重新判定。
func LoadSaveData(data: Dictionary) -> void:
	_unlocked = bool(data.get("unlocked", false)) if one_shot else false
	if is_node_ready():
		_broadcast_state()
