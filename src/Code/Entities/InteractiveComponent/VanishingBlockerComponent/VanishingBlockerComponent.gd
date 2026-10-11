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

var _vanishing: bool = false

func _ready() -> void:
	if use_export_settings:
		vanish_zone_group = ExportSettings.vanishing_blocker_zone_group
		fade_duration = ExportSettings.vanishing_blocker_fade_duration
	if not is_instance_valid(target_area) and not vanish_zone_group.is_empty():
		target_area = get_tree().get_first_node_in_group(vanish_zone_group) as Area2D
	if is_instance_valid(target_area):
		# Player.tscn uses physics layer 2. Keep the area's existing mask while
		# ensuring this trigger can detect the player body.
		target_area.set_collision_mask_value(2, true)
		if not target_area.body_entered.is_connected(_on_target_area_body_entered):
			target_area.body_entered.connect(_on_target_area_body_entered)
		call_deferred(&"_check_target_area_overlaps")


func _check_target_area_overlaps() -> void:
	if _vanishing or not is_instance_valid(target_area):
		return
	for body in target_area.get_overlapping_bodies():
		if _is_player(body):
			Vanish()
			return


func _on_target_area_body_entered(body: Node2D) -> void:
	if _is_player(body):
		Vanish()


func _is_player(body: Node) -> bool:
	return body != null and (body.is_in_group(&"player") or body.name == &"Player")

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
		call_deferred(&"_finish_vanish")

func _finish_vanish() -> void:
	Vanished.emit()
	SignalBus.BlockerVanished.emit(self)
	queue_free()
