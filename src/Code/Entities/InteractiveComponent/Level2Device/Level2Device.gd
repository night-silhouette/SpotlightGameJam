extends Node2D
## 第二关钥匙、符文、喷泉和残卷。玩家靠近后点击物体图像交互。
var available: bool = true
var _player: Node2D
var _level: Node2D
@onready var _visual: Polygon2D = $Visual
@onready var _interaction_light: PointLight2D = $InteractionLight

func _ready() -> void:
	add_to_group("touch_interactables")
	_level = get_parent() as Node2D
	while _level != null and not _level.is_in_group("level2_map"):
		_level = _level.get_parent() as Node2D
	$PromptContainer.hide()
	$PromptContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Caption.hide()
	var sprite := get_node_or_null("ItemArt") as Sprite2D
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = get_node_or_null("Node2D/FountainIdle") as Sprite2D
	_interaction_light.global_position = sprite.to_global(sprite.get_rect().get_center()) if sprite != null else _visual.to_global(Vector2(0, -28))

func _process(_delta: float) -> void:
	_interaction_light.enabled = available and ExportSettings.level2_hub_light_enabled and str(get_meta("kind", "")) != "fountain"
	_interaction_light.color = ExportSettings.level2_hub_light_device_color
	_interaction_light.energy = ExportSettings.level2_hub_light_device_energy
	_interaction_light.texture_scale = ExportSettings.level2_hub_light_device_radius / 128.0
	_player = null
	if available:
		for body in get_tree().get_nodes_in_group("player"):
			if body is Node2D and global_position.distance_to(body.global_position) <= ExportSettings.level2_interact_radius:
				_player = body
				break

func _unhandled_input(event: InputEvent) -> void:
	if not available or not is_instance_valid(_player) or not event.is_action_pressed(ExportSettings.interactable_action):
		return
	if event is not InputEventMouseButton or not _contains_world_point(get_global_mouse_position()):
		return
	_request()
	get_viewport().set_input_as_handled()

## 触屏点击设备图像时请求交互；world_pos 为世界坐标，interactor 为触摸的玩家，成功请求返回 true。
func TryTouchInteract(world_pos: Vector2, interactor: Node2D) -> bool:
	if not available or interactor != _player or not _contains_world_point(world_pos):
		return false
	if global_position.distance_to(interactor.global_position) > ExportSettings.level2_interact_radius:
		return false
	_request()
	return true

func _contains_world_point(world_pos: Vector2) -> bool:
	var sprite := get_node_or_null("ItemArt") as Sprite2D
	if sprite == null:
		sprite = get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		sprite = get_node_or_null("Node2D/FountainIdle") as Sprite2D
	if sprite != null:
		return sprite.is_visible_in_tree() and sprite.texture != null and sprite.get_rect().has_point(sprite.to_local(world_pos))
	return _visual.is_visible_in_tree() and Geometry2D.is_point_in_polygon(_visual.to_local(world_pos), _visual.polygon)

func _request() -> void:
	if available and is_instance_valid(_player) and global_position.distance_to(_player.global_position) <= ExportSettings.level2_interact_radius:
		SignalBus.Level2InteractionRequested.emit(self, _player)
