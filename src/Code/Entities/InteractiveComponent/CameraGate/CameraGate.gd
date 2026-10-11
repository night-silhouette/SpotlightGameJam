extends Area2D

## 禁止镜头越过的边：右边界防止提前看到右侧区域，其他方向同理。
@export_enum("左:0", "上:1", "右:2", "下:3") var blocked_side: int = SIDE_RIGHT
## 仅此路径所指的 Player 能开启本门；关卡实例中显式指定。
@export var player_path: NodePath
## 开启时进入后永久解锁；关闭时依玩家所在门侧限制镜头，跨门时平滑切换。
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
	if coordinate == boundary:
		return
	var side: int = _side_for_player(coordinate, boundary)
	if side != _side:
		_side = side
		SignalBus.CameraGateSideChanged.emit(player, self, side, boundary, false)


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
	if not one_shot or _unlocked or body != get_node_or_null(player_path):
		return
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
