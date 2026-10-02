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
@export var Max_HP: float = 100.0:
	set(value):
		Max_HP = value
		if Max_HP < now_HP:
			now_HP = Max_HP
@export var now_HP: float = 100.0:
	set(value):
		if value > Max_HP:
			now_HP = Max_HP
		elif value <= 0.0:
			now_HP = 0.0
			if move_state_machine:
				move_state_machine.change_state("died")
		else:
			now_HP = value

var is_special_state: bool = false
var face_dir: int = 1
var is_front_has_rigid: bool = false
var is_back_has_rigid: bool = false
var hurt_lock: bool = true

func _ready() -> void:
	move_state_machine.init(self, ani_move, gameInputControl)
	
	gameInputControl.special_state_start.connect(func(_state): is_special_state = true)
	gameInputControl.special_state_end.connect(func(_state): is_special_state = false)

func _physics_process(delta: float) -> void:
	if hp_label:
		hp_label.text = "%d hp" % int(now_HP)
	if debug:
		debug.text = "速度<%d,%d> %s" % [int(velocity.x), int(velocity.y), move_state_machine.cur_state_name]

	if not is_special_state:
		velocity.y += GlobalValue.gravity * delta
		if gameInputControl.row_dir > 0:
			velocity.x = move_toward(velocity.x, speed, accerleration * delta)
		elif gameInputControl.row_dir < 0:
			velocity.x = move_toward(velocity.x, -speed, accerleration * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()

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

	is_front_has_rigid = front_foot.is_colliding() or front_head.is_colliding() or front_body.is_colliding()
	is_back_has_rigid = back_foot.is_colliding() or back_head.is_colliding() or back_body.is_colliding()

## 受到伤害的公共方法
## @param damage 受到的伤害数值
func ApplyDamage(damage: float) -> void:
	if hurt_lock:
		now_HP -= damage
		hurt_lock = false
		move_state_machine.change_state("hurt")
		get_tree().create_timer(unbeatable_time).timeout.connect(func(): hurt_lock = true)

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
