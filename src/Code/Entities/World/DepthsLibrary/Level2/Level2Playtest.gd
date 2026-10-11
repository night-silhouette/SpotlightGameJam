extends Node2D
## F6 测试入口，复用正式玩家逻辑；贴图使用占位资源。
@onready var _player: CharacterBody2D = $Level2PlayerWithCamera/Player
@onready var _map: Node2D = $Level2Map

func _ready() -> void:
	# The city preview shares map-local coordinates, even after moving the map.
	$CityInterfacePreview.global_transform = _map.global_transform
	# 正式玩家初始化会隐藏占位图；测试入口在其初始化后恢复灰盒外观。
	_player.get_node("sprite").hide()
	_player.get_node("VisualPlaceholder").show()
	_player.global_position = $CityInterfacePreview/Spawn.global_position
	_player.SetRespawnPosition(_player.global_position)
	_player.get_node("debug").hide()
	_player.get_node("hp").hide()
