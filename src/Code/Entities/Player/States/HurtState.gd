extends State

func enter() -> void:
	if gameInputControl:
		gameInputControl.special_state_start.emit("hurt")
	change_use_all(false)
	# 允许保留外部施加的击退初速度进行自然减速，而非瞬间静止
	Util.setTime(obj.hurt_time, func():
		change_use_all(true)
		if gameInputControl:
			gameInputControl.special_state_end.emit("hurt")
	)
