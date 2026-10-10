extends State

func enter() -> void:
	super.enter()
	var animation_name: StringName = &"RopeSend" if name == &"rope_send" else &"fly"
	var fps: float = ExportSettings.rope_visual_deploy_fps if name == &"rope_send" else ExportSettings.rope_visual_fly_fps
	var animation := animation_player.get_animation(animation_name)
	animation_player.play(animation_name, -1.0, animation.length * fps / 2.0)
	# 发射点必须在同一次发射调用内取得本帧姿势，而不是等待下一渲染帧。
	animation_player.advance(0.0)

func exit() -> void:
	# 由 ani_move 恢复动作缩放和偏移，避免持绳配置污染受伤、跳跃等动画。
	animation_player.play("RESET")
	animation_player.advance(0.0)
