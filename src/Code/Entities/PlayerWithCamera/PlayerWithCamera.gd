extends Node2D
## 原玩家 + Phantom Camera。默认普通跟随，关卡经 SignalBus 请求五种镜头。
## 原 Player 和插件均不修改；CG 只暂停本组件的玩家子树。

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


func _ready() -> void:
	_active = _base
	_target = _player
	for camera: PhantomCamera2D in [_base, $ShotA, $ShotB]:
		camera.tween_resource = PhantomCameraTween.new()
		camera.set_tween_transition(Tween.TRANS_SINE)
		camera.set_tween_ease(Tween.EASE_IN_OUT)
		camera.tween_completed.connect(_on_arrived.bind(camera))
		camera.became_inactive.connect(_on_camera_interrupted.bind(camera))
	_base.teleport_position()
	SignalBus.CameraNormalRequested.connect(_on_normal_requested)
	SignalBus.CameraDesertRequested.connect(_on_desert_requested)
	SignalBus.CameraDescentRequested.connect(_on_descent_requested)
	SignalBus.CameraBoatRequested.connect(_on_boat_requested)
	SignalBus.CameraRitualRequested.connect(_on_ritual_requested)
	SignalBus.CameraFixedRequested.connect(_on_fixed_requested)
	SignalBus.CameraShotRequested.connect(_on_shot_requested)
	SignalBus.CameraShotEndRequested.connect(_on_end_requested)


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


func _on_shot_requested(player: Node2D, mode: StringName, options: Dictionary) -> void:
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
	_start_camera(mode)


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


func _start_camera(mode: StringName) -> void:
	var next: PhantomCamera2D = $ShotB if _active == $ShotA else $ShotA
	if mode == &"normal":
		next = _base
	next.follow_axis_lock = PhantomCamera2D.FollowLockAxis.NONE
	next.follow_mode = PhantomCamera2D.FollowMode.SIMPLE
	next.follow_target = _player if mode == &"ritual" else _target
	next.follow_damping = true
	next.follow_damping_value = ExportSettings.player_camera_damping
	next.follow_offset = ExportSettings.player_camera_offset
	var zoom_value: float = ExportSettings.player_camera_zoom
	var axis_lock: PhantomCamera2D.FollowLockAxis = PhantomCamera2D.FollowLockAxis.NONE
	_frame = Vector2(0.5, 0.5)
	match mode:
		&"normal":
			next.follow_damping = ExportSettings.player_camera_smoothing
		&"desert":
			zoom_value = ExportSettings.camera_desert_zoom
			_frame = ExportSettings.camera_desert_frame
			next.follow_damping_value = ExportSettings.camera_desert_damping
		&"descent":
			zoom_value = ExportSettings.camera_descent_zoom
			_frame = ExportSettings.camera_descent_frame
			next.follow_damping_value = ExportSettings.camera_descent_damping
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
		next.limit_left = int(bounds.position.x) if bounds.has_area() else _base.limit_left
		next.limit_top = int(bounds.position.y) if bounds.has_area() else _base.limit_top
		next.limit_right = int(bounds.end.x) if bounds.has_area() else _base.limit_right
		next.limit_bottom = int(bounds.end.y) if bounds.has_area() else _base.limit_bottom
	next.set_tween_duration(maxf(0.01, ExportSettings.camera_ritual_pan_duration if _phase == &"wide" else ExportSettings.camera_transition_duration))
	if next == _active:
		_pending = true
		_on_arrived(next)
		return
	next.teleport_position()
	next.follow_axis_lock = axis_lock
	_active = next
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
