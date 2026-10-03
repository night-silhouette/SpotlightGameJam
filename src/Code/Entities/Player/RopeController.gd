extends Node2D
class_name RopeController

## 绳索状态枚举
enum RopeState {
	IDLE,        ## 空闲未连接
	FLYING,      ## 绳头正在快速向前飞行伸展
	LATCHED,     ## 已命中墙面，处于等待选择窗口期
	PULLING,     ## 正在快速拉向命中点
	SWINGING     ## 正在以命中点为原点摆动荡跃
}

@export_group("Rope Settings")
## 绳索最大有效射程
@export var max_rope_length: float = 420.0
## 绳索飞行发射速度
@export var rope_speed: float = 2200.0
## 命中后的决策窗口期持续时间 (秒)
@export var window_duration: float = 0.45
## 拉向命中点的飞行速度
@export var pull_speed: float = 850.0
## 拉拽到达阈值距离
@export var pull_arrive_distance: float = 35.0
## 摆动受重力缩放因子
@export var swing_gravity_scale: float = 1.0
## 摆动左右按键施加的切向角加速度
@export var swing_input_accel: float = 1800.0
## 摆动阻尼系数
@export var swing_damping: float = 0.15
## 绳索检测的物理层级掩码 (默认层1 world + 层3 enemy/实体 = 1 | 4 = 5)
@export_flags_2d_physics var collision_mask: int = 5

var current_state: RopeState = RopeState.IDLE
var hook_point: Vector2 = Vector2.ZERO
var hook_target_node: Node2D = null
var hook_target_offset: Vector2 = Vector2.ZERO
var window_timer: float = 0.0
var pull_timer: float = 0.0
var can_use_rope: bool = true

## 是否在命中前就已经松开了左键
var released_during_flight: bool = false

## 绳头飞行变量
var fly_dir: Vector2 = Vector2.ZERO
var fly_distance: float = 0.0
var fly_tip_pos: Vector2 = Vector2.ZERO

## 摆动相关状态
var swing_radius: float = 0.0
var swing_angle: float = 0.0
var swing_angular_velocity: float = 0.0

@onready var player: Player = get_parent() as Player
@onready var line_2d: Line2D = $Line2D

func _sync_from_export_settings() -> void:
	if ExportSettings:
		max_rope_length = ExportSettings.rope_max_length
		rope_speed = ExportSettings.rope_projectile_speed
		window_duration = ExportSettings.rope_window_duration
		pull_speed = ExportSettings.rope_pull_speed
		pull_arrive_distance = ExportSettings.rope_pull_arrive_distance
		swing_gravity_scale = ExportSettings.rope_swing_gravity_scale
		swing_input_accel = ExportSettings.rope_swing_input_accel
		swing_damping = ExportSettings.rope_swing_damping
		collision_mask = ExportSettings.rope_collision_mask

func _ready() -> void:
	_sync_from_export_settings()
	if not line_2d:
		line_2d = Line2D.new()
		line_2d.name = "Line2D"
		line_2d.width = 2.5
		line_2d.default_color = Color(0.3, 0.85, 1.0, 0.9)
		add_child(line_2d)
	line_2d.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not player or player.now_HP <= 0.0:
		return

	if event.is_action_pressed("rope_shoot"):
		get_viewport().set_input_as_handled()
		_on_rope_shoot_pressed()
	elif event.is_action_released("rope_shoot"):
		get_viewport().set_input_as_handled()
		_on_rope_shoot_released()
	elif event.is_action_pressed("rope_swing"):
		get_viewport().set_input_as_handled()
		_on_rope_swing_pressed()
	elif event.is_action_pressed("jump"):
		_on_jump_pressed()

func _physics_process(delta: float) -> void:
	if not player:
		return

	if player.is_on_floor():
		can_use_rope = true

	match current_state:
		RopeState.IDLE:
			pass

		RopeState.FLYING:
			_process_flying(delta)

		RopeState.LATCHED:
			_process_latched(delta)

		RopeState.PULLING:
			_process_pulling(delta)

		RopeState.SWINGING:
			_process_swinging(delta)

