extends Node2D

@export_category("Oasis Battlefield")
## 是否在独立运行场景时直接启用返程/追逐阶段，仅用于关卡测试。
@export var start_in_return_phase: bool = false
## 追逐战死亡后的复活位置；未配置时回退到骨头交互组件的位置。
@export var chase_respawn_point: Node2D

@onready var outward_phase: Node2D = $OutwardPhase
@onready var return_phase: Node2D = $ReturnPhase
@onready var _chaser: Node = get_node_or_null("ReturnPhase/OasisBattlefieldChaser")
@onready var _boat: OasisBoat = $OutwardPhase/OasisBoat
@onready var _blocker: Node2D = $OutwardPhase/VanishingBlockerComponent
@onready var _bone_interactable: Node2D = $OutwardPhase/InteractableComponent
@onready var _get_boat_area: Area2D = $OutwardPhase/get_boat
@onready var _the_end_area: Area2D = $ReturnPhase/TheEnd
@onready var _phase_transition: CanvasLayer = $PhaseTransition
@onready var _phase_transition_black: ColorRect = $PhaseTransition/Black

var _in_return_phase: bool = false
var _boat_departure_triggered: bool = false
var _chase_finished: bool = false
var _chase_activation_pending: bool = false
var _bone_claimed: bool = false
var _bone_offered: bool = false
var _reset_chase_on_respawn: bool = false
var _reset_boat_on_respawn: bool = false
var _phase_collision_states: Dictionary = {}
var _phase_enabled_states: Dictionary = {}
# 在子节点 _ready、存档恢复和机关运行之前保留完整布置，包含 World 的实例覆盖。
# 重建整个阶段也能恢复已经 queue_free 的钟乳石、挡板及其关联尖刺。
var _initial_outward_phase: Node2D
var _initial_return_phase: Node2D
var _phase_transition_running: bool = false
var _phase_transition_tween: Tween
var _transition_player: Node2D
var _transition_player_process_mode: int = Node.PROCESS_MODE_INHERIT


func _enter_tree() -> void:
	_initial_outward_phase = get_node("OutwardPhase").duplicate() as Node2D
	_initial_return_phase = get_node("ReturnPhase").duplicate() as Node2D


func _exit_tree() -> void:
	_initial_outward_phase.free()
	_initial_return_phase.free()


func _ready() -> void:
	if not SignalBus.BlockerVanished.is_connected(_on_blocker_vanished):
		SignalBus.BlockerVanished.connect(_on_blocker_vanished)
	if not SignalBus.ComponentInteracted.is_connected(_on_component_interacted):
		SignalBus.ComponentInteracted.connect(_on_component_interacted)
	if not SignalBus.PlayerRespawned.is_connected(_on_player_respawned):
		SignalBus.PlayerRespawned.connect(_on_player_respawned)
	if not SignalBus.PlayerDied.is_connected(_on_player_died):
		SignalBus.PlayerDied.connect(_on_player_died)
	if not SignalBus.PlayerRelicConsumeRequested.is_connected(_on_relic_consumed):
		SignalBus.PlayerRelicConsumeRequested.connect(_on_relic_consumed)
	if not SignalBus.SaveSlotLoaded.is_connected(_on_save_loaded):
		SignalBus.SaveSlotLoaded.connect(_on_save_loaded)
	if not SignalBus.PlayerEnteredSlowWater.is_connected(_on_player_entered_slow_water):
		SignalBus.PlayerEnteredSlowWater.connect(_on_player_entered_slow_water)
	_connect_phase_areas()
	if start_in_return_phase:
		SwitchToReturnPhase(false)
	else:
		_set_phase_enabled(outward_phase, true)
		_set_phase_enabled(return_phase, false)
	_refresh_bone()


## 切换到返程/追逐阶段；use_black_transition 为 true 时，先淡入全黑再替换阶段，淡出后开始追逐。
func SwitchToReturnPhase(use_black_transition: bool = true) -> void:
	if _in_return_phase or _phase_transition_running:
		return
	if not use_black_transition or not ExportSettings.oasis_phase_transition_enabled:
		_activate_return_phase(true)
		return

	_phase_transition_running = true
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	_lock_transition_player(player)
	_phase_transition.visible = true
	_phase_transition_black.color.a = 0.0

	_phase_transition_tween = create_tween()
	_phase_transition_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_phase_transition_tween.tween_property(
		_phase_transition_black,
		"color:a",
		1.0,
		maxf(0.0, ExportSettings.oasis_phase_transition_fade_in)
	)
	await _phase_transition_tween.finished
	if not _phase_transition_running:
		return
	if not is_instance_valid(player) or float(player.get("now_HP")) <= 0.0 or not _bone_claimed:
		_finish_phase_transition()
		return

	# 仅在全黑后替换阶段；追逐者保持重置，直到黑幕完全淡出。
	_activate_return_phase(false)
	_phase_transition_tween = create_tween()
	_phase_transition_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var hold_duration: float = maxf(0.0, ExportSettings.oasis_phase_transition_hold)
	if hold_duration > 0.0:
		_phase_transition_tween.tween_interval(hold_duration)
	_phase_transition_tween.tween_property(
		_phase_transition_black,
		"color:a",
		0.0,
		maxf(0.0, ExportSettings.oasis_phase_transition_fade_out)
	)
	await _phase_transition_tween.finished
	if not _phase_transition_running:
		return
	_start_chase()
	_finish_phase_transition()


