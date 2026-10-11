extends Node2D
class_name WaterRuneController

## 玩家水符文控制组件：右键点击画面内的流水区域切换状态，保留技能冷却。

@export var cooldown: float = 2.0
var current_cd: float = 0.0

func _ready() -> void:
	if ExportSettings:
		cooldown = ExportSettings.water_rune_cooldown
	if SignalBus:
		SignalBus.WaterRuneCooldownChanged.emit(current_cd, cooldown)

func _process(delta: float) -> void:
	if current_cd > 0.0:
		current_cd = max(0.0, current_cd - delta)
		if SignalBus:
			SignalBus.WaterRuneCooldownChanged.emit(current_cd, cooldown)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
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
	if current_cd > 0.0 or not is_instance_valid(target_area):
		return false

	target_area.ToggleRuneFluid()
	current_cd = cooldown
	if SignalBus:
		SignalBus.WaterRuneCooldownChanged.emit(current_cd, cooldown)
		SignalBus.WaterRuneActivated.emit(target_area, target_area.is_fluid)
	return true
