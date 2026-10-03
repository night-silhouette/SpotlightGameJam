extends StaticBody2D
class_name CrumblingPlatform

## =============================================================================
## CrumblingPlatform.gd - 易碎平台交互组件
## 玩家站立踩踏后触发短暂震颤开裂，达到延迟时间后碎裂下坠/消失（碰撞关闭）
## 经过设定重置秒数后，原地淡入重生复原。
## =============================================================================

@export_category("Crumbling Platform Settings")
## 平台尺寸 (宽, 高)
@export var platform_size: Vector2 = Vector2(80.0, 16.0):
	set(value):
		platform_size = value
		_update_dimensions()

## 踩踏后开始震颤到完全塌陷的时长 (秒)
@export var crumble_delay: float = 0.6
## 塌陷碎裂后到原地重生的时长 (秒)
@export var respawn_time: float = 3.0
## 震颤剧烈程度幅度 (像素)
@export var shake_offset: float = 2.5

@onready var solid_collision: CollisionShape2D = $SolidCollision
@onready var trigger_area: Area2D = $TriggerArea
@onready var trigger_collision: CollisionShape2D = $TriggerArea/TriggerCollision
@onready var visual_root: Node2D = $VisualRoot
@onready var visual_rect: ColorRect = $VisualRoot/VisualRect
@onready var crack_line: Line2D = $VisualRoot/CrackLine

enum PlatformState { INTACT, CRUMBLING, COLLAPSED }

var current_state: PlatformState = PlatformState.INTACT
var _original_visual_pos: Vector2 = Vector2.ZERO
var _shake_tween: Tween = null
var _respawn_timer: Timer = null

func _ready() -> void:
	_sync_from_export_settings()
	_update_dimensions()
	_original_visual_pos = visual_root.position
	
	if trigger_area:
		trigger_area.body_entered.connect(_on_trigger_body_entered)
	
	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_on_respawn_timeout)
	add_child(_respawn_timer)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		crumble_delay = ExportSettings.crumble_delay
		respawn_time = ExportSettings.crumble_respawn_time
		shake_offset = ExportSettings.crumble_shake_offset

func _update_dimensions() -> void:
	if not is_inside_tree():
		return
	
	if solid_collision:
		var rect = RectangleShape2D.new()
		rect.size = platform_size
		solid_collision.shape = rect

	if trigger_collision:
		var trigger_rect = RectangleShape2D.new()
		# 触发区向上突出 4 像素，专门用于感应玩家脚底踩踏
		trigger_rect.size = Vector2(platform_size.x - 4.0, platform_size.y + 6.0)
		trigger_collision.shape = trigger_rect
		trigger_collision.position = Vector2(0.0, -3.0)

	if visual_rect:
		visual_rect.offset_left = -platform_size.x * 0.5
		visual_rect.offset_right = platform_size.x * 0.5
		visual_rect.offset_top = -platform_size.y * 0.5
		visual_rect.offset_bottom = platform_size.y * 0.5

	if crack_line:
		crack_line.clear_points()
		crack_line.add_point(Vector2(-platform_size.x * 0.35, -platform_size.y * 0.2))
		crack_line.add_point(Vector2(-platform_size.x * 0.05, platform_size.y * 0.25))
		crack_line.add_point(Vector2(platform_size.x * 0.3, -platform_size.y * 0.1))

func _on_trigger_body_entered(body: Node2D) -> void:
	if current_state != PlatformState.INTACT:
		return
	if body.is_in_group("player") or body is CharacterBody2D:
		_start_crumble()

func _start_crumble() -> void:
	current_state = PlatformState.CRUMBLING
	if SignalBus:
		SignalBus.PlatformCracked.emit(self)
	
	if crack_line:
		crack_line.visible = true
	
	# 启动高频震颤 Tween
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	
	_shake_tween = create_tween().set_loops(int(crumble_delay / 0.06))
	_shake_tween.tween_property(visual_root, "position", _original_visual_pos + Vector2(randf_range(-shake_offset, shake_offset), randf_range(-1.0, 1.0)), 0.03)
	_shake_tween.tween_property(visual_root, "position", _original_visual_pos, 0.03)
	
	get_tree().create_timer(crumble_delay).timeout.connect(_collapse)

func _collapse() -> void:
	if current_state != PlatformState.CRUMBLING:
		return
	
	current_state = PlatformState.COLLAPSED
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()
	visual_root.position = _original_visual_pos

	# 关闭实体碰撞
	solid_collision.set_deferred("disabled", true)
	trigger_collision.set_deferred("disabled", true)

	if SignalBus:
		SignalBus.PlatformCollapsed.emit(self)

	# 播放下坠破碎淡出演出
	var collapse_tween = create_tween().set_parallel(true)
	collapse_tween.tween_property(visual_root, "position:y", _original_visual_pos.y + 24.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	collapse_tween.tween_property(visual_root, "modulate:a", 0.0, 0.25)
	
	# 启动重生计时
	_respawn_timer.start(respawn_time)

func _on_respawn_timeout() -> void:
	# 复原位置与透明度并渐显
	visual_root.position = _original_visual_pos
	visual_root.modulate.a = 0.0
	if crack_line:
		crack_line.visible = false
	
	var respawn_tween = create_tween()
	respawn_tween.tween_property(visual_root, "modulate:a", 1.0, 0.35)
	respawn_tween.finished.connect(func():
		current_state = PlatformState.INTACT
		solid_collision.set_deferred("disabled", false)
		trigger_collision.set_deferred("disabled", false)
		if SignalBus:
			SignalBus.PlatformRespawned.emit(self)
	)

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"current_state": int(current_state),
		"remaining_respawn_time": _respawn_timer.time_left if _respawn_timer else 0.0
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("current_state"):
		var state_val = data["current_state"]
		if state_val == PlatformState.COLLAPSED:
			_collapse()
			if data.has("remaining_respawn_time") and data["remaining_respawn_time"] > 0:
				_respawn_timer.start(data["remaining_respawn_time"])
		else:
			current_state = PlatformState.INTACT
			solid_collision.set_deferred("disabled", false)
			trigger_collision.set_deferred("disabled", false)
			visual_root.position = _original_visual_pos
			visual_root.modulate.a = 1.0
			if crack_line:
				crack_line.visible = false
