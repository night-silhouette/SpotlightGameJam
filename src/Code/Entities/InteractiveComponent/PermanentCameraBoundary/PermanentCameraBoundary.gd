extends Area2D

## 永久禁止镜头越过的世界边界；左右边界使用竖向范围，上下边界使用横向范围。
@export_enum("左:0", "上:1", "右:2", "下:3") var blocked_side: int = SIDE_BOTTOM
## 仅此路径所指的 Player 使用该永久镜头边界；关卡实例中显式指定。
@export var player_path: NodePath
## 可选的所属关卡原点；仅玩家在该原点的高度范围内时启用。留空保持全局边界。
## 高度范围在 ExportSettings.camera_gate_scope_y_range 调整，不受边界自身旋转/缩放影响。
@export var scope_origin_path: NodePath

var _registered: bool = false


func _ready() -> void:
	set_physics_process(not scope_origin_path.is_empty())
	call_deferred("_broadcast_limit")


func _physics_process(_delta: float) -> void:
	var player := get_node_or_null(player_path) as Node2D
	if not is_instance_valid(player):
		return
	var active := _is_in_scope(player)
	if active != _registered:
		_send_limit(player, active)


func _exit_tree() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if is_instance_valid(player):
		SignalBus.CameraGateChanged.emit(player, self, false, blocked_side, 0.0)


func _broadcast_limit() -> void:
	var player: Node2D = get_node_or_null(player_path) as Node2D
	if not is_instance_valid(player):
		push_warning("PermanentCameraBoundary: configure player_path to the target Player node.")
		return
	_send_limit(player, _is_in_scope(player))


func _is_in_scope(player: Node2D) -> bool:
	if scope_origin_path.is_empty():
		return true
	var origin := get_node_or_null(scope_origin_path) as Node2D
	if not is_instance_valid(origin):
		return false
	var height: float = origin.to_local(player.global_position).y
	var span: Vector2 = ExportSettings.camera_gate_scope_y_range
	return height >= minf(span.x, span.y) and height <= maxf(span.x, span.y)


func _send_limit(player: Node2D, active: bool) -> void:
	_registered = active
	var boundary: float = global_position.y if blocked_side in [SIDE_TOP, SIDE_BOTTOM] else global_position.x
	SignalBus.CameraGateChanged.emit(player, self, active, blocked_side, boundary)
