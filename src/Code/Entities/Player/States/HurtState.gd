extends State

func enter() -> void:
	if gameInputControl:
		gameInputControl.special_state_start.emit("hurt")
	change_use_all(false)
	obj.velocity.y = 0.0
	obj.velocity.x = 0.0
	Util.setTime(obj.hurt_time, func():
		change_use_all(true)
		if gameInputControl:
			gameInputControl.special_state_end.emit("hurt")
	)
