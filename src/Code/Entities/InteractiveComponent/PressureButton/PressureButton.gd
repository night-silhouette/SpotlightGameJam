extends AnimatableBody2D
class_name PressureButton

## 按钮状态发生改变时发出（按下为 true，抬起为 false）。
signal pressed_state_changed(is_pressed: bool)

var _is_pressed: bool = false

@export_category("Pressure Button State")
## 当前按钮的按下状态。新实例默认未按下，存档载入时可恢复该状态。
@export var is_pressed: bool:
	get:
		return _is_pressed
	set(value):
		if is_node_ready():
			_apply_pressed_state(value, false, true)
		else:
			_is_pressed = value

## 由任意进入检测区的物理体压下，并通过 SignalBus 广播通道状态。

@export_category("Pressure Button Binding")
@export var stay_pressed: bool = false
## 输出通道；与门或其他接收组件的输入通道填写相同名称即可绑定。
@export var output_channel: StringName = &"door_1"
## 可触发按钮的物理层遮罩；修改后会同步到检测区域。
@export_flags_2d_physics var pressing_collision_mask: int = 0xFFFFFFFF
## 非空时只接受属于该分组的物理体；留空接受所有 PhysicsBody2D。
@export var required_body_group: StringName = &""

@export_category("Pressure Button Visuals")
@export var unpressed_color: Color = Color(0.82, 0.48, 0.18, 1.0)
@export var pressed_color: Color = Color(0.35, 0.85, 0.45, 1.0)

@onready var _base: Polygon2D = $Base
@onready var _solid_collision: CollisionShape2D = $SolidCollision
@onready var _trigger_area: Area2D = $TriggerArea
@onready var _trigger_collision: CollisionShape2D = $TriggerArea/TriggerCollision
@onready var _visual: Polygon2D = $Visual
@onready var _indicator: Polygon2D = $Visual/Indicator

var _button_size: Vector2 = Vector2(64.0, 14.0)
var _press_depth: float = 8.0
var _move_speed: float = 120.0
var _rest_position: Vector2 = Vector2.ZERO
var _pressing_bodies: Dictionary = {}
var _color_tween: Tween
var _overlap_refresh_version: int = 0

func _ready() -> void:
	_sync_from_export_settings()
	_rest_position = position
	_pressing_bodies.clear()
	_trigger_area.collision_mask = pressing_collision_mask
	_trigger_area.body_entered.connect(_on_body_entered)
	_trigger_area.body_exited.connect(_on_body_exited)
	_update_dimensions()
	# 按下状态是瞬时物理状态，不能继承场景序列化值或上一次实例的状态。
	_apply_pressed_state(false, false, true)
	_schedule_overlap_refresh()

func _physics_process(delta: float) -> void:
	var target_position := _rest_position + Vector2.DOWN * (_press_depth if _is_pressed else 0.0)
	position = position.move_toward(target_position, _move_speed * delta)

func _exit_tree() -> void:
	_overlap_refresh_version += 1
	if _is_pressed:
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
	var base_half_width := half_size.x + 4.0
	_base.position = Vector2(0.0, half_size.y - 1.0)
	_base.polygon = PackedVector2Array([
		Vector2(-base_half_width, -5.0),
		Vector2(base_half_width, -5.0),
		Vector2(half_size.x, 7.0),
		Vector2(-half_size.x, 7.0),
	])
	_visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	var indicator_half_width := maxf(half_size.x - 8.0, 2.0)
	var indicator_top := -half_size.y + 2.0
	_indicator.polygon = PackedVector2Array([
		Vector2(-indicator_half_width, indicator_top),
		Vector2(indicator_half_width, indicator_top),
		Vector2(indicator_half_width, indicator_top + 2.0),
		Vector2(-indicator_half_width, indicator_top + 2.0),
	])

func _on_body_entered(body: Node2D) -> void:
	if not _can_press(body):
		return
	_pressing_bodies[body.get_instance_id()] = body
	_set_pressed(true)

