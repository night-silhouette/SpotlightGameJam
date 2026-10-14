extends State

const WALL_RELEASE_GRACE_TIME: float = 0.12

var is_wall_kicking: bool = false
var wall_dir: int = 0
var wall_release_grace_remaining: float = 0.0

func enter() -> void:
	is_wall_kicking = false
	wall_release_grace_remaining = 0.0
	wall_dir = obj.face_dir
	obj.wall_jump_lock_dir = wall_dir
	if animation_player:
		animation_player.play("wall_grab")

func exit() -> void:
	is_wall_kicking = false
	wall_release_grace_remaining = 0.0

func physics_process(delta: float) -> void:
	if is_wall_kicking:
		if not animation_player or animation_player.current_animation != "jump_start" or not animation_player.is_playing():
			is_wall_kicking = false
			finished.emit("fall")
		return
	if gameInputControl and not gameInputControl.dash_control_flag:
		gameInputControl.InterruptDash()
	# 扒墙时一旦碰地，优先回到待机，不能继续保留墙面状态。
	if obj.is_on_floor():
		finished.emit("idle")
		return
	# 松开、反向或短暂丢失墙面时保留 0.12 秒宽限；期间停在墙边且仍可蹬墙跳。
	var holding_toward_wall: bool = gameInputControl != null and int(sign(gameInputControl.row_dir)) == wall_dir
	var wall_hold_valid: bool = obj.is_front_has_rigid and holding_toward_wall
	if wall_hold_valid:
		wall_release_grace_remaining = 0.0
	else:
		if wall_release_grace_remaining <= 0.0:
			wall_release_grace_remaining = WALL_RELEASE_GRACE_TIME
		wall_release_grace_remaining -= delta
		obj.velocity.y = 0.0
		if wall_release_grace_remaining <= 0.0:
			finished.emit("fall")
			return
	if obj.velocity.y > obj.max_fall_speed:
		obj.velocity.y = obj.max_fall_speed
	if gameInputControl.is_physics_processing() and Input.is_action_just_pressed("jump"):
		obj.velocity.y = -obj.climb_ability
		obj.velocity.x = -obj.climb_ability * 0.9 * wall_dir
		if obj.has_method("PlayWallJumpSFX"):
			obj.PlayWallJumpSFX()
		is_wall_kicking = true
		if animation_player:
			animation_player.play("jump_start")
