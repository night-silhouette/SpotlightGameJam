extends StaticBody2D
class_name VanishingBlockerComponent

## 当障碍物开始清除碰撞并下沉时触发一次。
signal VanishStarted
## 当障碍物下沉完成、即将调用 queue_free 前触发一次。
signal Vanished

@export var target_area: Area2D
## 随障碍物一起下沉的危险区；下沉开始时会立即禁用其伤害与碰撞。
@export var sink_follower: Node2D
@export var vanish_zone_group: StringName = &"VanishZone"
@export_range(0.0, 10.0, 0.05) var fade_duration: float = 0.5
@export_range(0.0, 2048.0, 1.0) var sink_distance: float = 240.0
@export var use_export_settings: bool = true

var _vanishing: bool = false

func _ready() -> void:
	_set_tilemap_collisions_enabled(self, true)
	if use_export_settings:
		vanish_zone_group = ExportSettings.vanishing_blocker_zone_group
		fade_duration = ExportSettings.vanishing_blocker_fade_duration
		sink_distance = ExportSettings.vanishing_blocker_sink_distance
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
	_disable_collision_tree(self, false)
	if is_instance_valid(sink_follower):
		# 在物理查询刷新前先封锁 Area2D 的信号，避免下沉帧仍触发尖刺伤害。
		_disable_collision_tree(sink_follower, true)
	VanishStarted.emit()
	SignalBus.BlockerVanishStarted.emit(self)
	var duration := maxf(fade_duration, 0.0)
	var offset := Vector2.DOWN * maxf(sink_distance, 0.0)
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", global_position + offset, duration)
	if is_instance_valid(sink_follower):
		tween.tween_property(
			sink_follower,
			"global_position",
			sink_follower.global_position + offset,
			duration
		)
	tween.chain().tween_callback(_finish_vanish)
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
	if is_instance_valid(sink_follower) and not is_ancestor_of(sink_follower):
		sink_follower.queue_free()
	queue_free()


func _disable_collision_tree(node: Node, block_collision_signals: bool) -> void:
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		if block_collision_signals:
			collision_object.set_block_signals(true)
		collision_object.set_deferred("collision_layer", 0)
		collision_object.set_deferred("collision_mask", 0)
		if collision_object is Area2D:
			collision_object.set_deferred("monitoring", false)
			collision_object.set_deferred("monitorable", false)
	elif node is TileMapLayer:
		node.set_deferred("collision_enabled", false)
	elif node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", true)
	for child in node.get_children():
		_disable_collision_tree(child, block_collision_signals)


func _set_tilemap_collisions_enabled(node: Node, enabled: bool) -> void:
	if node is TileMapLayer:
		(node as TileMapLayer).collision_enabled = enabled
	for child in node.get_children():
		_set_tilemap_collisions_enabled(child, enabled)
