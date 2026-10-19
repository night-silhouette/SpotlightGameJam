extends CanvasLayer
class_name PlayerUI

## =============================================================================
## PlayerUI.gd - 玩家界面 HUD
## 负责显示生命值图标、文本及状态提示，响应 SignalBus 全局生命值与状态事件
## =============================================================================

const TouchLayoutManagerRef = preload("res://Code/Entities/Setting/TouchLayoutManager.gd")
const TOUCH_JUMP_ICON = preload("res://Art/New/component/移动端/IMG_9839_切割/05_右上图标_左.png")
const TOUCH_DASH_ICON = preload("res://Art/New/component/移动端/IMG_9839_切割/07_右下图标_左.png")
const TOUCH_INTERACT_ICON = preload("res://Art/New/component/移动端/IMG_9839_切割/06_右上图标_右.png")
const TOUCH_GRAPPLE_ICON = preload("res://Art/New/component/移动端/IMG_9839_切割/08_右下图标_右.png")

const HEALTH_FRAME_X = [25, 146, 258, 379, 503, 626]

@onready var low_health_sand: ColorRect = $Control/LowHealthSand
@onready var _sand_material: ShaderMaterial = low_health_sand.material as ShaderMaterial
@onready var health_icon: TextureRect = $Control/MarginContainer/VBoxContainer/HealthIcon
@onready var health_label: Label = $Control/MarginContainer/VBoxContainer/HealthLabel
@onready var drain_indicator: Label = $Control/MarginContainer/VBoxContainer/DrainIndicator
@onready var setting_button: TextureButton = $Control/SettingButton
@onready var debug_toggle: Button = $Control/DebugPanel/ToggleButton
@onready var debug_abilities: VBoxContainer = $Control/DebugPanel/Abilities
@onready var double_jump_toggle: CheckButton = $Control/DebugPanel/Abilities/DoubleJump
@onready var rope_toggle: CheckButton = $Control/DebugPanel/Abilities/Rope
@onready var debug_flight_toggle: CheckButton = $Control/DebugPanel/Abilities/DebugFlight
@onready var virtual_joystick: Control = $Control/VirtualJoystick
@onready var crown_icon: TextureRect = $Control/RelicIcons/Crown
@onready var codex_icon: TextureRect = $Control/RelicIcons/Codex
@onready var bones_icon: TextureRect = $Control/RelicIcons/Bones
@onready var sun_key_icon: TextureRect = $Control/KeyIcons/Sun
@onready var moon_key_icon: TextureRect = $Control/KeyIcons/Moon
@onready var weave_key_icon: TextureRect = $Control/KeyIcons/Weave
@onready var ending_overlay: ColorRect = $Control/EndingOverlay

@onready var right_action_buttons: Control = $Control/RightActionButtons
@onready var btn_jump: TouchActionButton = $Control/RightActionButtons/BtnJump
@onready var btn_dash: TouchActionButton = $Control/RightActionButtons/BtnDash
@onready var btn_interact: TouchActionButton = $Control/RightActionButtons/BtnInteract

var touch_interaction_mode: bool = false

## 当前显示的血量
var _target_hp: float = 200.0
var _max_hp: float = 200.0
var _sand_health_valid: bool = true
var _sand_target: float = 0.0
var _sand_intensity: float = 0.0
var _sand_elapsed: float = 0.0

func _process(delta: float) -> void:
	_update_sand_target()
	if _sand_target <= 0.0 and _sand_intensity <= 0.0:
		return
	if not visible or not $Control.is_visible_in_tree():
		return
	var duration: float = ExportSettings.low_health_sand_fade_duration
	_sand_intensity = move_toward(_sand_intensity, _sand_target, delta / duration) if duration > 0.0 else _sand_target
	if _sand_intensity <= 0.0:
		_clear_sand_overlay()
		return
	low_health_sand.show()
	_sand_elapsed += delta
	_sand_material.set_shader_parameter("intensity", _sand_intensity)
	_sand_material.set_shader_parameter("elapsed", _sand_elapsed)
	_sand_material.set_shader_parameter("max_opacity", clampf(ExportSettings.low_health_sand_max_opacity, 0.0, 1.0))
	_sand_material.set_shader_parameter("edge_width", ExportSettings.low_health_sand_edge_width)
	_sand_material.set_shader_parameter("pulse_speed", ExportSettings.low_health_sand_pulse_speed)
	_sand_material.set_shader_parameter("pulse_amount", ExportSettings.low_health_sand_pulse_amount)
	_sand_material.set_shader_parameter("grain_size", ExportSettings.low_health_sand_grain_size)
	_sand_material.set_shader_parameter("flow_speed", ExportSettings.low_health_sand_flow_speed)
	_sand_material.set_shader_parameter("sand_color", ExportSettings.low_health_sand_color)
	_sand_material.set_shader_parameter("dark_color", ExportSettings.low_health_sand_dark_color)