func _activate_return_phase(start_chase: bool) -> void:
	_in_return_phase = true
	var player := get_tree().get_first_node_in_group(&"player")
	if is_instance_valid(player) and player.has_method(&"SetRespawnPosition"):
		player.call(&"SetRespawnPosition", _get_chase_respawn_position())
	_set_phase_enabled(outward_phase, false)
	return_phase.modulate.a = 1.0
	_set_phase_enabled(return_phase, true)

	if is_instance_valid(_chaser):
		if _chaser.has_method(&"ResetChase"):
			_chaser.call(&"ResetChase")
		if start_chase:
			_start_chase()
	_chase_finished = false


func _start_chase() -> void:
	if is_instance_valid(_chaser) and _chaser.has_method(&"StartChase"):
		_chaser.call(&"StartChase")


func _lock_transition_player(player: Node2D) -> void:
	if not is_instance_valid(player) or player.process_mode == Node.PROCESS_MODE_DISABLED:
		return
	_transition_player = player
	_transition_player_process_mode = player.process_mode
	player.process_mode = Node.PROCESS_MODE_DISABLED


func _finish_phase_transition() -> void:
	_phase_transition_running = false
	_phase_transition_tween = null
	_phase_transition_black.color.a = 0.0
	_phase_transition.visible = false
	if is_instance_valid(_transition_player):
		_transition_player.process_mode = _transition_player_process_mode
	_transition_player = null


func _cancel_phase_transition() -> void:
	if _phase_transition_tween != null:
		_phase_transition_tween.kill()
	_finish_phase_transition()


## 骨头收集完成后的关卡入口；对话结束后切换到返程/追逐阶段。
func OnBoneCollected() -> void:
	var dialog_box: Node = _bone_interactable.get("_dialog_box")
	if is_instance_valid(dialog_box) and dialog_box.call(&"IsOpen"):
		await dialog_box.Finished
		if not _chase_activation_pending:
			return
	_chase_activation_pending = false
	if _in_return_phase or _bone_claimed or _bone_offered:
		return

	# 1. 骨头拾取后立即将玩家重生点锁定至复活节点
	var player := get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player) or float(player.get("now_HP")) <= 0.0:
		return
	if player.has_method(&"SetRespawnPosition"):
		player.call(&"SetRespawnPosition", _get_chase_respawn_position())

	# 拾取与发奖先于存档，使复活点、地图和玩家持有状态一起落盘。
	_bone_claimed = true
	_refresh_bone()
	if SignalBus.has_signal(&"lock3"):
		SignalBus.emit_signal(&"lock3")
	await SwitchToReturnPhase()
	if not _in_return_phase:
		return
	SaveManager.AutoSave(get_tree())


## 导出第三关实际返程进度及骨头状态；玩家当前位置与复活点由 Player 保存。
func ExportSaveData() -> Dictionary:
	return {
		"checkpoint_reached": _in_return_phase,
		"bone_claimed": _bone_claimed,
		"bone_offered": _bone_offered,
	}


## 从存档还原第三关状态；data 为关卡字典，旧版检查点标记及坐标不再用于恢复玩家位置。
func LoadSaveData(data: Dictionary) -> void:
	_cancel_phase_transition()
	_bone_offered = bool(data.get("bone_offered", false))
	_bone_claimed = _bone_offered or bool(data.get("bone_claimed", false))
	_refresh_bone()

	# 先恢复场景，待所有实体加载后按玩家实际持有状态同步返程。
	if is_instance_valid(_chaser) and _chaser.has_method(&"ResetChase"):
		_chaser.call(&"ResetChase")
	_in_return_phase = false
	_chase_activation_pending = false
	_chase_finished = false
	_reset_chase_on_respawn = false
	_reset_boat_on_respawn = false
	_set_phase_enabled(return_phase, false)
	_set_phase_enabled(outward_phase, true)


