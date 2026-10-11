class_name SlowWaterArea2D
extends Area2D

## 减速水体组件（零侵入 Player.gd，纯外部属性调控）
## 挂载 CollisionShape2D 后放置在场景中，主角进入该区域即可实现减速阻尼效果。

@export_category("Slow Water Settings")
## 水中移速倍率（0.55 表示降低至 55% 移速）
@export var speed_multiplier: float = 0.55

## 冲刺时是否豁免减速（避免吞掉冲刺操作的手感）
@export var exempt_dash: bool = true

## 是否仅在 OutwardPhase（或者特定节点下）激活
@export var active_in_outward_only: bool = false

# 内部记录被修改过 speed 的角色以及其原始速度
var _original_speeds: Dictionary = {}


func _ready() -> void:
	process_physics_priority = -10
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _exit_tree() -> void:
	_restore_all_speeds()


func _on_body_entered(body: Node2D) -> void:
	if not (body is CharacterBody2D):
		return
	if active_in_outward_only and not _is_in_outward_phase():
		return

	if "speed" in body:
		if not _original_speeds.has(body):
			_original_speeds[body] = body.speed
		body.speed = _original_speeds[body] * speed_multiplier


func _on_body_exited(body: Node2D) -> void:
	if _original_speeds.has(body):
		if is_instance_valid(body) and "speed" in body:
			body.speed = _original_speeds[body]
		_original_speeds.erase(body)


func _physics_process(_delta: float) -> void:
	if _original_speeds.is_empty():
		return

	if active_in_outward_only and not _is_in_outward_phase():
		_restore_all_speeds()
		return

	for body in _original_speeds.keys():
		if not is_instance_valid(body) or not body.is_inside_tree():
			_original_speeds.erase(body)
			continue

		var orig_speed: float = _original_speeds[body]
		
		# 如果处于冲刺等特殊状态且开启了豁免，临时把速度拉回原速
		var is_dashing := false
		if exempt_dash:
			if "move_state_machine" in body and body.move_state_machine:
				if body.move_state_machine.cur_state_name == "dash":
					is_dashing = true
			if "is_special_state" in body and body.is_special_state:
				is_dashing = true

		if is_dashing:
			body.speed = orig_speed
		else:
			body.speed = orig_speed * speed_multiplier


func _restore_all_speeds() -> void:
	for body in _original_speeds.keys():
		if is_instance_valid(body) and "speed" in body:
			body.speed = _original_speeds[body]
	_original_speeds.clear()


func _is_in_outward_phase() -> bool:
	var node: Node = self
	while node:
		if node.name == "OutwardPhase":
			return true
		node = node.get_parent()
	return false