func _update_sand_target() -> void:
	if not _sand_health_valid or _target_hp <= 0.0 or not ExportSettings.low_health_sand_enabled or ExportSettings.low_health_sand_max_opacity <= 0.0:
		_clear_sand_overlay()
		return
	var threshold: float = clampf(ExportSettings.low_health_sand_threshold, 0.0, 1.0)
	var ratio: float = _target_hp / _max_hp
	_sand_target = 0.0
	if threshold > 0.0 and ratio < threshold:
		_sand_target = lerpf(0.28, 1.0, clampf(1.0 - ratio / threshold, 0.0, 1.0))

func _clear_sand_overlay() -> void:
	if _sand_material and (_sand_intensity > 0.0 or low_health_sand.visible):
		_sand_material.set_shader_parameter("intensity", 0.0)
	_sand_target = 0.0
	_sand_intensity = 0.0
	_sand_elapsed = 0.0
	low_health_sand.hide()

func _ready() -> void:
	btn_jump.button_icon = TOUCH_JUMP_ICON
	btn_dash.button_icon = TOUCH_DASH_ICON
	_update_touch_interaction_icon()
	_sync_mobile_ui_sizes()
	_apply_touch_layout()
	$Control.resized.connect(_apply_touch_layout)
	SignalBus.TouchLayoutChanged.connect(_apply_touch_layout)
	_check_mobile_controls()
	btn_interact.pressed_once.connect(_toggle_touch_interaction_mode)
	if SignalBus:
		SignalBus.PlayerHealthChanged.connect(_on_player_health_changed)
		SignalBus.StartPlayerHpDrain.connect(_on_start_player_hp_drain)
		SignalBus.StopPlayerHpDrain.connect(_on_stop_player_hp_drain)
		SignalBus.PlayerAbilitiesChanged.connect(_on_player_abilities_changed)
		SignalBus.PlayerDebugFlightChanged.connect(_on_debug_flight_changed)
		SignalBus.PlayerRelicsChanged.connect(_on_player_relics_changed)
		SignalBus.Level2StateChanged.connect(_on_level2_state_changed)
		SignalBus.LakeEndingTriggered.connect(_on_lake_ending_triggered)
	
	if ExportSettings:
		_max_hp = ExportSettings.player_max_hp
		_target_hp = _max_hp
	
	if setting_button:
		setting_button.pressed.connect(_on_setting_button_pressed)
	debug_toggle.pressed.connect(_on_debug_toggle_pressed)
	double_jump_toggle.toggled.connect(_on_double_jump_toggled)
	rope_toggle.toggled.connect(_on_rope_toggled)
	debug_flight_toggle.toggled.connect(_on_debug_flight_toggled)
	crown_icon.texture = ExportSettings.sunken_crown_texture
	codex_icon.texture = ExportSettings.starseekers_codex_texture
	bones_icon.texture = ExportSettings.scarred_bones_texture
	SignalBus.PlayerAbilityStateRequested.emit()
	SignalBus.PlayerDebugFlightStateRequested.emit()
	SignalBus.PlayerRelicStateRequested.emit()
	SignalBus.Level2StateRequested.emit()
	UpdateHealthDisplay(_target_hp, _max_hp)

func _on_debug_toggle_pressed() -> void:
	debug_abilities.visible = not debug_abilities.visible
	debug_toggle.text = "调试能力 ▲" if debug_abilities.visible else "调试能力 ▼"
	if debug_abilities.visible:
		SignalBus.PlayerAbilityStateRequested.emit()
		SignalBus.PlayerDebugFlightStateRequested.emit()

func _on_double_jump_toggled(enabled: bool) -> void:
	SignalBus.PlayerAbilityChangeRequested.emit(&"double_jump", enabled)

func _on_rope_toggled(enabled: bool) -> void:
	SignalBus.PlayerAbilityChangeRequested.emit(&"rope", enabled)

