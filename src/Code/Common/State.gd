extends Node2D

class_name State

var state_machine: Node = null
var animation_player: AnimationPlayer = null
var state_time: float = 0.0
var obj: CharacterBody2D = null
var gameInputControl: Node = null

## 状态完成切换信号
## @param next_state_name 下一个目标状态名称
signal finished(next_state_name: String)
var is_use: bool = true

func enter() -> void:
	state_time = 0.0

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_process(_delta: float) -> void:
	pass

func handled_input(_event: InputEvent) -> void:
	pass

## 切换当前节点的生命周期处理状态
## @param value 是否激活 process/physics_process/process_input
func change_process_state(value: bool) -> void:
	set_process(value)
	set_physics_process(value)
	set_process_input(value)

## 在动画播放完成后自动触发状态迁移
## @param next_state 动画结束后要切换到的目标状态名
func animation_end_finished(next_state: String) -> void:
	if animation_player:
		animation_player.animation_finished.connect(func(_t):
			finished.emit(next_state)
		, CONNECT_ONE_SHOT)

## 批量修改所有子状态是否可进入
## @param flag 是否可用
## @param temp 遍历根节点，默认为当前状态机
func change_use_all(flag: bool, temp: Node = null) -> void:
	var target_root = temp if temp != null else state_machine
	if not target_root:
		return
	for item in target_root.get_children():
		if item.has_method("enter"):
			item.is_use = flag
		else:
			change_use_all(flag, item)
