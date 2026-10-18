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

var _in_return_phase: bool = false
var _boat_departure_triggered: bool = false
var _chase_finished: bool = false
var _chase_activation_pending: bool = false
var _bone_claimed: bool = false
var _bone_offered: bool = false
var _reset_chase_on_respawn: bool = false
var _phase_collision_states: Dictionary = {}


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
	if not _get_boat_area.body_entered.is_connected(_on_get_boat_body_entered):
		_get_boat_area.body_entered.connect(_on_get_boat_body_entered)
	if not _the_end_area.body_entered.is_connected(_on_the_end_body_entered):
		_the_end_area.body_entered.connect(_on_the_end_body_entered)
	if start_in_return_phase:
		SwitchToReturnPhase()
	else:
		_set_phase_enabled(outward_phase, true)
		_set_phase_enabled(return_phase, false)
	_refresh_bone()


## 切换到返程/追逐阶段，启用返程内容、关闭去程内容，并在追逐者可用时开始追逐。
func SwitchToReturnPhase() -> void:
	if _in_return_phase:
		return
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
		if _chaser.has_method(&"StartChase"):
			_chaser.call(&"StartChase")
	_chase_finished = false


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
	SwitchToReturnPhase()
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
	_bone_offered = bool(data.get("bone_offered", false))
	_bone_claimed = _bone_offered or bool(data.get("bone_claimed", false))
	_refresh_bone()

	# 先恢复场景，待所有实体加载后按玩家实际持有状态同步返程。
	if is_instance_valid(_chaser) and _chaser.has_method(&"ResetChase"):
		_chaser.call(&"ResetChase")
	_in_return_phase = false
	_chase_activation_pending = false
	_chase_finished = false
	_set_phase_enabled(return_phase, false)
	_set_phase_enabled(outward_phase, true)


func _on_save_loaded(_slot: int) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var carrying := bool(player.get("has_scarred_bones"))
	_bone_claimed = _bone_offered or carrying
	_refresh_bone()
	if carrying and not _bone_offered:
		SwitchToReturnPhase()
	elif _in_return_phase and not _bone_offered:
		_in_return_phase = false
		_set_phase_enabled(return_phase, false)
		_set_phase_enabled(outward_phase, true)


func _set_phase_enabled(phase: Node2D, enabled: bool) -> void:
	if enabled:
		phase.process_mode = Node.PROCESS_MODE_INHERIT
		_set_phase_collisions(phase, true)
		phase.visible = true
	else:
		phase.visible = false
		_set_phase_collisions(phase, false)
		phase.process_mode = Node.PROCESS_MODE_DISABLED


func _set_phase_collisions(node: Node, enabled: bool) -> void:
	if node is CollisionObject2D:
		var collision_object := node as CollisionObject2D
		if not _phase_collision_states.has(collision_object):
			_phase_collision_states[collision_object] = Vector2i(
				collision_object.collision_layer,
				collision_object.collision_mask
			)
		var collision_state: Vector2i = _phase_collision_states[collision_object]
		collision_object.set_deferred(
			"collision_layer", collision_state.x if enabled else 0
		)
		collision_object.set_deferred(
			"collision_mask", collision_state.y if enabled else 0
		)
	elif node is TileMapLayer:
		var tile_layer := node as TileMapLayer
		if not _phase_collision_states.has(tile_layer):
			_phase_collision_states[tile_layer] = tile_layer.collision_enabled
		tile_layer.set_deferred(
			"collision_enabled",
			bool(_phase_collision_states[tile_layer]) if enabled else false
		)
	for child in node.get_children():
		_set_phase_collisions(child, enabled)


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
	_reset_chase_on_respawn = _in_return_phase and not _chase_finished
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
	if not _reset_chase_on_respawn:
		return
	_reset_chase_on_respawn = false
	# 无论是复活前已经进入追逐，还是出生在追逐战复活点，都重置为待交互追逐状态
	_chase_activation_pending = false
	_chase_finished = false
	_in_return_phase = false

	if is_instance_valid(_chaser) and _chaser.has_method(&"ResetChase"):
		_chaser.call(&"ResetChase")

	# 切回去程 OutwardPhase 激活骨头交互，关闭 ReturnPhase
	_set_phase_enabled(return_phase, false)
	_set_phase_enabled(outward_phase, true)

	if is_instance_valid(_boat) and _boat.has_method(&"ResetBoat"):
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
