@tool
extends Node2D
## Camp 分层原画：统一画布、缩放和原点，默认还原构图，可选有限范围视差。
const COVERAGE: Shader = preload("res://Code/Entities/World/Camp/Scenery/CampCoverage.gdshader")
const SETTINGS: Script = preload("res://Code/Autoloads/ExportSettings.gd")
const SETTINGS_SCENE: PackedScene = preload("res://Code/Autoloads/ExportSettings.tscn")
var _editor_settings: Dictionary = {}
var _materials: Dictionary = {}
var _poll_left: float = 0.0

func _ready() -> void:
	_read_settings()
	_prepare_materials()
	_refresh()

func _read_settings() -> void:
	_editor_settings.clear()
	if not Engine.is_editor_hint():
		return
	var state := SETTINGS_SCENE.get_state()
	for index in range(state.get_node_property_count(0)):
		var key := state.get_node_property_name(0, index)
		if str(key).begins_with("camp_scenery_"):
			_editor_settings[key] = state.get_node_property_value(0, index)

func _setting(key: StringName) -> Variant:
	if not Engine.is_editor_hint():
		return ExportSettings.get(key)
	return _editor_settings.get(key, SETTINGS.get_property_default_value(key))

func _prepare_materials() -> void:
	for layer in get_children():
		if not layer is Node2D:
			continue
		var material := ShaderMaterial.new()
		material.shader = COVERAGE
		material.set_shader_parameter("foreground", layer.name == &"Foreground")
		_materials[layer] = material
		for sprite in layer.get_children():
			if sprite is Sprite2D:
				sprite.material = material

func _process(delta: float) -> void:
	if _materials.is_empty():
		_prepare_materials()
	_poll_left -= delta
	if _poll_left <= 0.0:
		_poll_left = 0.5
		_read_settings()
	_refresh()

func _refresh() -> void:
	var factor := maxf(0.01, float(_setting(&"camp_scenery_scale")))
	var ground := float(_setting(&"camp_scenery_ground_y"))
	var left := float(_setting(&"camp_scenery_offset_x"))
	var origin := Vector2(left, ground - 1900.0 * factor)
	var width := 1152.0 * factor
	var camera_x := left + width * 0.5
	var player: Node2D = null
	if not Engine.is_editor_hint():
		var camera_world := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
		camera_x = to_local(camera_world).x
		player = get_tree().get_first_node_in_group("player") as Node2D
	var use_parallax := bool(_setting(&"camp_scenery_parallax_enabled"))
	for layer: Node2D in _materials:
		var speed := 1.0
		if layer.name == &"Sky":
			speed = float(_setting(&"camp_scenery_sky_speed"))
		elif layer.name == &"FarBackground":
			speed = float(_setting(&"camp_scenery_far_speed"))
		elif layer.name == &"MiddleBackground":
			speed = float(_setting(&"camp_scenery_middle_speed"))
		elif layer.name == &"Foreground":
			speed = float(_setting(&"camp_scenery_foreground_speed"))
		if layer is Parallax2D:
			# Parallax2D 架构模式：通过 scroll_scale 控制视差，repeat_size 保持本地尺寸 (1152, 4036)
			# 不可额外乘以 factor，因为 layer.scale 会自动作用于本地 repeat_size！
			layer.scroll_scale = Vector2(speed, 1.0) if use_parallax else Vector2.ONE
			layer.repeat_size = Vector2(2304.0, 4036.0)
			layer.position = origin
		else:
			var travel := clampf(camera_x - (left + width * 0.5), -width * 0.5, width * 0.5) if use_parallax else 0.0
			layer.position = origin + Vector2(travel * (1.0 - speed), 0.0)
		layer.scale = Vector2.ONE * factor
		var material: ShaderMaterial = _materials[layer]
		material.set_shader_parameter("enabled", 1.0 if bool(_setting(&"camp_scenery_enabled")) else 0.0)
		material.set_shader_parameter("opacity", float(_setting(&"camp_scenery_foreground_opacity")))
		material.set_shader_parameter("clear_radius", float(_setting(&"camp_scenery_player_clear_radius")))
		material.set_shader_parameter("player_world", player.global_position if is_instance_valid(player) else Vector2(-100000.0, -100000.0))

	# 视口范围裁剪：仅在主城相机边界内可见，避免溢出覆盖其他关卡
	var bounds_setting = _setting(&"camp_scenery_camera_bounds")
	var bounds: Vector2 = bounds_setting if bounds_setting is Vector2 else Vector2(-2000.0, 3000.0)
	var in_bounds: bool = camera_x >= bounds.x and camera_x <= bounds.y
	for layer: Node2D in _materials:
		layer.visible = in_bounds
