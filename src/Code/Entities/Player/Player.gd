extends CharacterBody2D
class_name Player

@onready var ani_move: AnimationPlayer = $ani_move
@onready var move_state_machine: Node = $move_state_machine
@onready var gameInputControl: Node = $GameInputControl
@onready var sprite: Node2D = $sprite
@onready var visual_placeholder: ColorRect = $VisualPlaceholder


@onready var front_foot: RayCast2D = $front_foot
@onready var front_head: RayCast2D = $front_head
@onready var front_body: RayCast2D = $front_body
@onready var back_foot: RayCast2D = $back_foot
@onready var back_head: RayCast2D = $back_head
@onready var back_body: RayCast2D = $back_body
@onready var debug: Label = $debug
@onready var hp_label: Label = $hp
@onready var rope_controller: RopeController = $RopeController
@onready var water_rune_controller: Node2D = $WaterRuneController
@onready var footstep_audio: AudioStreamPlayer2D = $FootstepAudio
@onready var move_audio: AudioStreamPlayer2D = $MoveAudio
@onready var slide_audio: AudioStreamPlayer2D = $SlideAudio
@onready var fall_audio: AudioStreamPlayer2D = $FallAudio

@export_category("properties")
@export_group("physical_prop")
@export var jump_speed: float = 380.0
@export var double_jump_speed: float = 380.0
@export var max_double_jumps: int = 1
@export var enable_double_jump: bool = true
@export var hurt_time: float = 0.15
@export var accerleration: float = 2500.0
@export var speed: float = 230.0
@export var friction: float = 3000.0
@export var jump_ability: float = 0.85
@export var dash_time: float = 0.15
@export var dash_speed: float = 700.0
@export var dash_span: float = 0.65
@export var max_fall_speed: float = 120.0
@export var unbeatable_time: float = 0.3
@export var climb_ability: float = 480.0

@export_group("state_prop")
@export var Max_HP: float = 200.0:
	set(value):
		Max_HP = value
		if Max_HP < now_HP:
			now_HP = Max_HP
		if SignalBus:
			SignalBus.PlayerHealthChanged.emit(now_HP, Max_HP)
@export var now_HP: float = 200.0:
	set(value):
		if value > Max_HP:
			now_HP = Max_HP
		elif value <= 0.0:
			now_HP = 0.0
			if rope_controller:
				rope_controller.ReleaseRope(false)
			if move_state_machine and move_state_machine.cur_state_name != "died":
				move_state_machine.change_state("died")
		else:
			now_HP = value
		if SignalBus:
			SignalBus.PlayerHealthChanged.emit(now_HP, Max_HP)

## 是否正在自然掉血
@export var is_hp_draining: bool = false
## 自然掉血速度 (每秒扣除点数)
@export var hp_drain_rate: float = 5.0

var is_special_state: bool = false
var face_dir: int = 1
var is_front_has_rigid: bool = false
var is_back_has_rigid: bool = false
var hurt_lock: bool = true
var wall_jump_lock_dir: int = 0

## 玩家重生点坐标 (初始为出生点，交互帐篷后刷新)
var respawn_position: Vector2 = Vector2.ZERO

## 玩家初始关卡出生点坐标
var spawn_position: Vector2 = Vector2.ZERO


## 当前剩余二段跳可用次数
var double_jump_count: int = 1

## 重力缩放系数（默认为 1.0，流水区域等会将其置为 0.0）
@export var gravity_scale: float = 1.0
var _water_flow_area_count: int = 0

## 绳索惯性保留计时器 (脱钩后给予一定的动量保护期，避免地面摩擦力瞬间吸死)
var rope_momentum_timer: float = 0.0

@export_group("audio_prop")
## 脚步声音频总线名称
@export var footstep_bus: StringName = &"SFX_Footstep_Wet"
## 脚步声音效资源数组 (5个脚步声)
@export var footstep_sounds: Array[AudioStream] = []
## 脚步声播放间隔
@export var footstep_interval: float = 0.22
## 起步迈出第一步的前置延迟
@export var footstep_initial_delay: float = 0.05
## 脚步声音量 (dB)
@export var footstep_volume_db: float = -2.0
## 脚步声音调微机随机变化范围
@export var footstep_pitch_randomness: float = 0.08

