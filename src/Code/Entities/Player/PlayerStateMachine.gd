extends StateMachine

func phy_middleware() -> void:
	if not gameInputControl:
		return
	if gameInputControl.is_fall:
		change_state("fall")
	if gameInputControl.is_idle:
		change_state("idle")
	if gameInputControl.is_run:
		change_state("run")
	if gameInputControl.is_jump:
		change_state("jump")
	if "is_double_jump" in gameInputControl and gameInputControl.is_double_jump:
		# 如果已经在 jump 状态中，先 exit 或直接允许重新进入以赋二段跳速度
		if cur_state_name == "jump":
			var jump_state = state_map.get("jump")
			if jump_state:
				jump_state.exit()
				jump_state.enter()
		else:
			change_state("jump")
	if gameInputControl.is_dash:
		change_state("dash")
	if obj and obj.is_front_has_rigid:
		change_state("climb")
