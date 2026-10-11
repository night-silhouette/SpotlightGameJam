@tool
extends Node2D
## Horizontal floors use shared Parallax2D compositions. Vertical shafts keep local clipping.
# Standalone F6 runs are parented to Window; map attachment is optional for preview.
@onready var _map: Node2D = get_parent() as Node2D
var _regions: Array[Control] = []
var _layers: Dictionary = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		_sync_editor_shaft_widths()
		return
	visible = ExportSettings.level2_scenery_enabled
	for region_node in get_children():
		if not region_node is Control:
			continue
		var region := region_node as Control
		var room: Node2D = null
		if is_instance_valid(_map):
			room = _map.get_node_or_null("Rooms/" + str(region.name)) as Node2D
		# Non-rendering room metadata preserves the old background bounds.
		# Standalone scenery keeps the authored region positions and sizes.
		if room != null and room.has_meta("scenery_bounds") and not region.get_meta("use_authored_bounds", false):
			var bounds: Rect2 = room.get_meta("scenery_bounds")
			region.position = to_local(room.to_global(bounds.position))
			region.size = bounds.size
		_regions.append(region)
		var textures: Array[TextureRect] = []
		for layer in region.find_children("*", "TextureRect", true, false):
			layer.material = layer.material.duplicate()
			textures.append(layer)
		_layers[region] = textures
	_update_layers()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_sync_editor_shaft_widths()
		return
	if visible:
		_update_layers()

# Keep editor previews fitted too; do not run camera culling or gameplay settings here.
# Vertical materials are local to each scene instance, so narrow shafts stay independent.
func _sync_editor_shaft_widths() -> void:
	for region in get_children():
		if not region is Control or not region.get_meta("vertical_layout", false):
			continue
		for layer in region.find_children("*", "TextureRect", true, false):
			var material := layer.material as ShaderMaterial
			if material != null and material.get_shader_parameter("shaft_width") != region.size.x:
				material.set_shader_parameter("shaft_width", region.size.x)

func _update_layers() -> void:
	var viewport := get_viewport()
	var inverse := viewport.get_canvas_transform().affine_inverse()
	var view_size := viewport.get_visible_rect().size
	var camera_local := to_local(inverse * (view_size * 0.5))
	var view_bounds := Rect2(to_local(inverse * Vector2.ZERO), Vector2.ZERO)
	view_bounds = view_bounds.expand(to_local(inverse * view_size)).grow(80.0)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	for region in _regions:
		region.visible = view_bounds.intersects(Rect2(region.position, region.size))
		if not region.visible:
			continue
		var vertical := bool(region.get_meta("vertical_layout", false))
		var player_local: Vector2 = region.get_global_transform().affine_inverse() * player.global_position if is_instance_valid(player) else Vector2(-10000, -10000)
		for layer: TextureRect in _layers[region]:
			var material := layer.material as ShaderMaterial
			var depth := str(layer.get_meta("depth", "middle"))
			var speed: float = ExportSettings.level2_scenery_middle_speed
			if depth == "far":
				speed = ExportSettings.level2_scenery_far_speed
			elif depth == "front":
				speed = ExportSettings.level2_scenery_foreground_speed
			# Legacy names describe draw groups, not visual distance: NearColumn is
			# the pale rear column. Change motion without changing artist opacity.
			if vertical:
				if layer.name == &"LeftColumns":
					speed = ExportSettings.level2_scenery_vertical_middle_speed
				elif layer.name == &"NearColumn":
					speed = ExportSettings.level2_scenery_vertical_far_speed
				elif layer.name == &"RightColumns":
					speed = ExportSettings.level2_scenery_vertical_foreground_speed
			var scroll := Vector2(region.position.x + camera_local.x * (speed - 1.0), 0.0)
			if vertical:
				scroll = Vector2(0.0, (camera_local.y - region.position.y) * (speed - 1.0))
			material.set_shader_parameter("vertical_layout", vertical)
			material.set_shader_parameter("shaft_width", region.size.x)
			material.set_shader_parameter("artwork_height", ExportSettings.level2_scenery_artwork_height)
			material.set_shader_parameter("scroll_pixels", scroll)
			material.set_shader_parameter("player_pixels", player_local)
			material.set_shader_parameter("clear_radius", ExportSettings.level2_scenery_player_clear_radius)
			material.set_shader_parameter("opacity", ExportSettings.level2_scenery_foreground_opacity if depth == "front" else 1.0)
