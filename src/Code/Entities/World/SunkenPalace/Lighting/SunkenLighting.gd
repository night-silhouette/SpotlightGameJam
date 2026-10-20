extends Node2D
## 第一关室外自然光与宫殿室内火把、破窗光照；不修改玩法、碰撞或存档。

@onready var _ambient: CanvasModulate = $Ambient
@onready var _sunlight: DirectionalLight2D = $OutdoorSunlight
@onready var _torches: Node2D = $Torches
@onready var _windows: Node2D = $Windows
@onready var _window_beams: Node2D = $WindowBeams
@onready var _settings: Node = get_node("/root/ExportSettings")
@onready var _palace: Node2D = get_parent() as Node2D

var _torch_lights: Array[PointLight2D] = []
var _window_lights: Array[PointLight2D] = []
var _player: Node2D
var _level_weight: float = 0.0
var _interior_weight: float = 0.0
var _lake_room_weight: float = 0.0
var _elapsed: float = 0.0


func _ready() -> void:
	for child in _torches.get_children():
		if child is PointLight2D:
			_torch_lights.append(child as PointLight2D)
	for child in _windows.get_children():
		if child is PointLight2D:
			_window_lights.append(child as PointLight2D)
	_ambient.visible = false
	_apply_settings()


func _process(delta: float) -> void:
	_elapsed += delta
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D

	var in_level := false
	var in_interior := false
	var in_lake_room := false
	if is_instance_valid(_player) and is_instance_valid(_palace):
		var local_position := _palace.to_local(_player.global_position)
		var x_bounds: Vector2 = _settings.sunken_scenery_camera_bounds
		var y_bounds: Vector2 = _settings.sunken_scenery_camera_y_bounds
		in_level = (
			local_position.x >= minf(x_bounds.x, x_bounds.y)
			and local_position.x <= maxf(x_bounds.x, x_bounds.y)
			and local_position.y >= minf(y_bounds.x, y_bounds.y)
			and local_position.y <= maxf(y_bounds.x, y_bounds.y)
		)
		in_interior = in_level and _settings.sunken_lighting_indoor_bounds.has_point(local_position)
		in_lake_room = in_interior and _settings.sunken_lighting_lake_room_bounds.has_point(local_position)

	var transition: float = maxf(_settings.sunken_lighting_transition_time, 0.001)
	_level_weight = move_toward(_level_weight, 1.0 if in_level else 0.0, delta / transition)
	_interior_weight = move_toward(_interior_weight, 1.0 if in_interior else 0.0, delta / transition)
	_lake_room_weight = move_toward(_lake_room_weight, 1.0 if in_lake_room else 0.0, delta / transition)
	_apply_settings()


func _apply_settings() -> void:
	var enabled: bool = _settings.sunken_lighting_enabled
	var active_amount := _level_weight if enabled else 0.0
	_ambient.visible = active_amount > 0.001
	var outdoor_ambient: Color = Color.WHITE.lerp(
		_settings.sunken_lighting_outdoor_ambient_color,
		active_amount
	)
	var palace_ambient: Color = outdoor_ambient.lerp(
		_settings.sunken_lighting_indoor_ambient_color,
		_interior_weight * active_amount
	)
	_ambient.color = palace_ambient.lerp(
		_settings.sunken_lighting_lake_room_ambient_color,
		_lake_room_weight * active_amount
	)

	_sunlight.enabled = active_amount > 0.001 and _interior_weight < 0.999
	_sunlight.color = _settings.sunken_lighting_sun_color
	_sunlight.energy = (
		_settings.sunken_lighting_sun_energy
		* active_amount
		* (1.0 - _interior_weight)
	)

	for index in range(_torch_lights.size()):
		var light := _torch_lights[index]
		light.enabled = active_amount > 0.001
		light.color = _settings.sunken_lighting_torch_color
		light.texture_scale = _settings.sunken_lighting_torch_radius / 128.0
		var phase := float(index) * 1.731
		var flicker := (
			sin(_elapsed * _settings.sunken_lighting_torch_flicker_speed + phase) * 0.55
			+ sin(_elapsed * _settings.sunken_lighting_torch_flicker_speed * 2.17 + phase * 0.7) * 0.30
			+ sin(_elapsed * _settings.sunken_lighting_torch_flicker_speed * 3.71 + phase * 1.3) * 0.15
		)
		light.energy = (
			_settings.sunken_lighting_torch_energy
			* (1.0 + flicker * _settings.sunken_lighting_torch_flicker_amount)
			* active_amount
		)

	for light in _window_lights:
		light.enabled = active_amount > 0.001
		light.color = _settings.sunken_lighting_window_color
		light.energy = _settings.sunken_lighting_window_energy * active_amount
		light.texture_scale = _settings.sunken_lighting_window_radius / 128.0

	_window_beams.visible = active_amount > 0.001
	var beam_color: Color = _settings.sunken_lighting_window_color
	beam_color.a = _settings.sunken_lighting_window_beam_opacity * active_amount
	_window_beams.modulate = beam_color


func _exit_tree() -> void:
	# CanvasModulate 与第二关共用同一 Canvas；离开时先隐藏，避免残留第一关色调。
	_ambient.visible = false
