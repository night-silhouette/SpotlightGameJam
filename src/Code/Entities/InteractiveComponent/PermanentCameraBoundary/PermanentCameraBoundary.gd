extends Area2D

## 永久禁止镜头越过的世界边界；左右边界使用竖向范围，上下边界使用横向范围。
@export_enum("左:0", "上:1", "右:2", "下:3") var blocked_side: int = SIDE_BOTTOM
## 仅此路径所指的 Player 使用该永久镜头边界；关卡实例中显式指定。
@export var player_path: NodePath


func _ready() -> void:
	call_deferred("_broadcast_limit")


func _exit_tree() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if is_instance_valid(player):
		SignalBus.CameraGateChanged.emit(player, self, false, blocked_side, 0.0)


func _broadcast_limit() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if not is_instance_valid(player):
		push_warning("PermanentCameraBoundary: configure player_path to the target Player node.")
		return
	var boundary: float = global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else global_position.x
	SignalBus.CameraGateChanged.emit(player, self, true, blocked_side, boundary)
