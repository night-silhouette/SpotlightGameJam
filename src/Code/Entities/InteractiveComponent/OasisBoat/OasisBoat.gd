class_name OasisBoat
extends Path2D

## 当舟到达某个停靠点时触发。
signal ArrivedAtStopPoint(point_id: String, index: int)
## 当舟从停靠点出发起航时触发。
signal DepartedFromStopPoint(point_id: String, index: int)
## 玩家登船时触发。
signal PlayerBoarded()
## 玩家离开船时触发。
signal PlayerUnboarded()
## 抵达整条航线终点时触发。
signal ReachedDestination()

enum BoatState {
	INITIAL_DRIFTING, # 初始从水流处漂向第一站（岸边）
	WAITING,          # 停靠在某个点等待放行条件（玩家上船/解密完成/等待时间）
	SAILING,          # 航行中
	ARRIVED_FINAL     # 已到达终点
}

@export_category("Boat Motion")
## 航行移动速度（像素/秒）。
@export var speed: float = 85.0
## 舟加速到目标速度的速率（像素/秒²）。
@export var acceleration: float = 120.0
## 舟减速到目标速度的速率（像素/秒²）。
@export var deceleration: float = 180.0
## 是否在关卡就绪时自动开始入场漂流到第 0 个停靠点。
@export var auto_start_initial_drift: bool = true
## 随波逐流垂直颠簸振幅（像素）。
@export var bob_amplitude: float = 0.0
## 随波逐流垂直颠簸频率（Hz）。
@export var bob_frequency: float = 2.0

@export_category("Stop Points")
## 沿途配置的停靠点序列（建议按 progress_ratio 从小到大排序）。
@export var stop_points: Array[OasisBoatStopPoint] = []
## 是否使用 ExportSettings 中第三关的七站航线配置。
@export var use_battlefield_stop_points: bool = false

@export_category("Visual & Collision")
## 船体甲板尺寸。
@export var boat_size: Vector2 = Vector2(120, 24)
## 前方检测人物距离（像素），在此范围内检测到人物时暂停前进，防止挤压。
@export var obstacle_detection_distance: float = 64.0
## 前方检测射线纵向偏移/高度范围半高。
@export var obstacle_detection_height: float = 20.0

@onready var path_follow: PathFollow2D = $PathFollow2D
@onready var animatable_body: AnimatableBody2D = $PathFollow2D/AnimatableBody2D
@onready var boarding_detector: Area2D = $PathFollow2D/AnimatableBody2D/BoardingDetector

var current_state: BoatState = BoatState.WAITING
var current_stop_index: int = -1
var is_player_on_board: bool = false
var _elapsed_time: float = 0.0
var _stop_wait_timer: float = 0.0
var _body_transform_offset: Transform2D
var _last_body_target_position: Vector2
var _body_sync_initialized: bool = false
var _current_speed: float = 0.0

const BATTLEFIELD_FIRST_TRANSIT_RATIO: float = 0.33399
const BATTLEFIELD_SECOND_TRANSIT_RATIO: float = 0.63845


func _ready() -> void:
	# 船先于角色执行物理更新，确保角色本帧就能取得最新的平台速度。
	process_physics_priority = -100
	path_follow.rotates = false
	path_follow.loop = false
	# PathFollow2D 只负责路线采样；物理船体改为顶层节点并显式同步全局变换。
	# 这样 AnimatableBody2D 能正确向 CharacterBody2D 提供平台速度。
	_body_transform_offset = path_follow.global_transform.affine_inverse() * animatable_body.global_transform
	animatable_body.top_level = true
	_sync_physics_body(0.0)
	if use_battlefield_stop_points:
		stop_points.clear()
		for index in range(ExportSettings.oasis_boat_stop_ratios.size()):
			if index == 2:
				stop_points.append(_create_battlefield_transit_point(
					BATTLEFIELD_FIRST_TRANSIT_RATIO,
					"transit_-3512"
				))
			if index == 3:
				stop_points.append(_create_battlefield_transit_point(
					BATTLEFIELD_SECOND_TRANSIT_RATIO,
					"transit_-6679"
				))
			var point := OasisBoatStopPoint.new()
			point.progress_ratio = ExportSettings.oasis_boat_stop_ratios[index]
			point.point_id = "stop_%d" % index
			point.require_player_on_board = index != ExportSettings.oasis_boat_blocker_stop_index
			point.follow_player = index != 2 and index != 3
			# 第一个停靠点只允许由关卡中的 get_boat 区域放行，避免船体自身检测提前启航。
			if index == 0:
				point.point_id = "get_boat"
				point.require_puzzle_solved = true
			if index == ExportSettings.oasis_boat_blocker_stop_index:
				point.point_id = "vanishing_blocker"
				point.require_puzzle_solved = true
			stop_points.append(point)
	
	boarding_detector.body_entered.connect(_on_boarding_detector_body_entered)
	boarding_detector.body_exited.connect(_on_boarding_detector_body_exited)
	
	if stop_points.is_empty():
		# 默认生成起点停靠点
		var default_start := OasisBoatStopPoint.new()
		default_start.point_id = "start_bank"
		default_start.progress_ratio = 0.0
		default_start.require_player_on_board = true
		stop_points.append(default_start)

	if auto_start_initial_drift:
		current_state = BoatState.INITIAL_DRIFTING
		current_stop_index = 0
		path_follow.progress_ratio = 0.0
	else:
		current_state = BoatState.WAITING
		current_stop_index = 0
		_prepare_stop_point(0)


