extends StateMachine

var _rope_pose_active: bool = false

func _ready() -> void:
	SignalBus.PlayerGrapplePhaseChanged.connect(_on_grapple_phase_changed)
	var animator: AnimationPlayer = get_parent().get_node("ani_move")
	animator.animation_finished.connect(_on_animation_finished)
	# 每个玩家使用独立动画资源；参数只修改轨道值，人物帧与显隐仍由 ani_move 播放。
	var library: AnimationLibrary = animator.get_animation_library("").duplicate(true)
	animator.remove_animation_library("")
	animator.add_animation_library("", library)
	for animation_name in [&"RopeSend", &"fly"]:
		var animation := animator.get_animation(animation_name)
		var position_track := animation.find_track(NodePath("sprite/Action:position"), Animation.TYPE_VALUE)
		var scale_track := animation.find_track(NodePath("sprite/Action:scale"), Animation.TYPE_VALUE)
		animation.track_set_key_value(position_track, 0, ExportSettings.rope_visual_player_offset)
		animation.track_set_key_value(scale_track, 0, Vector2.ONE * ExportSettings.rope_visual_player_scale)

## 查询人物是否由绳索动作占用；无参数，返回 true 时锁定发射朝向。
func IsRopePoseActive() -> bool:
	return _rope_pose_active

func _on_grapple_phase_changed(player: Node2D, phase: StringName, target_pos: Vector2) -> void:
	if player != obj:
		return
	if phase == &"":
		_rope_pose_active = false
		if cur_state_name in ["rope_send", "fly"] and obj.now_HP > 0.0:
			_resume_movement()
		return
	if obj.now_HP <= 0.0 or cur_state_name in ["hurt", "died"]:
		return
	if phase == &"RopeSend":
		_rope_pose_active = true
		obj.SetFacingDirection(-1 if target_pos.x < obj.global_position.x else 1)
		# jump/dash 会暂时禁用其他状态，但不能阻止已经成功发射的绳索接管人物动作。
		state_map["rope_send"].is_use = true
		change_state("rope_send")
	elif phase == &"fly" and _rope_pose_active:
		# 近距离命中也保留完整两帧发射；挂接、拉拽和摆动共用 fly。
		if cur_state_name != "rope_send":
			change_state("fly")

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == &"RopeSend" and _rope_pose_active and cur_state_name == "rope_send":
		change_state("fly")

func _resume_movement() -> void:
	if obj.IsInWaterFlow():
		change_state("shuttle")
	elif not obj.is_on_floor():
		change_state("fall")
	else:
		change_state("run" if gameInputControl.row_dir != 0.0 else "idle")

## 兼容状态机基类的状态迁移接口；next_state_name 为已有状态名，受伤/死亡优先于绳索动作。
func change_state(next_state_name: String) -> void:
	if cur_state_name == "died" and obj and obj.now_HP <= 0.0:
		return
	if next_state_name in ["hurt", "died"]:
		_rope_pose_active = false
	elif _rope_pose_active and next_state_name not in ["rope_send", "fly"]:
		return
	super.change_state(next_state_name)

func phy_middleware() -> void:
	if not gameInputControl:
		return
	# 受伤、死亡和持绳动作不被普通移动、跳跃或攀爬动画抢占。
	if cur_state_name in ["hurt", "died"] or _rope_pose_active:
		return
	if cur_state_name == "climb" and current_state.is_wall_kicking:
		return
	# 如果处于流水穿梭状态且仍在水流区域内，保持穿梭状态，不被 run / idle 打断
	if cur_state_name == "shuttle":
		if obj and obj.has_method("IsInWaterFlow") and obj.IsInWaterFlow():
			if gameInputControl.is_jump:
				change_state("jump")
			elif "is_double_jump" in gameInputControl and gameInputControl.is_double_jump:
				change_state("jump")
			return
		else:
			# 离开水流区域后平滑切回下落或普通状态
			if not obj.is_on_floor():
				change_state("fall")
				return

	if gameInputControl.is_fall:
		change_state("fall")
	elif not obj.is_on_floor() and obj.velocity.y < 0.0 and cur_state_name in ["idle", "run", "fall"]:
		change_state("fall")
	if gameInputControl.is_idle:
		change_state("idle")
	if gameInputControl.is_run:
		change_state("run")
	if gameInputControl.is_jump:
		change_state("jump")
	if "is_double_jump" in gameInputControl and gameInputControl.is_double_jump:
		# 如果已经在 jump 状态中，先 exit 或直接允许重新进入以赋二段跳速度
		if cur_state_name == "jump":
			var jump_state = state_map.get("jump")
			if jump_state:
				jump_state.exit()
				jump_state.enter()
		else:
			change_state("jump")
	if gameInputControl.is_dash:
		change_state("dash")
	if obj and obj.is_front_has_rigid:
		change_state("climb")
