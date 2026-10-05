extends Area2D
class_name Tent

## =============================================================================
## Tent.gd - 帐篷重生点交互组件
## 无实体碰撞体积（Area2D），支持键盘 [F] 键或点击上方 UI 交互。
## 交互后激活帐篷并将其设为玩家死亡重生点，广播全局 TentActivated 信号；
## 其他已激活帐篷收到信号后自动切换为未激活状态，确保全局仅一个活跃帐篷。
## =============================================================================

@export_category("Tent Settings")
## 是否在初始时即为当前激活的重生点
@export var is_active: bool = false:
	set(value):
		is_active = value
		if is_node_ready():
			_update_visual_state()

## 重生点相对帐篷的局部位置偏移
@export var respawn_offset: Vector2 = Vector2.ZERO

const KeybindManagerRef = preload("res://Code/Entities/Setting/KeybindManager.gd")

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
		prompt_button.pressed.connect(_on_prompt_pressed)
	
	if SignalBus:
		SignalBus.TentActivated.connect(_on_tent_activated_externally)
		SignalBus.KeybindChanged.connect(_on_keybind_changed)

	_update_visual_state()


func _sync_from_export_settings() -> void:
	if ExportSettings:
		if "tent_respawn_offset" in ExportSettings:
			respawn_offset = ExportSettings.tent_respawn_offset
		if "tent_interaction_size" in ExportSettings and collision_shape and collision_shape.shape is RectangleShape2D:
			(collision_shape.shape as RectangleShape2D).size = ExportSettings.tent_interaction_size

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _player_in_range and is_instance_valid(_cached_player):
			get_viewport().set_input_as_handled()
			ActivateTent()

## 鼠标点击提示 UI 触发交互
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

## 激活当前帐篷为重生点
func ActivateTent() -> void:
	is_active = true
	_update_visual_state()
	
	var spawn_pos = GetRespawnPosition()
	if SignalBus:
		SignalBus.TentActivated.emit(self, spawn_pos)

## 获取此帐篷对应的全局重生位置
func GetRespawnPosition() -> Vector2:
	return global_position + respawn_offset

## 监听外部帐篷激活事件，若是其他帐篷被激活则自身变为非活跃
func _on_tent_activated_externally(tent_node: Node2D, _spawn_pos: Vector2) -> void:
	if tent_node != self:
		if is_active:
			is_active = false
			_update_visual_state()

func _on_keybind_changed(action_name: StringName, _event_desc: String) -> void:
	if action_name == &"interact":
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

	# 交互 UI 提示（样式与 MiniChaliceStation 保持一致）
	if _player_in_range:
		if prompt_container:
			prompt_container.visible = true
		if action_label:
			action_label.text = "重设重生点" if is_active else "设为重生点"
		if key_badge:
			key_badge.text = KeybindManagerRef.GetActionKeyBadgeText(&"interact", "F")
	else:

		if prompt_container:
			prompt_container.visible = false

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"is_active": is_active
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("is_active"):
		is_active = data["is_active"]
		_update_visual_state()
