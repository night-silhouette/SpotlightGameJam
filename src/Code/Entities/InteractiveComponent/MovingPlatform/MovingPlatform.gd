extends AnimatableBody2D
class_name MovingPlatform

## 沿本地路径在起点与终点之间往返移动的平台。
## AnimatableBody2D 会把物理速度传递给站在平台上的 CharacterBody2D。

@export_category("Moving Platform Settings")
## 平台碰撞与占位视觉尺寸。
@export var platform_size: Vector2 = Vector2(112.0, 20.0):
	set(value):
		platform_size = Vector2(maxf(value.x, 8.0), maxf(value.y, 8.0))
		_update_dimensions()

## 终点相对平台初始位置的本地偏移；可设置为横向、纵向或斜向路径。
@export var movement_offset: Vector2 = Vector2(240.0, 0.0):
	set(value):
		movement_offset = value
		_update_path_preview()

## 平台移动速度；小于等于 0 时平台保持静止。
@export var movement_speed: float = 90.0
## 到达起点或终点后的停顿时间。
@export var endpoint_wait_time: float = 0.45
## 是否在起点与终点之间往返循环；关闭时平台单程移动到终点后停下。
@export var loop_movement: bool = true
## 为 true 时平台从终点向起点移动，为 false 时从起点向终点移动。
@export var start_from_end: bool = false
## 在编辑器和游戏中显示移动路径及端点标记。
@export var show_path_preview: bool = true:
	set(value):
		show_path_preview = value
		_update_path_preview()

@onready var _solid_collision: CollisionShape2D = $SolidCollision
@onready var _visual_rect: Polygon2D = $VisualRect
@onready var _top_highlight: Line2D = $TopHighlight
@onready var _path_preview: Line2D = $PathPreview
@onready var _start_marker: Polygon2D = $StartMarker
@onready var _end_marker: Polygon2D = $EndMarker

var _origin_position: Vector2 = Vector2.ZERO
var _path_progress: float = 0.0
var _direction: int = 1
var _wait_remaining: float = 0.0
var _movement_finished: bool = false

func _ready() -> void:
	_origin_position = position
	_direction = -1 if start_from_end else 1
	_path_progress = 1.0 if start_from_end else 0.0
	position = _origin_position + movement_offset * _path_progress
	_update_dimensions()
	_update_path_preview()

func _physics_process(delta: float) -> void:
	if _movement_finished or movement_speed <= 0.0 or movement_offset.is_zero_approx():
		return

	if _wait_remaining > 0.0:
		_wait_remaining = maxf(_wait_remaining - delta, 0.0)
		if _wait_remaining <= 0.0 and loop_movement:
			_direction *= -1
			SignalBus.MovingPlatformDirectionChanged.emit(self, _direction)
		return

	var path_length := movement_offset.length()
	_path_progress += float(_direction) * movement_speed * delta / path_length
	var reached_endpoint := false
	if _direction > 0 and _path_progress >= 1.0:
		_path_progress = 1.0
		reached_endpoint = true
	elif _direction < 0 and _path_progress <= 0.0:
		_path_progress = 0.0
		reached_endpoint = true

	position = _origin_position + movement_offset * _path_progress
	_update_path_preview()

	if reached_endpoint:
		var endpoint_index := 1 if _direction > 0 else 0
		SignalBus.MovingPlatformEndpointReached.emit(self, endpoint_index)
		if not loop_movement:
			_movement_finished = true
			return
		_wait_remaining = maxf(endpoint_wait_time, 0.0)
		if _wait_remaining <= 0.0:
			_direction *= -1
			SignalBus.MovingPlatformDirectionChanged.emit(self, _direction)

func _update_dimensions() -> void:
	if not is_inside_tree():
		return
	var rectangle := RectangleShape2D.new()
	rectangle.size = platform_size
	_solid_collision.shape = rectangle
	var half_size := platform_size * 0.5
	_visual_rect.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	_top_highlight.points = PackedVector2Array([
		Vector2(-half_size.x + 4.0, -half_size.y + 4.0),
		Vector2(half_size.x - 4.0, -half_size.y + 4.0),
	])

func _update_path_preview() -> void:
	if not is_inside_tree():
		return
	_path_preview.visible = show_path_preview
	_start_marker.visible = show_path_preview
	_end_marker.visible = show_path_preview
	_path_preview.points = PackedVector2Array([
		-movement_offset * _path_progress,
		movement_offset * (1.0 - _path_progress),
	])
	_start_marker.position = -movement_offset * _path_progress
	_end_marker.position = movement_offset * (1.0 - _path_progress)

## 导出移动平台当前运行状态。
## 返回值包含世界位置、路径进度、移动方向和剩余停顿时间。
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"path_progress": _path_progress,
		"direction": _direction,
		"wait_remaining": _wait_remaining,
		"movement_finished": _movement_finished,
	}

## 从存档恢复移动平台运行状态。
## @param data 由 ExportSaveData() 生成的字典；缺失字段时沿用当前状态。
func LoadSaveData(data: Dictionary) -> void:
	_path_progress = clampf(float(data.get("path_progress", _path_progress)), 0.0, 1.0)
	_direction = 1 if int(data.get("direction", _direction)) >= 0 else -1
	_wait_remaining = maxf(float(data.get("wait_remaining", 0.0)), 0.0)
	_movement_finished = bool(data.get("movement_finished", false))
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(float(data["position_x"]), float(data["position_y"]))
		_origin_position = position - movement_offset * _path_progress
	else:
		position = _origin_position + movement_offset * _path_progress
	_update_path_preview()
