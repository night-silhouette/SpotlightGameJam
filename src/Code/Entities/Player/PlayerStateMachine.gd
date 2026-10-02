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
	if gameInputControl.is_dash:
		change_state("dash")
	if obj and obj.is_front_has_rigid:
		change_state("climb")
