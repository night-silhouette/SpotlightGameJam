extends Node2D
## 两个多边形区域互斥遮罩：进入一个区域时遮住另一个区域，只影响绘制，不改变碰撞。

const Settings = preload("res://Code/Entities/World/视觉装饰组件/ShaftOcclusion/ExportSettings.gd")

@export var settings: Settings

var player: Node2D

@onready var _region_a: Polygon2D = $RegionA
@onready var _region_b: Polygon2D = $RegionB
@onready var _mask: Control = $Overlay/Mask

func _ready() -> void:
	_region_a.hide()
	_region_b.hide()

func _process(_delta: float) -> void:
	if settings == null or not settings.enabled:
		_mask.hide()
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group(&"player") as Node2D
	_mask.visible = is_instance_valid(player)
	_mask.queue_redraw()
