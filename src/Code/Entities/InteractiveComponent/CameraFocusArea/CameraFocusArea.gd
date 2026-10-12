extends Area2D

## 只响应此路径指向的玩家；在关卡实例中指向 PlayerWithCamera/Player。
@export var player_path: NodePath

@onready var _focus_point: Marker2D = $FocusPoint
var _player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body != get_node_or_null(player_path):
		return
	_player_inside = true
	SignalBus.CameraFixedRequested.emit(body, _focus_point, "", "", Rect2())


func _on_body_exited(body: Node2D) -> void:
	if not _player_inside or body != get_node_or_null(player_path):
		return
	_player_inside = false
	SignalBus.CameraNormalRequested.emit(body)
