extends State

var _hurt_generation: int = 0

func enter() -> void:
	_hurt_generation += 1
	var generation := _hurt_generation
	if animation_player:
		animation_player.play("hit")
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
		if not state_machine or state_machine.cur_state_name != "hurt" or generation != _hurt_generation:
			return
		change_use_all(true)
		if gameInputControl:
			gameInputControl.special_state_end.emit("hurt")
		if obj and obj.is_on_floor():
			state_machine.change_state("idle")
		else:
			state_machine.change_state("fall")
	)
