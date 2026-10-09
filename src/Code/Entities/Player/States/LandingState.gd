extends State

var _remaining: float = 0.0

func enter() -> void:
	super.enter()
	_remaining = obj.landing_lock_time
	obj.velocity.x = 0.0
	if animation_player:
		animation_player.play("Onland", -1.0, animation_player.get_animation("Onland").length / maxf(_remaining, 0.01))

func physics_process(delta: float) -> void:
	obj.velocity.x = 0.0
	_remaining -= delta
	if _remaining <= 0.0:
		finished.emit("run" if gameInputControl.row_dir != 0.0 else "idle")
