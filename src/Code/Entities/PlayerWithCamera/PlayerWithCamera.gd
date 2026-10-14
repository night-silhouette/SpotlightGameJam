extends Node2D
## 原玩家 + Phantom Camera。默认普通跟随，关卡经 SignalBus 请求五种镜头。
## 原 Player 和插件均不修改；CG 只暂停本组件的玩家子树。

@export_category("Player Properties")
@export_group("physical_prop")
@export var jump_speed: float = 380.0
@export var hurt_time: float = 0.15
@export var accerleration: float = 2500.0
@export var speed: float = 230.0
@export var friction: float = 3000.0
@export var jump_ability: float = 0.85
@export var dash_time: float = 0.15
@export var dash_speed: float = 700.0
@export var dash_span: float = 0.65
@export var max_fall_speed: float = 120.0
@export var unbeatable_time: float = 0.3
@export var climb_ability: float = 480.0

@export_group("state_prop")
@export var Max_HP: float = 200.0
@export var now_HP: float = 200.0
@export var is_hp_draining: bool = false
@export var hp_drain_rate: float = 5.0
@export var gravity_scale: float = 1.0

const MODES: Array[StringName] = [&"normal", &"desert", &"descent", &"boat", &"ritual", &"fixed"]
var current_mode: StringName = &"normal"
var input_locked: bool = false
var _options: Dictionary = {}
var _previous_mode: StringName = &"normal"
var _previous_options: Dictionary = {}
var _active: PhantomCamera2D
var _target: Node2D
var _pending: bool = false
var _phase: StringName = &""
var _generation: int = 0
var _saved_process_mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT
var _frame: Vector2 = Vector2(0.5, 0.5)
var _last_target_position: Vector2
var _target_velocity_y: float = 0.0
var _camera_bounds: Dictionary = {}
var _gate_limits: Dictionary = {}
var _pending_gate_limits: Dictionary = {}
@onready var _player: CharacterBody2D = $Player
@onready var _base: PhantomCamera2D = $PhantomCamera2D
@onready var _presentation: CanvasLayer = $CameraPresentation


func _enter_tree() -> void:
	# 在插件子节点进入场景树前应用配置，避免开场先使用另一套镜头参数。
	var phantom: PhantomCamera2D = $PhantomCamera2D
	phantom.priority = ExportSettings.player_camera_priority
	phantom.zoom = Vector2.ONE * maxf(0.01, ExportSettings.player_camera_zoom)
	phantom.follow_offset = ExportSettings.player_camera_offset
	phantom.follow_damping = ExportSettings.player_camera_smoothing
	phantom.follow_damping_value = ExportSettings.player_camera_damping
	phantom.dead_zone_width = clampf(ExportSettings.player_camera_box_fraction.x, 0.0, 1.0)
	phantom.dead_zone_height = clampf(ExportSettings.player_camera_box_fraction.y, 0.0, 1.0)


func _ready() -> void:
	hp_drain_rate = ExportSettings.player_hp_drain_rate
	_sync_player_properties()
	_active = _base
	_target = _player
	for camera: PhantomCamera2D in [_base, $ShotA, $ShotB]:
		camera.tween_resource = PhantomCameraTween.new()
		camera.set_tween_transition(Tween.TRANS_SINE)
		camera.set_tween_ease(Tween.EASE_IN_OUT)
		camera.tween_completed.connect(_on_arrived.bind(camera))
		camera.is_tweening.connect(_on_camera_tweening.bind(camera))
		camera.became_inactive.connect(_on_camera_interrupted.bind(camera))
		_camera_bounds[camera] = Vector4i(camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom)
	# 首次定位时让死区下边界贴住玩家；之后恢复正常跟随偏移。
	var initial_offset: Vector2 = _base.follow_offset
	_base.follow_offset.y = -get_viewport_rect().size.y * _base.dead_zone_height / (2.0 * maxf(_base.zoom.y, 0.05))
	_base.global_position = _player.global_position + _base.follow_offset
	_base.teleport_position()
	_base.follow_offset = initial_offset
	SignalBus.CameraNormalRequested.connect(_on_normal_requested)
	SignalBus.CameraDesertRequested.connect(_on_desert_requested)
	SignalBus.CameraDescentRequested.connect(_on_descent_requested)
	SignalBus.CameraBoatRequested.connect(_on_boat_requested)
	SignalBus.CameraRitualRequested.connect(_on_ritual_requested)
	SignalBus.CameraFixedRequested.connect(_on_fixed_requested)
	SignalBus.CameraShotRequested.connect(_on_shot_requested)
	SignalBus.CameraShotEndRequested.connect(_on_end_requested)
	SignalBus.CameraGateChanged.connect(_on_camera_gate_changed)
	SignalBus.CameraGateSideChanged.connect(_on_camera_gate_side_changed)
	SignalBus.CameraGateSideRemoved.connect(_on_camera_gate_side_removed)
	SignalBus.PlayerRespawned.connect(_on_player_respawned)
	if is_hp_draining:
		SignalBus.StartPlayerHpDrain.emit(_player.hp_drain_rate)


