extends Node2D
## 独立双向井遮罩：按人物原点是否位于井内切换，只影响绘制，不改变碰撞。

const Settings = preload("res://Code/Entities/World/视觉装饰组件/ShaftOcclusion/ExportSettings.gd")

@export var settings: Settings
## 可选；留空时按配置中的人物分组查找。
@export var player: Node2D

@onready var _mask: Control = $Overlay/Mask

func _process(_delta: float) -> void:
	if settings == null or not settings.enabled:
		_mask.hide()
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(settings.player_group) as Node2D
	_mask.visible = is_instance_valid(player)
	_mask.queue_redraw()
