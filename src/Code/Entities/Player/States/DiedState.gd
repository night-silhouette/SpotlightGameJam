extends State

## =============================================================================
## DiedState.gd - 玩家死亡状态
## 禁用常规状态转换与输入，并在延迟后在设定的帐篷/出生重生点满血重生
## =============================================================================

var _respawn_timer: SceneTreeTimer = null

func enter() -> void:
	super.enter()
	change_use_all(false)
	
	if obj:
		obj.velocity = Vector2.ZERO
		if obj.has_method("PlayDeathSFX"):
			obj.PlayDeathSFX()
	
	var delay = 1.0
	if ExportSettings and "tent_respawn_delay" in ExportSettings:
		delay = ExportSettings.tent_respawn_delay
	
	_respawn_timer = get_tree().create_timer(delay)
	_respawn_timer.timeout.connect(_on_respawn_timeout)

func _on_respawn_timeout() -> void:
	# 重新恢复状态机的子状态可用性
	change_use_all(true)
	if obj and obj.has_method("Respawn"):
		obj.Respawn()
	else:
		finished.emit("idle")

