extends StaticBody2D
class_name WaterFlowArea

## =============================================================================
## WaterFlowArea.gd - 流水区域交互组件
## 默认状态为坚固刚体地形；靠近后按 E 键使用流水符文转化为流体状态。
## 处于流体状态时，玩家进入该区域会顺着进入方向获得强力喷射加速。
## =============================================================================

@export_category("WaterFlowArea Settings")
## 区域尺寸 (宽, 高)
@export var area_size: Vector2 = Vector2(160.0, 100.0):
	set(value):
		area_size = value
		_update_dimensions()

## 初始状态是否为流体 (默认 false 为普通实体刚体)
@export var is_fluid: bool = false:
	set(value):
		is_fluid = value
		if is_node_ready():
			_apply_state(is_fluid)

## 玩家进入流体时获得的加速倍率
@export var boost_multiplier: float = 1.6
## 玩家进入流体时保证的最低爆发速度
@export var min_boost_speed: float = 480.0
## 靠近使用水符文石交互的有效距离
@export var interact_radius: float = 120.0

@onready var solid_collision: CollisionShape2D = $SolidCollision
@onready var fluid_area: Area2D = $FluidArea
@onready var fluid_collision: CollisionShape2D = $FluidArea/FluidCollision
@onready var visual_rect: ColorRect = $VisualRect
@onready var prompt_label: Label = $PromptLabel

var _player_in_range: bool = false
var _cached_player: CharacterBody2D = null
var _bodies_in_water: Array[CharacterBody2D] = []

func _ready() -> void:
	_sync_from_export_settings()
	_update_dimensions()
	_apply_state(is_fluid)

	if fluid_area:
		fluid_area.body_entered.connect(_on_fluid_area_body_entered)
		fluid_area.body_exited.connect(_on_fluid_area_body_exited)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		boost_multiplier = ExportSettings.water_flow_speed_multiplier
		min_boost_speed = ExportSettings.water_flow_min_speed
		interact_radius = ExportSettings.water_flow_interact_distance

func _update_dimensions() -> void:
	if not is_inside_tree():
		return

	var rect_shape = RectangleShape2D.new()
	rect_shape.size = area_size

	if solid_collision:
		solid_collision.shape = rect_shape
	if fluid_collision:
		fluid_collision.shape = rect_shape

	if visual_rect:
		visual_rect.size = area_size
		visual_rect.position = -area_size * 0.5

	if prompt_label:
		prompt_label.position = Vector2(-prompt_label.size.x * 0.5, -area_size.y * 0.5 - 28.0)

## 将流水区域切换为流体或固态刚体状态
## @param to_fluid 是否切换为流体
func SetFluidState(to_fluid: bool) -> void:
	is_fluid = to_fluid
	_apply_state(is_fluid)

func _apply_state(fluid: bool) -> void:
	if not is_inside_tree():
		return

	if fluid:
		# 转换为流体：关闭实体阻挡碰撞，启用感应触发 Area
		solid_collision.set_deferred("disabled", true)
		fluid_collision.set_deferred("disabled", false)
		visual_rect.color = Color(0.15, 0.65, 0.95, 0.45) # 澄澈流体半透水蓝
		SignalBus.RuneWallConverted.emit(self, Vector2.UP)
	else:
		# 恢复为普通刚体：开启实体碰撞，关闭流体感应
		solid_collision.set_deferred("disabled", false)
		fluid_collision.set_deferred("disabled", true)
		visual_rect.color = Color(0.28, 0.42, 0.55, 1.0) # 固态符文石砖青灰色
		# 若凝固时有玩家还在流体中，清除其在流体中的状态
		_clear_all_bodies_in_water()

## 切换符文流水/凝固状态的公共方法
func ToggleRuneFluid() -> void:
	SetFluidState(not is_fluid)
	_update_prompt(true)

func _toggle_rune_fluid() -> void:
	ToggleRuneFluid()

func _physics_process(_delta: float) -> void:
	_check_player_distance()

