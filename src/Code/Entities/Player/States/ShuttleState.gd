extends State
class_name ShuttleState

## =============================================================================
## ShuttleState.gd - 流水穿梭状态
## 玩家穿过流体流水区域时进入该状态，退出 run 和 dash 状态并保留喷射爆发冲量。
## 为之后增加穿梭流水区专属动画预留扩展接口。
## =============================================================================

func enter() -> void:
	super.enter()
	change_use_all(true)
	_play_shuttle_animation()

func exit() -> void:
	super.exit()

func physics_process(_delta: float) -> void:
	pass

## 播放穿梭动画（优先寻找专属 shuttle 动画，未就绪时使用跳跃飞跃姿态平滑过渡）
func _play_shuttle_animation() -> void:
	if not animation_player:
		return
	if animation_player.has_animation("shuttle"):
		animation_player.play("shuttle")
	elif animation_player.has_animation("water_shuttle"):
		animation_player.play("water_shuttle")
	elif animation_player.has_animation("jump"):
		animation_player.play("jump")
