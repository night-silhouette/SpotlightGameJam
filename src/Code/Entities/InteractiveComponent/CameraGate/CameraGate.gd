extends Area2D

## 禁止镜头越过的边；左/右使用水平检测，上/下使用垂直检测，由关卡实例指定。
@export_enum("左:0", "上:1", "右:2", "下:3") var blocked_side: int = SIDE_RIGHT
## 仅此路径所指的 Player 能开启本门；关卡实例中显式指定。
@export var player_path: NodePath
## 开启时进入后永久解锁；关闭时越过检测区域远端边缘才平滑切换，区域内保持原侧。
@export var one_shot: bool = true

var _unlocked: bool = false
var _side: int = -1


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)
	call_deferred("_broadcast_state")


func _exit_tree() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if is_instance_valid(player):
		SignalBus.CameraGateChanged.emit(player, self, false, blocked_side, 0.0)
		if not one_shot:
			SignalBus.CameraGateSideRemoved.emit(player, self)


func _physics_process(_delta: float) -> void:
	if one_shot or _side == -1:
		return
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if not is_instance_valid(player):
		return
	var coordinate: float = player.global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else player.global_position.x
	var boundary: float = global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else global_position.x
	var bounds: Rect2 = _get_detection_bounds()
	if not bounds.has_area():
		return
	var minimum: float = bounds.position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else bounds.position.x
	var maximum: float = bounds.end.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else bounds.end.x
	# 两个边缘构成滞回区；人物在区域内往返时不改变镜头所在侧。
	var side: int = _side
	if coordinate < minimum:
		side = SIDE_BOTTOM if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else SIDE_RIGHT
	elif coordinate > maximum:
		side = SIDE_TOP if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else SIDE_LEFT
	if side != _side:
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
	if not one_shot:
		var coordinate: float = player.global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else player.global_position.x
		_side = _side_for_player(coordinate, boundary)
		SignalBus.CameraGateSideChanged.emit(player, self, _side, boundary, true)
	else:
		SignalBus.CameraGateChanged.emit(player, self, not _unlocked, blocked_side, boundary)


func _on_body_entered(body: Node2D) -> void:
	if body != get_node_or_null(player_path):
		return
	if one_shot and _unlocked:
		return
	SignalBus.CameraGateFadeRequested.emit(body, self)
	if one_shot:
		_unlocked = true
		_broadcast_state()


func _on_save_slot_loaded(_slot_index: int) -> void:
	if not one_shot:
		_broadcast_state()


## 导出门的一次性解锁状态；返回字典供 SaveManager 按场景节点路径保存。
func ExportSaveData() -> Dictionary:
	return {"unlocked": _unlocked if one_shot else false}


## 从存档恢复一次性解锁状态；data 为该门的保存字典，非一次性门依玩家当前位置重新判定。
func LoadSaveData(data: Dictionary) -> void:
	_unlocked = bool(data.get("unlocked", false)) if one_shot else false
	if is_node_ready():
		_broadcast_state()
