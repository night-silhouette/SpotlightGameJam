extends State

signal s_fall

var temp: float = 1440.0
var frame: float = 0.0

func _fall() -> void:
	change_use_all(true)
	finished.emit("fall")

func _on_jump_start_finished(animation_name: StringName) -> void:
	if animation_name != &"jump_start" or state_machine.current_state != self:
		return
	if obj.velocity.y >= 0.0:
		_fall()
	elif animation_player:
		animation_player.play("jump_rise")

func enter() -> void:
	if not s_fall.is_connected(_fall):
		s_fall.connect(_fall, CONNECT_ONE_SHOT)

	if obj.is_on_floor():
		obj.velocity.y = -obj.jump_speed
		if obj.has_method("PlayJumpFirstSFX"):
			obj.PlayJumpFirstSFX()
	elif not obj.is_back_has_rigid and not obj.is_front_has_rigid:
		# 空中二段跳
		if "double_jump_count" in obj and obj.double_jump_count > 0:
			obj.double_jump_count -= 1
			var d_speed = obj.double_jump_speed if "double_jump_speed" in obj else obj.jump_speed
			obj.velocity.y = -d_speed
			if obj.has_method("PlayJumpSecondSFX"):
				obj.PlayJumpSecondSFX()
		else:
			obj.velocity.y = -obj.jump_speed
			if obj.has_method("PlayJumpFirstSFX"):
				obj.PlayJumpFirstSFX()
	else:
		obj.velocity.y = -obj.jump_speed
		if obj.has_method("PlayJumpFirstSFX"):
			obj.PlayJumpFirstSFX()

	if obj.is_back_has_rigid:
		var back_wall_dir = -obj.face_dir
		if obj.wall_jump_lock_dir != back_wall_dir:
			obj.wall_jump_lock_dir = back_wall_dir
			obj.velocity.y = -obj.climb_ability
			obj.velocity.x = obj.climb_ability * 0.9 * obj.face_dir
			if obj.has_method("PlayWallJumpSFX"):
				obj.PlayWallJumpSFX()

	if animation_player:
		animation_player.play("jump_start")
		if not animation_player.animation_finished.is_connected(_on_jump_start_finished):
			animation_player.animation_finished.connect(_on_jump_start_finished)

	change_use_all(false)
	var dash_node = state_machine.get_node_or_null("dash")
	if dash_node:
		dash_node.is_use = true
	var hurt_node = state_machine.get_node_or_null("hurt")
	if hurt_node:
		hurt_node.is_use = true
	var died_node = state_machine.get_node_or_null("died")
	if died_node:
		died_node.is_use = true

func exit() -> void:
	change_use_all(true)
	if animation_player and animation_player.animation_finished.is_connected(_on_jump_start_finished):
		animation_player.animation_finished.disconnect(_on_jump_start_finished)
	if s_fall.is_connected(_fall):
		s_fall.disconnect(_fall)
	temp = GlobalValue.gravity
	frame = 0.0

func physics_process(delta: float) -> void:
	frame += delta * obj.jump_ability
	temp = (1.0 - ease(frame, 0.32)) * GlobalValue.gravity
	if Input.is_action_pressed("jump"):
		obj.velocity.y = move_toward(obj.velocity.y, -obj.jump_speed, temp * delta)
	if obj.velocity.y >= 0:
		s_fall.emit()
