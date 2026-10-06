extends State

func enter() -> void:
	if animation_player:
		animation_player.play("idle")

func exit() -> void:
	pass
