extends Node2D

@onready var _crown: InteractableComponent = $collisionlayer/InterRa/Crown

var _crown_triggered: bool = false
var _crown_offered: bool = false
var _has_explicit_crown_offered: bool = false


func _ready() -> void:
	if not SignalBus.ComponentInteracted.is_connected(_on_component_interacted):
		SignalBus.ComponentInteracted.connect(_on_component_interacted)
	SignalBus.PlayerDied.connect(_on_player_died)
	SignalBus.PlayerRelicConsumeRequested.connect(_on_relic_consumed)
	SignalBus.SaveSlotLoaded.connect(_on_save_loaded)


func _on_component_interacted(component: Node2D, _interactor: Node2D) -> void:
	if _crown_triggered or _crown_offered or component != _crown:
		return
	var player := get_tree().get_first_node_in_group(&"player")
	if is_instance_valid(player) and bool(player.get("has_sunken_crown")):
		_crown_triggered = true
		_refresh_crown()
		return
	_crown_triggered = true
	_refresh_crown()
	SignalBus.lock1.emit()


func _on_player_died(player: Node2D) -> void:
	if player != get_tree().get_first_node_in_group(&"player") or _crown_offered:
		return
	_crown_triggered = false
	_refresh_crown()


func _on_relic_consumed(relic: StringName) -> void:
	if relic != &"crown":
		return
	_crown_offered = true
	_crown_triggered = true
	_refresh_crown()


func _on_save_loaded(_slot: int) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var carrying := bool(player.get("has_sunken_crown"))
	if not _has_explicit_crown_offered and bool(player.get("unlocked_double_jump")) and not carrying:
		_crown_offered = true
	_crown_triggered = _crown_offered or carrying
	_refresh_crown()


func _refresh_crown() -> void:
	_crown.visible = not _crown_triggered and not _crown_offered
	_crown.enable_interaction = _crown.visible


func ExportSaveData() -> Dictionary:
	return {"crown_triggered": _crown_triggered, "crown_offered": _crown_offered}


func LoadSaveData(data: Dictionary) -> void:
	_has_explicit_crown_offered = data.has("crown_offered")
	_crown_offered = bool(data.get("crown_offered", false))
	_crown_triggered = _crown_offered or bool(data.get("crown_triggered", false))
	_refresh_crown()
