extends State

func enter() -> void:
	if gameInputControl:
		gameInputControl.special_state_start.emit("hurt")
	change_use_all(false)
	# 确保 hurt 与 died 始终可用，不被自身拦截
	var hurt_node = state_machine.get_node_or_null("hurt") if state_machine else null
	if hurt_node:
		hurt_node.is_use = true
	var died_node = state_machine.get_node_or_null("died") if state_machine else null
	if died_node:
		died_node.is_use = true

	# 允许保留外部施加的击退初速度进行自然减速，硬直结束后恢复并迁移到对应移动状态
	Util.setTime(obj.hurt_time, func():
		change_use_all(true)
		if gameInputControl:
			gameInputControl.special_state_end.emit("hurt")
		if state_machine and state_machine.cur_state_name == "hurt":
			if obj and obj.is_on_floor():
				state_machine.change_state("idle")
			else:
				state_machine.change_state("fall")
	)
