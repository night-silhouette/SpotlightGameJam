extends StaticBody2D
class_name WaterFlowArea

## 流水区域：按 interact 映射切换鼠标指向区域的固态与流体；流体状态下为进入的玩家提供加速。

## 流水区域完成初始化或流体状态发生变化时触发；is_fluid 为当前是否处于流体状态。
signal FluidStateChanged(is_fluid: bool)

@export_category("WaterFlowArea Settings")
## 区域尺寸（宽、高）
@export var area_size: Vector2 = Vector2(160.0, 100.0):
	set(value):
		area_size = value
		_update_dimensions()

## 初始状态是否为流体
@export var is_fluid: bool = false:
	set(value):
		is_fluid = value
		if is_node_ready():
			_apply_state(is_fluid)

## 玩家进入流体时获得的加速倍率
@export var boost_multiplier: float = 1.6
## 玩家进入流体时保证的最低爆发速度
@export var min_boost_speed: float = 480.0
## 进入流水区域的音效
@export var sfx_water_pass: AudioStream = preload("res://Music/SFX/Interactive-SFX_Interactive/HuaShui.wav")
## 离开流水区域的音效
@export var sfx_water_exit: AudioStream = preload("res://Music/SFX/Interactive-SFX_Interactive/YouShui.wav")
## 流水音效音量分贝 (dB)
@export var sfx_water_pass_volume_db: float = 0.0
## 流水音效音频总线
@export var sfx_water_pass_bus: StringName = &"SFX_Interact"

@onready var solid_collision: CollisionShape2D = $SolidCollision
@onready var fluid_area: Area2D = $FluidArea
@onready var fluid_collision: CollisionShape2D = $FluidArea/FluidCollision
@onready var visual_rect: ColorRect = $VisualRect
@onready var before_visual: TileMapLayer = get_node_or_null("BeforeVisual") as TileMapLayer
@onready var before_sprite_visuals: Node2D = get_node_or_null("BeforeSpriteVisuals") as Node2D
@onready var after_visual: NinePatchRect = get_node_or_null("AfterVisual") as NinePatchRect
@onready var water_curtain: ColorRect = $WaterCurtain

var _bodies_in_water: Array[CharacterBody2D] = []
var _has_applied_state: bool = false
var _last_applied_fluid: bool = false
var _impact_tween: Tween

func _ready() -> void:
	add_to_group("touch_interactables")
	_sync_from_export_settings()
	_update_dimensions()
	_apply_state(is_fluid)

	fluid_area.body_entered.connect(_on_fluid_area_body_entered)
	fluid_area.body_exited.connect(_on_fluid_area_body_exited)

func _process(_delta: float) -> void:
	if is_fluid and not _bodies_in_water.is_empty():
		var player_body := _bodies_in_water[0]
		if is_instance_valid(player_body):
			_set_water_curtain_impact_position(player_body.global_position)

func _sync_from_export_settings() -> void:
	if ExportSettings:
		boost_multiplier = ExportSettings.water_flow_speed_multiplier
		min_boost_speed = ExportSettings.water_flow_min_speed
		if "water_flow_pass_volume_db" in ExportSettings:
			sfx_water_pass_volume_db = ExportSettings.water_flow_pass_volume_db
		if "water_flow_audio_bus" in ExportSettings:
			sfx_water_pass_bus = ExportSettings.water_flow_audio_bus

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
	if after_visual:
		after_visual.size = area_size
		after_visual.position = -area_size * 0.5
	if water_curtain:
		water_curtain.size = area_size
		water_curtain.position = -area_size * 0.5
		(water_curtain.material as ShaderMaterial).set_shader_parameter("curtain_size", area_size)

## 判断世界坐标是否落在流水区域可见矩形内；world_point 为鼠标的世界坐标，返回是否命中。
func ContainsWorldPoint(world_point: Vector2) -> bool:
	var local_point = to_local(world_point)
	return abs(local_point.x) <= area_size.x * 0.5 and abs(local_point.y) <= area_size.y * 0.5