## 刷新钩索使用次数（允许在空中再次使用）
func ResetRopeCooldown() -> void:
	can_use_rope = true

## 发射绳索的公共调用接口
## @return 是否成功勾中墙面
func ShootRope() -> bool:
	if current_state != RopeState.IDLE or not can_use_rope:
		return false
	return _shoot_rope()

## 触发拉向勾中点的公共调用接口
func TriggerPull() -> void:
	if current_state == RopeState.LATCHED:
		_start_pull()

## 触发摆动荡绳的公共调用接口
func TriggerSwing() -> void:
	if current_state == RopeState.LATCHED:
		_start_swing()

## 释放并收回绳索的公共调用接口
## @param preserve_velocity 是否保留当前的动量惯性
func ReleaseRope(preserve_velocity: bool = true) -> void:
	_release_rope(preserve_velocity)

func _on_rope_shoot_pressed() -> void:
	match current_state:
		RopeState.IDLE:
			if can_use_rope:
				_shoot_rope()
		RopeState.LATCHED:
			_start_pull()
		RopeState.PULLING:
			# 再次按射绳键提前脱钩并飞跃
			_finish_pull(true)
		RopeState.SWINGING:
			# 荡绳时再次按左键可转为高速拉向挂点
			_start_pull()

func _on_rope_shoot_released() -> void:
	match current_state:
		RopeState.FLYING:
			# 在绳头飞行阶段就已经松开左键，记录标记
			released_during_flight = true
		RopeState.LATCHED:
			# 只要松开左键，立刻零延迟把自己拉过去
			_start_pull()
		RopeState.SWINGING:
			# 长按荡绳后松开左键，脱钩飞出保留惯性
			_finish_swing(false)

func _on_rope_swing_pressed() -> void:
	match current_state:
		RopeState.LATCHED:
			_start_swing()
		RopeState.SWINGING:
			# 再次按荡绳键脱钩飞出
			_release_rope(true)

func _on_jump_pressed() -> void:
	if current_state == RopeState.PULLING:
		_finish_pull(true, true)
	elif current_state == RopeState.SWINGING:
		_finish_swing(true)

func _shoot_rope() -> bool:
	fly_dir = _get_shoot_direction()
	var ray_target = player.global_position + fly_dir * max_rope_length

	SignalBus.PlayerGrappleLaunched.emit(ray_target)

	fly_distance = 0.0
	fly_tip_pos = player.global_position
	released_during_flight = false
	current_state = RopeState.FLYING
	line_2d.visible = true
	line_2d.default_color = Color(0.3, 0.85, 1.0, 0.9)
	line_2d.clear_points()
	line_2d.add_point(to_local(player.global_position))
	line_2d.add_point(to_local(player.global_position))

	return true

