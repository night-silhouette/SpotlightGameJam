extends Node2D
class_name OasisBattlefieldChaser

## 第三关追逐威胁实体，封装定向移动组件及追逐体表现。

@export_category("Oasis Battlefield Chaser")
## 玩家节点路径；留空时由内部组件自动查找 player 分组。
@export var target_path: NodePath

@onready var _movement_component: DirectionalChaseMover = $DirectionalChaseMover

var _chase_finished: bool = false
var _initial_global_position: Vector2

func _ready() -> void:
	_initial_global_position = global_position
	if not target_path.is_empty():
		_movement_component.SetTarget(get_node_or_null(target_path) as Node2D)

## 启动或继续第三关追逐实体。
func StartChase() -> void:
	if _chase_finished:
		return
	visible = true
	_movement_component.visible = true
	_movement_component.StartChase()

## 重置第三关追逐实体到初始出生点，清空追逐进度并保持停止，等待再次触发。
func ResetChase() -> void:
	_chase_finished = false
	global_position = _initial_global_position
	# 确保在未重新触发追逐前，实体保持隐藏，彻底避免复活时在屏幕上闪现残影
	visible = false
	_movement_component.visible = false
	_movement_component.ResetMover()

## 暂停第三关追逐实体并保留当前阶段。
func StopChase() -> void:
	_movement_component.StopChase()

## 永久结束本次追逐：停止移动并关闭实体碰撞、致死区域和显示。
func EndChase() -> void:
	if _chase_finished:
		return
	_chase_finished = true
	_movement_component.StopChase()
	_movement_component.collision_layer = 0
	_movement_component.collision_mask = 0
	var kill_area := _movement_component.get_node_or_null("KillArea") as Area2D
	if is_instance_valid(kill_area):
		kill_area.set_deferred("monitoring", false)
		kill_area.set_deferred("monitorable", false)
	_movement_component.visible = false
	_movement_component.process_mode = Node.PROCESS_MODE_DISABLED

## 导出追逐实体的移动状态。
## 返回值为内部定向移动组件生成的存档字典。
func ExportSaveData() -> Dictionary:
	return _movement_component.ExportSaveData()

## 从存档恢复追逐实体的移动状态。
## @param data 由 ExportSaveData() 生成的字典。
func LoadSaveData(data: Dictionary) -> void:
	_movement_component.LoadSaveData(data)
