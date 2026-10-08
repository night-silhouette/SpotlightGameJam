extends StaticBody2D
class_name VanishingBlockerComponent

## 当障碍物开始清除碰撞并淡出时触发一次。
signal VanishStarted
## 当障碍物淡出完成、即将调用 queue_free 前触发一次。
signal Vanished

@export var target_area: Area2D
@export var vanish_zone_group: StringName = &"VanishZone"
@export_range(0.0, 10.0, 0.05) var fade_duration: float = 0.5
@export var use_export_settings: bool = true

@onready var _collision: CollisionShape2D = $CollisionShape2D
var _vanishing: bool = false

func _ready() -> void:
	if use_export_settings:
		vanish_zone_group = ExportSettings.vanishing_blocker_zone_group
		fade_duration = ExportSettings.vanishing_blocker_fade_duration

func _physics_process(_delta: float) -> void:
	if _vanishing or _collision.disabled or _collision.shape == null:
		return
	# Query areas directly: StaticBody2D has no area_entered signal.
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _collision.shape
	query.transform = _collision.global_transform
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = 0xFFFFFFFF
	for result in get_world_2d().direct_space_state.intersect_shape(query, 256):
		var area := result["collider"] as Area2D
		if area != null and (area == target_area or area.is_in_group(vanish_zone_group)):
			Vanish()
			return

## 触发障碍物消失流程（仅初次调用生效）。
## @return 首次触发返回 true，已处于消失流程中返回 false。
func Vanish() -> bool:
	if _vanishing or not is_node_ready():
		return false
	_vanishing = true
	set_physics_process(false)
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.set_deferred("disabled", true)
	VanishStarted.emit()
	SignalBus.BlockerVanishStarted.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, maxf(fade_duration, 0.0))
	tween.tween_callback(_finish_vanish)
	return true

## 导出障碍物持久化存档数据。
func ExportSaveData() -> Dictionary:
	return {
		"vanishing": _vanishing,
		"visible": visible,
		"modulate_a": modulate.a
	}

## 加载并恢复障碍物存档数据。
## @param data 包含 vanishing 状态的存档字典。
func LoadSaveData(data: Dictionary) -> void:
	_vanishing = bool(data.get("vanishing", false))
	if _vanishing:
		queue_free()

func _finish_vanish() -> void:
	Vanished.emit()
	SignalBus.BlockerVanished.emit(self)
	queue_free()