## 触屏交互模式下点中区域时，使用玩家原有的水符文冷却与激活流程。
## world_pos 为触点世界坐标，interactor 为玩家；成功切换时返回 true。
func TryTouchInteract(world_pos: Vector2, interactor: Node2D) -> bool:
	if not ContainsWorldPoint(world_pos) or not is_instance_valid(interactor):
		return false
	var water_rune := interactor.get_node_or_null("WaterRuneController") as WaterRuneController
	return water_rune != null and water_rune.TryActivateTargetArea(self)

## 将流水区域切换为流体或固态；to_fluid 表示目标是否为流体。
func SetFluidState(to_fluid: bool) -> void:
	is_fluid = to_fluid
	_apply_state(is_fluid)

func _apply_state(fluid: bool) -> void:
	if not is_inside_tree():
		return

	var state_changed := not _has_applied_state or _last_applied_fluid != fluid
	_has_applied_state = true
	_last_applied_fluid = fluid
	_update_visual_state(fluid)

	if fluid:
		# 转换为流体：关闭实体阻挡碰撞，启用感应触发 Area
		solid_collision.set_deferred("disabled", true)
		fluid_collision.set_deferred("disabled", false)
		visual_rect.color = Color(0.15, 0.65, 0.95, 0.45)
		SignalBus.RuneWallConverted.emit(self, Vector2.UP)
	else:
		# 恢复为普通刚体：开启实体碰撞，关闭流体感应
		solid_collision.set_deferred("disabled", false)
		fluid_collision.set_deferred("disabled", true)
		visual_rect.color = Color(0.28, 0.42, 0.55, 1.0)
		_clear_all_bodies_in_water()
		if _impact_tween and _impact_tween.is_running():
			_impact_tween.kill()
		(water_curtain.material as ShaderMaterial).set_shader_parameter("impact_strength", 0.0)

	if state_changed:
		FluidStateChanged.emit(fluid)

func _update_visual_state(fluid: bool) -> void:
	var has_tile_content := _has_before_visual_content()
	var has_sprite_content := _has_before_sprite_visual_content()
	var has_before_content := has_tile_content or has_sprite_content

	if before_visual:
		before_visual.visible = not fluid and has_tile_content
	if before_sprite_visuals:
		before_sprite_visuals.visible = not fluid and has_sprite_content
	if after_visual:
		after_visual.visible = false
	if water_curtain:
		water_curtain.visible = fluid
	if visual_rect:
		visual_rect.visible = not fluid and not has_before_content

func _has_before_visual_content() -> bool:
	return before_visual != null and before_visual.tile_set != null and not before_visual.get_used_cells().is_empty()

func _has_before_sprite_visual_content() -> bool:
	if before_sprite_visuals == null:
		return false
	return _has_configured_canvas_visual(before_sprite_visuals)

func _has_configured_canvas_visual(node: Node) -> bool:
	for child in node.get_children():
		if child is Sprite2D and (child as Sprite2D).texture != null:
			return true
		if child is TextureRect and (child as TextureRect).texture != null:
			return true
		if _has_configured_canvas_visual(child):
			return true
	return false

## 切换符文流水与凝固状态。
func ToggleRuneFluid() -> void:
	SetFluidState(not is_fluid)

