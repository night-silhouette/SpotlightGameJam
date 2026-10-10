extends State

var _dash_timer: SceneTreeTimer = null
var _dash_direction: int = 1

func enter() -> void:
	_dash_direction = int(sign(gameInputControl.row_dir)) if gameInputControl.row_dir != 0.0 else obj.face_dir
	obj.SetFacingDirection(_dash_direction)
	change_use_all(false)
	state_machine.state_map["hurt"].is_use = true
	state_machine.state_map["died"].is_use = true
	if animation_player:
		animation_player.play("dash")
	if obj and obj.has_method("PlayDashSFX"):
		obj.PlayDashSFX()
	_dash_timer = Util.setTime(obj.dash_time, func():
		if state_machine.cur_state_name == "dash":
			change_use_all(true)
			finished.emit("fall" if not obj.is_on_floor() else "run" if gameInputControl.row_dir != 0.0 else "idle")
	)

func exit() -> void:
	change_use_all(true)

func physics_process(_delta: float) -> void:
	obj.velocity.x = _dash_direction * obj.dash_speed
	obj.velocity.y = 0.0
