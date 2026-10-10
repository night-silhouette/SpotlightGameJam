extends SceneTree

var _failures: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error(description)

func _shoot(player: Node, direction: float = 1.0) -> void:
	var rope: Node = player.rope_controller
	rope.can_use_rope = true
	rope.has_touch_aim = true
	rope.touch_aim_position = player.global_position + Vector2(direction * 300.0, -100.0)
	_check(rope.ShootRope(), "应成功发射绳索")

func _run() -> void:
	var packed: PackedScene = load("res://Code/Entities/Player/Player.tscn")
	var player: Node = packed.instantiate()
	root.add_child(player)
	# 暂停自动处理但保留物理空间，供下方手动 _physics_process 验证。
	player.disable_mode = CollisionObject2D.DISABLE_MODE_KEEP_ACTIVE
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var machine: Node = player.move_state_machine
	var animator: AnimationPlayer = player.ani_move
	var rope: Node = player.rope_controller
	var action: Sprite2D = player.get_node("sprite/Action")
	var origin: Marker2D = action.get_node("RopeOrigin")
	var settings: Node = root.get_node("ExportSettings")
	var bus: Node = root.get_node("SignalBus")
	await physics_frame
	_check(animator.has_animation("RopeSend") and animator.has_animation("fly"), "ani_move 必须拥有严格命名的 RopeSend、fly")
	_check(not player.has_node("GrappleVisual/Deploy"), "独立视觉层不再含人物 Sprite")
	_check(origin.position.is_equal_approx(Vector2(-5.5555553, -33.333336)), "手调 Marker 坐标不可丢失")
	_check(is_equal_approx(settings.rope_visual_width, 1.5) and is_equal_approx(settings.rope_visual_hook_scale, 0.4), "绳宽和钩头缩放须保留")

	_shoot(player)
	_check(machine.cur_state_name == "rope_send" and animator.current_animation == "RopeSend", "成功发射须立即进入发射状态及动画")
	_check(action.frame == 0 and action.visible and player.sprite.visible, "发射第一帧由 ani_move 显示")
	var expected: Vector2 = settings.rope_visual_player_offset + origin.position * settings.rope_visual_player_scale
	_check(player.to_local(origin.global_position).is_equal_approx(expected), "右向发射点必须保留原偏移与缩放换算")
	_check(rope.fly_tip_pos.is_equal_approx(origin.global_position), "控制器必须从应用动画后的 Marker 发射")
	var launch_pos: Vector2 = origin.global_position
	_check(rope.fly_start_pos.is_equal_approx(launch_pos) and rope.fly_previous_tip_pos.is_equal_approx(launch_pos), "发射时固定起点并初始化前一端点")
	var saved_marker_pos: Vector2 = origin.position
	origin.position += Vector2(12.0, 8.0)
	rope.collision_mask = 0
	rope._process_flying(0.02)
	_check(rope.fly_previous_tip_pos.is_equal_approx(launch_pos), "首个物理步的前一端点应是发射点")
	_check(rope.fly_tip_pos.is_equal_approx(launch_pos + rope.fly_dir * rope.rope_speed * 0.02), "手部位移不能改变首个飞行端点")
	var first_tip: Vector2 = rope.fly_tip_pos
	rope._process_flying(0.02)
	_check(rope.fly_previous_tip_pos.is_equal_approx(first_tip), "每个物理步须记录旧端点")
	_check(rope.fly_tip_pos.is_equal_approx(launch_pos + rope.fly_dir * rope.rope_speed * 0.04), "后续端点仍依据固定发射起点计算")
	_check(rope.fly_start_pos.is_equal_approx(launch_pos), "飞行中发射原点不得随手部移动")
	origin.position = saved_marker_pos
	rope.collision_mask = settings.rope_collision_mask
	animator.advance(1.1 / settings.rope_visual_deploy_fps)
	_check(action.frame == 1, "发射第二帧应由动画轨道播放")
	for state in ["idle", "run", "jump", "fall", "climb", "dash", "shuttle"]:
		machine.change_state(state)
		_check(machine.cur_state_name == "rope_send", "发射不能被 %s 抢占" % state)
	rope.hook_point = player.global_position + Vector2(100.0, -100.0)
	rope._update_line()
	var visual: Node2D = player.get_node("GrappleVisual")
	visual._process(0.0)
	_check(visual.get_node("Rope").is_visible_in_tree() and visual.get_node("Hook").is_visible_in_tree(), "持绳时绳身和钩头必须在场景树中实际可见")
	bus.PlayerGrapplePhaseChanged.emit(player, &"fly", rope.hook_point)
	_check(machine.cur_state_name == "rope_send", "近距离挂接不跳过发射第二帧")
	rope.TriggerPull() # 飞行阶段不应改变物理状态。
	animator.advance(1.1 / settings.rope_visual_deploy_fps)
	_check(machine.cur_state_name == "fly" and animator.current_animation == "fly", "发射结束自动进入 fly")
	_check(action.texture.resource_path.ends_with("graphook/fly.png"), "fly 使用人物素材而非绳子图片")
	rope.current_state = rope.RopeState.LATCHED
	rope.TriggerPull()
	_check(rope.current_state == rope.RopeState.PULLING and machine.cur_state_name == "fly", "拉拽保持 fly")
	rope.current_state = rope.RopeState.LATCHED
	rope.TriggerSwing()
	_check(rope.current_state == rope.RopeState.SWINGING and machine.cur_state_name == "fly", "摆动保持 fly")
	rope.ReleaseRope()
	visual._process(0.0)
	_check(not visual.get_node("Rope").is_visible_in_tree() and not visual.get_node("Hook").is_visible_in_tree(), "释放后绳身和钩头必须隐藏")
	animator.advance(0.0)
	_check(machine.cur_state_name == "fall" and not machine.IsRopePoseActive(), "空中释放恢复移动状态")
	_check(action.scale.is_equal_approx(Vector2(0.36287013, 0.36287013)), "退出后恢复普通动作缩放")

	_shoot(player)
	_check(machine.cur_state_name == "rope_send" and animator.current_animation == "RopeSend", "再次发射先进入 RopeSend")
	rope.hook_point = player.global_position + Vector2(100.0, -100.0)
	rope.current_state = rope.RopeState.LATCHED
	rope.TriggerPull()
	_check(rope.current_state == rope.RopeState.PULLING and machine.cur_state_name == "fly" and animator.current_animation == "fly", "RopeSend 未播完时开始拉拽须立即进入 fly")
	rope.ReleaseRope()

	_shoot(player, -1.0)
	_check(player.face_dir == -1 and player.sprite.scale.x < 0.0, "左向人物朝向必须同步")
	_check(player.to_local(origin.global_position).is_equal_approx(expected * Vector2(-1, 1)), "左向发射点必须镜像原手调坐标")
	_check(rope.fly_tip_pos.is_equal_approx(origin.global_position), "左向发射点无一帧延迟")
	player.gameInputControl.row_dir = 1.0
	player._physics_process(0.0)
	_check(player.face_dir == -1, "反向移动输入不能改变持绳人物朝向")
	rope.collision_mask = 0
	rope._process_flying(1.0)
	_check(rope.current_state == rope.RopeState.IDLE and not machine.IsRopePoseActive(), "射程落空必须退出绳索动作")
	animator.advance(1.0)
	_check(machine.cur_state_name != "fly", "过期的动画完成回调不能复活持绳状态")

	_shoot(player)
	player.ApplyDamage(1.0, Vector2(20.0, -10.0))
	animator.advance(0.0)
	_check(machine.cur_state_name == "hurt" and animator.current_animation == "hit", "受伤优先打断绳索动作")
	_check(rope.current_state == rope.RopeState.IDLE and not machine.IsRopePoseActive(), "受伤解除绳索约束与动作锁")
	bus.PlayerGrapplePhaseChanged.emit(player, &"RopeSend", Vector2.ZERO)
	_check(machine.cur_state_name == "hurt", "受伤期间发射通知不得抢占")
	await create_timer(player.hurt_time + 0.05).timeout
	_shoot(player)
	player.now_HP = 0.0
	animator.advance(0.0)
	_check(machine.cur_state_name == "died" and animator.current_animation == "death", "死亡优先打断绳索动作")
	bus.PlayerGrapplePhaseChanged.emit(player, &"fly", Vector2.ZERO)
	_check(machine.cur_state_name == "died", "死亡不可被迟到的绳索事件覆盖")
	await create_timer(settings.tent_respawn_delay + 0.05).timeout
	_check(machine.cur_state_name == "idle" and player.now_HP == player.Max_HP and not machine.IsRopePoseActive(), "重生恢复 idle 与满血")

	# 其他玩家的通知不能影响本玩家。
	var other := Node2D.new()
	root.add_child(other)
	bus.PlayerGrapplePhaseChanged.emit(other, &"RopeSend", Vector2.ZERO)
	_check(machine.cur_state_name == "idle", "带玩家引用的信号应隔离实例")
	other.queue_free()
	player.queue_free()
	await process_frame
	print("GrappleAnimationTest: %s" % ("PASS" if _failures == 0 else "%d failures" % _failures))
	quit(0 if _failures == 0 else 1)
