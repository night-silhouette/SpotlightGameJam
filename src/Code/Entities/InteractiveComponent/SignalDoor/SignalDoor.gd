extends AnimatableBody2D
class_name SignalDoor

## 监听 SignalBus 物理机关通道，或按绑定按钮的完成比例分段升起门板。

@export_category("Signal Door Binding")
## 直接绑定的按钮列表；每个按钮贡献等比例视觉进度，全部按下后才解除门的物理碰撞。
@export var bound_buttons: Array[PressureButton] = []
## 输入通道；若 bound_buttons 为空，则回退到该通道进行监听绑定。
@export var input_channel: StringName = &"door_1"
## 门板在自身局部坐标中的完全开启位移；实例应设为足以将整张门板收起的距离。
@export var open_offset: Vector2 = Vector2(0.0, -128.0)
## true 时通道激活则开门；false 时逻辑反转。
@export var open_when_active: bool = true

@onready var _solid_collision: CollisionShape2D = $SolidCollision
@onready var _visual: Polygon2D = $Visual
@onready var _dust_particles: CPUParticles2D = $DustParticles

var _door_size: Vector2 = Vector2(32.0, 128.0)
var _move_speed: float = 180.0
var _shake_duration: float = 0.24
var _shake_amount: float = 1.2
var _active_sources: Dictionary = {}
var _visual_nodes: Array[Node2D] = []
var _visual_closed_positions: Dictionary = {}
var _open_progress: float = 0.0
var _should_open: bool = false
var _collision_disabled: bool = false
var _visual_shake_offset: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null

func _ready() -> void:
	_sync_from_export_settings()
	_update_dimensions()
	_collect_visual_nodes()
	if bound_buttons.is_empty():
		SignalBus.MechanismChannelStateChanged.connect(_on_channel_state_changed)
	else:
		for btn in bound_buttons:
			if is_instance_valid(btn) and not btn.pressed_state_changed.is_connected(_on_bound_button_changed):
				btn.pressed_state_changed.connect(_on_bound_button_changed)
	_refresh_open_state()

func _on_bound_button_changed(_is_pressed: bool) -> void:
	var previous_progress := _open_progress
	_refresh_open_state()
	if _open_progress > previous_progress:
		_play_lift_feedback()

func _physics_process(delta: float) -> void:
	var target_offset := open_offset * _open_progress
	if not _should_open:
		_set_collision_disabled(false)
	var visuals_arrived := true
	for visual_node in _visual_nodes:
		if not is_instance_valid(visual_node):
			continue
		var closed_position: Vector2 = _visual_closed_positions.get(visual_node.get_instance_id(), visual_node.position)
		var target_position := closed_position + target_offset + _visual_shake_offset
		visual_node.position = visual_node.position.move_toward(target_position, _move_speed * delta)
		visuals_arrived = visuals_arrived and visual_node.position.is_equal_approx(target_position)
	if _should_open and visuals_arrived:
		_set_collision_disabled(true)

func _collect_visual_nodes() -> void:
	_visual_nodes.clear()
	_visual_closed_positions.clear()
	for child in get_children():
		if child is Polygon2D or child is Sprite2D:
			var visual_node := child as Node2D
			_visual_nodes.append(visual_node)
			_visual_closed_positions[visual_node.get_instance_id()] = visual_node.position

func _sync_from_export_settings() -> void:
	if not ExportSettings:
		return
	_door_size = Vector2(
		maxf(ExportSettings.signal_door_size.x, 4.0),
		maxf(ExportSettings.signal_door_size.y, 4.0)
	)
	_move_speed = maxf(ExportSettings.signal_door_move_speed, 1.0)
	_shake_duration = maxf(ExportSettings.signal_door_shake_duration, 0.0)
	_shake_amount = maxf(ExportSettings.signal_door_shake_offset, 0.0)
	_dust_particles.amount = maxi(ExportSettings.signal_door_dust_amount, 1)
	_dust_particles.lifetime = maxf(ExportSettings.signal_door_dust_lifetime, 0.1)
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
	var previous_progress := _open_progress
	_refresh_open_state()
	if _open_progress > previous_progress:
		_play_lift_feedback()

func _play_lift_feedback() -> void:
	_dust_particles.restart()
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	_visual_shake_offset = Vector2.ZERO
	if is_zero_approx(_shake_duration) or is_zero_approx(_shake_amount):
		return
	var shake_steps := maxi(2, int(ceil(_shake_duration / 0.04)))
	var step_duration := _shake_duration / float(shake_steps)
	_shake_tween = create_tween()
	for index in range(shake_steps - 1):
		var direction := -1.0 if index % 2 == 0 else 1.0
		var vertical_jitter := _shake_amount * (0.25 if index % 3 == 0 else -0.15)
		_shake_tween.tween_property(
			self,
			"_visual_shake_offset",
			Vector2(direction * _shake_amount, vertical_jitter),
			step_duration
		)
	_shake_tween.tween_property(self, "_visual_shake_offset", Vector2.ZERO, step_duration)

func _refresh_open_state() -> void:
	var activation_progress: float = 0.0
	if not bound_buttons.is_empty():
		var pressed_count: int = 0
		for btn in bound_buttons:
			if is_instance_valid(btn) and btn.IsPressed():
				pressed_count += 1
		activation_progress = float(pressed_count) / float(bound_buttons.size())
	else:
		activation_progress = 1.0 if not _active_sources.is_empty() else 0.0
	_open_progress = activation_progress if open_when_active else 1.0 - activation_progress
	_should_open = is_equal_approx(_open_progress, 1.0)
	if not _should_open:
		_set_collision_disabled(false)

func _set_collision_disabled(disabled: bool) -> void:
	if _collision_disabled == disabled:
		return
	_collision_disabled = disabled
	_solid_collision.set_deferred("disabled", disabled)

## 立即清除已记录的发送端状态，并将门恢复为未激活逻辑。
## 可用于关卡重置；门仍会按配置速度移动到目标位置。
func ResetSignalState() -> void:
	_active_sources.clear()
	_refresh_open_state()

## 返回门当前是否已收集全部开启条件。
## 返回值为 true 表示门板正在完成最后一段升起，或已完全开启。
func IsOpenRequested() -> bool:
	return _should_open

## 返回已激活条件对应的开门进度，范围为 0.0 至 1.0。
## 返回值仅表示目标进度；门板的实际视觉位置会按移动速度追赶该目标。
func GetOpenProgress() -> float:
	return _open_progress

## 导出门的持久化数据。
## 门的位置和开关目标均由按钮/通道实时派生，因此不持久化瞬时运行状态。
func ExportSaveData() -> Dictionary:
	return {}

## 忽略旧存档中的门位置/开关状态，并按当前按钮或通道状态重新同步。
## @param _data 由 ExportSaveData() 生成的字典；兼容并丢弃旧版瞬时状态字段。
func LoadSaveData(_data: Dictionary) -> void:
	_active_sources.clear()
	_refresh_open_state()
	var target_offset := open_offset * _open_progress
	for visual_node in _visual_nodes:
		if not is_instance_valid(visual_node):
			continue
		var closed_position: Vector2 = _visual_closed_positions.get(visual_node.get_instance_id(), visual_node.position)
		visual_node.position = closed_position + target_offset
	_set_collision_disabled(_should_open)