func _on_body_exited(body: Node2D) -> void:
	_pressing_bodies.erase(body.get_instance_id())
	_set_pressed(not _pressing_bodies.is_empty())

func _schedule_overlap_refresh() -> void:
	_overlap_refresh_version += 1
	_refresh_overlapping_bodies(_overlap_refresh_version)

func _refresh_overlapping_bodies(refresh_version: int) -> void:
	await get_tree().physics_frame
	if refresh_version != _overlap_refresh_version or not is_inside_tree():
		return
	_pressing_bodies.clear()
	for body in _trigger_area.get_overlapping_bodies():
		if _can_press(body):
			_pressing_bodies[body.get_instance_id()] = body
	_apply_pressed_state(not _pressing_bodies.is_empty(), false, true)

func _can_press(body: Node2D) -> bool:
	# TriggerArea 是按钮自身的子节点，其范围会覆盖本体 SolidCollision；
	# 必须排除 self，否则按钮会在第一个物理帧检测到自己并永久变成按下。
	if body == self or not body is PhysicsBody2D:
		return false
	return required_body_group.is_empty() or body.is_in_group(required_body_group)

func _set_pressed(value: bool) -> void:
	if stay_pressed and _is_pressed and not value:
		return
	_apply_pressed_state(value, true)

func _apply_pressed_state(value: bool, animate: bool, force_refresh: bool = false) -> void:
	if _is_pressed == value and not force_refresh:
		return
	_is_pressed = value
	if not animate:
		position = _rest_position + (Vector2.DOWN * _press_depth if _is_pressed else Vector2.ZERO)
	_update_visual_color(animate)
	pressed_state_changed.emit(_is_pressed)
	_emit_state(_is_pressed)

func _update_visual_color(animate: bool) -> void:
	var target_color := pressed_color if _is_pressed else unpressed_color
	var target_indicator_color := target_color.lightened(0.35)
	if _color_tween and _color_tween.is_valid():
		_color_tween.kill()
	if not animate:
		_visual.color = target_color
		_indicator.color = target_indicator_color
		return
	_color_tween = create_tween()
	_color_tween.set_parallel(true)
	_color_tween.set_trans(Tween.TRANS_SINE)
	_color_tween.set_ease(Tween.EASE_OUT)
	_color_tween.tween_property(_visual, "color", target_color, 0.15)
	_color_tween.tween_property(_indicator, "color", target_indicator_color, 0.15)

func _emit_state(value: bool) -> void:
	if output_channel.is_empty():
		return
	SignalBus.MechanismChannelStateChanged.emit(output_channel, value, self)

## 返回按钮当前是否被至少一个有效物理体压住。
## 返回值为 true 时按钮处于按下状态。
func IsPressed() -> bool:
	return _is_pressed

## 强制将按钮恢复为未按下状态。
## 清空当前踩踏实体，并忽略 stay_pressed 锁定；同时立即回弹、刷新视觉并广播未按下状态。
func ResetState() -> void:
	_overlap_refresh_version += 1
	_pressing_bodies.clear()
	_apply_pressed_state(false, false, true)

## 导出按钮的持久化状态。
## 返回值包含绑定通道和当前按下状态；新游戏未提供存档数据时仍使用默认未按下状态。
func ExportSaveData() -> Dictionary:
	return {
		"output_channel": String(output_channel),
		"is_pressed": _is_pressed,
	}

## 恢复按钮绑定通道和按下状态。
## @param data 由 ExportSaveData() 生成的字典；缺少 is_pressed 的旧存档按未按下处理。
func LoadSaveData(data: Dictionary) -> void:
	var previous_channel := output_channel
	if data.has("output_channel"):
		output_channel = StringName(data["output_channel"])
	if previous_channel != output_channel and not previous_channel.is_empty():
		SignalBus.MechanismChannelStateChanged.emit(previous_channel, false, self)
	_pressing_bodies.clear()
	_apply_pressed_state(bool(data.get("is_pressed", false)), false, true)
