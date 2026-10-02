extends State

func physics_process(_delta: float) -> void:
	if gameInputControl:
		gameInputControl.dash_control_flag = true
	if not obj.is_front_has_rigid:
		finished.emit("idle")
		return
	if obj.velocity.y > obj.max_fall_speed:
		obj.velocity.y = obj.max_fall_speed
	if Input.is_action_just_pressed("jump"):
		obj.velocity.y = -obj.climb_ability
		obj.velocity.x = -obj.climb_ability * 0.9 * obj.face_dir
		finished.emit("fall")
