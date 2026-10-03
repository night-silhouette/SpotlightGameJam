extends RefCounted
## 运行于 CameraShowcase 的行为回归检查；不提交输入映射或修改项目配置。

var _results: Dictionary = {}


## 在已经就绪的 CameraShowcase 内执行；返回每项行为是否通过。执行中会移动演示玩家。
func Run(scene: Node) -> Dictionary:
	_results.clear()
	var tree: SceneTree = scene.get_tree()
	var rig: Node = scene.get_node("PlayerWithCamera")
	var player: Node2D = rig.get_node("Player")
	var camera: Camera2D = rig.get_node("Camera2D")
	var text: Control = rig.get_node("CameraPresentation/Root/Narration")
	SignalBus.CameraShotEndRequested.emit(player)
	await tree.create_timer(1.5).timeout
	scene._select(1)
	await tree.create_timer(1.6).timeout
	var frame: Vector2 = player.get_global_transform_with_canvas().origin / camera.get_viewport_rect().size
	_results["desert_lower_left"] = frame.distance_to(ExportSettings.camera_desert_frame) < 0.03
	await tree.create_timer(2.0).timeout
	_results["intro_removed_and_text_visible"] = not rig.get_node("CameraPresentation/Root/Blur").visible and rig.get_node("CameraPresentation/Root/Curtain").modulate.a < 0.01 and not text.message.is_empty()
	scene._select(2)
	await tree.create_timer(3.0).timeout
	frame = player.get_global_transform_with_canvas().origin / camera.get_viewport_rect().size
	_results["descent_bottom_visible"] = frame.y > 0.6 and frame.y < 0.85
	var position_before: Vector2 = camera.global_position
	Input.action_press("move_r")
	await tree.create_timer(0.5).timeout
	Input.action_release("move_r")
	_results["descent_x_locked"] = absf(camera.global_position.x - position_before.x) < 0.1 and camera.global_position.y > position_before.y
	scene._select(3)
	await tree.create_timer(2.0).timeout
	position_before = camera.global_position
	await tree.create_timer(0.8).timeout
	_results["boat_horizontal_only"] = camera.global_position.x > position_before.x + 50 and absf(camera.global_position.y - position_before.y) < 0.1
	scene._select(5)
	await tree.create_timer(1.5).timeout
	position_before = camera.global_position
	var player_before: Vector2 = player.global_position
	Input.action_press("move_r")
	await tree.create_timer(0.5).timeout
	Input.action_release("move_r")
	_results["fixed_room_player_can_move"] = camera.global_position.distance_to(position_before) < 0.1 and player.global_position.x > player_before.x + 30
	scene._select(4)
	player_before = player.global_position
	Input.action_press("move_r")
	Input.action_press("jump")
	Input.action_press("dash")
	await tree.create_timer(1.5).timeout
	_results["ritual_input_locked_no_early_text"] = rig.input_locked and player.global_position.distance_to(player_before) < 0.1 and text.message.is_empty()
	Input.action_release("move_r")
	Input.action_release("jump")
	Input.action_release("dash")
	await tree.create_timer(3.6).timeout
	_results["ritual_arrival_then_text"] = camera.global_position.distance_to(scene.get_node("RitualAnchor").global_position) < 0.1 and not text.message.is_empty() and rig.input_locked
	SignalBus.CameraShotEndRequested.emit(player)
	await tree.create_timer(1.5).timeout
	_results["ritual_restore_previous_mode_and_input"] = rig.current_mode == &"fixed" and not rig.input_locked and player.process_mode == Node.PROCESS_MODE_INHERIT
	# CG 在近景停留期间取消；旧延迟回调不能再把镜头切回空镜。
	scene._select(4)
	await tree.create_timer(1.3).timeout
	SignalBus.CameraShotEndRequested.emit(player)
	await tree.create_timer(2.0).timeout
	_results["cancel_invalidates_old_callbacks"] = rig.current_mode == &"fixed" and not rig.input_locked and text.message.is_empty()
	# 连续切换时，最后一次请求必须成为最终镜头，黑幕不能残留。
	SignalBus.CameraDesertRequested.emit(player, "", "旧字幕", true, Rect2())
	SignalBus.CameraBoatRequested.emit(player, scene.get_node("Boat"), "", "", Rect2())
	SignalBus.CameraNormalRequested.emit(player)
	await tree.create_timer(1.5).timeout
	_results["rapid_switch_last_request_wins"] = rig.current_mode == &"normal" and not rig._pending and text.message.is_empty() and rig.get_node("CameraPresentation/Root/Curtain").modulate.a < 0.01
	_results["normal_priority_restored"] = rig.get_node("PhantomCamera2D").priority == ExportSettings.player_camera_priority
	# 新接口必须只作用于指定玩家，同时保留旧关卡的通用请求接口。
	SignalBus.CameraDescentRequested.emit(scene.get_node("Boat"), "", "", Rect2())
	_results["other_player_request_ignored"] = rig.current_mode == &"normal"
	SignalBus.CameraShotRequested.emit(player, &"descent", {"title": "兼容标题", "text": "兼容正文"})
	_results["legacy_request_compatible"] = rig.current_mode == &"descent" and rig._options.title == "兼容标题" and rig._options.text == "兼容正文"
	# 检查显式参数的传递与空船体目标回退；范围要足够大，避免边界限制干扰其他测试。
	var bounds := Rect2(-10000, -10000, 20000, 20000)
	SignalBus.CameraDesertRequested.emit(player, "接口标题", "接口正文", false, bounds)
	await tree.create_timer(1.5).timeout
	_results["explicit_parameters_and_intro_skip"] = rig._options.title == "接口标题" and rig._options.text == "接口正文" and rig._active.limit_left == -10000 and rig._active.limit_right == 10000 and not rig.get_node("CameraPresentation/Root/Blur").visible and rig.get_node("CameraPresentation/Root/Curtain").modulate.a < 0.01
	SignalBus.CameraBoatRequested.emit(player, null, "", "", Rect2())
	_results["null_boat_target_uses_player"] = rig._target == player and rig.current_mode == &"boat"
	scene._select(1)
	return _results.duplicate()
