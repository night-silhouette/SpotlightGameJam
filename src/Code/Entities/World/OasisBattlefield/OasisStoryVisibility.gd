extends Node2D

@onready var _outward_story_items: Array[InteractableComponent] = [
	get_node("残破武器_4_4至4_5") as InteractableComponent,
	get_node("枯骨与发光植物_4_6至4_7") as InteractableComponent,
]

var _initial_visibility: Dictionary = {}
var _initial_interaction: Dictionary = {}


func _ready() -> void:
	for item in _outward_story_items:
		_initial_visibility[item] = item.visible
		_initial_interaction[item] = item.enable_interaction
	if not SignalBus.OasisReturnPhaseChanged.is_connected(_on_oasis_return_phase_changed):
		SignalBus.OasisReturnPhaseChanged.connect(_on_oasis_return_phase_changed)


func _on_oasis_return_phase_changed(_source: Node2D, in_return_phase: bool) -> void:
	for item in _outward_story_items:
		item.visible = bool(_initial_visibility[item]) and not in_return_phase
		item.enable_interaction = bool(_initial_interaction[item]) and not in_return_phase