func _physics_process(delta: float) -> void:
	match current_state:
		BoatState.INITIAL_DRIFTING:
			_process_drifting(delta)
		BoatState.WAITING:
			_process_waiting(delta)
		BoatState.SAILING:
			_process_sailing(delta)
		BoatState.ARRIVED_FINAL:
			pass

	_sync_physics_body(delta)


## 将承载角色的物理船体同步到路线采样点，并显式报告本帧平台速度。
func _sync_physics_body(delta: float) -> void:
	var target_transform := path_follow.global_transform * _body_transform_offset
	if _body_sync_initialized and delta > 0.0:
		animatable_body.constant_linear_velocity = (target_transform.origin - _last_body_target_position) / delta
	else:
		animatable_body.constant_linear_velocity = Vector2.ZERO
		_body_sync_initialized = true
	_last_body_target_position = target_transform.origin
	animatable_body.global_transform = target_transform


## 外部通知：解密已完成或某个机关已激活。
func SolvePuzzle(point_id: String = "") -> void:
	var solved_matching_point: bool = false
	for pt in stop_points:
		if point_id == "" or pt.point_id == point_id:
			pt.is_puzzle_solved = true
			solved_matching_point = true
	if not solved_matching_point:
		push_warning("OasisBoat could not find stop point for puzzle id: %s" % point_id)
		return
	# 如果当前正卡在等待状态，检查是否可立即启航
	if current_state == BoatState.WAITING:
		_check_depart_condition()


## 外部通知：强制起航，驶向下一停靠点。
func ResumeJourney() -> void:
	if current_state == BoatState.WAITING:
		_depart_to_next()


## 外部通知：重置到航线初始状态。
func ResetBoat() -> void:
	path_follow.progress_ratio = 0.0
	_body_sync_initialized = false
	_sync_physics_body(0.0)
	current_stop_index = 0
	current_state = BoatState.WAITING
	for pt in stop_points:
		pt.is_puzzle_solved = false
	_current_speed = 0.0


## 检查玩家当前是否在船上。
func IsPlayerOnBoard() -> bool:
	return is_player_on_board


func _process_drifting(delta: float) -> void:
	var target_ratio: float = 0.0
	if not stop_points.is_empty():
		target_ratio = stop_points[0].progress_ratio
	
	if path_follow.progress_ratio >= target_ratio:
		path_follow.progress_ratio = target_ratio
		current_stop_index = 0
		_prepare_stop_point(0)
	else:
		path_follow.progress += (speed * 0.6) * delta
		if path_follow.progress_ratio >= target_ratio:
			path_follow.progress_ratio = target_ratio
			current_stop_index = 0
			_prepare_stop_point(0)


func _process_waiting(delta: float) -> void:
	if _stop_wait_timer > 0.0:
		_stop_wait_timer -= delta
	_check_depart_condition()


func _check_depart_condition() -> void:
	if current_stop_index < 0 or current_stop_index >= stop_points.size():
		return
	var pt: OasisBoatStopPoint = stop_points[current_stop_index]
	
	# 检查等待时间
	if _stop_wait_timer > 0.0:
		return
	
	# 检查解密条件
	if pt.require_puzzle_solved and not pt.is_puzzle_solved:
		return
		
	# 检查登船条件
	if pt.require_player_on_board and not is_player_on_board:
		return
		
	# 前方有玩家阻挡时暂不起航，避免挤压
	if _is_player_ahead():
		return

	_depart_to_next()


func _depart_to_next() -> void:
	if path_follow.progress_ratio >= 1.0:
		return
	var point_id: String = ""
	if current_stop_index >= 0 and current_stop_index < stop_points.size():
		point_id = stop_points[current_stop_index].point_id
	DepartedFromStopPoint.emit(point_id, current_stop_index)
	current_state = BoatState.SAILING


func _process_sailing(delta: float) -> void:
	var next_point: OasisBoatStopPoint = _get_next_stop_point()
	var target_speed: float = speed

	# 前方检测到人物阻挡时将期望速度降为零，惯性减速避免把人物挤入墙体或物块。
	if _is_player_ahead():
		target_speed = 0.0
	elif next_point != null and next_point.follow_player and not is_player_on_board:
		var player: Node2D = get_tree().get_first_node_in_group(&"player") as Node2D
		if player != null:
			target_speed = _get_follow_target_speed(player, next_point.max_lead_distance)

	var accel: float = acceleration if target_speed > _current_speed else deceleration
	_current_speed = move_toward(_current_speed, target_speed, maxf(accel, 0.0) * delta)
	path_follow.progress += _current_speed * delta
	
	# 检查是否到达下一个停靠点
	var next_index: int = current_stop_index + 1
	while next_index < stop_points.size():
		next_point = stop_points[next_index]
		if path_follow.progress_ratio >= next_point.progress_ratio:
			current_stop_index = next_index
			if next_point.is_transit_point:
				next_index += 1
				continue
			path_follow.progress_ratio = next_point.progress_ratio
			_prepare_stop_point(current_stop_index)
			return
		break

	# 检查是否到达航线终点
	if path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		_current_speed = 0.0
		current_state = BoatState.ARRIVED_FINAL
		ReachedDestination.emit()


