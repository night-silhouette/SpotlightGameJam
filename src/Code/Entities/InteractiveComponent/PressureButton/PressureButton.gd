extends AnimatableBody2D
class_name PressureButton

const PRESSURE_SWITCH_SFX = preload("res://Music/SFX/InteractiveLV3/PressureSwitch.wav")
const BUTTON_TEXTURE_REGION_WIDTH: float = 212.0
const UNPRESSED_TEXTURE_REGION_HEIGHT: float = 46.0
const PRESSED_TEXTURE_REGION_HEIGHT: float = 30.0

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
			_apply_pressed_state(value, true)
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

@onready var _solid_collision: CollisionShape2D = $SolidCollision
@onready var _trigger_area: Area2D = $TriggerArea
@onready var _trigger_collision: CollisionShape2D = $TriggerArea/TriggerCollision
@onready var _unpressed_sprite: Sprite2D = $UnpressedSprite2D
@onready var _pressed_sprite: Sprite2D = $PressedSprite2D

var _button_size: Vector2 = Vector2(64.0, 14.0)
var _pressing_bodies: Dictionary = {}
var _overlap_refresh_version: int = 0

func _ready() -> void:
	_sync_from_export_settings()
	_pressing_bodies.clear()
	_trigger_area.collision_mask = pressing_collision_mask
	_trigger_area.body_entered.connect(_on_body_entered)
	_trigger_area.body_exited.connect(_on_body_exited)
	_update_dimensions()
	# 按下状态是瞬时物理状态，不能继承场景序列化值或上一次实例的状态。
	_apply_pressed_state(false, true)
	_schedule_overlap_refresh()

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

func _update_dimensions() -> void:
	var solid_shape := RectangleShape2D.new()
	solid_shape.size = _button_size
	_solid_collision.shape = solid_shape
	_solid_collision.position = Vector2.ZERO

	var trigger_shape := RectangleShape2D.new()
	trigger_shape.size = Vector2(maxf(_button_size.x - 4.0, 4.0), _button_size.y + 8.0)
	_trigger_collision.shape = trigger_shape
	_trigger_collision.position = Vector2(0.0, -4.0)

	var visual_scale := _button_size.x / BUTTON_TEXTURE_REGION_WIDTH
	_unpressed_sprite.scale = Vector2.ONE * visual_scale
	_pressed_sprite.scale = Vector2.ONE * visual_scale
	_pressed_sprite.position.y = (
		UNPRESSED_TEXTURE_REGION_HEIGHT - PRESSED_TEXTURE_REGION_HEIGHT
	) * visual_scale * 0.5

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
	_apply_pressed_state(not _pressing_bodies.is_empty(), true)

func _can_press(body: Node2D) -> bool:
	# TriggerArea 是按钮自身的子节点，其范围会覆盖本体 SolidCollision；
	# 必须排除 self，否则按钮会在第一个物理帧检测到自己并永久变成按下。
	if body == self or not body is PhysicsBody2D:
		return false
	return required_body_group.is_empty() or body.is_in_group(required_body_group)

func _set_pressed(value: bool) -> void:
	if stay_pressed and _is_pressed and not value:
		return
	if value and not _is_pressed:
		Util.PlaySFX2D(PRESSURE_SWITCH_SFX, global_position, &"SFX_Interact", 6.0)
	_apply_pressed_state(value)

func _apply_pressed_state(value: bool, force_refresh: bool = false) -> void:
	if _is_pressed == value and not force_refresh:
		return
	_is_pressed = value
	_update_visual_state()
	pressed_state_changed.emit(_is_pressed)
	_emit_state(_is_pressed)

func _update_visual_state() -> void:
	_unpressed_sprite.visible = not _is_pressed
	_pressed_sprite.visible = _is_pressed

func _emit_state(value: bool) -> void:
	if output_channel.is_empty():
		return
	SignalBus.MechanismChannelStateChanged.emit(output_channel, value, self)

## 返回按钮当前是否被至少一个有效物理体压住。
## 返回值为 true 时按钮处于按下状态。
func IsPressed() -> bool:
	return _is_pressed

## 强制将按钮恢复为未按下状态。
## 清空当前踩踏实体，并忽略 stay_pressed 锁定；同时恢复抬起形态并广播未按下状态。
func ResetState() -> void:
	_overlap_refresh_version += 1
	_pressing_bodies.clear()
	_apply_pressed_state(false, true)

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
	_apply_pressed_state(bool(data.get("is_pressed", false)), true)
