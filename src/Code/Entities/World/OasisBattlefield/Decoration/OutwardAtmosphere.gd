extends Node2D
## 第三关去程专用的世界空间柔光与漂浮微粒；效果固定在地图中，不跟随镜头。


@onready var _ambient_glow: ColorRect = $AmbientGlow
@onready var _motes: CPUParticles2D = $Motes
@onready var _action_wake: CPUParticles2D = $ActionWake

var _wake_refresh_left: float = 0.0


func _ready() -> void:
	if not SignalBus.PlayerBeforeMotion.is_connected(_on_player_before_motion):
		SignalBus.PlayerBeforeMotion.connect(_on_player_before_motion)
	_apply_settings()


func _process(delta: float) -> void:
	if _wake_refresh_left <= 0.0:
		_action_wake.emitting = false
		return
	_wake_refresh_left = maxf(0.0, _wake_refresh_left - delta)


func _apply_settings() -> void:
	visible = ExportSettings.oasis_outward_light_enabled
	_motes.emitting = visible
	var bounds: Vector2 = ExportSettings.oasis_outward_light_world_x_bounds
	var field_width := maxf(1.0, bounds.y - bounds.x)
	var field_height := maxf(1.0, ExportSettings.oasis_outward_light_world_height)
	var field_center := Vector2(
		(bounds.x + bounds.y) * 0.5,
		ExportSettings.oasis_outward_light_world_center_y
	)
	_ambient_glow.position = field_center - Vector2(field_width, field_height) * 0.5
	_ambient_glow.size = Vector2(field_width, field_height)
	_motes.position = field_center
	_motes.emission_rect_extents = Vector2(field_width, field_height) * 0.5
	_motes.amount = maxi(1, ExportSettings.oasis_outward_light_mote_count)
	_motes.lifetime = maxf(0.1, ExportSettings.oasis_outward_light_mote_lifetime)
	_motes.preprocess = _motes.lifetime
	_motes.initial_velocity_min = maxf(0.0, ExportSettings.oasis_outward_light_mote_speed * 0.55)
	_motes.initial_velocity_max = maxf(_motes.initial_velocity_min, ExportSettings.oasis_outward_light_mote_speed)
	_motes.scale_amount_min = maxf(0.05, ExportSettings.oasis_outward_light_mote_size.x)
	_motes.scale_amount_max = maxf(_motes.scale_amount_min, ExportSettings.oasis_outward_light_mote_size.y)
	_motes.color = ExportSettings.oasis_outward_light_mote_color
	_action_wake.amount = maxi(1, ExportSettings.oasis_outward_light_wake_count)
	_action_wake.lifetime = maxf(0.1, ExportSettings.oasis_outward_light_wake_lifetime)
	_action_wake.scale_amount_min = _motes.scale_amount_min
	_action_wake.scale_amount_max = _motes.scale_amount_max * 1.25
	_action_wake.color = ExportSettings.oasis_outward_light_mote_color
	var glow_material := _ambient_glow.material as ShaderMaterial
	if glow_material:
		glow_material.set_shader_parameter(&"glow_color", ExportSettings.oasis_outward_light_glow_color)
		glow_material.set_shader_parameter(&"glow_strength", ExportSettings.oasis_outward_light_glow_strength)


func _on_player_before_motion(player: CharacterBody2D, _delta: float) -> void:
	if not is_visible_in_tree() or not ExportSettings.oasis_outward_light_wake_enabled or not is_instance_valid(player):
		_action_wake.emitting = false
		return
	var local_player_position := to_local(player.global_position)
	var bounds: Vector2 = ExportSettings.oasis_outward_light_world_x_bounds
	var half_height := ExportSettings.oasis_outward_light_world_height * 0.5
	var center_y := ExportSettings.oasis_outward_light_world_center_y
	var inside_field := (
		local_player_position.x >= bounds.x
		and local_player_position.x <= bounds.y
		and local_player_position.y >= center_y - half_height
		and local_player_position.y <= center_y + half_height
	)
	var speed := player.velocity.length()
	if not inside_field or speed < ExportSettings.oasis_outward_light_wake_min_speed:
		_action_wake.emitting = false
		return
	_action_wake.global_position = player.global_position
	var horizontal_push := clampf(-player.velocity.x / maxf(speed, 1.0), -1.0, 1.0)
	_action_wake.direction = Vector2(horizontal_push * 0.75, -1.0).normalized()
	var wake_speed := minf(speed * ExportSettings.oasis_outward_light_wake_speed_ratio, 90.0)
	_action_wake.initial_velocity_min = wake_speed * 0.45
	_action_wake.initial_velocity_max = wake_speed
	_action_wake.emitting = true
	_wake_refresh_left = 0.12