func _process_flying(delta: float) -> void:
	var prev_tip_pos = fly_tip_pos
	var step = rope_speed * delta
	fly_distance += step
	var next_tip_pos = player.global_position + fly_dir * fly_distance

	# 随着绳头实际向前飞行，步进式检测当前帧飞过的线段是否碰撞到了墙体表面
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(prev_tip_pos, next_tip_pos, collision_mask)
	query.exclude = [player.get_rid()]
	var result = space_state.intersect_ray(query)

	if result and not result.is_empty():
		var hit_collider = result.collider as Node2D
		# 检查命中目标是否为禁止钩锁吸附的物体（如光滑滑石墙）
		if hit_collider and (hit_collider.is_in_group("slick_wall") or hit_collider.is_in_group("no_hook") or hit_collider.get("disable_hook") == true or hit_collider.get("is_slick_wall") == true):
			# 无法抓取吸附：播放滑石火花并立刻弹出弹刀落空回收
			_show_miss_effect(result.position)
			_release_rope(true)
			return

		# 绳头实际碰撞命中有效墙体
		fly_tip_pos = result.position
		can_use_rope = false
		hook_point = result.position
		hook_target_node = hit_collider
		if hook_target_node:
			hook_target_offset = hook_target_node.to_local(hook_point)
		else:
			hook_target_offset = Vector2.ZERO

		SignalBus.PlayerGrappleHooked.emit(hook_point)

		# 若玩家在绳子飞行过程中就已经松手了，或者命中瞬间未按住左键，立即拉过去
		if released_during_flight or not Input.is_action_pressed("rope_shoot"):
			_start_pull()
		else:
			current_state = RopeState.LATCHED
			window_timer = window_duration
			_update_line()
		return

	fly_tip_pos = next_tip_pos

	# 若超过最大射程仍未命中，绳索落空回收
	if fly_distance >= max_rope_length:
		_show_miss_effect(player.global_position + fly_dir * max_rope_length)
		_release_rope(true)
		return

	# 绘制飞行中的绳索
	line_2d.clear_points()
	line_2d.add_point(to_local(player.global_position))
	line_2d.add_point(to_local(fly_tip_pos))

func _get_shoot_direction() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	var dir = mouse_pos - player.global_position
	if dir.length_squared() < 0.001:
		return Vector2(player.face_dir, -0.7).normalized()
	return dir.normalized()

func _show_miss_effect(end_point: Vector2) -> void:
	line_2d.clear_points()
	line_2d.add_point(to_local(player.global_position))
	line_2d.add_point(to_local(end_point))
	line_2d.default_color = Color(0.6, 0.7, 0.8, 0.4)
	line_2d.visible = true

	var tween = create_tween()
	tween.tween_property(line_2d, "modulate:a", 0.0, 0.12)
	tween.finished.connect(func():
		line_2d.visible = false
		line_2d.modulate.a = 1.0
		line_2d.default_color = Color(0.3, 0.85, 1.0, 0.9)
	)

func _sync_hook_point() -> void:
	if is_instance_valid(hook_target_node):
		hook_point = hook_target_node.to_global(hook_target_offset)

func _process_latched(delta: float) -> void:
	_sync_hook_point()
	window_timer -= delta
	_update_line()

	# 窗口期内：仅当挂钩点在玩家上方（绳索朝上提拉玩家）时才减缓下落速度；若朝下勾中则不产生减速
	var is_hook_above = hook_point.y < player.global_position.y
	if is_hook_above and not player.is_on_floor() and player.velocity.y > 60.0:
		player.velocity.y = move_toward(player.velocity.y, 60.0, 1200.0 * delta)

	# 若玩家一直长按射绳键（左键），并在窗口期过去一定时间（长按判定），则自动转为荡绳（Swing）
	if Input.is_action_pressed("rope_shoot"):
		if (window_duration - window_timer) >= 0.16:
			_start_swing()
			return

	# 窗口期结束时，拉拽自己过去
	if window_timer <= 0.0:
		_start_pull()

func _start_pull() -> void:
	_sync_hook_point()
	current_state = RopeState.PULLING
	pull_timer = 0.0
	player.is_special_state = true
	_update_line()

func _process_pulling(delta: float) -> void:
	_sync_hook_point()
	pull_timer += delta
	var to_hook = hook_point - player.global_position
	var dist = to_hook.length()

	if dist <= pull_arrive_distance or pull_timer >= 1.2:
		_finish_pull(true)
		return

	var pull_dir = to_hook.normalized()
	player.velocity = pull_dir * pull_speed
	_update_line()

