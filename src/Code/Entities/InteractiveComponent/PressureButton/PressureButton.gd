extends AnimatableBody2D
class_name PressureButton

## 按钮状态发生改变时发出（按下为 true，抬起为 false）。
signal pressed_state_changed(is_pressed: bool)

## 由任意进入检测区的物理体压下，并通过 SignalBus 广播通道状态。

@export_category("Pressure Button Binding")
@export var stay_pressed: bool = true
## 输出通道；与门或其他接收组件的输入通道填写相同名称即可绑定。
@export var output_channel: StringName = &"door_1"
## 可触发按钮的物理层遮罩；修改后会同步到检测区域。
@export_flags_2d_physics var pressing_collision_mask: int = 0xFFFFFFFF
## 非空时只接受属于该分组的物理体；留空接受所有 PhysicsBody2D。
@export var required_body_group: StringName = &""

@onready var _solid_collision: CollisionShape2D = $SolidCollision
@onready var _trigger_area: Area2D = $TriggerArea
@onready var _trigger_collision: CollisionShape2D = $TriggerArea/TriggerCollision
@onready var _visual: Polygon2D = $Visual

var _button_size: Vector2 = Vector2(64.0, 14.0)
var _press_depth: float = 8.0
var _move_speed: float = 120.0
var _rest_position: Vector2 = Vector2.ZERO
var _pressing_bodies: Dictionary = {}
var _is_pressed: bool = false

func _ready() -> void:
	_sync_from_export_settings()
	_rest_position = position
	_trigger_area.collision_mask = pressing_collision_mask
	_trigger_area.body_entered.connect(_on_body_entered)
	_trigger_area.body_exited.connect(_on_body_exited)
	_update_dimensions()
	_emit_state(false)

func _physics_process(delta: float) -> void:
	var target_position := _rest_position + Vector2.DOWN * (_press_depth if _is_pressed else 0.0)
	position = position.move_toward(target_position, _move_speed * delta)

func _exit_tree() -> void:
	if _is_pressed and not stay_pressed:
		_emit_state(false)

func _sync_from_export_settings() -> void:
	if not ExportSettings:
		return
	_button_size = Vector2(
		maxf(ExportSettings.pressure_button_size.x, 8.0),
		maxf(ExportSettings.pressure_button_size.y, 4.0)
	)
	_press_depth = maxf(ExportSettings.pressure_button_press_depth, 0.0)
	_move_speed = maxf(ExportSettings.pressure_button_move_speed, 1.0)

func _update_dimensions() -> void:
	var solid_shape := RectangleShape2D.new()
	solid_shape.size = _button_size
	_solid_collision.shape = solid_shape

	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(maxf(_button_size.x - 4.0, 4.0), _button_size.y + 8.0)
	_trigger_collision.shape = trigger_shape
	_trigger_collision.position = Vector2(0.0, -4.0)

	var half_size := _button_size * 0.5
	_visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])

func _on_body_entered(body: Node2D) -> void:
	if not _can_press(body):
		return
	_pressing_bodies[body.get_instance_id()] = body
	_set_pressed(true)

func _on_body_exited(body: Node2D) -> void:
	_pressing_bodies.erase(body.get_instance_id())
	_set_pressed(not _pressing_bodies.is_empty())

func _can_press(body: Node2D) -> bool:
	if not body is PhysicsBody2D:
		return false
	return required_body_group.is_empty() or body.is_in_group(required_body_group)

func _set_pressed(value: bool) -> void:
	if stay_pressed and _is_pressed and not value:
		return
	if _is_pressed == value:
		return
	_is_pressed = value
	pressed_state_changed.emit(_is_pressed)
	_emit_state(_is_pressed)

func _emit_state(value: bool) -> void:
	if output_channel.is_empty():
		return
	SignalBus.MechanismChannelStateChanged.emit(output_channel, value, self)

## 返回按钮当前是否被至少一个有效物理体压住。
## 返回值为 true 时按钮处于按下状态。
func IsPressed() -> bool:
	return _is_pressed

## 导出按钮的持久化状态；压住按钮的物理体不会被序列化。
## 返回值包含绑定通道，按钮会在物理检测恢复后自动刷新状态。
func ExportSaveData() -> Dictionary:
	return {"output_channel": String(output_channel)}

## 恢复按钮绑定通道。
## @param data 由 ExportSaveData() 生成的字典；缺失通道时保留场景配置。
func LoadSaveData(data: Dictionary) -> void:
	if data.has("output_channel"):
		output_channel = StringName(data["output_channel"])