func _on_fluid_area_body_entered(body: Node2D) -> void:
	if not is_fluid:
		return

	if body.is_in_group("player") and body is CharacterBody2D:
		var player_body = body as CharacterBody2D

		# 记录并获取进入时的速度方向与大小
		var enter_velocity = player_body.velocity

		# 若玩家当前处于冲刺状态中，获取冲刺专属速度并打断冲刺
		var is_dashing = false
		if player_body.has_node("move_state_machine"):
			var sm = player_body.get_node("move_state_machine")
			if sm.cur_state_name == "dash":
				is_dashing = true
		if "is_special_state" in player_body and player_body.is_special_state:
			is_dashing = true

		if is_dashing and "dash_speed" in player_body:
			var dash_spd = float(player_body.dash_speed)
			var face = float(player_body.face_dir) if "face_dir" in player_body else 1.0
			# 如果进入时已有横向冲刺速度，按该速度方向作为基础
			if abs(enter_velocity.x) > 0.1:
				enter_velocity.x = sign(enter_velocity.x) * dash_spd
			else:
				enter_velocity = Vector2(face * dash_spd, 0.0)

		# 中断并彻底退出冲刺状态
		if player_body.has_method("InterruptDash"):
			player_body.InterruptDash()
		elif "is_special_state" in player_body:
			player_body.is_special_state = false

		var current_speed = enter_velocity.length()
		var boost_dir = enter_velocity.normalized()
		# 若玩家几乎是静止蹭入的，按照玩家面朝方向给予推力
		if current_speed < 10.0:
			var face = 1.0
			if "face_dir" in player_body:
				face = float(player_body.face_dir)
			boost_dir = Vector2(face, 0.0).normalized()
			current_speed = min_boost_speed

		# 计算加速后的爆发冲量（基于包含冲刺速度的进入速度 * boost_multiplier）
		var boosted_speed = max(current_speed * boost_multiplier, min_boost_speed)
		player_body.velocity = boost_dir * boosted_speed

		# 在流水区域中消除重力影响
		if player_body not in _bodies_in_water:
			_bodies_in_water.append(player_body)
			if player_body.has_method("SetInWaterFlow"):
				player_body.SetInWaterFlow(true)

		# 退出冲刺并恢复常规空中动作，保留流水赋予的速度。
		if player_body.has_node("move_state_machine"):
			var sm = player_body.get_node("move_state_machine")
			sm.state_map["fall"].is_use = true
			sm.change_state("fall")

		# 穿过流体水幕：刷新冲刺（Dash）与钩索（Rope）
		if player_body.has_method("ResetDashAndRope"):
			player_body.ResetDashAndRope()

		SignalBus.PlayerEnteredWaterWall.emit()

		# 播放进入流水区域的音效
		if sfx_water_pass and Util:
			Util.PlaySFX2D(sfx_water_pass, global_position, sfx_water_pass_bus, sfx_water_pass_volume_db)

		_disturb_water_curtain(player_body.global_position, true)

func _on_fluid_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D and body in _bodies_in_water:
		_bodies_in_water.erase(body)
		if body.has_method("SetInWaterFlow"):
			body.SetInWaterFlow(false)
		SignalBus.PlayerExitedWaterWall.emit(body.velocity)
		if is_fluid:
			_disturb_water_curtain(body.global_position)
			if sfx_water_exit and Util:
				Util.PlaySFX2D(sfx_water_exit, global_position, sfx_water_pass_bus, sfx_water_pass_volume_db)

func _disturb_water_curtain(world_position: Vector2, entering: bool = false) -> void:
	var material := water_curtain.material as ShaderMaterial
	_set_water_curtain_impact_position(world_position)
	if _impact_tween and _impact_tween.is_running():
		_impact_tween.kill()
	material.set_shader_parameter("impact_strength", 1.0)
	if entering:
		return
	_impact_tween = create_tween()
	_impact_tween.tween_property(material, "shader_parameter/impact_strength", 0.0, 0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_water_curtain_impact_position(world_position: Vector2) -> void:
	var local_point: Vector2 = to_local(world_position) - water_curtain.position
	var impact_position := Vector2(
		clampf(local_point.x / area_size.x, 0.0, 1.0),
		clampf(local_point.y / area_size.y, 0.0, 1.0)
	)
	(water_curtain.material as ShaderMaterial).set_shader_parameter("impact_position", impact_position)

func _clear_all_bodies_in_water() -> void:
	for body in _bodies_in_water:
		if is_instance_valid(body) and body.has_method("SetInWaterFlow"):
			body.SetInWaterFlow(false)
	_bodies_in_water.clear()

func _exit_tree() -> void:
	_clear_all_bodies_in_water()
