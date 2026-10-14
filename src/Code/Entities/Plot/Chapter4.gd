extends "res://Code/Entities/Plot/Chapter2.gd"

@export var outward_phase: Node2D
@export var return_phase: Node2D
@export var bone_interactable: InteractableComponent

func _ready() -> void:
	if bone_interactable != null:
		SignalBus.ComponentInteracted.connect(_on_component_interacted)
	super._ready()

func _on_body_entered(body: Node2D, index: int) -> void:
	var trigger := get_child(index) as InteractableComponent
	if trigger == null or not body.is_in_group("player"):
		return
	match String(trigger.get_meta("story_phase", "outward")):
		"outward":
			if outward_phase != null and not outward_phase.visible:
				return
		"return":
			if return_phase == null or not return_phase.visible:
				return
		"bone", "pending":
			return
	super._on_body_entered(body, index)

func _queue_event(index: int, body: Node2D) -> void:
	if index not in _completed and index != _active_event and index not in _pending:
		super._on_body_entered(body, index)

func _on_component_interacted(component: Node2D, interactor: Node2D) -> void:
	if component == bone_interactable and interactor.is_in_group("player"):
		_queue_event(3, interactor)
