extends StaticBody2D
class_name SignalVanishBlocker

const SHATTER_SHADER := preload("res://Code/Entities/InteractiveComponent/SignalVanishBlocker/SignalVanishBlockerShatter.gdshader")

enum ListenMode {
	NATIVE_SIGNAL,
	MECHANISM_CHANNEL,
}

## 障碍物开始禁用碰撞并淡出时发出。
signal VanishStarted
## 障碍物完成淡出并隐藏或释放时发出。
signal Vanished

@export_category("Signal Binding")
## 监听模式：SignalBus 原生信号，或 MechanismChannelStateChanged 机制通道。
@export var listen_mode: ListenMode = ListenMode.NATIVE_SIGNAL
## 原生信号名称；例如 lock1 或 lock2。仅在 NATIVE_SIGNAL 模式使用。
@export var signal_name: StringName = &"lock1"
## 机制通道名称。仅在 MECHANISM_CHANNEL 模式使用。
@export var channel_name: StringName = &""

@export_category("Vanish Behavior")
## 是否播放透明度淡出；关闭时立即隐藏或释放。
@export var fade_enabled: bool = true
## 是否使用 ExportSettings 中的 vanishing_blocker_fade_duration。
@export var use_export_settings: bool = true
## 不使用全局配置时采用的淡出时长（秒）。
@export_range(0.0, 10.0, 0.05) var fade_duration: float = 0.5
## 淡出完成后是否释放节点；默认仅隐藏，便于存档系统保留节点路径。
@export var free_after_vanish: bool = false
## 与本挡板同步碎裂并隐藏的画面节点；可指向同级 TileMapLayer。
@export_node_path("CanvasItem") var visual_target_path: NodePath

var _is_vanished: bool = false
var _visual_target: CanvasItem
var _shatter_material: ShaderMaterial

func _ready() -> void:
	if use_export_settings:
		fade_duration = maxf(ExportSettings.vanishing_blocker_fade_duration, 0.0)
	_resolve_visual_target()
	_prepare_visual_effect()
	_connect_trigger()

func _resolve_visual_target() -> void:
	if not visual_target_path.is_empty():
		_visual_target = get_node_or_null(visual_target_path) as CanvasItem
		if not is_instance_valid(_visual_target):
			push_warning("SignalVanishBlocker could not find visual target: %s" % visual_target_path)
	if not is_instance_valid(_visual_target):
		_visual_target = get_node_or_null(^"Visual") as CanvasItem
	if is_instance_valid(_visual_target) and _visual_target != self:
		var fallback_visual := get_node_or_null(^"Visual") as CanvasItem
		if is_instance_valid(fallback_visual) and fallback_visual != _visual_target:
			fallback_visual.hide()

func _prepare_visual_effect() -> void:
	if not ExportSettings.vanishing_blocker_shatter_enabled or not is_instance_valid(_visual_target):
		return
	_shatter_material = ShaderMaterial.new()
	_shatter_material.shader = SHATTER_SHADER
	_shatter_material.set_shader_parameter(&"progress", 0.0)
	_shatter_material.set_shader_parameter(&"shard_size", ExportSettings.vanishing_blocker_shard_size)
	_shatter_material.set_shader_parameter(&"scatter_distance", ExportSettings.vanishing_blocker_scatter_distance)
	_shatter_material.set_shader_parameter(&"fall_distance", ExportSettings.vanishing_blocker_fall_distance)
	_shatter_material.set_shader_parameter(&"edge_width", ExportSettings.vanishing_blocker_edge_width)
	_shatter_material.set_shader_parameter(&"edge_color", ExportSettings.vanishing_blocker_edge_color)
	_visual_target.material = _shatter_material

func _connect_trigger() -> void:
	if listen_mode == ListenMode.MECHANISM_CHANNEL:
		if channel_name.is_empty():
			push_warning("SignalVanishBlocker requires channel_name in mechanism channel mode.")
			return
		if not SignalBus.MechanismChannelStateChanged.is_connected(_on_channel_state_changed):
			SignalBus.MechanismChannelStateChanged.connect(_on_channel_state_changed)
		return

	if signal_name.is_empty():
		push_warning("SignalVanishBlocker requires signal_name in native signal mode.")
		return
	if not SignalBus.has_signal(signal_name):
		push_warning("SignalVanishBlocker could not find SignalBus signal: %s" % signal_name)
		return
	var callback := Callable(self, "_on_native_signal_received")
	if not SignalBus.is_connected(signal_name, callback):
		SignalBus.connect(signal_name, callback)

func _on_native_signal_received() -> void:
	Vanish()

func _on_channel_state_changed(channel: StringName, is_active: bool, _source: Node2D) -> void:
	if channel == channel_name and is_active:
		Vanish()

## 禁用全部子级 CollisionShape2D/CollisionPolygon2D，并执行淡出消失流程。
## @return 首次触发返回 true；已经消失或正在消失时返回 false。
func Vanish() -> bool:
	if _is_vanished:
		return false
	_is_vanished = true
	_set_collisions_disabled(self)
	_set_visual_collision_disabled()
	VanishStarted.emit()
	SignalBus.BlockerVanishStarted.emit(self)

	var duration := fade_duration if fade_enabled else 0.0
	if duration <= 0.0:
		_set_vanish_progress(1.0)
		_finish_vanish()
		return true
	var tween := create_tween()
	if is_instance_valid(_shatter_material):
		tween.tween_method(_set_vanish_progress, 0.0, 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	elif is_instance_valid(_visual_target):
		tween.tween_property(_visual_target, "modulate:a", 0.0, duration)
	else:
		tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(_finish_vanish)
	return true

func _set_collisions_disabled(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
		_set_collisions_disabled(child)

func _set_visual_collision_disabled() -> void:
	if not is_instance_valid(_visual_target):
		return
	if _visual_target is TileMapLayer:
		(_visual_target as TileMapLayer).set_deferred(&"collision_enabled", false)
	_set_collisions_disabled(_visual_target)

func _set_vanish_progress(value: float) -> void:
	if is_instance_valid(_shatter_material):
		_shatter_material.set_shader_parameter(&"progress", clampf(value, 0.0, 1.0))

func _finish_vanish() -> void:
	Vanished.emit()
	SignalBus.BlockerVanished.emit(self)
	if is_instance_valid(_visual_target):
		_visual_target.hide()
	if free_after_vanish:
		queue_free()
	else:
		hide()

## 导出障碍物是否已消失，用于存档恢复。
## @return 包含 vanished 状态的字典。
func ExportSaveData() -> Dictionary:
	return {"vanished": _is_vanished}

## 从存档恢复障碍物状态。
## @param data 由 ExportSaveData() 生成的字典；缺少 vanished 时保持当前状态。
func LoadSaveData(data: Dictionary) -> void:
	if bool(data.get("vanished", false)):
		_is_vanished = true
		_set_collisions_disabled(self)
		_set_visual_collision_disabled()
		_set_vanish_progress(1.0)
		modulate.a = 0.0
		if is_instance_valid(_visual_target):
			_visual_target.hide()
		hide()
