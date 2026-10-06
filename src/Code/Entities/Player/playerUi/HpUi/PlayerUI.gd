extends CanvasLayer
class_name PlayerUI

## =============================================================================
## PlayerUI.gd - 玩家界面 HUD
## 负责显示生命值进度条、文本及状态提示，响应 SignalBus 全局生命值与状态事件
## =============================================================================

@onready var health_bar: ProgressBar = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var health_label: Label = $Control/MarginContainer/VBoxContainer/HealthBar/HealthLabel
@onready var drain_indicator: Label = $Control/MarginContainer/VBoxContainer/DrainIndicator
@onready var setting_button: Button = $Control/MarginContainer/VBoxContainer/SettingButton
@onready var virtual_joystick: Control = $Control/VirtualJoystick

@onready var right_action_buttons: Control = $Control/RightActionButtons
@onready var btn_jump: TouchActionButton = $Control/RightActionButtons/BtnJump
@onready var btn_dash: TouchActionButton = $Control/RightActionButtons/BtnDash

## 目标血量，用于平滑过渡动画（可选效果）
var _target_hp: float = 200.0
var _max_hp: float = 200.0

func _ready() -> void:
	_sync_mobile_ui_sizes()
	_check_mobile_controls()
	if SignalBus:
		SignalBus.PlayerHealthChanged.connect(_on_player_health_changed)
		SignalBus.StartPlayerHpDrain.connect(_on_start_player_hp_drain)
		SignalBus.StopPlayerHpDrain.connect(_on_stop_player_hp_drain)
	
	if ExportSettings:
		_max_hp = ExportSettings.player_max_hp
		_target_hp = _max_hp
	
	if setting_button:
		setting_button.pressed.connect(_on_setting_button_pressed)
	
	UpdateHealthDisplay(_target_hp, _max_hp)

func _on_setting_button_pressed() -> void:
	if SignalBus:
		SignalBus.SettingVisibilityRequested.emit(true)


func _sync_mobile_ui_sizes() -> void:
	if not ExportSettings:
		return

	if virtual_joystick:
		if "mobile_joystick_size" in ExportSettings and virtual_joystick.has_method("set_joystick_size"):
			virtual_joystick.set_joystick_size(ExportSettings.mobile_joystick_size)
		if "mobile_joystick_tip_size" in ExportSettings and virtual_joystick.has_method("set_tip_size"):
			virtual_joystick.set_tip_size(ExportSettings.mobile_joystick_tip_size)

	if btn_jump and "mobile_jump_button_radius" in ExportSettings:
		btn_jump.SetButtonRadius(ExportSettings.mobile_jump_button_radius)

	if btn_dash and "mobile_dash_button_radius" in ExportSettings:
		btn_dash.SetButtonRadius(ExportSettings.mobile_dash_button_radius)

func _check_mobile_controls() -> void:
	var is_android = (OS.get_name() == "Android")
	var force_debug = false
	if ExportSettings and "mobile_debug_force_touch_controls" in ExportSettings:
		force_debug = ExportSettings.mobile_debug_force_touch_controls

	var should_show = (is_android or force_debug)
	if virtual_joystick:
		virtual_joystick.visible = should_show
	if right_action_buttons:
		right_action_buttons.visible = should_show


func _process(delta: float) -> void:
	if health_bar:
		# 平滑插值动画让血条变动更加流畅
		if abs(health_bar.value - _target_hp) > 0.05:
			health_bar.value = move_toward(health_bar.value, _target_hp, 150.0 * delta)
		else:
			health_bar.value = _target_hp

## 更新血量显示界面的公共方法
## @param current_hp 当前生命值
## @param max_hp 最大生命值
func UpdateHealthDisplay(current_hp: float, max_hp: float) -> void:
	_target_hp = max(0.0, current_hp)
	_max_hp = max(1.0, max_hp)
	
	if health_bar:
		health_bar.max_value = _max_hp
	if health_label:
		health_label.text = "%d / %d HP" % [int(ceil(_target_hp)), int(_max_hp)]

func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	UpdateHealthDisplay(current_hp, max_hp)

func _on_start_player_hp_drain(_drain_rate: float) -> void:
	if drain_indicator:
		drain_indicator.visible = true

func _on_stop_player_hp_drain() -> void:
	if drain_indicator:
		drain_indicator.visible = false