func _sync_player_properties() -> void:
	_player.jump_speed = jump_speed
	_player.hurt_time = hurt_time
	_player.accerleration = accerleration
	_player.speed = speed
	_player.friction = friction
	_player.jump_ability = jump_ability
	_player.dash_time = dash_time
	_player.dash_speed = dash_speed
	_player.dash_span = dash_span
	_player.max_fall_speed = max_fall_speed
	_player.unbeatable_time = unbeatable_time
	_player.climb_ability = climb_ability
	_player.Max_HP = Max_HP
	_player.now_HP = now_HP
	_player.is_hp_draining = is_hp_draining
	_player.hp_drain_rate = hp_drain_rate
	_player.gravity_scale = gravity_scale


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		_on_shot_requested(_player, &"normal", {})
		return
	if current_mode == &"descent":
		var velocity_y: float = (_target.global_position.y - _last_target_position.y) / maxf(delta, 0.001)
		_target_velocity_y = lerpf(_target_velocity_y, velocity_y, 1.0 - exp(-delta * 8.0))
	_last_target_position = _target.global_position
	if current_mode in [&"desert", &"descent", &"boat"]:
		_active.follow_offset = _frame_offset(_active.zoom.x)
		if current_mode == &"descent":
			# 以插件实际的阻尼延迟做速度前馈，保持高速下落时的底部构图。
			_active.follow_offset.y += _target_velocity_y * _active.follow_damping_value.y * ExportSettings.camera_descent_velocity_compensation


func _process(delta: float) -> void:
	if _pending_gate_limits.is_empty():
		return
	var host_camera: Camera2D = $Camera2D
	var half_screen: Vector2 = get_viewport_rect().size / (2.0 * host_camera.zoom.abs())
	var travel: Vector2 = half_screen * 2.0 * delta / maxf(0.01, ExportSettings.camera_gate_transition_duration)
	var settled: Array[Area2D] = []
	# 从当前画面边缘平滑推进新侧限位，抵达门边界后保持限位。
	for gate: Area2D in _pending_gate_limits:
		var limit: Vector3 = _pending_gate_limits[gate]
		var boundary: float = limit.y
		var margin: float = ExportSettings.camera_gate_margin
		match int(limit.x):
			SIDE_LEFT:
				limit.z = minf(boundary + margin, limit.z + travel.x)
				if limit.z >= boundary + margin:
					settled.append(gate)
			SIDE_TOP:
				limit.z = minf(boundary + margin, limit.z + travel.y)
				if limit.z >= boundary + margin:
					settled.append(gate)
			SIDE_RIGHT:
				limit.z = maxf(boundary - margin, limit.z - travel.x)
				if limit.z <= boundary - margin:
					settled.append(gate)
			SIDE_BOTTOM:
				limit.z = maxf(boundary - margin, limit.z - travel.y)
				if limit.z <= boundary - margin:
					settled.append(gate)
		_pending_gate_limits[gate] = limit
	for gate: Area2D in settled:
		var limit: Vector3 = _pending_gate_limits[gate]
		_gate_limits[gate] = Vector2(limit.x, limit.y)
		_pending_gate_limits.erase(gate)
	_apply_gate_limits()


func _unhandled_input(event: InputEvent) -> void:
	if input_locked and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_on_end_requested(_player)
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	_generation += 1
	if input_locked and is_instance_valid(_player):
		_player.process_mode = _saved_process_mode
		input_locked = false
		SignalBus.CameraInputLockChanged.emit(_player, false)


# 对外接口显式声明各镜头参数；内部沿用同一套切镜逻辑，兼容已接入的旧信号。
func _on_normal_requested(player: Node2D) -> void:
	_on_shot_requested(player, &"normal", {})


func _on_player_respawned(_position: Vector2) -> void:
	_on_shot_requested(_player, &"normal", {}, true)
	_base.teleport_position()
	$Camera2D.global_position = _base.get_transform_output().origin
	$Camera2D.reset_physics_interpolation()


