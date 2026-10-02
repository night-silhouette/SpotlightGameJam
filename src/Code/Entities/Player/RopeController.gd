extends Node2D
class_name RopeController

## 绳索状态枚举
enum RopeState {
	IDLE,        ## 空闲未连接
	LATCHED,     ## 已命中墙面，处于等待选择窗口期
	PULLING,     ## 正在快速拉向命中点
	SWINGING     ## 正在以命中点为原点摆动荡跃
}

@export_group("Rope Settings")
## 绳索最大有效射程
@export var max_rope_length: float = 420.0
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

## 摆动相关状态
var swing_radius: float = 0.0
var swing_angle: float = 0.0
var swing_angular_velocity: float = 0.0

@onready var player: Player = get_parent() as Player
@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
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
		_on_rope_shoot_pressed()
	elif event.is_action_pressed("rope_swing"):
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

		RopeState.LATCHED:
			_process_latched(delta)

		RopeState.PULLING:
			_process_pulling(delta)

		RopeState.SWINGING:
			_process_swinging(delta)

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
			# 荡绳时按射绳键可转为拉向挂点
			_start_pull()

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
	var space_state = player.get_world_2d().direct_space_state
	var shoot_dir = _get_shoot_direction()
	var ray_target = player.global_position + shoot_dir * max_rope_length

	var query = PhysicsRayQueryParameters2D.create(player.global_position, ray_target, collision_mask)
	query.exclude = [player.get_rid()]
	var result = space_state.intersect_ray(query)

	SignalBus.PlayerGrappleLaunched.emit(ray_target)

	if result and not result.is_empty():
		can_use_rope = false
		hook_point = result.position
		hook_target_node = result.collider as Node2D
		if hook_target_node:
			hook_target_offset = hook_target_node.to_local(hook_point)
		else:
			hook_target_offset = Vector2.ZERO
		current_state = RopeState.LATCHED
		window_timer = window_duration
		_update_line()
		line_2d.visible = true
		SignalBus.PlayerGrappleHooked.emit(hook_point)
		return true

	_show_miss_effect(ray_target)
	return false

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

	# 窗口期内减缓下落速度，给予良好的反应窗口
	if not player.is_on_floor() and player.velocity.y > 60.0:
		player.velocity.y = move_toward(player.velocity.y, 60.0, 1200.0 * delta)

	if window_timer <= 0.0:
		_release_rope(true)
	elif player.is_on_floor() and window_timer < window_duration - 0.15:
		_release_rope(true)

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
		# 保留速度惯性冲量
		player.velocity = launch_dir * pull_speed * 0.92
		if launch_dir.y >= -0.2:
			player.velocity.y = min(player.velocity.y, -320.0)
		if with_jump_boost:
			player.velocity.y = -player.jump_speed * 1.1

func _start_swing() -> void:
	_sync_hook_point()
	current_state = RopeState.SWINGING
	player.is_special_state = true

	var rel = player.global_position - hook_point
	swing_radius = clamp(rel.length(), 40.0, max_rope_length)
	swing_angle = atan2(rel.x, rel.y)

	var tangent = Vector2(cos(swing_angle), -sin(swing_angle))
	var initial_tangent_speed = player.velocity.dot(tangent)

	# 给予更顺畅的初速度启动感
	if abs(initial_tangent_speed) < 260.0:
		var start_dir = float(player.face_dir)
		if player.gameInputControl and player.gameInputControl.row_dir != 0.0:
			start_dir = sign(player.gameInputControl.row_dir)
		initial_tangent_speed = 420.0 * start_dir

	swing_angular_velocity = initial_tangent_speed / swing_radius
	_update_line()

func _process_swinging(delta: float) -> void:
	_sync_hook_point()
	var gravity_val = GlobalValue.gravity * swing_gravity_scale
	var alpha = -(gravity_val / swing_radius) * sin(swing_angle)

	var row_input = 0.0
	if player.gameInputControl:
		row_input = player.gameInputControl.row_dir

	if row_input != 0.0:
		# 玩家顺势加力
		alpha += (swing_input_accel / swing_radius) * row_input * max(cos(swing_angle), 0.1)

	swing_angular_velocity *= (1.0 - swing_damping * delta)
	swing_angular_velocity += alpha * delta

	swing_angle += swing_angular_velocity * delta
	swing_angle = clamp(swing_angle, -PI * 0.46, PI * 0.46)

	var target_pos = hook_point + Vector2(sin(swing_angle), cos(swing_angle)) * swing_radius
	var tangent = Vector2(cos(swing_angle), -sin(swing_angle))
	var current_tangent_speed = swing_angular_velocity * swing_radius

	player.velocity = tangent * current_tangent_speed
	player.global_position = target_pos

	_update_line()

	if player.is_on_wall():
		# 撞墙微反弹
		swing_angular_velocity = -swing_angular_velocity * 0.5

func _finish_swing(with_jump_boost: bool) -> void:
	var tangent = Vector2(cos(swing_angle), -sin(swing_angle))
	var current_tangent_speed = swing_angular_velocity * swing_radius
	var exit_velocity = tangent * current_tangent_speed

	_release_rope(true)

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
