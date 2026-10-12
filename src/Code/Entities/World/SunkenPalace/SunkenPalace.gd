extends Node2D

@onready var _crown: InteractableComponent = $collisionlayer/InterRa/Crown

var _crown_triggered: bool = false


func _ready() -> void:
	if not SignalBus.ComponentInteracted.is_connected(_on_component_interacted):
		SignalBus.ComponentInteracted.connect(_on_component_interacted)


func _on_component_interacted(component: Node2D, _interactor: Node2D) -> void:
	if _crown_triggered or component != _crown:
		return
	_crown_triggered = true
	SignalBus.lock1.emit()
