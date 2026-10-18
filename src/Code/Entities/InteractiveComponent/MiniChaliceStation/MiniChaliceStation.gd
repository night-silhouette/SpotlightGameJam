extends Area2D
class_name MiniChaliceStation

## 微光小圣杯补水站：玩家靠近后可右键点击圣杯或提示按钮补满水量。
## 使用后圣杯光芒隐去。支持单次使用或配置定时刷新重置。

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
	add_to_group("touch_interactables")
	_sync_from_export_settings()
	_update_player_range()
	if prompt_button:
		prompt_button.button_mask = MOUSE_BUTTON_MASK_RIGHT
		prompt_button.pressed.connect(_on_prompt_pressed)
	_setup_reset_timer()
	_update_visual_state(is_available)

func _process(_delta: float) -> void:
	_update_player_range()
	if not _player_in_range or not is_available:
		return
	var bound_event := KeybindManager.GetPrimaryEventForAction(ExportSettings.interactable_action)
	prompt_button.button_mask = MOUSE_BUTTON_MASK_RIGHT
	if bound_event is InputEventMouseButton:
		prompt_button.button_mask |= 1 << (bound_event.button_index - 1)
	key_badge.text = KeybindManager.GetActionKeyBadgeText(ExportSettings.interactable_action, "右键")

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
	if not event.is_action_pressed(ExportSettings.interactable_action):
		return
	_update_player_range()
	if _player_in_range and is_available and is_instance_valid(_cached_player):
		if event is InputEventMouseButton and not _contains_world_point(get_global_mouse_position()):
			return
		_drink_chalice(_cached_player)
		get_viewport().set_input_as_handled()

## 尝试在世界坐标 world_pos 点击圣杯；interactor 为附近玩家，成功饮用返回 true。
func TryTouchInteract(world_pos: Vector2, interactor: Node2D) -> bool:
	_update_player_range()
	if not _player_in_range or not is_available or interactor != _cached_player:
		return false
	if not _contains_world_point(world_pos):
		return false
	_on_prompt_pressed()
	return true

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
				key_badge.text = KeybindManager.GetActionKeyBadgeText(ExportSettings.interactable_action, "右键")
		else:
			if prompt_container:
				prompt_container.visible = false

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

func _contains_world_point(world_pos: Vector2) -> bool:
	var art := $Sprite2D as Sprite2D
	return art.is_visible_in_tree() and art.get_rect().has_point(art.to_local(world_pos))

func _update_player_range() -> void:
	var previous_in_range := _player_in_range
	_cached_player = null
	var art := $Sprite2D as Sprite2D
	var rect := art.get_rect()
	var nearest_distance := ExportSettings.chalice_interact_distance
	for candidate in get_tree().get_nodes_in_group("player"):
		if not candidate is Node2D:
			continue
		var local_point := art.to_local(candidate.global_position)
		var closest := local_point.clamp(rect.position, rect.end)
		var distance: float = candidate.global_position.distance_to(art.to_global(closest))
		if distance <= nearest_distance:
			nearest_distance = distance
			_cached_player = candidate
	_player_in_range = is_instance_valid(_cached_player)
	if previous_in_range != _player_in_range:
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

## 实体数据导出。
## @return 包含位置、可用状态及剩余充能时间的字典。
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"is_available": is_available,
		"remaining_reset_time": _reset_timer.time_left if _reset_timer else 0.0
	}

## 实体数据加载。
## @param data 存档字典。
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
