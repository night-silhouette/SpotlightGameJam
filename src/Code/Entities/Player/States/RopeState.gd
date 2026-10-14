extends State

func enter() -> void:
	super.enter()
	var animation_name: StringName = &"RopeSend" if name == &"rope_send" else &"fly_right"
	var fps: float = ExportSettings.rope_visual_deploy_fps if name == &"rope_send" else ExportSettings.rope_visual_fly_fps
	var animation := animation_player.get_animation(animation_name)
	var frame_count: float = 2.0 if name == &"rope_send" else 3.0
	animation_player.play(animation_name, -1.0, animation.length * fps / frame_count)
	# 发射点必须在同一次发射调用内取得本帧姿势，而不是等待下一渲染帧。
	animation_player.advance(0.0)

func physics_process(_delta: float) -> void:
	if name != &"fly":
		return
	var rope: RopeController = obj.rope_controller
	var animation_name: StringName = &"fly_right"
	if rope.current_state == RopeController.RopeState.SWINGING and obj.velocity.x * obj.face_dir > 1.0:
		animation_name = &"fly_left"
	elif rope.current_state == RopeController.RopeState.SWINGING and abs(obj.velocity.x) <= 1.0:
		return
	if animation_player.current_animation != animation_name:
		var animation := animation_player.get_animation(animation_name)
		animation_player.play(animation_name, -1.0, animation.length * ExportSettings.rope_visual_fly_fps / 3.0)
		animation_player.advance(0.0)

func exit() -> void:
	# 由 ani_move 恢复动作缩放和偏移，避免持绳配置污染受伤、跳跃等动画。
	animation_player.play("RESET")
	animation_player.advance(0.0)
