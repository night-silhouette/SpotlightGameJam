extends GameInputControl

var row_dir: float = 0.0
var dash_control_flag: bool = true
var dash_span_flag: bool = true

## 特殊动作状态开始信号 (如 dash / hurt)
signal special_state_start(state: String)
## 特殊动作状态结束信号
signal special_state_end(state: String)

func _check_dash() -> bool:
	if dash_control_flag and Input.is_action_just_pressed("dash"):
		dash_control_flag = false
		dash_span_flag = false
		special_state_start.emit("dash")
		get_tree().create_timer(obj.dash_time).timeout.connect(func():
			special_state_end.emit("dash")
		, CONNECT_ONE_SHOT)
		get_tree().create_timer(obj.dash_span).timeout.connect(func():
			dash_span_flag = true
		, CONNECT_ONE_SHOT)
		return true
	return false

var column_dir: float = 0.0
var is_jump: bool = false
var is_dash: bool = false
var is_idle: bool = false
var is_run: bool = false
var is_fall: bool = false
var is_normal: bool = false

func _physics_process(_delta: float) -> void:
	if not obj:
		return

	if not dash_control_flag and obj.is_on_floor() and dash_span_flag:
		dash_control_flag = true

	row_dir = Input.get_axis("move_l", "move_r")
	column_dir = Input.get_axis("up", "down")

	is_jump = obj.is_on_floor() and Input.is_action_just_pressed("jump")
	is_dash = _check_dash()

	is_normal = not obj.is_front_has_rigid
	is_fall = not obj.is_on_floor() and is_normal and obj.velocity.y >= 0

	is_run = row_dir != 0.0 and obj.is_on_floor() and is_normal
	is_idle = row_dir == 0.0 and obj.is_on_floor() and is_normal