func _finish_pull(preserve_momentum: bool, with_jump_boost: bool = false) -> void:
	_sync_hook_point()
	var launch_dir = (hook_point - player.global_position).normalized()
	_release_rope(true)

	if preserve_momentum:
		# 获取配置参数
		var momentum_ratio = ExportSettings.rope_pull_momentum_ratio if ExportSettings else 0.95
		var momentum_duration = ExportSettings.rope_momentum_duration if ExportSettings else 0.4

		# 记录动量保护期，使玩家在地面上滑行时不被高摩擦骤停
		player.rope_momentum_timer = momentum_duration

		# 保留水平向前的速度惯性冲量
		var final_vel_x = launch_dir.x * pull_speed * momentum_ratio
		if abs(final_vel_x) > 0.01:
			player.velocity.x = final_vel_x

		# 垂直方向处理：
		# 如果勾的是地面或水平前方（launch_dir.y >= 0），绝不强加向上弹跳速度（去除弹起来的感觉）
		if launch_dir.y >= 0.0:
			player.velocity.y = 0.0
		else:
			# 如果确实是朝上方拉（如斜上方挂点脱钩飞出），自然保留向上的速度
			player.velocity.y = launch_dir.y * pull_speed * momentum_ratio

		if with_jump_boost:
			player.velocity.y = -player.jump_speed * 1.1

func _start_swing() -> void:
	_sync_hook_point()
	current_state = RopeState.SWINGING
	player.is_special_state = true

	var rel = player.global_position - hook_point
	swing_radius = clamp(rel.length(), 30.0, max_rope_length)
	_update_line()

func _process_swinging(delta: float) -> void:
	_sync_hook_point()

	# 1. 真实受力：重力自然下坠（支持流水区域等零重力或自定义重力影响）
	var current_gravity_scale: float = 1.0
	if "gravity_scale" in player:
		current_gravity_scale = player.gravity_scale
	player.velocity.y += GlobalValue.gravity * current_gravity_scale * delta

	# 2. 绳索刚性约束（距离约束）：
	# 计算假设无约束移动后，玩家相对于锚点的位置
	var current_rel = player.global_position - hook_point
	var current_dist = current_rel.length()

	# 只有当绳索被拉直时（距离 >= swing_radius），绳索才产生张力拉拽人物
	if current_dist >= swing_radius:
		var rope_dir = current_rel / max(current_dist, 0.001)

		# 消除沿着绳子往外拉伸的速度分量（法向张力消除），仅保留切向速度（产生天然的圆弧运动）
		var radial_vel = player.velocity.dot(rope_dir)
		if radial_vel > 0.0:
			player.velocity -= rope_dir * radial_vel

		# 施加微弱阻尼（空气阻力），保持长久自然的摆动
		player.velocity *= (1.0 - swing_damping * delta)

		# 几何位置修正，防止物理积分累计导致绳子变长
		player.global_position = hook_point + rope_dir * swing_radius

	# 3. 正常走角色物理碰撞滑动，绝无穿墙，碰到地形自然受阻滑动
	player.move_and_slide()

	# 4. 更新实际绳长（若碰撞使角色靠近挂点，动态缩短或维持当前绳长）
	var after_rel = player.global_position - hook_point
	var after_dist = after_rel.length()
	if after_dist < swing_radius:
		swing_radius = max(after_dist, 30.0)

	_update_line()

func _finish_swing(with_jump_boost: bool) -> void:
	var exit_velocity = player.velocity
	_release_rope(true)

	var momentum_duration = ExportSettings.rope_momentum_duration if ExportSettings else 0.4
	player.rope_momentum_timer = momentum_duration
	player.velocity = exit_velocity
	if with_jump_boost:
		player.velocity.y = min(player.velocity.y - 200.0, -player.jump_speed * 0.9)

func _release_rope(preserve_velocity: bool) -> void:
	current_state = RopeState.IDLE
	hook_target_node = null
	hook_target_offset = Vector2.ZERO
	window_timer = 0.0
	pull_timer = 0.0
	line_2d.visible = false

	if player:
		player.is_special_state = false
		if not preserve_velocity:
			player.velocity = Vector2.ZERO

	SignalBus.PlayerGrappleReleased.emit()

func _update_line() -> void:
	if not line_2d or not player:
		return
	line_2d.clear_points()
	line_2d.add_point(to_local(player.global_position))
	line_2d.add_point(to_local(hook_point))
