class_name ProximityInteraction
extends Node
## 单玩家靠近交互组件。检测区和提示预置在实体场景中，由实体在 _ready 配置。
## 只负责选择、提示和请求；是否领取、展示、存档由实体自行处理。

const INTERACTION_GROUP: StringName = &"proximity_interactions"
var _target: Node2D
var _area: Area2D
var _prompt: Label
var _enabled: bool = true


## 配置组件；实体 _ready 中调用，重复配置也安全。
## @param target 交互实体根节点；area 须包含名为 CollisionShape2D 的圆形检测形状。
## @param prompt 预置的提示 Label；radius 是世界像素半径（场景缩放保持 1）。
## @param text 不含按键的提示文字；font_size 是字体像素大小。返回 void。
func Configure(target: Node2D, area: Area2D, prompt: Label, radius: float, text: String, font_size: int) -> void:
	if is_instance_valid(_prompt):
		_prompt.hide()
	_target = target
	_area = area
	_prompt = prompt
	var collider := _area.get_node("CollisionShape2D") as CollisionShape2D
	collider.shape = collider.shape.duplicate()
	(collider.shape as CircleShape2D).radius = maxf(1.0, radius)
	_prompt.add_theme_font_size_override("font_size", font_size)
	_prompt.text = "[%s] %s" % [_interaction_key_label(), text]
	_prompt.hide()
	if not is_in_group(INTERACTION_GROUP):
		add_to_group(INTERACTION_GROUP)


## 开关交互资格；关闭时立即隐藏提示，不改变实体的拾取或保存状态。
## @param enabled true 为允许检测和输入，false 为停止交互。返回 void。
func SetEnabled(enabled: bool) -> void:
	_enabled = enabled
	if not enabled and is_instance_valid(_prompt):
		_prompt.hide()


## 检查指定玩家是否能与本目标交互；供实体公开操作进行范围与状态校验。
## @param player 原 CharacterBody2D，须在 player 组、存活、可处理且位于检测区。
## @return 合法且在范围内返回 true；不要求本目标为最近目标，输入选择另行处理。
func CanInteract(player: Node2D) -> bool:
	if not _enabled or not is_inside_tree() or not can_process() or is_queued_for_deletion():
		return false
	if not is_instance_valid(_target) or not _target.is_inside_tree() or _target.is_queued_for_deletion():
		return false
	if not _target.is_visible_in_tree() or not _target.can_process():
		return false
	if not is_instance_valid(_area) or not _area.is_inside_tree() or not _is_available_player(player):
		return false
	return _area.monitoring and _area.overlaps_body(player)


func _process(_delta: float) -> void:
	if is_instance_valid(_prompt):
		var player := _find_player()
		_prompt.visible = player != null and _nearest_interaction(player) == self


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	var player := _find_player()
	if player == null or _nearest_interaction(player) != self:
		return
	# 先消费本次输入，再通知实体；领取后其他目标变可选，也不能共享这次按键。
	get_viewport().set_input_as_handled()
	SignalBus.InteractionRequested.emit(_target, player)


func _find_player() -> Node2D:
	if not is_instance_valid(_area):
		return null
	var nearest: Node2D = null
	var nearest_distance: float = INF
	for body in _area.get_overlapping_bodies():
		if CanInteract(body):
			var distance: float = _target.global_position.distance_squared_to(body.global_position)
			if distance < nearest_distance:
				nearest = body
				nearest_distance = distance
	return nearest


func _nearest_interaction(player: Node2D) -> ProximityInteraction:
	var nearest: ProximityInteraction = null
	var nearest_distance: float = INF
	for candidate in get_tree().get_nodes_in_group(INTERACTION_GROUP):
		if not candidate is ProximityInteraction or candidate.get_viewport() != get_viewport():
			continue
		if not candidate.CanInteract(player):
			continue
		var distance: float = candidate._target.global_position.distance_squared_to(player.global_position)
		# 相同距离用实例 ID 稳定选择，避免两个提示闪烁或同时亮起。
		if distance < nearest_distance or (distance == nearest_distance and (nearest == null or candidate.get_instance_id() < nearest.get_instance_id())):
			nearest = candidate
			nearest_distance = distance
	return nearest


func _is_available_player(player: Node2D) -> bool:
	if not is_instance_valid(player) or player.is_queued_for_deletion():
		return false
	if not player is CharacterBody2D or not player.is_in_group("player") or not player.can_process():
		return false
	var health: Variant = player.get("now_HP")
	return health == null or (health is float or health is int) and health > 0


func _interaction_key_label() -> String:
	for binding in InputMap.action_get_events("interact"):
		if binding is InputEventKey:
			var key: int = binding.physical_keycode if binding.physical_keycode != 0 else binding.keycode
			return OS.get_keycode_string(key)
	return "交互"
