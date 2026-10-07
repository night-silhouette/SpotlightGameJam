extends Node2D
## F6 测试入口，复用正式玩家逻辑；贴图使用占位资源。
@onready var _player: CharacterBody2D = $PreviewPlayer
@onready var _map: Node2D = $Level2Map
@onready var _camera: Camera2D = $PreviewCamera

func _ready() -> void:
	_player.global_position = $Level2Map/Rooms/EntryCollapse/Spawn.global_position
	_player.SetRespawnPosition(_player.global_position)
	_player.get_node("debug").hide()
	_player.get_node("hp").hide()
	_player.rope_controller.process_mode = Node.PROCESS_MODE_DISABLED
	_player.enable_double_jump = true
	_player.ResetDoubleJump()
	_camera.position = _player.global_position
	_camera.reset_smoothing()

func _process(_delta: float) -> void:
	_camera.zoom = Vector2.ONE * get_viewport_rect().size.x / maxf(640.0, ExportSettings.level2_view_width)
	# 持续跟随实际世界位置，不在房间交界切换或重置镜头。
	_camera.global_position = _player.global_position + Vector2(0, -80)
