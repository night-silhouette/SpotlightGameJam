extends Node2D
class_name OasisBattlefieldChaser

## 第三关追逐威胁实体，封装定向移动组件及追逐体表现。

@export_category("Oasis Battlefield Chaser")
## 玩家节点路径；留空时由内部组件自动查找 player 分组。
@export var target_path: NodePath

@onready var _movement_component: DirectionalChaseMover = $DirectionalChaseMover

func _ready() -> void:
	if not target_path.is_empty():
		_movement_component.SetTarget(get_node_or_null(target_path) as Node2D)

## 启动或继续第三关追逐实体。
func StartChase() -> void:
	_movement_component.StartChase()

## 暂停第三关追逐实体并保留当前阶段。
func StopChase() -> void:
	_movement_component.StopChase()

## 导出追逐实体的移动状态。
## 返回值为内部定向移动组件生成的存档字典。
func ExportSaveData() -> Dictionary:
	return _movement_component.ExportSaveData()

## 从存档恢复追逐实体的移动状态。
## @param data 由 ExportSaveData() 生成的字典。
func LoadSaveData(data: Dictionary) -> void:
	_movement_component.LoadSaveData(data)
