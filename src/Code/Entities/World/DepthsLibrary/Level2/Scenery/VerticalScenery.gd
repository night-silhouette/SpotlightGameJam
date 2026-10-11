@tool
extends Control
## Fits the supplied composition and clips its Parallax2D layers to the shaft.
const COVERAGE_SHADER: Shader = preload("res://Code/Entities/World/DepthsLibrary/Level2/Scenery/HorizontalCoverage.gdshader")
const COMPOSITION: PackedScene = preload("res://Code/Entities/World/DepthsLibrary/Level2/Scenery/VerticalComposition.tscn")
var _original_transforms: Dictionary = {}
var _materials: Array[ShaderMaterial] = []
var _art_size := Vector2.ONE
var _last_size := Vector2.ZERO

func _ready() -> void:
	_initialize()
	_fit_to_bounds()

func _initialize() -> void:
	_original_transforms.clear()
	_materials.clear()
	_last_size = Vector2.ZERO
	var composition := get_node_or_null("Composition")
	if composition == null:
		return
	_art_size = composition.get_node("BlueDepth/BlueBase").texture.get_size()
	# Read unscaled transforms from the source; hot reload must not scale twice.
	var state := COMPOSITION.get_state()
	for index in range(state.get_node_count()):
		if state.get_node_type(index) != &"Sprite2D":
			continue
		var source_position := Vector2.ZERO
		var source_scale := Vector2.ONE
		var source_rotation := 0.0
		for property_index in range(state.get_node_property_count(index)):
			var property_name := state.get_node_property_name(index, property_index)
			var value: Variant = state.get_node_property_value(index, property_index)
			if property_name == &"position":
				source_position = value
			elif property_name == &"scale":
				source_scale = value
			elif property_name == &"rotation":
				source_rotation = value
		var sprite := composition.get_node_or_null(state.get_node_path(index)) as Sprite2D
		if sprite != null:
			_original_transforms[sprite] = Transform2D(source_rotation, source_scale, 0.0, source_position)
	for layer in composition.get_children():
		if not layer is Parallax2D:
			continue
		var material := ShaderMaterial.new()
		material.shader = COVERAGE_SHADER
		material.set_shader_parameter("foreground", layer.name == &"Foreground")
		_materials.append(material)
		for sprite in layer.get_children():
			if sprite is Sprite2D:
				sprite.material = material

func _fit_to_bounds() -> void:
	var factor := size / _art_size
	for sprite: Sprite2D in _original_transforms:
		var original: Transform2D = _original_transforms[sprite]
		sprite.transform = Transform2D(Vector2(factor.x, 0), Vector2(0, factor.y), Vector2.ZERO) * original
	_last_size = size

func _process(_delta: float) -> void:
	if _materials.is_empty():
		_initialize()
	if size != _last_size:
		_fit_to_bounds()
	if is_visible_in_tree():
		_update_motion()
		_update_materials()

func _update_motion() -> void:
	# Unique lower decoration may drift, but cannot wrap back into the entrance.
	var architecture_offset := 0.0
	if not Engine.is_editor_hint():
		var camera_world := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
		var camera_y := (get_global_transform().affine_inverse() * camera_world).y
		var travel := minf(ExportSettings.level2_scenery_vertical_architecture_travel, size.y * 0.1)
		if travel > 0.0:
			# Spread bounded travel over the entire shaft; avoid tanh saturation
			# making the column appear stationary near both ends.
			var progress := clampf(camera_y / maxf(size.y, 1.0), 0.0, 1.0)
			architecture_offset = lerpf(-travel, travel, progress)
	for layer in $Composition.get_children():
		if not layer is Parallax2D:
			continue
		var speed := 1.0
		# Editor preview keeps the authored arrangement. Only the game's camera
		# drives motion. The silver column uses bounded offset; BlueDepth/LowerLedge stays fixed.
		if not Engine.is_editor_hint():
			if layer.name == &"DistantColumn":
				speed = ExportSettings.level2_scenery_vertical_far_speed
			elif layer.name == &"Foreground":
				speed = ExportSettings.level2_scenery_vertical_foreground_speed
		layer.scroll_offset = Vector2(0.0, architecture_offset) if layer.name == &"LeftArchitecture" else Vector2.ZERO
		var scroll := Vector2(1.0, speed)
		var moving := not is_equal_approx(speed, 1.0)
		var blend := clampf(ExportSettings.level2_scenery_vertical_loop_blend, 0.01, 0.15) if moving else 0.0
		var repeat := Vector2(0.0, size.y * (1.0 - blend)) if moving else Vector2.ZERO
		var material := layer.get_child(0).material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("vertical_loop_fade", blend)
		if layer.scroll_scale != scroll:
			layer.scroll_scale = scroll
		if layer.repeat_size != repeat:
			layer.repeat_size = repeat
		layer.repeat_times = 2

func _update_materials() -> void:
	var corner := global_position
	var end := get_global_transform() * size
	var player: Node2D = null
	if not Engine.is_editor_hint():
		player = get_tree().get_first_node_in_group("player") as Node2D
	for material in _materials:
		material.set_shader_parameter("world_bounds", Vector4(corner.x, corner.y, end.x, end.y))
		material.set_shader_parameter("opacity", 1.0 if Engine.is_editor_hint() else ExportSettings.level2_scenery_vertical_foreground_opacity)
		material.set_shader_parameter("clear_radius", 32.0 if Engine.is_editor_hint() else ExportSettings.level2_scenery_vertical_clear_radius)
		material.set_shader_parameter("player_world", player.global_position if is_instance_valid(player) else Vector2(-100000, -100000))
