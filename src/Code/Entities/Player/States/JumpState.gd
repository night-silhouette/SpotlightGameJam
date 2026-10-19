extends State

signal s_fall

var temp: float = 1440.0
var frame: float = 0.0
var _jump_started: bool = false

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

	_jump_started = false
	if obj.is_on_floor() or gameInputControl.is_jump:
		obj.velocity.y = -obj.jump_speed
		if obj.has_method("PlayJumpFirstSFX"):
			obj.PlayJumpFirstSFX()
	elif obj.enable_double_jump and obj.double_jump_count > 0:
		obj.double_jump_count -= 1
		obj.velocity.y = -obj.double_jump_speed
		obj.PlayDoubleJumpRing()
		if obj.has_method("PlayJumpSecondSFX"):
			obj.PlayJumpSecondSFX()
	else:
		# 无资源的进入请求不能借贴墙、背墙或后续长按修正获得向上速度。
		return

	_jump_started = true
	gameInputControl.ConsumeGroundJump()

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
	if not _jump_started:
		_fall()
		return
	# 必须先结束已经下落的跳跃；贴墙时通用下落判定不会代为切换。
	if obj.velocity.y >= 0.0:
		s_fall.emit()
		return
	frame += delta * obj.jump_ability
	temp = (1.0 - ease(frame, 0.32)) * GlobalValue.gravity
	if gameInputControl.is_physics_processing() and Input.is_action_pressed("jump"):
		obj.velocity.y = move_toward(obj.velocity.y, -obj.jump_speed, temp * delta)
	if obj.velocity.y >= 0:
		s_fall.emit()