func _on_desert_requested(player: Node2D, title: String, text: String, intro: bool, bounds: Rect2) -> void:
	_on_shot_requested(player, &"desert", {"title": title, "text": text, "intro": intro, "bounds": bounds})


func _on_descent_requested(player: Node2D, title: String, text: String, bounds: Rect2) -> void:
	_on_shot_requested(player, &"descent", {"title": title, "text": text, "bounds": bounds})


func _on_boat_requested(player: Node2D, follow_target: Node2D, title: String, text: String, bounds: Rect2) -> void:
	_on_shot_requested(player, &"boat", {"follow_target": follow_target, "title": title, "text": text, "bounds": bounds})


func _on_ritual_requested(player: Node2D, anchor: Node2D, title: String, text: String, bounds: Rect2) -> void:
	_on_shot_requested(player, &"ritual", {"anchor": anchor, "title": title, "text": text, "bounds": bounds})


func _on_fixed_requested(player: Node2D, anchor: Node2D, title: String, text: String, bounds: Rect2) -> void:
	_on_shot_requested(player, &"fixed", {"anchor": anchor, "title": title, "text": text, "bounds": bounds})


func _on_shot_requested(player: Node2D, mode: StringName, options: Dictionary, instant: bool = false) -> void:
	if player != _player:
		return
	if mode not in MODES:
		push_warning("Camera: unknown mode '%s'." % mode)
		return
	if mode in [&"ritual", &"fixed"]:
		if not is_instance_valid(options.get("anchor")) or not options.anchor is Node2D:
			push_warning("Camera: %s requires a live Node2D anchor." % mode)
			return
	if options.has("follow_target") and is_instance_valid(options.follow_target) and not options.follow_target is Node2D:
		push_warning("Camera: follow_target must be a Node2D.")
		return
	if mode == &"ritual" and current_mode != &"ritual":
		_previous_mode = current_mode
		_previous_options = _options.duplicate()
	_generation += 1
	current_mode = mode
	_options = options.duplicate()
	# 返回 CG 前的船体可能已离场，先验证再赋给强类型节点引用。
	var requested_target: Variant = options.get("follow_target", _player)
	_target = requested_target if is_instance_valid(requested_target) else _player
	_last_target_position = _target.global_position
	_target_velocity_y = 0.0
	_presentation.Prepare(mode, bool(options.get("intro", true)))
	_phase = &"close" if mode == &"ritual" else &""
	if mode == &"ritual":
		_lock_player()
		# 锚点取快照，最终空镜不会继续追踪移动中的标记。
		_options["anchor_position"] = (options.anchor as Node2D).global_position
	_start_camera(mode, instant)


func _on_end_requested(player: Node2D) -> void:
	if player != _player:
		return
	var mode: StringName = _previous_mode if current_mode == &"ritual" else &"normal"
	var options: Dictionary = _previous_options.duplicate() if current_mode == &"ritual" else {}
	options["intro"] = false
	options["title"] = ""
	options["text"] = ""
	if mode == &"fixed" and not is_instance_valid(options.get("anchor")):
		mode = &"normal"
		options = {}
	_on_shot_requested(_player, mode, options)


