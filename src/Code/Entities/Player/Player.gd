extends CharacterBody2D
class_name Player

@onready var ani_move: AnimationPlayer = $ani_move
@onready var move_state_machine: Node = $move_state_machine
@onready var gameInputControl: Node = $GameInputControl


@onready var front_foot: RayCast2D = $front_foot
@onready var front_head: RayCast2D = $front_head
@onready var front_body: RayCast2D = $front_body
@onready var back_foot: RayCast2D = $back_foot
@onready var back_head: RayCast2D = $back_head
@onready var back_body: RayCast2D = $back_body
@onready var debug: Label = $debug
@onready var hp_label: Label = $hp
@onready var rope_controller: RopeController = $RopeController

@export_category("properties")
@export_group("physical_prop")
@export var jump_speed: float = 380.0
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

## 重力缩放系数（默认为 1.0，流水区域等会将其置为 0.0）
@export var gravity_scale: float = 1.0
var _water_flow_area_count: int = 0

func _sync_from_export_settings() -> void:
	if ExportSettings:
		speed = ExportSettings.player_speed
		accerleration = ExportSettings.player_acceleration
		friction = ExportSettings.player_friction
		jump_speed = ExportSettings.player_jump_speed
		jump_ability = ExportSettings.player_jump_ability
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

func _ready() -> void:
	_sync_from_export_settings()
	move_state_machine.init(self, ani_move, gameInputControl)
	
	gameInputControl.special_state_start.connect(func(_state): is_special_state = true)
	gameInputControl.special_state_end.connect(func(_state): is_special_state = false)
	
	if SignalBus:
		SignalBus.StartPlayerHpDrain.connect(_on_start_player_hp_drain)
		SignalBus.StopPlayerHpDrain.connect(_on_stop_player_hp_drain)
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
		debug.text = "速度<%d,%d> %s%s" % [int(velocity.x), int(velocity.y), move_state_machine.cur_state_name, rope_info]

	if not is_special_state:
		velocity.y += GlobalValue.gravity * gravity_scale * delta
		if _water_flow_area_count > 0:
			# 水流区域内：若没有方向输入，微弱阻尼滑行；有输入则微调方向，不施加地面强摩擦
			if gameInputControl.row_dir != 0:
				velocity.x = move_toward(velocity.x, speed * sign(gameInputControl.row_dir), accerleration * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, (friction * 0.15) * delta)
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

	if gameInputControl.row_dir != 0:
		var new_face_dir = int(sign(gameInputControl.row_dir))
		if face_dir != new_face_dir:
			front_foot.scale.x *= -1
			front_head.scale.x *= -1
			front_body.scale.x *= -1
			back_foot.scale.x *= -1
			back_head.scale.x *= -1
			back_body.scale.x *= -1
		face_dir = new_face_dir

	is_front_has_rigid = _check_wall_climbable(front_foot) or _check_wall_climbable(front_head) or _check_wall_climbable(front_body)
	is_back_has_rigid = _check_wall_climbable(back_foot) or _check_wall_climbable(back_head) or _check_wall_climbable(back_body)

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

## 受到伤害的公共方法
## @param damage 受到的伤害数值
## @param knockback 击退冲量向量 (可选，默认 Vector2.ZERO)
func ApplyDamage(damage: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if hurt_lock:
		now_HP -= damage
		hurt_lock = false
		if knockback != Vector2.ZERO:
			velocity = knockback
		move_state_machine.change_state("hurt")
		if SignalBus:
			SignalBus.PlayerHurt.emit(damage, knockback)
		get_tree().create_timer(unbeatable_time).timeout.connect(func(): hurt_lock = true)

## 恢复生命值/水量的公共方法
## @param amount 恢复数值
func Heal(amount: float) -> void:
	now_HP += amount

## 刷新冲刺与钩索技能状态（供流水区域等交互组件调用）
func ResetDashAndRope() -> void:
	if gameInputControl:
		gameInputControl.dash_control_flag = true
		gameInputControl.dash_span_flag = true
	if rope_controller:
		rope_controller.ResetRopeCooldown()

## 设置玩家在水流/零重力区域的计数
## @param entered true 为进入，false 为离开
func SetInWaterFlow(entered: bool) -> void:
	if entered:
		_water_flow_area_count += 1
	else:
		_water_flow_area_count = max(0, _water_flow_area_count - 1)
	gravity_scale = 0.0 if _water_flow_area_count > 0 else 1.0

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
		"max_hp": Max_HP
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
