extends State

var _dash_timer: SceneTreeTimer = null

func enter() -> void:
	change_use_all(false)
	if obj and obj.has_method("PlayDashSFX"):
		obj.PlayDashSFX()
	_dash_timer = Util.setTime(obj.dash_time, func():
		change_use_all(true)
	)

func exit() -> void:
	change_use_all(true)

func physics_process(_delta: float) -> void:
	obj.velocity.x = obj.face_dir * obj.dash_speed
	obj.velocity.y = 0.0
