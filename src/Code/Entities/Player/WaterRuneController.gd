extends Node2D
class_name WaterRuneController

## =============================================================================
## WaterRuneController.gd - 玩家水符文控制组件
## 统一管理水符文技能冷却 (CD) 与多流水区域冲突时的组合键判定。
## 快捷键说明：
## - 单一流水区域在交互范围内：按 E 即可激活/凝固。
## - 多个流水区域在交互范围内（产生冲突）：
##   使用组合键：[方向键 + E]（例如 S+E 激活下方，A+E 激活左侧，D+E 激活右侧，W+E 激活上方）。
##   若同一方向存在多个流水区域，则优先解锁该方向上离玩家最近的那一个。
## =============================================================================

@export var cooldown: float = 2.0
var current_cd: float = 0.0

@onready var player: CharacterBody2D = get_parent() as CharacterBody2D

func _ready() -> void:
	_sync_from_export_settings()
	if SignalBus:
		SignalBus.WaterRuneCooldownChanged.emit(current_cd, cooldown)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		cooldown = ExportSettings.water_rune_cooldown

func _process(delta: float) -> void:
	if current_cd > 0.0:
		current_cd = max(0.0, current_cd - delta)
		if SignalBus:
			SignalBus.WaterRuneCooldownChanged.emit(current_cd, cooldown)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("water_rune"):
		if TryActivateWaterRune():
			get_viewport().set_input_as_handled()

## 重置水符文冷却时间
func ResetCooldown() -> void:
	current_cd = 0.0
	if SignalBus:
		SignalBus.WaterRuneCooldownChanged.emit(0.0, cooldown)

## 尝试使用水符文
## @return 是否成功激活/切换了流水区域
func TryActivateWaterRune() -> bool:
	if current_cd > 0.0:
		return false

	var nearby_areas = GetNearbyWaterAreas()
	if nearby_areas.is_empty():
		return false

	var target_area: WaterFlowArea = null

	if nearby_areas.size() == 1:
		# 只有一个流水区域，直接激活
		target_area = nearby_areas[0]
	else:
		# 存在多个流水区域冲突，读取玩家当前按住的方向输入
		var input_dir = _get_input_direction()
		target_area = _resolve_conflicting_target(nearby_areas, input_dir)

	if target_area:
		target_area.ToggleRuneFluid()
		current_cd = cooldown
		if SignalBus:
			SignalBus.WaterRuneCooldownChanged.emit(current_cd, cooldown)
			SignalBus.WaterRuneActivated.emit(target_area, target_area.is_fluid)
		return true

	return false

## 获取当前玩家可交互范围内的所有流水区域
## @return 交互范围内的 WaterFlowArea 列表 (按距离由近到远排序)
func GetNearbyWaterAreas() -> Array[WaterFlowArea]:
	var results: Array[WaterFlowArea] = []
	if not is_instance_valid(player):
		return results

	var areas = get_tree().get_nodes_in_group("water_flow")
	var p_pos = player.global_position

	for node in areas:
		if node is WaterFlowArea and is_instance_valid(node):
			var dist = p_pos.distance_to(node.global_position)
			if dist <= node.interact_radius:
				results.append(node)

	# 按距玩家由近到远排序
	results.sort_custom(func(a: WaterFlowArea, b: WaterFlowArea):
		return p_pos.distance_to(a.global_position) < p_pos.distance_to(b.global_position)
	)
	return results

## 获取当前输入的离散 4 向方向 (Vector2.LEFT, RIGHT, UP, DOWN 或 ZERO)
func _get_input_direction() -> Vector2:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("down"):
		dir.y += 1.0
	if Input.is_action_pressed("up"):
		dir.y -= 1.0
	if Input.is_action_pressed("move_r"):
		dir.x += 1.0
	if Input.is_action_pressed("move_l"):
		dir.x -= 1.0

	if dir == Vector2.ZERO:
		return Vector2.ZERO

	# 转换为主要的主轴离散方向 (W/S/A/D)
	if abs(dir.x) >= abs(dir.y):
		return Vector2.RIGHT if dir.x > 0 else Vector2.LEFT
	else:
		return Vector2.DOWN if dir.y > 0 else Vector2.UP

## 解决多个区域冲突时的目标匹配：
## 若指定了输入方向，优先筛选出处于该方向象限的区域，并取其中最靠近玩家的那个；
## 若无方向输入，则默认选择最靠近玩家的那个。
func _resolve_conflicting_target(nearby_areas: Array[WaterFlowArea], input_dir: Vector2) -> WaterFlowArea:
	var p_pos = player.global_position

	if input_dir != Vector2.ZERO:
		var matched_areas: Array[WaterFlowArea] = []
		for area in nearby_areas:
			var to_area = area.global_position - p_pos
			var dominant_dir = Vector2.ZERO
			if abs(to_area.x) >= abs(to_area.y):
				dominant_dir = Vector2.RIGHT if to_area.x > 0 else Vector2.LEFT
			else:
				dominant_dir = Vector2.DOWN if to_area.y > 0 else Vector2.UP

			if dominant_dir == input_dir:
				matched_areas.append(area)

		if not matched_areas.is_empty():
			# matched_areas 已经按距离排好序，直接取最靠近的
			return matched_areas[0]

	# 如果玩家没有按方向键，或输入方向无匹配，则取最靠近的那个
	return nearby_areas[0]
