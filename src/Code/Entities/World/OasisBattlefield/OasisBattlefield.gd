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
var _loaded_checkpoint: bool = false
var _loaded_respawn_position: Vector2 = Vector2.ZERO
var _reset_chase_on_respawn: bool = false


func _ready() -> void:
	if not SignalBus.BlockerVanished.is_connected(_on_blocker_vanished):
		SignalBus.BlockerVanished.connect(_on_blocker_vanished)
	if not SignalBus.ComponentInteracted.is_connected(_on_component_interacted):
		SignalBus.ComponentInteracted.connect(_on_component_interacted)
	if not SignalBus.PlayerRespawned.is_connected(_on_player_respawned):
		SignalBus.PlayerRespawned.connect(_on_player_respawned)
	SignalBus.PlayerDied.connect(_on_player_died)
	SignalBus.PlayerRelicConsumeRequested.connect(_on_relic_consumed)
	SignalBus.SaveSlotLoaded.connect(_on_save_loaded)
	_get_boat_area.body_entered.connect(_on_get_boat_body_entered)
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
	return_phase.modulate.a = 1.0
	_set_phase_enabled(return_phase, true)
	_set_phase_enabled(outward_phase, false)

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


## 导出第三关关卡与复活点存档数据
func ExportSaveData() -> Dictionary:
	var respawn_pos := _get_chase_respawn_position()
	return {
		"checkpoint_reached": _in_return_phase or is_instance_valid(chase_respawn_point),
		"respawn_x": respawn_pos.x,
		"respawn_y": respawn_pos.y,
		"bone_claimed": _bone_claimed,
		"bone_offered": _bone_offered,
	}


## 从存档还原第三关状态；若仍持有骨头则恢复返程，否则在拾取点待交互。
func LoadSaveData(data: Dictionary) -> void:
	_bone_offered = bool(data.get("bone_offered", false))
	_bone_claimed = _bone_offered or bool(data.get("bone_claimed", false))
	_loaded_checkpoint = bool(data.get("checkpoint_reached", false))
	if _loaded_checkpoint:
		_loaded_respawn_position = Vector2(
			float(data.get("respawn_x", _get_chase_respawn_position().x)),
			float(data.get("respawn_y", _get_chase_respawn_position().y))
		)
	_refresh_bone()

	# 先恢复场景，玩家持有状态和存档点位置待所有实体加载后同步。
	if is_instance_valid(_chaser) and _chaser.has_method(&"ResetChase"):
		_chaser.call(&"ResetChase")
	_in_return_phase = false
	_chase_activation_pending = false
	_chase_finished = false
	_set_phase_enabled(outward_phase, true)
	_set_phase_enabled(return_phase, false)


func _on_save_loaded(_slot: int) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var carrying := bool(player.get("has_scarred_bones"))
	_bone_claimed = _bone_offered or carrying
	_refresh_bone()
	if _loaded_checkpoint:
		player.global_position = _loaded_respawn_position
		if player.has_method(&"SetRespawnPosition"):
			player.call(&"SetRespawnPosition", _loaded_respawn_position)
		_loaded_checkpoint = false
	if carrying and not _bone_offered:
		SwitchToReturnPhase()
	elif _in_return_phase and not _bone_offered:
		_in_return_phase = false
		_set_phase_enabled(outward_phase, true)
		_set_phase_enabled(return_phase, false)


func _set_phase_enabled(phase: Node2D, enabled: bool) -> void:
	phase.visible = enabled
	phase.process_mode = (
		Node.PROCESS_MODE_INHERIT
		if enabled
		else Node.PROCESS_MODE_DISABLED
	)
	_set_phase_collisions(phase, enabled)


func _set_phase_collisions(node: Node, enabled: bool) -> void:
	if node is TileMapLayer:
		node.collision_enabled = enabled
	elif node is CollisionShape2D or node is CollisionPolygon2D:
		node.set_deferred("disabled", not enabled)
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
	var return_tiles: TileMapLayer = $ReturnPhase/ReturnTileMap
	_reset_chase_on_respawn = _in_return_phase and return_tiles.get_used_rect().has_point(return_tiles.local_to_map(return_tiles.to_local(player.global_position)))
	if _bone_claimed and not _bone_offered:
		_reset_chase_on_respawn = _reset_chase_on_respawn or _in_return_phase
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
	_set_phase_enabled(outward_phase, true)
	_set_phase_enabled(return_phase, false)

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
