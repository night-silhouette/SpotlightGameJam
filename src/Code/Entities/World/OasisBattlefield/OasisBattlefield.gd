extends Node2D

@export_category("Oasis Battlefield")
## 是否在独立运行场景时直接启用返程/追逐阶段，仅用于关卡测试。
@export var start_in_return_phase: bool = false

@onready var outward_phase: Node2D = $OutwardPhase
@onready var return_phase: Node2D = $ReturnPhase
@onready var _chaser: Node = get_node_or_null("ReturnPhase/OasisBattlefieldChaser")
@onready var _boat: OasisBoat = $OutwardPhase/OasisBoat
@onready var _blocker: Node2D = $OutwardPhase/VanishingBlockerComponent
@onready var _bone_interactable: Node2D = $OutwardPhase/InteractableComponent

var _in_return_phase: bool = false


func _ready() -> void:
	SignalBus.BlockerVanished.connect(_on_blocker_vanished)
	SignalBus.ComponentInteracted.connect(_on_component_interacted)
	if start_in_return_phase:
		SwitchToReturnPhase()
	else:
		_set_phase_enabled(outward_phase, true)
		_set_phase_enabled(return_phase, false)


## 切换到返程/追逐阶段，启用返程内容、关闭去程内容，并在追逐者可用时开始追逐。
func SwitchToReturnPhase() -> void:
	if _in_return_phase:
		return
	_in_return_phase = true
	return_phase.modulate.a = 1.0
	_set_phase_enabled(return_phase, true)
	_set_phase_enabled(outward_phase, false)

	if is_instance_valid(_chaser) and _chaser.has_method(&"StartChase"):
		_chaser.call(&"StartChase")


## 骨头收集完成后的关卡入口；调用后切换到返程/追逐阶段。
func OnBoneCollected() -> void:
	SwitchToReturnPhase()


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
	if not _in_return_phase and blocker == _blocker:
		_boat.SolvePuzzle("vanishing_blocker")


func _on_component_interacted(component: Node2D, _interactor: Node2D) -> void:
	if not _in_return_phase and component == _bone_interactable:
		# Interaction can originate from a physics callback; switch outside the query flush.
		call_deferred(&"OnBoneCollected")