func _on_debug_flight_toggled(enabled: bool) -> void:
	SignalBus.PlayerDebugFlightChangeRequested.emit(enabled)

func _on_debug_flight_changed(enabled: bool) -> void:
	debug_flight_toggle.set_pressed_no_signal(enabled)

func _on_player_abilities_changed(double_jump_enabled: bool, rope_enabled: bool) -> void:
	double_jump_toggle.set_pressed_no_signal(double_jump_enabled)
	rope_toggle.set_pressed_no_signal(rope_enabled)

func _on_player_relics_changed(crown: bool, codex: bool, bones: bool) -> void:
	crown_icon.visible = crown
	codex_icon.visible = codex
	bones_icon.visible = bones

func _on_level2_state_changed(level: Node2D) -> void:
	var carried: Array[String] = level.keys
	var submitted: Array[String] = level.submitted_keys
	sun_key_icon.visible = "sun" in carried and not "sun" in submitted
	moon_key_icon.visible = "moon" in carried and not "moon" in submitted
	weave_key_icon.visible = "weave" in carried and not "weave" in submitted

func _on_lake_ending_triggered() -> void:
	ending_overlay.visible = true

func _on_setting_button_pressed() -> void:
	if SignalBus:
		SignalBus.SettingVisibilityRequested.emit(true)


func _toggle_touch_interaction_mode() -> void:
	touch_interaction_mode = not touch_interaction_mode
	_update_touch_interaction_icon()

func _update_touch_interaction_icon() -> void:
	btn_interact.button_text = "钩" if touch_interaction_mode else "交"
	btn_interact.button_icon = TOUCH_GRAPPLE_ICON if touch_interaction_mode else TOUCH_INTERACT_ICON

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

func _apply_touch_layout() -> void:
	var viewport_size: Vector2 = $Control.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var half_width: float = viewport_size.x * 0.5
	var layout: Dictionary = TouchLayoutManagerRef.GetLayout(viewport_size)
	var buttons: Dictionary = {"jump": btn_jump, "dash": btn_dash, "interact": btn_interact}
	var base_radii: Dictionary = {
		"jump": ExportSettings.mobile_jump_button_radius,
		"dash": ExportSettings.mobile_dash_button_radius,
		"interact": 44.0,
	}
	for action in TouchLayoutManagerRef.ACTIONS:
		var button: TouchActionButton = buttons[action]
		var entry: Dictionary = layout[action]
		# 触控圆比绘制圆大 25%；先收紧半径，再约束中心，保证触控和 Control 均留在右半屏。
		var radius: float = minf(base_radii[action] * entry["scale"], minf(half_width, viewport_size.y) / 2.5)
		button.SetButtonRadius(radius)
		var hit_radius: float = button.button_radius * 1.25
		var center := Vector2(
			clampf(half_width * entry["x"], hit_radius, half_width - hit_radius),
			clampf(viewport_size.y * entry["y"], hit_radius, viewport_size.y - hit_radius)
		)
		button.position = center + Vector2(half_width, 0.0) - right_action_buttons.position - button.size * 0.5

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


## 更新血量显示界面的公共方法
## @param current_hp 当前生命值
## @param max_hp 最大生命值
func UpdateHealthDisplay(current_hp: float, max_hp: float) -> void:
	_sand_health_valid = is_finite(current_hp) and is_finite(max_hp) and max_hp > 0.0
	_max_hp = maxf(1.0, max_hp)
	_target_hp = clampf(current_hp, 0.0, _max_hp)
	_update_sand_target()
	# 前五帧每 20% 一档，最后一帧为空瓶；统一裁切尺寸避免切换时跳动。
	var frame: int = 5 - clampi(int(ceil(_target_hp / _max_hp * 5.0)), 0, 5)
	var atlas := health_icon.texture as AtlasTexture
	atlas.region = Rect2(HEALTH_FRAME_X[frame], 33, 106, 221)
	if health_label:
		health_label.text = "%d / %d" % [int(ceil(_target_hp)), int(_max_hp)]

func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	UpdateHealthDisplay(current_hp, max_hp)

func _on_start_player_hp_drain(_drain_rate: float) -> void:
	if drain_indicator:
		drain_indicator.visible = true

func _on_stop_player_hp_drain() -> void:
	if drain_indicator:
		drain_indicator.visible = false
