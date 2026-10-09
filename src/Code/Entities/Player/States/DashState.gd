extends State

var _dash_timer: SceneTreeTimer = null

func enter() -> void:
	change_use_all(false)
	state_machine.state_map["hurt"].is_use = true
	state_machine.state_map["died"].is_use = true
	state_machine.state_map["landing"].is_use = true
	if animation_player:
		animation_player.play("dash")
	if obj and obj.has_method("PlayDashSFX"):
		obj.PlayDashSFX()
	_dash_timer = Util.setTime(obj.dash_time, func():
		if state_machine.cur_state_name == "dash":
			change_use_all(true)
	)

func exit() -> void:
	change_use_all(true)

func physics_process(_delta: float) -> void:
	obj.velocity.x = obj.face_dir * obj.dash_speed
	obj.velocity.y = 0.0
