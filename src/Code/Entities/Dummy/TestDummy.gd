extends CharacterBody2D
class_name TestDummy

## 假人伤害数值
@export var collision_damage: float = 20.0
@export var max_hp: float = 50.0

var now_hp: float = 50.0
@onready var hp_label: Label = $hp_label
@onready var hurt_area: Area2D = $HurtArea

func _ready() -> void:
	now_hp = max_hp
	_update_label()
	if hurt_area:
		hurt_area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GlobalValue.gravity * delta
	move_and_slide()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.ApplyDamage(collision_damage)

## 实体受击扣血
## @param amount 伤害量
func ApplyDamage(amount: float) -> void:
	now_hp = max(0.0, now_hp - amount)
	_update_label()
	if now_hp <= 0.0:
		queue_free()

func _update_label() -> void:
	if hp_label:
		hp_label.text = "Dummy: %d HP" % int(now_hp)
