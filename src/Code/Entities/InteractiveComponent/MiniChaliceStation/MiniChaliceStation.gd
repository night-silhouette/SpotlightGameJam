extends Area2D
class_name MiniChaliceStation

## =============================================================================
## MiniChaliceStation.gd - 微光小圣杯补水站
## 关卡中途补水设施：靠近后按下交互键 [F] 瞬间将水量/生命值回满至 100%
## 使用后圣杯光芒隐去。支持单次使用或配置定时刷新重置。
## =============================================================================

@export_category("Chalice Settings")
## 重置刷新冷却时间 (秒)；若 <= 0 则为单次使用，不重置
@export var reset_time: float = 10.0
## 是否在关卡初始状态可用
@export var is_available: bool = true:
	set(value):
		is_available = value
		if is_node_ready():
			_update_visual_state(is_available)

## 补水比例 (1.0 代表回满至 100%)
@export var heal_ratio: float = 1.0

const KeybindManagerRef = preload("res://Code/Entities/Setting/KeybindManager.gd")

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@onready var chalice_base: ColorRect = $ChaliceBase
@onready var glow_cup: ColorRect = $GlowCup
@onready var light_glow: PointLight2D = $LightGlow
@onready var prompt_container: Control = $PromptContainer
@onready var prompt_button: Button = $PromptContainer/PromptButton
@onready var key_badge: Label = $PromptContainer/HBox/KeyBadge
@onready var action_label: Label = $PromptContainer/HBox/ActionLabel
@onready var cooldown_label: Label = $CooldownLabel

var _reset_timer: Timer = null
var _glow_tween: Tween = null
var _player_in_range: bool = false
var _cached_player: Node2D = null

func _ready() -> void:
	_sync_from_export_settings()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt_button:
		prompt_button.pressed.connect(_on_prompt_pressed)
	if SignalBus:
		SignalBus.KeybindChanged.connect(_on_keybind_changed)
	_setup_reset_timer()

	_update_visual_state(is_available)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		reset_time = ExportSettings.chalice_reset_time
		heal_ratio = ExportSettings.chalice_heal_ratio

func _setup_reset_timer() -> void:
	_reset_timer = Timer.new()
	_reset_timer.one_shot = true
	_reset_timer.timeout.connect(_on_reset_timer_timeout)
	add_child(_reset_timer)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _player_in_range and is_available and is_instance_valid(_cached_player):
			get_viewport().set_input_as_handled()
			_drink_chalice(_cached_player)

## 鼠标点击提示 UI 触发饮用交互
func _on_prompt_pressed() -> void:
	if _player_in_range and is_available and is_instance_valid(_cached_player):
		_drink_chalice(_cached_player)

func _update_visual_state(available: bool) -> void:
	if not is_inside_tree():
		return
	
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()

	if available:
		glow_cup.color = Color(0.2, 0.85, 1.0, 0.9)
		if light_glow:
			light_glow.enabled = true
		if cooldown_label:
			cooldown_label.visible = false
		if _player_in_range:
			if prompt_container:
				prompt_container.visible = true
			if action_label:
				action_label.text = "饮用"
			if key_badge:
				key_badge.text = KeybindManagerRef.GetActionKeyBadgeText(&"interact", "F")
		else:

			if prompt_container:
				prompt_container.visible = false
		
		# 循环呼吸闪烁微光
		_glow_tween = create_tween().set_loops()
		_glow_tween.tween_property(glow_cup, "modulate:a", 0.5, 0.8).set_trans(Tween.TRANS_SINE)
		_glow_tween.tween_property(glow_cup, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	else:
		glow_cup.color = Color(0.35, 0.35, 0.4, 0.3)
		glow_cup.modulate.a = 1.0
		if light_glow:
			light_glow.enabled = false
		if prompt_container:
			prompt_container.visible = false
		if reset_time > 0:
			if cooldown_label:
				cooldown_label.visible = true
				cooldown_label.text = "充能中..."
		else:
			if cooldown_label:
				cooldown_label.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body is CharacterBody2D:
		_player_in_range = true
		_cached_player = body
		_update_visual_state(is_available)

func _on_body_exited(body: Node2D) -> void:
	if body == _cached_player:
		_player_in_range = false
		_cached_player = null
		_update_visual_state(is_available)

func _on_keybind_changed(action_name: StringName, _event_desc: String) -> void:
	if action_name == &"interact":
		_update_visual_state(is_available)

func _drink_chalice(player: Node2D) -> void:

	is_available = false
	_update_visual_state(false)
	
	# 回复水量/生命值至 100%
	if player.has_method("Heal"):
		var max_hp = player.Max_HP if "Max_HP" in player else 200.0
		player.Heal(max_hp * heal_ratio)
	elif "now_HP" in player and "Max_HP" in player:
		player.now_HP = player.Max_HP * heal_ratio
	
	# 通过 SignalBus 广播小圣杯被使用
	if SignalBus:
		SignalBus.ChaliceStationUsed.emit(self)
	
	# 启动定时充能重置
	if reset_time > 0.0:
		_reset_timer.start(reset_time)

func _on_reset_timer_timeout() -> void:
	is_available = true
	_update_visual_state(true)

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"is_available": is_available,
		"remaining_reset_time": _reset_timer.time_left if _reset_timer else 0.0
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("is_available"):
		is_available = data["is_available"]
		_update_visual_state(is_available)
	if data.has("remaining_reset_time") and data["remaining_reset_time"] > 0:
		is_available = false
		_update_visual_state(false)
		if _reset_timer:
			_reset_timer.start(data["remaining_reset_time"])
