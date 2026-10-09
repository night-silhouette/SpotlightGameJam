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
## 是否在关卡就绪时自动开始入场漂流到第 0 个停靠点。
@export var auto_start_initial_drift: bool = true
## 随波逐流垂直颠簸振幅（像素）。
@export var bob_amplitude: float = 3.5
## 随波逐流垂直颠簸频率（Hz）。
@export var bob_frequency: float = 2.0

@export_category("Stop Points")
## 沿途配置的停靠点序列（建议按 progress_ratio 从小到大排序）。
@export var stop_points: Array[OasisBoatStopPoint] = []

@export_category("Visual & Collision")
## 船体甲板尺寸。
@export var boat_size: Vector2 = Vector2(120, 24)

@onready var path_follow: PathFollow2D = $PathFollow2D
@onready var animatable_body: AnimatableBody2D = $PathFollow2D/AnimatableBody2D
@onready var visual_root: Node2D = $PathFollow2D/AnimatableBody2D/VisualRoot
@onready var boarding_detector: Area2D = $PathFollow2D/AnimatableBody2D/BoardingDetector

var current_state: BoatState = BoatState.WAITING
var current_stop_index: int = -1
var is_player_on_board: bool = false
var _elapsed_time: float = 0.0
var _stop_wait_timer: float = 0.0


func _ready() -> void:
	path_follow.rotates = false
	path_follow.loop = false
	
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
	_elapsed_time += delta
	_update_bobbing_effect()

	match current_state:
		BoatState.INITIAL_DRIFTING:
			_process_drifting(delta)
		BoatState.WAITING:
			_process_waiting(delta)
		BoatState.SAILING:
			_process_sailing(delta)
		BoatState.ARRIVED_FINAL:
			pass


## 外部通知：解密已完成或某个机关已激活。
func SolvePuzzle(point_id: String = "") -> void:
	for pt in stop_points:
		if point_id == "" or pt.point_id == point_id:
			pt.is_puzzle_solved = true
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
	current_stop_index = 0
	current_state = BoatState.WAITING
	for pt in stop_points:
		pt.is_puzzle_solved = false


## 检查玩家当前是否在船上。
func IsPlayerOnBoard() -> bool:
	return is_player_on_board


func _update_bobbing_effect() -> void:
	if is_instance_valid(visual_root):
		var offset_y: float = sin(_elapsed_time * bob_frequency * TAU) * bob_amplitude
		visual_root.position.y = offset_y


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
		
	_depart_to_next()


func _depart_to_next() -> void:
	var point_id: String = ""
	if current_stop_index >= 0 and current_stop_index < stop_points.size():
		point_id = stop_points[current_stop_index].point_id
	DepartedFromStopPoint.emit(point_id, current_stop_index)
	current_state = BoatState.SAILING


func _process_sailing(delta: float) -> void:
	path_follow.progress += speed * delta
	
	# 检查是否到达下一个停靠点
	var next_index: int = current_stop_index + 1
	if next_index < stop_points.size():
		var next_point: OasisBoatStopPoint = stop_points[next_index]
		if path_follow.progress_ratio >= next_point.progress_ratio:
			path_follow.progress_ratio = next_point.progress_ratio
			current_stop_index = next_index
			_prepare_stop_point(current_stop_index)
			return

	# 检查是否到达航线终点
	if path_follow.progress_ratio >= 1.0:
		path_follow.progress_ratio = 1.0
		current_state = BoatState.ARRIVED_FINAL
		ReachedDestination.emit()


func _prepare_stop_point(index: int) -> void:
	current_state = BoatState.WAITING
	var pt: OasisBoatStopPoint = stop_points[index]
	_stop_wait_timer = pt.wait_time
	ArrivedAtStopPoint.emit(pt.point_id, index)


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
