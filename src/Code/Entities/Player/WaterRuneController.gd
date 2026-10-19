extends Node2D
class_name WaterRuneController

## 玩家水符文控制组件：按 interact 映射切换鼠标指向的流水区域状态，无技能冷却。

const cooldown: float = 0.0
var current_cd: float = 0.0

func _ready() -> void:
	if SignalBus:
		SignalBus.WaterRuneCooldownChanged.emit(current_cd, cooldown)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var mouse_world_position = get_global_mouse_position()
		for node in get_tree().get_nodes_in_group("water_flow"):
			if node is WaterFlowArea and node.ContainsWorldPoint(mouse_world_position):
				if TryActivateTargetArea(node):
					get_viewport().set_input_as_handled()
				return

## 重置水符文冷却时间。
func ResetCooldown() -> void:
	current_cd = 0.0
	if SignalBus:
		SignalBus.WaterRuneCooldownChanged.emit(0.0, cooldown)

## 尝试切换指定流水区域；target_area 为鼠标点中的区域，返回是否成功激活。
func TryActivateTargetArea(target_area: WaterFlowArea) -> bool:
	if get_parent().get("offering_locked") == true or not is_instance_valid(target_area):
		return false

	target_area.ToggleRuneFluid()
	if SignalBus:
		SignalBus.WaterRuneActivated.emit(target_area, target_area.is_fluid)
	return true
