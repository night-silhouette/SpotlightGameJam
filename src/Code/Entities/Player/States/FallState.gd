extends State

func enter() -> void:
	super.enter()
	if animation_player:
		animation_player.play("jump_rise" if obj.velocity.y < 0.0 else "fall")

func physics_process(_delta: float) -> void:
	if obj.velocity.y >= 0.0 and animation_player and animation_player.current_animation != "fall":
		animation_player.play("fall")
	elif obj.velocity.y < 0.0 and animation_player and animation_player.current_animation != "jump_rise":
		animation_player.play("jump_rise")