func _check_player_distance() -> void:
	if not is_instance_valid(_cached_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_cached_player = players[0] as CharacterBody2D

	if not is_instance_valid(_cached_player):
		_player_in_range = false
		_update_prompt(false)
		return

	var dist = global_position.distance_to(_cached_player.global_position)
	var in_range = dist <= interact_radius

	_player_in_range = in_range
	_update_prompt(_player_in_range)

func _update_prompt(show_it: bool) -> void:
	if not prompt_label:
		return

	if not show_it or not is_instance_valid(_cached_player):
		prompt_label.visible = false
		return

	prompt_label.visible = true

	# 检查当前玩家交互范围内是否同时存在多个流水区域
	var nearby_count = 0
	var all_areas = get_tree().get_nodes_in_group("water_flow")
	var p_pos = _cached_player.global_position

	for area in all_areas:
		if area is WaterFlowArea and is_instance_valid(area):
			if p_pos.distance_to(area.global_position) <= area.interact_radius:
				nearby_count += 1

	var action_name = "凝固" if is_fluid else "水化"

	if nearby_count > 1:
		# 存在多个流水区域冲突，计算该区域相对玩家的大致方向提示
		var to_self = global_position - p_pos
		var dir_hint = ""
		if abs(to_self.x) >= abs(to_self.y):
			dir_hint = "D+E" if to_self.x > 0 else "A+E"
		else:
			dir_hint = "S+E" if to_self.y > 0 else "W+E"
		prompt_label.text = "[%s] 流水符文%s" % [dir_hint, action_name]
	else:
		prompt_label.text = "[E] 流水符文%s" % action_name

func _on_fluid_area_body_entered(body: Node2D) -> void:
	if not is_fluid:
		return

	if body.is_in_group("player") and body is CharacterBody2D:
		var player_body = body as CharacterBody2D

		# 记录并获取进入时的速度方向与大小
		var enter_velocity = player_body.velocity
		var current_speed = enter_velocity.length()

		var boost_dir = enter_velocity.normalized()
		# 若玩家几乎是静止蹭入的，按照玩家面朝方向给予推力
		if current_speed < 10.0:
			var face = 1.0
			if "face_dir" in player_body:
				face = float(player_body.face_dir)
			boost_dir = Vector2(face, 0.0).normalized()
			current_speed = min_boost_speed

		# 计算加速后的爆发冲量
		var boosted_speed = max(current_speed * boost_multiplier, min_boost_speed)
		player_body.velocity = boost_dir * boosted_speed

		# 如果玩家当前处于冲刺（Dash）等特殊状态，强行切换并重置，避免冲刺结束时截断/清空进入速度
		if player_body.has_node("move_state_machine"):
			var sm = player_body.get_node("move_state_machine")
			if sm.cur_state_name == "dash":
				sm.change_state("fall")
		if "is_special_state" in player_body:
			player_body.is_special_state = false

		# 穿过流体水幕：刷新冲刺（Dash）与钩索（Rope）
		if player_body.has_method("ResetDashAndRope"):
			player_body.ResetDashAndRope()

		SignalBus.PlayerEnteredWaterWall.emit()

		# 水花波纹微动视觉反馈
		var tween = create_tween()
		visual_rect.color = Color(0.4, 0.9, 1.0, 0.8)
		tween.tween_property(visual_rect, "color", Color(0.15, 0.65, 0.95, 0.45), 0.3)

		# 在流水区域中消除重力影响
		if player_body not in _bodies_in_water:
			_bodies_in_water.append(player_body)
			if player_body.has_method("SetInWaterFlow"):
				player_body.SetInWaterFlow(true)

func _on_fluid_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body in _bodies_in_water:
		_bodies_in_water.erase(body)
		if body.has_method("SetInWaterFlow"):
			body.SetInWaterFlow(false)
		SignalBus.PlayerExitedWaterWall.emit(body.velocity)

func _clear_all_bodies_in_water() -> void:
	for body in _bodies_in_water:
		if is_instance_valid(body) and body.has_method("SetInWaterFlow"):
			body.SetInWaterFlow(false)
	_bodies_in_water.clear()

func _exit_tree() -> void:
	_clear_all_bodies_in_water()
