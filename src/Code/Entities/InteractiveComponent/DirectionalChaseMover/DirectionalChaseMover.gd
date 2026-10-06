extends AnimatableBody2D
class_name DirectionalChaseMover

## 按固定方向分阶段加速，并在追逐时与玩家维持可调距离的通用移动组件。

@export_category("Directional Chase Mover")
## 移动方向；运行时会自动归一化，零向量会回退为向右。
@export var movement_direction: Vector2 = Vector2.RIGHT
## 追逐目标；留空时自动查找 player 分组中的玩家。
@export var target_path: NodePath
## 进入场景后是否立即开始移动。
@export var start_active: bool = true
## 是否启用与目标的距离调节。
@export var keep_target_distance: bool = true

var _target: Node2D = null
var _active: bool = false
var _elapsed_time: float = 0.0
var _current_stage: int = -1
var _current_speed: float = 0.0

func _ready() -> void:
	movement_direction = movement_direction.normalized() if not movement_direction.is_zero_approx() else Vector2.RIGHT
	_target = get_node_or_null(target_path) as Node2D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node2D
	_active = start_active
	_set_stage(0)
	$KillArea.body_entered.connect(_on_kill_area_body_entered)

func _physics_process(delta: float) -> void:
	if not _active:
		return
	_elapsed_time += delta
	var stage := _get_stage_for_time(_elapsed_time)
	if stage != _current_stage:
		_set_stage(stage)
	var target_speed := _get_stage_speed(stage)
	if keep_target_distance and is_instance_valid(_target):
		target_speed = _apply_distance_control(target_speed)
	_current_speed = move_toward(_current_speed, target_speed, ExportSettings.chase_mover_acceleration * delta)
	global_position += movement_direction * _current_speed * delta

func _get_stage_for_time(elapsed: float) -> int:
	if elapsed < ExportSettings.chase_mover_stage_1_duration:
		return 0
	if elapsed < ExportSettings.chase_mover_stage_1_duration + ExportSettings.chase_mover_stage_2_duration:
		return 1
	return 2

func _get_stage_speed(stage: int) -> float:
	match stage:
		0:
			return ExportSettings.chase_mover_stage_1_speed
		1:
			return ExportSettings.chase_mover_stage_2_speed
		_:
			return ExportSettings.chase_mover_stage_3_speed

func _apply_distance_control(base_speed: float) -> float:
	var forward_gap := (_target.global_position - global_position).dot(movement_direction)
	var near_distance := ExportSettings.chase_mover_follow_distance
	var far_distance := maxf(ExportSettings.chase_mover_max_follow_distance, near_distance + 1.0)
	var speed_multiplier := 1.0
	if forward_gap <= near_distance:
		var near_ratio := clampf(forward_gap / maxf(near_distance, 1.0), 0.0, 1.0)
		speed_multiplier = lerpf(ExportSettings.chase_mover_near_speed_multiplier, 1.0, smoothstep(0.0, 1.0, near_ratio))
	else:
		var far_ratio := clampf(inverse_lerp(near_distance, far_distance, forward_gap), 0.0, 1.0)
		speed_multiplier = lerpf(1.0, ExportSettings.chase_mover_far_speed_multiplier, smoothstep(0.0, 1.0, far_ratio))
	return base_speed * speed_multiplier

func _on_kill_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		SignalBus.PlayerInstantDeathRequested.emit(body, self)

func _set_stage(stage: int) -> void:
	_current_stage = stage
	SignalBus.ChaseMoverStageChanged.emit(self, stage + 1, _get_stage_speed(stage))

## 开始或继续追逐，不会清空已经经过的阶段时间。
func StartChase() -> void:
	_active = true
	SignalBus.ChaseMoverActiveChanged.emit(self, true)

## 暂停追逐并保留当前阶段和速度。
func StopChase() -> void:
	_active = false
	SignalBus.ChaseMoverActiveChanged.emit(self, false)

## 设置距离调节所跟随的目标。
## @param target 新目标节点；传 null 时仅按阶段速度移动。
func SetTarget(target: Node2D) -> void:
	_target = target

## 导出移动组件当前状态。
## 返回值包含位置、运行时间、阶段、速度与启停状态。
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"elapsed_time": _elapsed_time,
		"stage": _current_stage,
		"speed": _current_speed,
		"active": _active,
	}

## 从存档恢复移动组件状态。
## @param data 由 ExportSaveData() 生成的字典；缺失字段沿用当前值。
func LoadSaveData(data: Dictionary) -> void:
	global_position = Vector2(float(data.get("position_x", global_position.x)), float(data.get("position_y", global_position.y)))
	_elapsed_time = maxf(float(data.get("elapsed_time", _elapsed_time)), 0.0)
	_current_speed = maxf(float(data.get("speed", _current_speed)), 0.0)
	_active = bool(data.get("active", _active))
	_set_stage(clampi(int(data.get("stage", _get_stage_for_time(_elapsed_time))), 0, 2))
