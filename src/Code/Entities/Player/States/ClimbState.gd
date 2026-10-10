extends State

var is_wall_kicking: bool = false

func enter() -> void:
	is_wall_kicking = false
	if animation_player:
		animation_player.play("wall_grab")

func exit() -> void:
	is_wall_kicking = false

func physics_process(_delta: float) -> void:
	if is_wall_kicking:
		if not animation_player or animation_player.current_animation != "jump_start" or not animation_player.is_playing():
			is_wall_kicking = false
			finished.emit("fall")
		return
	if gameInputControl:
		gameInputControl.dash_control_flag = true
	if not obj.is_front_has_rigid:
		finished.emit("fall" if not obj.is_on_floor() else "idle")
		return
	if obj.velocity.y > obj.max_fall_speed:
		obj.velocity.y = obj.max_fall_speed
	if Input.is_action_just_pressed("jump"):
		if obj.wall_jump_lock_dir != obj.face_dir:
			obj.wall_jump_lock_dir = obj.face_dir
			obj.velocity.y = -obj.climb_ability
			obj.velocity.x = -obj.climb_ability * 0.9 * obj.face_dir
			if obj.has_method("PlayWallJumpSFX"):
				obj.PlayWallJumpSFX()
			is_wall_kicking = true
			if animation_player:
				animation_player.play("jump_start")