func _on_save_loaded(_slot: int) -> void:
	_cancel_phase_transition()
	# 子实体的旧存档可能恢复了下落、塌陷、移动位置，甚至排队删除节点。
	# 全部实体加载完毕后统一丢弃瞬态，再按玩家的遗物状态恢复去返程。
	_rebuild_phases()
	_in_return_phase = false
	_chase_finished = false
	_chase_activation_pending = false
	_boat_departure_triggered = false
	_reset_chase_on_respawn = false
	_reset_boat_on_respawn = false
	_set_phase_enabled(return_phase, false)
	_set_phase_enabled(outward_phase, true)
	_chaser.call(&"ResetChase")
	var player := get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var carrying := bool(player.get("has_scarred_bones"))
	_bone_claimed = _bone_offered or carrying
	_refresh_bone()
	if carrying and not _bone_offered:
		SwitchToReturnPhase(false)


func _on_player_entered_slow_water(player: Node2D, water_source: Node2D) -> void:
	if not ExportSettings.oasis_outward_water_full_heal_on_enter or _in_return_phase:
		return
	if not is_instance_valid(player) or not is_instance_valid(water_source):
		return
	if not outward_phase.is_ancestor_of(water_source):
		return
	SignalBus.PlayerFullHealRequested.emit(player)


func _set_phase_enabled(phase: Node2D, enabled: bool) -> void:
	# 重复禁用不能把已清零的碰撞再记作初始状态；首次启用保留 _ready 的实际状态。
	var was_enabled: bool = bool(_phase_enabled_states.get(phase, true))
	if was_enabled != enabled:
		_set_phase_collisions(phase, enabled)
	_phase_enabled_states[phase] = enabled
	if enabled:
		phase.process_mode = Node.PROCESS_MODE_INHERIT
		phase.visible = true
	else:
		phase.visible = false
		phase.process_mode = Node.PROCESS_MODE_DISABLED


func _set_phase_collisions(node: Node, enabled: bool) -> void:
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		if not enabled:
			_phase_collision_states[collision_object] = Vector2i(
				collision_object.collision_layer,
				collision_object.collision_mask
			)
		if _phase_collision_states.has(collision_object):
			var collision_state: Vector2i = _phase_collision_states[collision_object]
			collision_object.set_deferred(
				"collision_layer", collision_state.x if enabled else 0
			)
			collision_object.set_deferred(
				"collision_mask", collision_state.y if enabled else 0
			)
	elif node is TileMapLayer:
		var tile_layer := node as TileMapLayer
		if not enabled:
			_phase_collision_states[tile_layer] = tile_layer.collision_enabled
		if _phase_collision_states.has(tile_layer):
			if enabled and tile_layer.get_parent() is WaterFlowArea:
				# 阶段启用与符文切换可能发生在同一帧；延迟执行时读取最新流体状态，
				# 不能让先排队的“恢复砖块碰撞”覆盖后来已经显示的水幕。
				call_deferred(&"_restore_water_tile_collision", tile_layer)
			else:
				tile_layer.set_deferred(
					"collision_enabled",
					bool(_phase_collision_states[tile_layer]) if enabled else false
				)
	for child in node.get_children():
		_set_phase_collisions(child, enabled)


func _restore_water_tile_collision(tile_layer: TileMapLayer) -> void:
	if not is_instance_valid(tile_layer):
		return
	var water := tile_layer.get_parent() as WaterFlowArea
	tile_layer.collision_enabled = not water.is_fluid and tile_layer.visible


func _connect_phase_areas() -> void:
	_get_boat_area.body_entered.connect(_on_get_boat_body_entered)
	_the_end_area.body_entered.connect(_on_the_end_body_entered)


func _rebuild_phases() -> void:
	# 骨头交互的已读剧情属于持久进度，不随机关重新播放。
	var bone_dialog_data: Dictionary = _bone_interactable.call(&"ExportSaveData")
	var outward_index := outward_phase.get_index()
	var return_index := return_phase.get_index()
	remove_child(outward_phase)
	remove_child(return_phase)
	outward_phase.free()
	return_phase.free()
	_phase_collision_states.clear()
	_phase_enabled_states.clear()
	outward_phase = _initial_outward_phase.duplicate() as Node2D
	return_phase = _initial_return_phase.duplicate() as Node2D
	# 在本次调用完成前不允许新机关推进；各脚本仍正常执行 _ready 初始化。
	outward_phase.process_mode = Node.PROCESS_MODE_DISABLED
	return_phase.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(outward_phase)
	move_child(outward_phase, outward_index)
	add_child(return_phase)
	move_child(return_phase, return_index)
	_boat = outward_phase.get_node("OasisBoat") as OasisBoat
	_blocker = outward_phase.get_node("VanishingBlockerComponent") as Node2D
	_bone_interactable = outward_phase.get_node("InteractableComponent") as Node2D
	_get_boat_area = outward_phase.get_node("get_boat") as Area2D
	_the_end_area = return_phase.get_node("TheEnd") as Area2D
	_chaser = return_phase.get_node("OasisBattlefieldChaser")
	_connect_phase_areas()
	_bone_interactable.call(&"LoadSaveData", bone_dialog_data)
	_refresh_bone()