func _start_camera(mode: StringName, instant: bool = false) -> void:
	var next: PhantomCamera2D = $ShotB if _active == $ShotA else $ShotA
	if mode == &"normal":
		next = _base
	next.follow_axis_lock = PhantomCamera2D.FollowLockAxis.NONE
	next.follow_mode = PhantomCamera2D.FollowMode.FRAMED if mode == &"normal" else PhantomCamera2D.FollowMode.SIMPLE
	next.follow_target = _player if mode in [&"normal", &"ritual"] else _target
	next.follow_damping = true
	next.follow_damping_value = ExportSettings.player_camera_damping
	next.follow_offset = ExportSettings.player_camera_offset
	var zoom_value: float = ExportSettings.player_camera_zoom
	var axis_lock: PhantomCamera2D.FollowLockAxis = PhantomCamera2D.FollowLockAxis.NONE
	_frame = Vector2(0.5, 0.5)
	match mode:
		&"normal":
			next.follow_damping = ExportSettings.player_camera_smoothing
			next.follow_offset = ExportSettings.player_camera_offset
		&"desert":
			zoom_value = ExportSettings.camera_desert_zoom
			_frame = ExportSettings.camera_desert_frame
			next.follow_damping_value = ExportSettings.camera_desert_damping
		&"descent":
			zoom_value = ExportSettings.camera_descent_zoom
			_frame = ExportSettings.camera_descent_frame
			next.follow_damping_value = ExportSettings.camera_descent_damping
			if bool(_options.get("level2_slow_descent", false)):
				_frame = Vector2(0.5, ExportSettings.level2_descent_frame_y)
				next.follow_damping_value = ExportSettings.level2_descent_camera_damping
			axis_lock = PhantomCamera2D.FollowLockAxis.X
		&"boat":
			zoom_value = ExportSettings.camera_boat_zoom
			_frame = ExportSettings.camera_boat_frame
			next.follow_damping_value = ExportSettings.camera_boat_damping
			axis_lock = PhantomCamera2D.FollowLockAxis.Y
		&"fixed":
			zoom_value = ExportSettings.camera_fixed_zoom
			_set_fixed_target(next, (_options.anchor as Node2D).global_position)
		&"ritual":
			next.follow_damping = false
			zoom_value = ExportSettings.camera_ritual_close_zoom
			next.follow_offset = Vector2.ZERO
			if _phase == &"wide":
				zoom_value = ExportSettings.camera_ritual_wide_zoom
				_set_fixed_target(next, _options.anchor_position)
	next.zoom = Vector2.ONE * maxf(zoom_value, 0.05)
	if mode in [&"desert", &"descent", &"boat"]:
		next.follow_offset = _frame_offset(next.zoom.x)
	if next != _base:
		var bounds: Rect2 = _options.get("bounds", Rect2())
		var base_bounds: Vector4i = _camera_bounds[_base]
		_camera_bounds[next] = Vector4i(floori(bounds.position.x), floori(bounds.position.y), ceili(bounds.end.x), ceili(bounds.end.y)) if bounds.has_area() else base_bounds
	_apply_gate_limits()
	next.set_tween_duration(0.0 if instant else maxf(0.01, ExportSettings.camera_ritual_pan_duration if _phase == &"wide" else ExportSettings.camera_transition_duration))
	if next == _active:
		_pending = true
		_on_arrived(next)
		return
	next.teleport_position()
	next.follow_axis_lock = axis_lock
	_active = next
	_sync_host_limits(next)
	_pending = true
	# 先提升新镜头，再降低旧镜头，避免过渡途经第三个镜头。
	var priority: int = ExportSettings.player_camera_priority + 20
	next.priority = priority + 1
	for camera: PhantomCamera2D in [_base, $ShotA, $ShotB]:
		if camera != next:
			camera.priority = 0
	next.priority = ExportSettings.player_camera_priority if mode == &"normal" else priority
	call_deferred("_check_activation", _generation)


func _check_activation(generation: int) -> void:
	if generation == _generation and _pending and not _active.is_active():
		_on_camera_interrupted(_active)


func _set_fixed_target(camera: PhantomCamera2D, position_value: Vector2) -> void:
	var anchor: Marker2D = $AnchorA if camera == $ShotA else $AnchorB
	anchor.global_position = position_value
	camera.follow_target = anchor
	camera.follow_offset = Vector2.ZERO
	camera.follow_damping = false


func _on_camera_interrupted(camera: PhantomCamera2D) -> void:
	# 插件重新选择同一台镜头时也会短暂发送 inactive；等本轮选择完成再判断。
	call_deferred("_resolve_camera_interruption", camera, _generation)


func _resolve_camera_interruption(camera: PhantomCamera2D, generation: int) -> void:
	# 其他系统的更高优先级镜头接管时，不能留下锁输入或过期字幕。
	if generation != _generation or camera != _active or camera.is_active():
		return
	_generation += 1
	_pending = false
	_phase = &""
	_presentation.Clear()
	_unlock_player()
	current_mode = &"normal"
	_target = _player
	_active = _base
	$ShotA.priority = 0
	$ShotB.priority = 0
	_base.priority = ExportSettings.player_camera_priority


func _on_camera_gate_changed(player: Node2D, gate: Area2D, active: bool, side: int, boundary: float) -> void:
	if player != _player:
		return
	if active:
		_gate_limits[gate] = Vector2(side, boundary)
	else:
		_gate_limits.erase(gate)
	_apply_gate_limits()


