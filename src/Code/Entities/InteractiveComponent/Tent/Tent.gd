extends Area2D
class_name Tent

## 帐篷重生点：玩家靠近时可右键点击帐篷或上方提示按钮激活。
## 激活后广播全局 TentActivated 信号，其他帐篷自动取消激活。

@export_category("Tent Settings")
## 是否在初始时即为当前激活的重生点
@export var is_active: bool = false:
	set(value):
		is_active = value
		if is_node_ready():
			_update_visual_state()

## 重生点相对帐篷的局部位置偏移
@export var respawn_offset: Vector2 = Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var tent_sprite: CanvasItem = $TentVisual
@onready var light_glow: PointLight2D = $LightGlow
@onready var prompt_container: Control = $PromptContainer
@onready var prompt_button: Button = $PromptContainer/PromptButton
@onready var key_badge: Label = $PromptContainer/HBox/KeyBadge
@onready var action_label: Label = $PromptContainer/HBox/ActionLabel
@onready var status_label: Label = $StatusLabel

var _player_in_range: bool = false
var _cached_player: Node2D = null
var _glow_tween: Tween = null

func _ready() -> void:
	_sync_from_export_settings()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt_button:
		prompt_button.button_mask = MOUSE_BUTTON_MASK_RIGHT
		prompt_button.pressed.connect(_on_prompt_pressed)
	if SignalBus:
		SignalBus.TentActivated.connect(_on_tent_activated_externally)
	_update_visual_state()

func _process(_delta: float) -> void:
	if not _player_in_range:
		return
	var bound_event := KeybindManager.GetPrimaryEventForAction(ExportSettings.interactable_action)
	prompt_button.button_mask = MOUSE_BUTTON_MASK_RIGHT
	if bound_event is InputEventMouseButton:
		prompt_button.button_mask |= 1 << (bound_event.button_index - 1)
	key_badge.text = KeybindManager.GetActionKeyBadgeText(ExportSettings.interactable_action, "右键")

func _sync_from_export_settings() -> void:
	if ExportSettings:
		if "tent_respawn_offset" in ExportSettings:
			respawn_offset = ExportSettings.tent_respawn_offset
		if "tent_interaction_size" in ExportSettings and collision_shape and collision_shape.shape is RectangleShape2D:
			(collision_shape.shape as RectangleShape2D).size = ExportSettings.tent_interaction_size

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(ExportSettings.interactable_action):
		return
	if _player_in_range and is_instance_valid(_cached_player):
		if event is InputEventMouseButton:
			var shape := collision_shape.shape as RectangleShape2D
			var point := collision_shape.to_local(get_global_mouse_position())
			if not shape or not Rect2(-shape.size * 0.5, shape.size).has_point(point):
				return
		ActivateTent()
		get_viewport().set_input_as_handled()

func _on_prompt_pressed() -> void:
	if _player_in_range and is_instance_valid(_cached_player):
		ActivateTent()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		_player_in_range = true
		_cached_player = body
		_update_visual_state()

func _on_body_exited(body: Node2D) -> void:
	if body == _cached_player:
		_player_in_range = false
		_cached_player = null
		_update_visual_state()

## 激活当前帐篷为重生点。
func ActivateTent() -> void:
	is_active = true
	_update_visual_state()
	var spawn_pos = GetRespawnPosition()
	if SignalBus:
		SignalBus.TentActivated.emit(self, spawn_pos)

## 获取此帐篷对应的全局重生位置。
## @return 重生点的世界坐标。
func GetRespawnPosition() -> Vector2:
	return global_position + respawn_offset

func _on_tent_activated_externally(tent_node: Node2D, _spawn_pos: Vector2) -> void:
	if tent_node != self:
		if is_active:
			is_active = false
			_update_visual_state()

func _update_visual_state() -> void:
	if not is_inside_tree():
		return
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	# 更新光照与呼吸动画
	if light_glow:
		light_glow.enabled = is_active
	if is_active:
		if light_glow:
			_glow_tween = create_tween().set_loops()
			_glow_tween.tween_property(light_glow, "energy", 1.4, 0.8).set_trans(Tween.TRANS_SINE)
			_glow_tween.tween_property(light_glow, "energy", 0.8, 0.8).set_trans(Tween.TRANS_SINE)
		if status_label:
			status_label.visible = true
			status_label.text = "重生点已设置"
	else:
		if status_label:
			status_label.visible = false

	# 交互提示与小圣杯保持一致
	if _player_in_range:
		if prompt_container:
			prompt_container.visible = true
		if action_label:
			action_label.text = "重设重生点" if is_active else "设为重生点"
		if key_badge:
			key_badge.text = KeybindManager.GetActionKeyBadgeText(ExportSettings.interactable_action, "右键")
	else:
		if prompt_container:
			prompt_container.visible = false

## 导出帐篷持久化数据。
## @return 位置、重生偏移和激活状态组成的字典。
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"respawn_offset_x": respawn_offset.x,
		"respawn_offset_y": respawn_offset.y,
		"respawn_world_x": GetRespawnPosition().x,
		"respawn_world_y": GetRespawnPosition().y,
		"is_active": is_active
	}

## 加载帐篷持久化数据。
## @param data 存档字典。
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("respawn_offset_x") and data.has("respawn_offset_y"):
		respawn_offset = Vector2(data["respawn_offset_x"], data["respawn_offset_y"])
	if data.has("is_active"):
		is_active = data["is_active"]
		_update_visual_state()
		if is_active and SignalBus:
			SignalBus.TentActivated.emit(self, GetRespawnPosition())
