@tool
extends Node2D
## Fits the shared artist composition in both the editor and the game.
## Native Parallax2D owns repetition; coverage only trims each horizontal floor.
const COVERAGE_SHADER: Shader = preload("res://Code/Entities/World/DepthsLibrary/Level2/Scenery/HorizontalCoverage.gdshader")
const COMPOSITION: PackedScene = preload("res://Code/Entities/World/DepthsLibrary/Level2/Scenery/parallax_scenery2.tscn")
const SETTINGS_SCENE: PackedScene = preload("res://Code/Autoloads/ExportSettings.tscn")
const SETTINGS_SCRIPT: Script = preload("res://Code/Autoloads/ExportSettings.gd")
var _materials: Array[ShaderMaterial] = []
var _sources: Dictionary = {}
var _editor_settings: Dictionary = {}
var _composition_height: float = 1.0
var _last_bounds := Rect2()
var _last_height: float = -1.0

func _ready() -> void:
	_initialize()
	_refresh()

func _initialize() -> void:
	_materials.clear()
	_sources.clear()
	_composition_height = 1.0
	_last_height = -1.0
	# Read authored values, never the already-scaled editor nodes. This also
	# prevents cumulative scaling after a script reload or scene re-entry.
	var state := COMPOSITION.get_state()
	for index in range(state.get_node_count()):
		var properties: Dictionary = {}
		for property_index in range(state.get_node_property_count(index)):
			properties[state.get_node_property_name(index, property_index)] = state.get_node_property_value(index, property_index)
		var path := state.get_node_path(index)
		if state.get_node_type(index) == &"Sprite2D":
			var source_position: Vector2 = properties.get("position", Vector2.ZERO)
			var source_scale: Vector2 = properties.get("scale", Vector2.ONE)
			var texture := properties.get("texture") as Texture2D
			_sources[path] = {"position": source_position, "scale": source_scale}
			if texture != null:
				_composition_height = maxf(_composition_height, source_position.y + texture.get_height() * source_scale.y)
		elif state.get_node_type(index) == &"Parallax2D":
			_sources[path] = {"repeat_size": properties.get("repeat_size", Vector2.ZERO)}
	for child in get_children():
		var layer := child as Parallax2D
		if layer == null:
			continue
		var material := ShaderMaterial.new()
		material.shader = COVERAGE_SHADER
		material.set_shader_parameter("foreground", layer.name == &"ForegroundLoop")
		_materials.append(material)
		for sprite in layer.get_children():
			if sprite is Sprite2D:
				sprite.material = material

func _process(_delta: float) -> void:
	# Hot-reloading @tool can start processing without another _ready call.
	if _materials.is_empty():
		_initialize()
	_refresh()

func _read_editor_settings() -> void:
	_editor_settings.clear()
	if not Engine.is_editor_hint():
		return
	# Autoloads do not run in the editor. Read the same saved overrides/defaults.
	var state := SETTINGS_SCENE.get_state()
	for index in range(state.get_node_property_count(0)):
		var property_name := state.get_node_property_name(0, index)
		if str(property_name).begins_with("level2_scenery_"):
			_editor_settings[property_name] = state.get_node_property_value(0, index)

func _setting(property_name: StringName) -> Variant:
	if not Engine.is_editor_hint():
		var settings := get_node_or_null("/root/ExportSettings")
		if settings != null:
			return settings.get(property_name)
	return _editor_settings.get(property_name, SETTINGS_SCRIPT.get_property_default_value(property_name))

func _shaft_bounds(region_name: StringName) -> Vector4:
	# Read the sibling background region, not a fixed width or a camera position.
	# A standalone horizontal composition has no shafts and therefore no cutouts.
	var parent := get_parent()
	if parent == null:
		return Vector4.ZERO
	var region := parent.get_node_or_null(NodePath(region_name)) as Control
	if region == null or not bool(region.get_meta("vertical_layout", false)):
		return Vector4.ZERO
	var rect := region.get_global_rect()
	if region_name == &"LowerStairwell":
		var overlap := clampf(float(_setting(&"level2_scenery_lower_entry_overlap")), 0.0, region.size.y)
		var clip_top := region.get_global_transform() * Vector2(0.0, overlap)
		rect.size.y = maxf(rect.end.y - clip_top.y, 0.0)
		rect.position.y = clip_top.y
	return Vector4(rect.position.x, rect.position.y, rect.end.x, rect.end.y)

func _refresh() -> void:
	_read_editor_settings()
	var bounds: Rect2 = get_meta("coverage", Rect2(-4300, 0, 8400, 800))
	var height := minf(maxf(float(_setting(&"level2_scenery_artwork_height")), 1.0), maxf(bounds.size.y, 1.0))
	if bounds != _last_bounds or not is_equal_approx(height, _last_height):
		var factor := height / _composition_height
		for path: NodePath in _sources:
			var node := get_node_or_null(path)
			if node is Sprite2D:
				# Pillars are placed/scaled per room in the scene. Their parent
				# still supplies parallax and repetition; fitting must not reset them.
				if node.get_parent() == get_node_or_null("ForegroundLoop"):
					continue
				node.position = _sources[path]["position"] * factor + Vector2(0.0, bounds.position.y)
				node.scale = _sources[path]["scale"] * factor
			elif node is Parallax2D:
				node.repeat_size = _sources[path]["repeat_size"] * factor
		_last_bounds = bounds
		_last_height = height
	for child in get_children():
		if child is Parallax2D:
			var speed_name: StringName = &"level2_scenery_foreground_speed" if child.name == &"ForegroundLoop" else &"level2_scenery_middle_speed"
			child.scroll_scale = Vector2(float(_setting(speed_name)), 1.0)
	var corner := to_global(bounds.position)
	var end := to_global(bounds.end)
	var descent := _shaft_bounds(&"DescentShaft")
	var stairwell := _shaft_bounds(&"LowerStairwell")
	var fountain := _shaft_bounds(&"FountainShaft")
	var player: Node2D = null
	if not Engine.is_editor_hint():
		player = get_tree().get_first_node_in_group("player") as Node2D
	for material in _materials:
		material.set_shader_parameter("world_bounds", Vector4(corner.x, corner.y, end.x, end.y))
		material.set_shader_parameter("descent_bounds", descent)
		material.set_shader_parameter("stairwell_bounds", stairwell)
		material.set_shader_parameter("fountain_bounds", fountain)
		material.set_shader_parameter("opacity", float(_setting(&"level2_scenery_foreground_opacity")))
		material.set_shader_parameter("clear_radius", float(_setting(&"level2_scenery_player_clear_radius")))
		material.set_shader_parameter("player_world", player.global_position if is_instance_valid(player) else Vector2(-100000, -100000))