func _prepare_stop_point(index: int) -> void:
	current_state = BoatState.WAITING
	_current_speed = 0.0
	var pt: OasisBoatStopPoint = stop_points[index]
	_stop_wait_timer = pt.wait_time
	ArrivedAtStopPoint.emit(pt.point_id, index)
	if pt.progress_ratio >= 1.0:
		current_state = BoatState.ARRIVED_FINAL
		ReachedDestination.emit()


func _on_boarding_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player") or body.name == "Player":
		is_player_on_board = true
		PlayerBoarded.emit()
		if current_state == BoatState.WAITING:
			_check_depart_condition()


func _on_boarding_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player") or body.name == "Player":
		is_player_on_board = false
		PlayerUnboarded.emit()


func _create_battlefield_transit_point(ratio: float, point_id: String) -> OasisBoatStopPoint:
	var point := OasisBoatStopPoint.new()
	point.progress_ratio = ratio
	point.point_id = point_id
	point.require_player_on_board = false
	point.follow_player = true
	point.is_transit_point = true
	return point


func _get_next_stop_point() -> OasisBoatStopPoint:
	var next_index: int = current_stop_index + 1
	if next_index < 0 or next_index >= stop_points.size():
		return null
	return stop_points[next_index]


func _get_follow_target_speed(player: Node2D, max_lead_distance: float) -> float:
	if max_lead_distance <= 0.0:
		return 0.0

	var forward_dir: Vector2 = _get_path_forward_direction()
	if forward_dir == Vector2.ZERO:
		return speed

	var lead_distance: float = (animatable_body.global_position - player.global_position).dot(forward_dir)
	var slowdown_start: float = max_lead_distance * 0.6
	if lead_distance <= slowdown_start:
		return speed
	if lead_distance >= max_lead_distance:
		return 0.0

	return speed * inverse_lerp(max_lead_distance, slowdown_start, lead_distance)


func _get_path_forward_direction() -> Vector2:
	if curve == null or curve.point_count < 2:
		return Vector2.ZERO

	var current_prog: float = path_follow.progress
	var p_current: Vector2 = curve.sample_baked(current_prog)
	var sample_distance: float = minf(5.0, curve.get_baked_length())
	var p_next: Vector2 = curve.sample_baked(current_prog + sample_distance)
	var local_forward: Vector2 = p_next - p_current
	if local_forward.is_zero_approx():
		var p_previous: Vector2 = curve.sample_baked(maxf(current_prog - sample_distance, 0.0))
		local_forward = p_current - p_previous
	if local_forward.is_zero_approx():
		return Vector2.ZERO

	var global_current: Vector2 = global_transform * p_current
	var global_forward_point: Vector2 = global_transform * (p_current + local_forward)
	return (global_forward_point - global_current).normalized()


## 检测航向前方一段距离内是否存在玩家
func _is_player_ahead() -> bool:
	if curve == null or curve.point_count < 2 or obstacle_detection_distance <= 0.0:
		return false

	var forward_dir: Vector2 = _get_path_forward_direction()
	if forward_dir == Vector2.ZERO:
		return false

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var origin_center: Vector2 = animatable_body.global_position
	# 船体半宽沿切线延伸，从船体前缘向前探测
	var half_width: float = maxf(boat_size.x, 0.0) * 0.5
	var ray_start_base: Vector2 = origin_center + forward_dir * half_width
	var ray_target_base: Vector2 = ray_start_base + forward_dir * obstacle_detection_distance

	# 多条水平射线覆盖船头高度范围（避免低身/起跳擦空）
	var perp_dir: Vector2 = Vector2(-forward_dir.y, forward_dir.x)
	var detection_height: float = maxf(obstacle_detection_height, 0.0)
	var height_offsets: Array[float] = [-detection_height, 0.0, detection_height]
	var excluded_rids: Array[RID] = [animatable_body.get_rid()]

	for height_offset in height_offsets:
		var offset_vec: Vector2 = perp_dir * height_offset
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			ray_start_base + offset_vec,
			ray_target_base + offset_vec,
			2,
			excluded_rids
		)
		query.collide_with_areas = false
		query.collide_with_bodies = true

		var result: Dictionary = space_state.intersect_ray(query)
		if not result.is_empty():
			var collider: Node = result.get("collider") as Node
			if collider != null and (collider.is_in_group(&"player") or collider.name == &"Player"):
				return true

	return false
