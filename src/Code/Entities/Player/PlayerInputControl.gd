extends GameInputControl

var row_dir: float = 0.0
var dash_control_flag: bool = true
var dash_span_flag: bool = true
var _dash_timer: SceneTreeTimer = null
var _coyote_time_left: float = 0.0
var _ground_jump_consumed: bool = false

## 特殊动作状态开始信号 (如 dash / hurt)
signal special_state_start(state: String)
## 特殊动作状态结束信号
signal special_state_end(state: String)

func _check_dash() -> bool:
	if dash_control_flag and Input.is_action_just_pressed("dash"):
		dash_control_flag = false
		dash_span_flag = false
		special_state_start.emit("dash")
		_dash_timer = get_tree().create_timer(obj.dash_time)
		_dash_timer.timeout.connect(func():
			if not dash_control_flag: # 仅当未被提前打断时正常结束
				special_state_end.emit("dash")
		, CONNECT_ONE_SHOT)
		get_tree().create_timer(obj.dash_span).timeout.connect(func():
			dash_span_flag = true
		, CONNECT_ONE_SHOT)
		return true
	return false

## 主动中断冲刺状态 (如冲刺进入流水区域时调用)
func InterruptDash() -> void:
	dash_control_flag = true
	special_state_end.emit("dash")

var column_dir: float = 0.0
var is_jump: bool = false
var is_double_jump: bool = false
var is_dash: bool = false
var is_idle: bool = false
var is_run: bool = false
var is_fall: bool = false
var is_normal: bool = false

## 实际起跳时清除普通跳跃宽限；无参数，不影响二段跳次数。
func ConsumeGroundJump() -> void:
	_coyote_time_left = 0.0
	_ground_jump_consumed = true

func _can_drop_through_platform() -> bool:
	if not obj.is_on_floor():
		return false
	for index in obj.get_slide_collision_count():
		var platform := obj.get_slide_collision(index).get_collider() as OneWayDropPlatformComponent
		if platform != null and platform.CanDropPlayer(obj):
			return true
	return false

func _physics_process(delta: float) -> void:
	if not obj or obj.get("offering_locked") == true:
		return

	obj.RefreshWallContacts()
	if not dash_control_flag and obj.is_on_floor() and dash_span_flag:
		dash_control_flag = true

	row_dir = Input.get_axis("move_l", "move_r")
	column_dir = Input.get_axis("up", "down")

	var jump_pressed := Input.is_action_just_pressed("jump")
	# 只有脚下平台确实可以下穿，才消费跳跃；斜下移动不应屏蔽地面跳和二段跳。
	var drop_through_pressed := jump_pressed and Input.is_action_pressed("down") and _can_drop_through_platform()
	var normal_jump_pressed := jump_pressed and not drop_through_pressed
	if not obj.is_on_floor():
		_ground_jump_consumed = false
		_coyote_time_left = maxf(0.0, _coyote_time_left - delta)
	elif not _ground_jump_consumed and obj.velocity.y >= 0.0:
		_coyote_time_left = ExportSettings.player_coyote_time
	# 主动跳起、下穿和特殊运动不保留走出边缘的起跳机会。
	if drop_through_pressed:
		ConsumeGroundJump()
	if obj.velocity.y < 0.0 or obj.now_HP <= 0.0 or obj.debug_flight_enabled or obj.IsInWaterFlow():
		_coyote_time_left = 0.0
	if state_machine and state_machine.cur_state_name in ["hurt", "died", "dash", "rope_send", "fly", "climb"]:
		_coyote_time_left = 0.0
	is_jump = (obj.is_on_floor() or _coyote_time_left > 0.0) and normal_jump_pressed and (obj.is_on_floor() or not obj.is_front_has_rigid)
	is_double_jump = (
		not obj.is_on_floor()
		and not is_jump
		and normal_jump_pressed
		and not obj.is_front_has_rigid
		and not obj.is_back_has_rigid
		and obj.get("enable_double_jump") == true
		and obj.get("double_jump_count") > 0
	)
	is_dash = _check_dash()

	is_normal = not obj.is_front_has_rigid
	is_fall = not obj.is_on_floor() and is_normal and obj.velocity.y >= 0

	is_run = row_dir != 0.0 and obj.is_on_floor() and is_normal
	is_idle = obj.is_on_floor() and (row_dir == 0.0 or not is_normal)
