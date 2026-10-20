extends Node2D
class_name OasisBattlefieldChaser

## 第三关追逐威胁实体，封装定向移动组件及追逐体表现。

@export_category("Oasis Battlefield Chaser")
## 玩家节点路径；留空时由内部组件自动查找 player 分组。
@export var target_path: NodePath
## 是否在Y轴平滑对齐玩家。
@export var follow_player_y: bool = true
## Y轴跟随插值平滑速度。
@export var y_follow_speed: float = 6.0

@onready var _movement_component: DirectionalChaseMover = $DirectionalChaseMover
@onready var _chase_backdrop: ColorRect = get_node_or_null("ChaseBackdrop")
@onready var _corruption_visual: CanvasGroup = $DirectionalChaseMover/CorruptionVisual
@onready var _body_fill: ColorRect = $DirectionalChaseMover/CorruptionVisual/ColorRect

var _target: Node2D = null
var _chase_finished: bool = false
var _initial_global_position: Vector2
var _chase_origin_x: float = 0.0

func _ready() -> void:
	_configure_body_blend()
	_configure_corruption_visual()
	_initial_global_position = global_position
	_chase_origin_x = global_position.x
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(_target):
		_movement_component.SetTarget(_target)
	_update_chase_backdrop()

func _configure_body_blend() -> void:
	if not is_instance_valid(_body_fill):
		return
	var horizontal_scale := maxf(absf(_body_fill.scale.x), 0.001)
	var overlap := maxf(ExportSettings.oasis_boss_body_overlap, 0.0)
	_body_fill.size.x += overlap / horizontal_scale
	var displayed_width := maxf(_body_fill.size.x * horizontal_scale, 1.0)
	var dissolve_material := _body_fill.material as ShaderMaterial
	if dissolve_material == null:
		return
	var dissolve_ratio := clampf(ExportSettings.oasis_boss_body_dissolve_width / displayed_width, 0.001, 1.0)
	dissolve_material.set_shader_parameter(&"edge_fade_ratio", dissolve_ratio)
	dissolve_material.set_shader_parameter(&"edge_breakup", ExportSettings.oasis_boss_body_dissolve_breakup)

func _configure_corruption_visual() -> void:
	var corruption_material := _corruption_visual.material as ShaderMaterial
	if corruption_material == null:
		return
	var strength := ExportSettings.oasis_boss_corruption_strength if ExportSettings.oasis_boss_corruption_enabled else 0.0
	corruption_material.set_shader_parameter(&"effect_strength", strength)
	corruption_material.set_shader_parameter(&"distortion_pixels", ExportSettings.oasis_boss_distortion_pixels)
	corruption_material.set_shader_parameter(&"flow_speed", ExportSettings.oasis_boss_flow_speed)
	corruption_material.set_shader_parameter(&"vein_strength", ExportSettings.oasis_boss_vein_strength)
	corruption_material.set_shader_parameter(&"tint_strength", ExportSettings.oasis_boss_tint_strength)
	corruption_material.set_shader_parameter(&"corruption_color", ExportSettings.oasis_boss_corruption_color)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player") as Node2D
		if is_instance_valid(_target):
			_movement_component.SetTarget(_target)
	if follow_player_y and is_instance_valid(_target) and _movement_component.IsActive():
		global_position.y = lerpf(global_position.y, _target.global_position.y, y_follow_speed * delta)
	_update_chase_backdrop()

func _update_chase_backdrop() -> void:
	if not is_instance_valid(_chase_backdrop):
		return
	if not visible or not _movement_component.IsActive():
		_chase_backdrop.visible = false
		return
	_chase_backdrop.visible = true
	var current_lead_x := _movement_component.global_position.x
	var left_bound := minf(_chase_origin_x - 3000.0, current_lead_x - 3000.0)
	var width := maxf(100.0, (current_lead_x - left_bound) + 200.0)
	_chase_backdrop.global_position = Vector2(left_bound, -5000.0)
	_chase_backdrop.size = Vector2(width, 10000.0)

## 启动或继续第三关追逐实体。
func StartChase() -> void:
	if _chase_finished:
		return
	# 每次复苏都从场景中记录的出生位置重新开始，不能沿用上一次追逐留下的位置。
	global_position = _initial_global_position
	_movement_component.ResetMover()
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
	if is_instance_valid(_chase_backdrop):
		_chase_backdrop.visible = false

## 导出追逐实体的移动状态。
## 返回值为内部定向移动组件生成的存档字典。
func ExportSaveData() -> Dictionary:
	return _movement_component.ExportSaveData()

## 从存档恢复追逐实体的移动状态。
## @param data 由 ExportSaveData() 生成的字典。
func LoadSaveData(data: Dictionary) -> void:
	_movement_component.LoadSaveData(data)