## 动作音效音频总线名称
@export var sfx_move_bus: StringName = &"SFX_Move_Wet"
## 动作音效基础音量分贝 (dB)
@export var sfx_move_volume_db: float = 0.0
## 冲刺音效
@export var sfx_dash: AudioStream = null
@export var sfx_dash_volume_db: float = 0.0
## 一段跳音效
@export var sfx_jump_first: AudioStream = null
@export var sfx_jump_first_volume_db: float = 0.0
## 二段跳音效
@export var sfx_jump_second: AudioStream = null
@export var sfx_jump_second_volume_db: float = 0.0
## 蹬墙跳音效
@export var sfx_wall_jump: AudioStream = null
@export var sfx_wall_jump_volume_db: float = 0.0
## 贴墙下滑音效
@export var sfx_wall_sliding: AudioStream = null
@export var sfx_wall_sliding_volume_db: float = -2.0
## 下落/滞空起落呼啸音效
@export var sfx_rising_falling: AudioStream = null
@export var sfx_rising_falling_volume_db: float = -4.0
## 受伤音效
@export var sfx_hurt: AudioStream = null
@export var sfx_hurt_volume_db: float = 0.0
## 死亡音效
@export var sfx_death: AudioStream = null
@export var sfx_death_volume_db: float = 0.0
## 动作音效音调随机浮动范围
@export var sfx_move_pitch_randomness: float = 0.05
## 触发下落呼啸音效的垂直下落速度阈值
@export var sfx_move_falling_speed_threshold: float = 260.0

var _footstep_timer: float = 0.0
var _last_footstep_index: int = -1
var _is_wall_sliding: bool = false

func _sync_from_export_settings() -> void:
	if ExportSettings:
		speed = ExportSettings.player_speed
		accerleration = ExportSettings.player_acceleration
		friction = ExportSettings.player_friction
		jump_speed = ExportSettings.player_jump_speed
		jump_ability = ExportSettings.player_jump_ability
		double_jump_speed = ExportSettings.player_double_jump_speed
		max_double_jumps = ExportSettings.player_max_double_jumps
		enable_double_jump = ExportSettings.player_enable_double_jump
		double_jump_count = max_double_jumps
		climb_ability = ExportSettings.player_climb_ability
		max_fall_speed = ExportSettings.player_max_fall_speed
		dash_time = ExportSettings.player_dash_time
		dash_speed = ExportSettings.player_dash_speed
		dash_span = ExportSettings.player_dash_span
		hurt_time = ExportSettings.player_hurt_time
		unbeatable_time = ExportSettings.player_unbeatable_time
		Max_HP = ExportSettings.player_max_hp
		now_HP = ExportSettings.player_max_hp
		hp_drain_rate = ExportSettings.player_hp_drain_rate
		if "player_footstep_bus" in ExportSettings:
			footstep_bus = ExportSettings.player_footstep_bus
		if "player_footstep_interval" in ExportSettings:
			footstep_interval = ExportSettings.player_footstep_interval
		if "player_footstep_initial_delay" in ExportSettings:
			footstep_initial_delay = ExportSettings.player_footstep_initial_delay
		if "player_footstep_volume_db" in ExportSettings:
			footstep_volume_db = ExportSettings.player_footstep_volume_db
		if "player_footstep_pitch_randomness" in ExportSettings:
			footstep_pitch_randomness = ExportSettings.player_footstep_pitch_randomness
		if "sfx_move_bus" in ExportSettings:
			sfx_move_bus = ExportSettings.sfx_move_bus
		if "sfx_move_volume_db" in ExportSettings:
			sfx_move_volume_db = ExportSettings.sfx_move_volume_db
		if "sfx_move_dash_volume_db" in ExportSettings:
			sfx_dash_volume_db = ExportSettings.sfx_move_dash_volume_db
		if "sfx_move_jump_first_volume_db" in ExportSettings:
			sfx_jump_first_volume_db = ExportSettings.sfx_move_jump_first_volume_db
		if "sfx_move_jump_second_volume_db" in ExportSettings:
			sfx_jump_second_volume_db = ExportSettings.sfx_move_jump_second_volume_db
		if "sfx_move_wall_jump_volume_db" in ExportSettings:
			sfx_wall_jump_volume_db = ExportSettings.sfx_move_wall_jump_volume_db
		if "sfx_move_wall_sliding_volume_db" in ExportSettings:
			sfx_wall_sliding_volume_db = ExportSettings.sfx_move_wall_sliding_volume_db
		if "sfx_move_rising_falling_volume_db" in ExportSettings:
			sfx_rising_falling_volume_db = ExportSettings.sfx_move_rising_falling_volume_db
		if "sfx_move_hurt_volume_db" in ExportSettings:
			sfx_hurt_volume_db = ExportSettings.sfx_move_hurt_volume_db
		if "sfx_move_death_volume_db" in ExportSettings:
			sfx_death_volume_db = ExportSettings.sfx_move_death_volume_db
		if "sfx_move_pitch_randomness" in ExportSettings:
			sfx_move_pitch_randomness = ExportSettings.sfx_move_pitch_randomness
		if "sfx_move_falling_speed_threshold" in ExportSettings:
			sfx_move_falling_speed_threshold = ExportSettings.sfx_move_falling_speed_threshold

