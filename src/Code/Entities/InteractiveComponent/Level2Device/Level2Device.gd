extends Node2D
## 第二关钥匙、符文和喷泉。行为类型保存在节点元数据，位置直接在2D视图编辑。
const KEYBINDS = preload("res://Code/Entities/Setting/KeybindManager.gd")
var available: bool = true
var _player: Node2D
var _level: Node2D
@onready var _prompt: Control = $PromptContainer

func _ready() -> void:
	_level = get_parent() as Node2D
	while _level != null and not _level.is_in_group("level2_map"):
		_level = _level.get_parent() as Node2D
	$PromptContainer/PromptButton.pressed.connect(_request)
	$PromptContainer/HBox/ActionLabel.text = str(get_meta("label", "交互"))

func _process(_delta: float) -> void:
	_player = null
	if available:
		for body in get_tree().get_nodes_in_group("player"):
			if body is Node2D and global_position.distance_to(body.global_position) <= ExportSettings.level2_interact_radius:
				_player = body
				break
	if is_instance_valid(_player) and is_instance_valid(_level):
		var nearest: Node2D = self
		var nearest_distance: float = global_position.distance_squared_to(_player.global_position)
		for other in get_tree().get_nodes_in_group("level2_device"):
			if other == self or not _level.is_ancestor_of(other) or not other.get("available"):
				continue
			var distance: float = other.global_position.distance_squared_to(_player.global_position)
			if distance < nearest_distance or (is_equal_approx(distance, nearest_distance) and other.get_instance_id() < nearest.get_instance_id()):
				nearest = other
				nearest_distance = distance
		if nearest != self:
			_player = null
	_prompt.visible = is_instance_valid(_player)
	$PromptContainer/HBox/KeyBadge.text = KEYBINDS.GetActionKeyBadgeText(&"interact", "F")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo() and _prompt.visible:
		get_viewport().set_input_as_handled()
		_request()

func _request() -> void:
	if available and is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= ExportSettings.level2_interact_radius:
		SignalBus.Level2InteractionRequested.emit(self, _player)
