extends Node2D
## 第二关钥匙、符文和喷泉。玩家靠近后可右键点击物体或提示按钮交互。
var available: bool = true
var _player: Node2D
var _level: Node2D
@onready var _prompt: Control = $PromptContainer
@onready var _visual: Polygon2D = $Visual

func _ready() -> void:
	add_to_group("touch_interactables")
	_level = get_parent() as Node2D
	while _level != null and not _level.is_in_group("level2_map"):
		_level = _level.get_parent() as Node2D
	$PromptContainer/PromptButton.button_mask = MOUSE_BUTTON_MASK_RIGHT
	$PromptContainer/PromptButton.pressed.connect(_request)
	$PromptContainer/HBox/ActionLabel.text = str(get_meta("label", "交互"))

func _process(_delta: float) -> void:
	_player = null
	if available:
		for body in get_tree().get_nodes_in_group("player"):
			if body is Node2D and global_position.distance_to(body.global_position) <= ExportSettings.level2_interact_radius:
				_player = body
				break
	_prompt.visible = is_instance_valid(_player)
	var bound_event := KeybindManager.GetPrimaryEventForAction(ExportSettings.interactable_action)
	$PromptContainer/PromptButton.button_mask = MOUSE_BUTTON_MASK_RIGHT
	if bound_event is InputEventMouseButton:
		$PromptContainer/PromptButton.button_mask |= 1 << (bound_event.button_index - 1)
	$PromptContainer/HBox/KeyBadge.text = KeybindManager.GetActionKeyBadgeText(ExportSettings.interactable_action, "右键")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(ExportSettings.interactable_action) or not _prompt.visible:
		return
	if event is InputEventMouseButton and not Geometry2D.is_point_in_polygon(_visual.to_local(get_global_mouse_position()), _visual.polygon):
		return
	_request()
	get_viewport().set_input_as_handled()

func TryTouchInteract(world_pos: Vector2, interactor: Node2D) -> bool:
	if not available or not _prompt.visible or interactor != _player:
		return false
	if not Geometry2D.is_point_in_polygon(_visual.to_local(world_pos), _visual.polygon):
		return false
	if global_position.distance_to(interactor.global_position) > ExportSettings.level2_interact_radius:
		return false
	_request()
	return true

func _request() -> void:
	if available and is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= ExportSettings.level2_interact_radius:
		SignalBus.Level2InteractionRequested.emit(self, _player)