func _ready() -> void:
	_init_footstep_sounds()
	_init_move_sounds()
	_sync_from_export_settings()
	if sprite:
		sprite.visible = true
	if visual_placeholder:
		visual_placeholder.visible = false
	move_state_machine.init(self, ani_move, gameInputControl)
	
	gameInputControl.special_state_start.connect(func(_state): is_special_state = true)
	gameInputControl.special_state_end.connect(func(_state): is_special_state = false)
	
	respawn_position = global_position
	spawn_position = global_position

	
	if SignalBus:
		SignalBus.StartPlayerHpDrain.connect(_on_start_player_hp_drain)
		SignalBus.StopPlayerHpDrain.connect(_on_stop_player_hp_drain)
		SignalBus.TentActivated.connect(_on_tent_activated)
		SignalBus.PlayerInstantDeathRequested.connect(_on_player_instant_death_requested)
		SignalBus.PlayerHealthChanged.emit(now_HP, Max_HP)

func _process(delta: float) -> void:
	if is_hp_draining and now_HP > 0.0:
		now_HP -= hp_drain_rate * delta

func _physics_process(delta: float) -> void:
	if hp_label:
		hp_label.text = "%d hp" % int(now_HP)
	if debug:
		var rope_info = ""
		if rope_controller:
			rope_info = " [绳索:%s]" % RopeController.RopeState.keys()[rope_controller.current_state]
		var dj_info = " [二段跳:%d]" % double_jump_count
		debug.text = "速度<%d,%d> %s%s%s" % [int(velocity.x), int(velocity.y), move_state_machine.cur_state_name, rope_info, dj_info]

	if not is_special_state:
		velocity.y += GlobalValue.gravity * gravity_scale * delta
		if rope_momentum_timer > 0.0:
			rope_momentum_timer -= delta
		if _water_flow_area_count > 0:
			# 水流区域内：若没有方向输入，微弱阻尼滑行；有输入则微调方向，不施加地面强摩擦
			if gameInputControl.row_dir != 0:
				velocity.x = move_toward(velocity.x, speed * sign(gameInputControl.row_dir), accerleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, (friction * 0.15) * delta)
		elif rope_momentum_timer > 0.0:
			# 仅针对绳索脱钩后的惯性保持逻辑：
			# 在绳索动量保护期内，不施加普通的急停摩擦力，保留高速惯性方便起跳
			var target_dir = sign(gameInputControl.row_dir)
			# 如果玩家按了反方向键，允许快速转向/刹车
			if target_dir != 0 and sign(velocity.x) != 0 and target_dir != sign(velocity.x):
				velocity.x = move_toward(velocity.x, speed * target_dir, accerleration * delta)
			else:
				# 同向或无输入：
				if is_on_floor():
					# 在地面上滑行：采用较平缓的滑行摩擦力，保留足够的前冲速度让玩家可以跳得更远
					var slide_friction = ExportSettings.rope_ground_slide_friction if ExportSettings else 900.0
					var target_speed = speed * sign(velocity.x) if target_dir != 0 else 0.0
					velocity.x = move_toward(velocity.x, target_speed, slide_friction * delta)
				else:
					# 在空中飞跃：仅有轻微空气阻尼，保留高速前冲惯性
					var air_drag = ExportSettings.rope_air_drag if ExportSettings else 250.0
					var target_speed = speed * sign(velocity.x)
					velocity.x = move_toward(velocity.x, target_speed, air_drag * delta)
		else:
			if gameInputControl.row_dir > 0:
				velocity.x = move_toward(velocity.x, speed, accerleration * delta)
			elif gameInputControl.row_dir < 0:
				velocity.x = move_toward(velocity.x, -speed, accerleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()

	if is_on_floor():
		wall_jump_lock_dir = 0
		ResetDoubleJump()

	if gameInputControl.row_dir != 0:
		var new_face_dir = int(sign(gameInputControl.row_dir))
		if face_dir != new_face_dir:
			front_foot.scale.x *= -1
			front_head.scale.x *= -1
			front_body.scale.x *= -1
			back_foot.scale.x *= -1
			back_head.scale.x *= -1
			back_body.scale.x *= -1
			if sprite:
				sprite.scale.x = abs(sprite.scale.x) * new_face_dir
		face_dir = new_face_dir

	is_front_has_rigid = _check_wall_climbable(front_foot) or _check_wall_climbable(front_head) or _check_wall_climbable(front_body)
	is_back_has_rigid = _check_wall_climbable(back_foot) or _check_wall_climbable(back_head) or _check_wall_climbable(back_body)

	# 扒墙时刷新二段跳（蹬墙跳方向锁定仅在落地或反向蹬墙时解锁）
	if is_front_has_rigid:
		ResetDoubleJump()

	_handle_footstep_audio(delta)
	_handle_continuous_move_audio(delta)

## 初始化加载动作音频资源
func _init_move_sounds() -> void:
	if not sfx_dash and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/Dash.wav"):
		sfx_dash = load("res://Music/SFX/Move-SFX_Move_DryOrWet/Dash.wav")
	if not sfx_jump_first and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/JumpFirst.wav"):
		sfx_jump_first = load("res://Music/SFX/Move-SFX_Move_DryOrWet/JumpFirst.wav")
	if not sfx_jump_second and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/JumpSecond.wav"):
		sfx_jump_second = load("res://Music/SFX/Move-SFX_Move_DryOrWet/JumpSecond.wav")
	if not sfx_wall_jump and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/WallJump.wav"):
		sfx_wall_jump = load("res://Music/SFX/Move-SFX_Move_DryOrWet/WallJump.wav")
	if not sfx_wall_sliding and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/WallSliding.wav"):
		sfx_wall_sliding = load("res://Music/SFX/Move-SFX_Move_DryOrWet/WallSliding.wav")
	if not sfx_rising_falling and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/RisingFalling.wav"):
		sfx_rising_falling = load("res://Music/SFX/Move-SFX_Move_DryOrWet/RisingFalling.wav")
	if not sfx_hurt and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/Hurt.wav"):
		sfx_hurt = load("res://Music/SFX/Move-SFX_Move_DryOrWet/Hurt.wav")
	if not sfx_death and ResourceLoader.exists("res://Music/SFX/Move-SFX_Move_DryOrWet/Death.wav"):
		sfx_death = load("res://Music/SFX/Move-SFX_Move_DryOrWet/Death.wav")

## 播放动作音效通用接口
## @param stream 音频资源
## @param volume_offset 分贝偏移
## @param custom_pitch 自定义基准音调
func PlayMoveSFX(stream: AudioStream, volume_offset: float = 0.0, custom_pitch: float = 1.0) -> void:
	if not stream or not move_audio:
		return
	if move_audio.bus != sfx_move_bus:
		move_audio.bus = sfx_move_bus
	move_audio.stream = stream
	move_audio.volume_db = sfx_move_volume_db + volume_offset
	if sfx_move_pitch_randomness > 0.0:
		move_audio.pitch_scale = custom_pitch * randf_range(1.0 - sfx_move_pitch_randomness, 1.0 + sfx_move_pitch_randomness)
	else:
		move_audio.pitch_scale = custom_pitch
	move_audio.play()

## 播放冲刺音效
func PlayDashSFX() -> void:
	PlayMoveSFX(sfx_dash, sfx_dash_volume_db)

## 播放一段跳起跳音效
func PlayJumpFirstSFX() -> void:
	PlayMoveSFX(sfx_jump_first, sfx_jump_first_volume_db)

## 播放二段跳起跳音效
func PlayJumpSecondSFX() -> void:
	PlayMoveSFX(sfx_jump_second, sfx_jump_second_volume_db)

## 播放蹬墙跳音效
func PlayWallJumpSFX() -> void:
	PlayMoveSFX(sfx_wall_jump, sfx_wall_jump_volume_db)

## 播放受击音效
func PlayHurtSFX() -> void:
	PlayMoveSFX(sfx_hurt, sfx_hurt_volume_db)

## 播放死亡音效
func PlayDeathSFX() -> void:
	PlayMoveSFX(sfx_death, sfx_death_volume_db)

## 处理持续性动作音效（贴墙滑落、空中高速下落呼啸）
func _handle_continuous_move_audio(_delta: float) -> void:
	var cur_state = move_state_machine.cur_state_name if move_state_machine else ""

	# 1. 贴墙下滑音效：在 climb 状态且正在沿墙下滑
	var should_slide = (cur_state == "climb" and is_front_has_rigid and not is_on_floor() and velocity.y > 10.0)
	if should_slide:
		if slide_audio and not slide_audio.playing and sfx_wall_sliding:
			if slide_audio.bus != sfx_move_bus:
				slide_audio.bus = sfx_move_bus
			slide_audio.stream = sfx_wall_sliding
			slide_audio.volume_db = sfx_move_volume_db + sfx_wall_sliding_volume_db
			slide_audio.play()
	else:
		if slide_audio and slide_audio.playing:
			slide_audio.stop()

	# 2. 空中起伏与下落呼啸音效：在空中且下落速度较快时播放，落地或进入特殊状态停止
	var should_fall = (not is_on_floor() and velocity.y >= sfx_move_falling_speed_threshold and cur_state != "climb" and cur_state != "died" and not is_special_state)
	if should_fall:
		if fall_audio and not fall_audio.playing and sfx_rising_falling:
			if fall_audio.bus != sfx_move_bus:
				fall_audio.bus = sfx_move_bus
			fall_audio.stream = sfx_rising_falling
			fall_audio.volume_db = sfx_move_volume_db + sfx_rising_falling_volume_db
			fall_audio.play()
	else:
		if fall_audio and fall_audio.playing:
			fall_audio.stop()

## 初始化加载脚步声音频资源
func _init_footstep_sounds() -> void:
	if footstep_sounds.is_empty():
		var paths = [
			"res://Music/footStep/Footstep_01.wav",
			"res://Music/footStep/Footstep_02.wav",
			"res://Music/footStep/Footstep_03.wav",
			"res://Music/footStep/Footstep_04.wav",
			"res://Music/footStep/Footstep_05.wav"
		]
		for p in paths:
			if ResourceLoader.exists(p):
				var stream = load(p) as AudioStream
				if stream:
					footstep_sounds.append(stream)

## 处理行走时的脚步声随机播放逻辑
func _handle_footstep_audio(delta: float) -> void:
	# 判定条件：必须在地面上、有横向移动输入、有横向速度、非受伤/死亡等硬直状态
	var is_moving_on_ground: bool = is_on_floor() and abs(velocity.x) > 10.0 and gameInputControl and gameInputControl.row_dir != 0.0
	if move_state_machine and (move_state_machine.cur_state_name == "died" or move_state_machine.cur_state_name == "hurt" or move_state_machine.cur_state_name == "shuttle"):
		is_moving_on_ground = false

	if is_moving_on_ground:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			PlayRandomFootstep()
			_footstep_timer = footstep_interval
	else:
		# 停止移动或离地时，重置定时器为起步延迟，这样停下再走时稍有起步缓冲，不会瞬间连击
		_footstep_timer = footstep_initial_delay

## 播放随机脚步声音效
func PlayRandomFootstep() -> void:
	if footstep_sounds.is_empty():
		return
	if not footstep_audio:
		return
	
	var count = footstep_sounds.size()
	var pick_idx = randi() % count
	# 如果有多个音效，避免连续播放同一段
	if count > 1 and pick_idx == _last_footstep_index:
		pick_idx = (pick_idx + 1 + (randi() % (count - 1))) % count
	_last_footstep_index = pick_idx

	if footstep_audio.bus != footstep_bus:
		footstep_audio.bus = footstep_bus
	footstep_audio.stream = footstep_sounds[pick_idx]
	footstep_audio.volume_db = footstep_volume_db
	if footstep_pitch_randomness > 0.0:
		footstep_audio.pitch_scale = randf_range(1.0 - footstep_pitch_randomness, 1.0 + footstep_pitch_randomness)
	else:
		footstep_audio.pitch_scale = 1.0
	footstep_audio.play()

## 辅助检测射线碰撞的墙体是否可供攀爬（排除光滑滑石墙）
func _check_wall_climbable(ray: RayCast2D) -> bool:
	if not ray or not ray.is_colliding():
		return false
	var collider = ray.get_collider()
	if collider:
		if collider.is_in_group("slick_wall") or collider.is_in_group("no_climb"):
			return false
		if collider.get("is_slick_wall") == true or collider.get("disable_climb") == true:
			return false
	return true

## 开启随时间自然掉血
## @param rate 每秒掉血速率 (若 <= 0 则保留默认速率)
func StartHpDrain(rate: float = -1.0) -> void:
	if rate > 0.0:
		hp_drain_rate = rate
	is_hp_draining = true

## 停止随时间自然掉血
func StopHpDrain() -> void:
	is_hp_draining = false

func _on_start_player_hp_drain(drain_rate: float) -> void:
	StartHpDrain(drain_rate)

func _on_stop_player_hp_drain() -> void:
	StopHpDrain()

func _on_player_instant_death_requested(player_node: Node2D, _source_node: Node2D) -> void:
	if player_node == self:
		now_HP = 0.0

func _on_tent_activated(_tent_node: Node2D, spawn_pos: Vector2) -> void:
	SetRespawnPosition(spawn_pos)

## 设置重生点坐标
## @param new_pos 新的重生点世界坐标
func SetRespawnPosition(new_pos: Vector2) -> void:
	respawn_position = new_pos

## 执行玩家重生并恢复满血
func Respawn() -> void:
	if slide_audio and slide_audio.playing:
		slide_audio.stop()
	if fall_audio and fall_audio.playing:
		fall_audio.stop()
	global_position = respawn_position
	velocity = Vector2.ZERO
	ResetDashAndRope()
	hurt_lock = true
	now_HP = Max_HP
	if SignalBus:
		SignalBus.PlayerRespawned.emit(respawn_position)
	if move_state_machine:
		move_state_machine.change_state("idle")

## 受到伤害的公共方法
## @param damage 受到的伤害数值
## @param knockback 击退冲量向量 (可选，默认 Vector2.ZERO)
func ApplyDamage(damage: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if hurt_lock:
		now_HP -= damage
		hurt_lock = false
		if knockback != Vector2.ZERO:
			velocity = knockback
		PlayHurtSFX()
		if rope_controller:
			rope_controller.ReleaseRope(false)
		move_state_machine.change_state("hurt")
		if SignalBus:
			SignalBus.PlayerHurt.emit(damage, knockback)
		get_tree().create_timer(unbeatable_time).timeout.connect(func(): hurt_lock = true)

## 恢复生命值/水量的公共方法
## @param amount 恢复数值
func Heal(amount: float) -> void:
	now_HP += amount

## 重置/刷新二段跳次数
func ResetDoubleJump() -> void:
	double_jump_count = max_double_jumps

## 刷新冲刺、钩索与符文技能状态（供流水区域等交互组件调用）
func ResetDashAndRope() -> void:
	ResetDoubleJump()
	if gameInputControl:
		gameInputControl.dash_control_flag = true
		gameInputControl.dash_span_flag = true
	if rope_controller:
		rope_controller.ResetRopeCooldown()
	if water_rune_controller:
		water_rune_controller.ResetCooldown()

## 中断并退出冲刺状态
func InterruptDash() -> void:
	is_special_state = false
	if gameInputControl and gameInputControl.has_method("InterruptDash"):
		gameInputControl.InterruptDash()

## 设置玩家在水流/零重力区域的计数
## @param entered true 为进入，false 为离开
func SetInWaterFlow(entered: bool) -> void:
	if entered:
		_water_flow_area_count += 1
	else:
		_water_flow_area_count = max(0, _water_flow_area_count - 1)
	gravity_scale = 0.0 if _water_flow_area_count > 0 else 1.0

## 查询玩家当前是否处于流水区域内
func IsInWaterFlow() -> bool:
	return _water_flow_area_count > 0

## 兼容原工程受击方法
## @param damage 受到的伤害数值
func be_hurted(damage: float) -> void:
	ApplyDamage(damage)

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"now_hp": now_HP,
		"max_hp": Max_HP,
		"spawn_x": spawn_position.x,
		"spawn_y": spawn_position.y,
		"respawn_x": respawn_position.x,
		"respawn_y": respawn_position.y
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("max_hp"):
		Max_HP = data["max_hp"]
	if data.has("now_hp"):
		now_HP = data["now_hp"]
	if data.has("spawn_x") and data.has("spawn_y"):
		spawn_position = Vector2(data["spawn_x"], data["spawn_y"])
	if data.has("respawn_x") and data.has("respawn_y"):
		respawn_position = Vector2(data["respawn_x"], data["respawn_y"])