func _on_blocker_vanished(blocker: Node2D) -> void:
	if not _in_return_phase and is_instance_valid(_boat) and blocker == _blocker:
		_boat.SolvePuzzle("vanishing_blocker")


func _on_component_interacted(component: Node2D, interactor: Node2D) -> void:
	if not _in_return_phase and not _chase_activation_pending and not _bone_claimed and not _bone_offered and component == _bone_interactable:
		if bool(interactor.get("has_scarred_bones")):
			_bone_claimed = true
			_refresh_bone()
			return
		# Interaction can originate from a physics callback; switch outside the query flush.
		_chase_activation_pending = true
		call_deferred(&"OnBoneCollected")


func _on_player_died(player: Node2D) -> void:
	if player != get_tree().get_first_node_in_group(&"player"):
		return
	if _phase_transition_running:
		_cancel_phase_transition()
	_reset_boat_on_respawn = not _in_return_phase and _boat_departure_triggered
	_reset_chase_on_respawn = _in_return_phase and (not _chase_finished or (_bone_claimed and not _bone_offered))
	# 必须在死亡信号这一帧立刻停止、关闭伤害并复位。之前仅在复活时
	# ResetChase，会留下约一秒的移动窗口，Boss 可移动到复活点造成连续死亡。
	if _reset_chase_on_respawn and is_instance_valid(_chaser) and _chaser.has_method(&"ResetChase"):
		_chaser.call(&"ResetChase")
	if _bone_claimed and not _bone_offered:
		_bone_claimed = false
		_refresh_bone()


func _on_relic_consumed(relic: StringName) -> void:
	if relic != &"bones":
		return
	_bone_offered = true
	_bone_claimed = true
	_refresh_bone()


func _refresh_bone() -> void:
	_bone_interactable.visible = not _bone_claimed and not _bone_offered
	_bone_interactable.set("enable_interaction", _bone_interactable.visible)


func _on_player_respawned(_respawn_position: Vector2) -> void:
	if not _reset_boat_on_respawn and not _reset_chase_on_respawn:
		return
	# PlayerRespawned 可来自物理回调，退出查询后再重建碰撞节点。
	call_deferred(&"_restore_phases_after_respawn")


func _restore_phases_after_respawn() -> void:
	if not _reset_boat_on_respawn and not _reset_chase_on_respawn:
		return
	_reset_boat_on_respawn = false
	_reset_chase_on_respawn = false
	# 无论是复活前已经进入追逐，还是出生在追逐战复活点，都重置为待交互追逐状态
	_chase_activation_pending = false
	_chase_finished = false
	_in_return_phase = false
	_rebuild_phases()

	if is_instance_valid(_chaser) and _chaser.has_method(&"ResetChase"):
		_chaser.call(&"ResetChase")

	# 切回去程 OutwardPhase 激活骨头交互，关闭 ReturnPhase
	_set_phase_enabled(return_phase, false)
	_set_phase_enabled(outward_phase, true)

	_reset_outward_boat()


func _reset_outward_boat() -> void:
	if is_instance_valid(_boat):
		_boat.ResetBoat()
	_boat_departure_triggered = false


func _get_chase_respawn_position() -> Vector2:
	if is_instance_valid(chase_respawn_point):
		return chase_respawn_point.global_position
	return _bone_interactable.global_position


func _is_player(body: Node2D) -> bool:
	return body.is_in_group(&"player") or body.name == "Player"


func _on_get_boat_body_entered(body: Node2D) -> void:
	if _in_return_phase or _boat_departure_triggered or not _is_player(body):
		return
	_boat_departure_triggered = true
	_boat.SolvePuzzle("get_boat")
	_boat.ResumeJourney()


func _on_the_end_body_entered(body: Node2D) -> void:
	if not _in_return_phase or _chase_finished or not _is_player(body):
		return
	_chase_finished = true
	if is_instance_valid(_chaser) and _chaser.has_method(&"EndChase"):
		_chaser.call_deferred(&"EndChase")
