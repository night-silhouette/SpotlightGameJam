extends State

func enter() -> void:
	if animation_player:
		animation_player.play("run")

func exit() -> void:
	pass
