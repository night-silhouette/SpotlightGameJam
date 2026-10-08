extends Node2D
## F6 测试入口，复用正式玩家逻辑；贴图使用占位资源。
@onready var _player: CharacterBody2D = $Level2PlayerWithCamera/Player
@onready var _map: Node2D = $Level2Map

func _ready() -> void:
	_player.global_position = $Level2Map/Rooms/EntryCollapse/Spawn.global_position
	_player.SetRespawnPosition(_player.global_position)
	_player.get_node("debug").hide()
	_player.get_node("hp").hide()
	_player.rope_controller.process_mode = Node.PROCESS_MODE_DISABLED
	_player.enable_double_jump = true
	_player.ResetDoubleJump()
