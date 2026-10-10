extends "res://Code/Entities/PlayerWithCamera/PlayerWithCamera.gd"
## 第二关适配层：复用项目镜头导演/Phantom Camera，只覆盖本关视野与阻尼。
## 不覆盖玩家物理参数，不修改 ExportSettings 的其他关卡镜头值。

var _framing_offset: Vector2 = Vector2.ZERO

func _sync_player_properties() -> void:
	# 玩家自身已经读取全局玩家设置，避免镜头包装覆盖已验证的跳跃参数。
	pass

func _enter_tree() -> void:
	super._enter_tree()
	$PhantomCamera2D.zoom = Vector2.ONE * _level_zoom()
	$PhantomCamera2D.follow_offset = ExportSettings.level2_camera_offset

func _start_camera(mode: StringName) -> void:
	if mode != &"normal" and mode != &"descent":
		super._start_camera(mode)
		return
	# 连续探索使用同一台 Phantom Camera，避免高速下落被过场插值拖住。
	_active = _base
	_base.follow_mode = PhantomCamera2D.FollowMode.SIMPLE
	_base.follow_axis_lock = PhantomCamera2D.FollowLockAxis.NONE
	_base.follow_target = _target
	_base.tween_on_load = false
	_base.set_tween_duration(0.0)
	_base.priority = ExportSettings.player_camera_priority + 1
	$ShotA.priority = 0
	$ShotB.priority = 0
	_base.priority = ExportSettings.player_camera_priority
	_apply_level_framing()
	_pending = true
	_on_arrived(_base)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_mode == &"normal" or current_mode == &"descent":
		_apply_level_framing(delta)

func _level_zoom() -> float:
	var viewport_size: Vector2 = get_viewport_rect().size
	return maxf(viewport_size.x / maxf(640.0, ExportSettings.level2_view_width),
		viewport_size.y / maxf(400.0, ExportSettings.level2_camera_max_view_height))

func _apply_level_framing(delta: float = 0.0) -> void:
	if not is_instance_valid(_active):
		return
	if current_mode != &"normal" and current_mode != &"descent":
		return
	var level_zoom: float = _level_zoom()
	if not _active.zoom.is_equal_approx(Vector2.ONE * level_zoom):
		_active.zoom = Vector2.ONE * level_zoom
	_active.follow_damping = true
	_active.follow_damping_value = ExportSettings.level2_camera_damping
	var desired_offset: Vector2 = ExportSettings.level2_camera_offset
	if current_mode == &"descent":
		_active.follow_damping_value = ExportSettings.level2_camera_shaft_damping
		var frame_y: float = ExportSettings.level2_camera_ascent_frame_y if bool(_options.get("level2_ascent", false)) else ExportSettings.level2_camera_descent_frame_y
		_frame = Vector2(0.5, frame_y)
		desired_offset = _frame_offset(level_zoom)
		desired_offset.y += _player.velocity.y * _active.follow_damping_value.y
	if delta > 0.0:
		var blend: float = 1.0 - exp(-delta * 4.0 / maxf(0.01, ExportSettings.level2_camera_transition_time))
		_framing_offset = _framing_offset.lerp(desired_offset, blend)
	_active.follow_offset = _framing_offset
	var bounds: Rect2 = _options.get("bounds", Rect2())
	if bounds.has_area():
		var visible_size: Vector2 = get_viewport_rect().size / level_zoom
		var expanded_size: Vector2 = bounds.size.max(visible_size + Vector2(2, 2))
		bounds = Rect2(bounds.get_center() - expanded_size * 0.5, expanded_size)
		_active.limit_left = floori(bounds.position.x)
		_active.limit_top = floori(bounds.position.y)
		_active.limit_right = ceili(bounds.end.x)
		_active.limit_bottom = ceili(bounds.end.y)

## 仅在出生或重生时让镜头立即就位；普通房间切换保持平滑。
func SnapToPlayer() -> void:
	if not is_instance_valid(_active):
		return
	_target_velocity_y = 0.0
	_last_target_position = _target.global_position
	_framing_offset = ExportSettings.level2_camera_offset
	if current_mode == &"descent":
		_frame = Vector2(0.5, ExportSettings.level2_camera_ascent_frame_y if bool(_options.get("level2_ascent", false)) else ExportSettings.level2_camera_descent_frame_y)
		_framing_offset = _frame_offset(_level_zoom())
	_apply_level_framing()
	_active.teleport_position()
	$Camera2D.global_position = _active.global_position
	$Camera2D.reset_smoothing()
	$Camera2D.force_update_scroll()