func _on_camera_gate_side_changed(player: Node2D, gate: Area2D, side: int, boundary: float, reset: bool) -> void:
	if player != _player:
		return
	var limit := Vector2(side, boundary)
	if reset:
		_pending_gate_limits.erase(gate)
		_gate_limits[gate] = limit
	else:
		# 从画面同侧边缘推进限位，推动镜头跨门，完成后固定在新侧。
		var host_camera: Camera2D = $Camera2D
		var center: Vector2 = host_camera.get_screen_center_position()
		var half_screen: Vector2 = get_viewport_rect().size / (2.0 * host_camera.zoom.abs())
		var edge: float
		match side:
			SIDE_LEFT:
				edge = center.x - half_screen.x
			SIDE_TOP:
				edge = center.y - half_screen.y
			SIDE_RIGHT:
				edge = center.x + half_screen.x
			SIDE_BOTTOM:
				edge = center.y + half_screen.y
		_gate_limits.erase(gate)
		_pending_gate_limits[gate] = Vector3(side, boundary, edge)
	_apply_gate_limits()


func _on_camera_gate_side_removed(player: Node2D, gate: Area2D) -> void:
	if player != _player:
		return
	_pending_gate_limits.erase(gate)
	_gate_limits.erase(gate)
	_apply_gate_limits()


func _apply_gate_limits() -> void:
	for camera: PhantomCamera2D in [_base, $ShotA, $ShotB]:
		var bounds: Vector4i = _camera_bounds[camera]
		var left: int = bounds.x
		var top: int = bounds.y
		var right: int = bounds.z
		var bottom: int = bounds.w
		for gate: Area2D in _gate_limits:
			var limit: Vector2 = _gate_limits[gate]
			match int(limit.x):
				SIDE_LEFT:
					left = maxi(left, ceili(limit.y + ExportSettings.camera_gate_margin))
				SIDE_TOP:
					top = maxi(top, ceili(limit.y + ExportSettings.camera_gate_margin))
				SIDE_RIGHT:
					right = mini(right, floori(limit.y - ExportSettings.camera_gate_margin))
				SIDE_BOTTOM:
					bottom = mini(bottom, floori(limit.y - ExportSettings.camera_gate_margin))
		for gate: Area2D in _pending_gate_limits:
			var moving: Vector3 = _pending_gate_limits[gate]
			match int(moving.x):
				SIDE_LEFT:
					left = maxi(left, ceili(moving.z))
				SIDE_TOP:
					top = maxi(top, ceili(moving.z))
				SIDE_RIGHT:
					right = mini(right, floori(moving.z))
				SIDE_BOTTOM:
					bottom = mini(bottom, floori(moving.z))
		camera.limit_left = left
		camera.limit_top = top
		camera.limit_right = right
		camera.limit_bottom = bottom
	if _active != null:
		_sync_host_limits(_active)


func _on_camera_tweening(camera: PhantomCamera2D) -> void:
	if camera == _active:
		# 插件在切镜首帧临时重置 Camera2D 限位，逐帧恢复已合并的边界。
		_sync_host_limits(camera)


func _sync_host_limits(camera: PhantomCamera2D) -> void:
	var host_camera: Camera2D = $Camera2D
	host_camera.limit_left = camera.limit_left
	host_camera.limit_top = camera.limit_top
	host_camera.limit_right = camera.limit_right
	host_camera.limit_bottom = camera.limit_bottom


func _frame_offset(zoom_value: float) -> Vector2:
	return (Vector2(0.5, 0.5) - _frame) * get_viewport_rect().size / maxf(0.05, zoom_value)


func _on_arrived(camera: PhantomCamera2D) -> void:
	if camera != _active or not _pending:
		return
	_pending = false
	if current_mode == &"ritual" and _phase == &"close":
		var generation: int = _generation
		await get_tree().create_timer(maxf(0.01, ExportSettings.camera_ritual_close_hold), false).timeout
		if generation != _generation:
			return
		_phase = &"wide"
		_start_camera(&"ritual")
		return
	if current_mode != &"ritual":
		_unlock_player()
	_presentation.Present(current_mode, str(_options.get("title", "")), str(_options.get("text", "")), bool(_options.get("intro", true)))
	SignalBus.CameraShotReady.emit(_player, current_mode)


func _lock_player() -> void:
	if input_locked:
		return
	_saved_process_mode = _player.process_mode
	input_locked = true
	_player.process_mode = Node.PROCESS_MODE_DISABLED
	SignalBus.CameraInputLockChanged.emit(_player, true)


func _unlock_player() -> void:
	if not input_locked:
		return
	_player.process_mode = _saved_process_mode
	input_locked = false
	SignalBus.CameraInputLockChanged.emit(_player, false)
