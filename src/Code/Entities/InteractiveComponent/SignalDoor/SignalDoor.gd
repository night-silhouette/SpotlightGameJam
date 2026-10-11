extends AnimatableBody2D
class_name SignalDoor

## 监听 SignalBus 物理机关通道，并在通道激活时移动到开启位置。

@export_category("Signal Door Binding")
## 直接绑定的按钮列表；如果不为空，则当且仅当列表内所有按钮均被按下时门才开启（多对一模式）。
@export var bound_buttons: Array[PressureButton] = []
## 输入通道；若 bound_buttons 为空，则回退到该通道进行监听绑定。
@export var input_channel: StringName = &"door_1"
## 相对关闭位置的开启位移；允许每扇门独立设置方向与距离。
@export var open_offset: Vector2 = Vector2(0.0, -128.0)
## true 时通道激活则开门；false 时逻辑反转。
@export var open_when_active: bool = true

@onready var _solid_collision: CollisionShape2D = $SolidCollision
@onready var _visual: Polygon2D = $Visual

var _door_size: Vector2 = Vector2(32.0, 128.0)
var _move_speed: float = 180.0
var _closed_position: Vector2 = Vector2.ZERO
var _active_sources: Dictionary = {}
var _should_open: bool = false

func _ready() -> void:
	_sync_from_export_settings()
	_closed_position = position
	_update_dimensions()
	if bound_buttons.is_empty():
		SignalBus.MechanismChannelStateChanged.connect(_on_channel_state_changed)
	else:
		for btn in bound_buttons:
			if is_instance_valid(btn) and not btn.pressed_state_changed.is_connected(_on_bound_button_changed):
				btn.pressed_state_changed.connect(_on_bound_button_changed)
	_refresh_open_state()

func _on_bound_button_changed(_is_pressed: bool) -> void:
	_refresh_open_state()

func _physics_process(delta: float) -> void:
	var target_position := _closed_position + (open_offset if _should_open else Vector2.ZERO)
	position = position.move_toward(target_position, _move_speed * delta)

func _sync_from_export_settings() -> void:
	if not ExportSettings:
		return
	_door_size = Vector2(
		maxf(ExportSettings.signal_door_size.x, 4.0),
		maxf(ExportSettings.signal_door_size.y, 4.0)
	)
	_move_speed = maxf(ExportSettings.signal_door_move_speed, 1.0)
	if open_offset == Vector2(0.0, -128.0):
		open_offset = ExportSettings.signal_door_open_offset

func _update_dimensions() -> void:
	var door_shape := RectangleShape2D.new()
	door_shape.size = _door_size
	_solid_collision.shape = door_shape
	var half_size := _door_size * 0.5
	_visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])

func _on_channel_state_changed(channel: StringName, is_active: bool, source: Node2D) -> void:
	if channel != input_channel:
		return
	if not is_instance_valid(source):
		return
	var source_id := source.get_instance_id()
	if is_active:
		_active_sources[source_id] = source
	else:
		_active_sources.erase(source_id)
	_refresh_open_state()

func _refresh_open_state() -> void:
	var active: bool = false
	if not bound_buttons.is_empty():
		active = true
		for btn in bound_buttons:
			if not is_instance_valid(btn) or not btn.IsPressed():
				active = false
				break
	else:
		active = not _active_sources.is_empty()
	_should_open = active if open_when_active else not active

## 立即清除已记录的发送端状态，并将门恢复为未激活逻辑。
## 可用于关卡重置；门仍会按配置速度移动到目标位置。
func ResetSignalState() -> void:
	_active_sources.clear()
	_refresh_open_state()

## 返回门当前是否正在朝开启位置移动或已完全开启。
## 返回值为 true 表示当前目标状态是开启。
func IsOpenRequested() -> bool:
	return _should_open

## 导出门当前运行状态。
## 返回值包含门位置、关闭基准位置和当前目标状态。
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"closed_position_x": _closed_position.x,
		"closed_position_y": _closed_position.y,
		"should_open": _should_open,
	}

## 从存档恢复门的位置与目标状态。
## @param data 由 ExportSaveData() 生成的字典；缺失字段时沿用当前状态。
func LoadSaveData(data: Dictionary) -> void:
	if data.has("closed_position_x") and data.has("closed_position_y"):
		_closed_position = Vector2(float(data["closed_position_x"]), float(data["closed_position_y"]))
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(float(data["position_x"]), float(data["position_y"]))
	_should_open = bool(data.get("should_open", _should_open))
