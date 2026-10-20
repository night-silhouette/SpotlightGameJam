extends Node2D
## 第三关返程专用的屏幕哑光与世界空间暗尘；保留中央行动区域的可读性。


@onready var _matte_layer: CanvasLayer = $MatteLayer
@onready var _matte_wash: ColorRect = $MatteLayer/MatteWash
@onready var _dark_motes: CPUParticles2D = $DarkMotes
@onready var _glow_motes: CPUParticles2D = $GlowMotes
@onready var _motion_trail: CPUParticles2D = $MotionTrail
@onready var _action_burst: CPUParticles2D = $ActionBurst
@onready var _motion_light: PointLight2D = $MotionLight

var _phase: Node2D
var _oasis: Node2D
var _in_return_phase: bool = false
var _effect_active: bool = false
var _player: CharacterBody2D
var _previous_state: StringName = &""
var _was_on_floor: bool = true
var _light_impulse: float = 0.0
var _motion_speed: float = 0.0


func _ready() -> void:
	_phase = get_parent() as Node2D
	_oasis = _phase.get_parent() as Node2D if _phase else null
	# 单独运行返程场景时没有 Oasis 父节点，直接按返程预览。
	_in_return_phase = _oasis == null
	if not SignalBus.OasisReturnPhaseChanged.is_connected(_on_oasis_return_phase_changed):
		SignalBus.OasisReturnPhaseChanged.connect(_on_oasis_return_phase_changed)
	if not get_viewport().size_changed.is_connected(_refresh_layout):
		get_viewport().size_changed.connect(_refresh_layout)
	if not SignalBus.PlayerBeforeMotion.is_connected(_on_player_before_motion):
		SignalBus.PlayerBeforeMotion.connect(_on_player_before_motion)
	if not SignalBus.PlayerHurt.is_connected(_on_player_hurt):
		SignalBus.PlayerHurt.connect(_on_player_hurt)
	if not SignalBus.PlayerDied.is_connected(_on_player_died):
		SignalBus.PlayerDied.connect(_on_player_died)
	if not SignalBus.PlayerRespawned.is_connected(_on_player_respawned):
		SignalBus.PlayerRespawned.connect(_on_player_respawned)
	_apply_settings()
	_refresh_layout()
	_refresh_particle_area()
	_refresh_visibility()


func _process(delta: float) -> void:
	_refresh_visibility()
	_update_motion_light(delta)


func _apply_settings() -> void:
	_dark_motes.amount = maxi(1, ExportSettings.oasis_return_atmosphere_mote_count)
	_dark_motes.lifetime = maxf(0.1, ExportSettings.oasis_return_atmosphere_mote_lifetime)
	_dark_motes.preprocess = _dark_motes.lifetime
	_dark_motes.initial_velocity_min = maxf(
		0.0, ExportSettings.oasis_return_atmosphere_mote_speed * 0.45
	)
	_dark_motes.initial_velocity_max = maxf(
		_dark_motes.initial_velocity_min, ExportSettings.oasis_return_atmosphere_mote_speed
	)
	_dark_motes.scale_amount_min = maxf(
		0.05, ExportSettings.oasis_return_atmosphere_mote_size.x
	)
	_dark_motes.scale_amount_max = maxf(
		_dark_motes.scale_amount_min, ExportSettings.oasis_return_atmosphere_mote_size.y
	)
	_dark_motes.color = ExportSettings.oasis_return_atmosphere_mote_color
	_glow_motes.amount = maxi(1, ExportSettings.oasis_return_atmosphere_glow_mote_count)
	_glow_motes.lifetime = maxf(0.1, ExportSettings.oasis_return_atmosphere_glow_mote_lifetime)
	_glow_motes.preprocess = _glow_motes.lifetime
	_glow_motes.color = ExportSettings.oasis_return_atmosphere_glow_mote_color
	_motion_trail.amount = maxi(1, ExportSettings.oasis_return_atmosphere_motion_trail_count)
	_motion_trail.color = ExportSettings.oasis_return_atmosphere_motion_glow_color
	_action_burst.amount = maxi(1, ExportSettings.oasis_return_atmosphere_action_burst_count)
	_action_burst.color = ExportSettings.oasis_return_atmosphere_motion_glow_color
	_motion_light.color = ExportSettings.oasis_return_atmosphere_motion_glow_color
	_motion_light.texture_scale = maxf(
		0.1, ExportSettings.oasis_return_atmosphere_motion_light_radius / 64.0
	)
	var matte_material := _matte_wash.material as ShaderMaterial
	if matte_material:
		matte_material.set_shader_parameter(
			&"matte_color", ExportSettings.oasis_return_atmosphere_matte_color
		)
		matte_material.set_shader_parameter(
			&"matte_strength", ExportSettings.oasis_return_atmosphere_matte_strength
		)
		matte_material.set_shader_parameter(
			&"vignette_strength", ExportSettings.oasis_return_atmosphere_vignette_strength
		)
		matte_material.set_shader_parameter(
			&"guide_clear_strength", ExportSettings.oasis_return_atmosphere_guide_clear_strength
		)


func _refresh_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_matte_wash.position = Vector2.ZERO
	_matte_wash.size = viewport_size


func _refresh_particle_area() -> void:
	var x_bounds: Vector2 = ExportSettings.return_scenery_camera_bounds
	var y_bounds: Vector2 = ExportSettings.oasis_return_atmosphere_mote_y_bounds
	var area_size := Vector2(
		maxf(1.0, x_bounds.y - x_bounds.x), maxf(1.0, y_bounds.y - y_bounds.x)
	)
	_dark_motes.position = Vector2(
		(x_bounds.x + x_bounds.y) * 0.5, (y_bounds.x + y_bounds.y) * 0.5
	)
	_dark_motes.emission_rect_extents = area_size * 0.5
	_glow_motes.position = _dark_motes.position
	_glow_motes.emission_rect_extents = _dark_motes.emission_rect_extents


func _set_effect_visible(should_show: bool) -> void:
	_effect_active = should_show
	visible = should_show
	_matte_layer.visible = should_show
	_dark_motes.emitting = should_show
	_glow_motes.emitting = should_show
	if not should_show:
		_motion_trail.emitting = false
		_action_burst.emitting = false
		_motion_light.energy = 0.0


func _refresh_visibility() -> void:
	if (
		not ExportSettings.oasis_return_atmosphere_enabled
		or not _in_return_phase
		or not is_instance_valid(_phase)
		or not _phase.is_visible_in_tree()
	):
		_set_effect_visible(false)
		return
	var camera_world := (
		get_viewport().get_canvas_transform().affine_inverse()
		* (get_viewport().get_visible_rect().size * 0.5)
	)
	var camera_x := _phase.to_local(camera_world).x
	var bounds: Vector2 = ExportSettings.return_scenery_camera_bounds
	var should_show := camera_x >= bounds.x and camera_x <= bounds.y
	_set_effect_visible(should_show)


func _on_oasis_return_phase_changed(source: Node2D, in_return_phase: bool) -> void:
	if source != _oasis:
		return
	_in_return_phase = in_return_phase
	_refresh_visibility()


func _on_player_before_motion(player: CharacterBody2D, _delta: float) -> void:
	if not _effect_active or not is_instance_valid(player):
		return
	var player_changed := player != _player
	_player = player
	var local_position := _phase.to_local(player.global_position)
	_motion_trail.position = local_position
	_action_burst.position = local_position
	_motion_light.position = local_position
	_motion_speed = player.velocity.length()
	var motion_threshold: float = ExportSettings.oasis_return_atmosphere_motion_speed_threshold
	_motion_trail.emitting = _motion_speed >= motion_threshold
	if _motion_speed > 0.001:
		_motion_trail.direction = -player.velocity.normalized()
		_motion_trail.initial_velocity_min = _motion_speed * 0.025
		_motion_trail.initial_velocity_max = maxf(
			_motion_trail.initial_velocity_min, _motion_speed * 0.065
		)

	var current_state := _get_player_state(player)
	var on_floor := player.is_on_floor()
	if player_changed:
		_previous_state = current_state
		_was_on_floor = on_floor
		return
	if current_state != _previous_state:
		if current_state == &"dash":
			_trigger_action_burst(player.velocity, 1.0)
		elif current_state == &"jump":
			_trigger_action_burst(Vector2.DOWN, 0.72)
	if not _was_on_floor and on_floor:
		_trigger_action_burst(Vector2.UP, 0.58)
	_previous_state = current_state
	_was_on_floor = on_floor


func _get_player_state(player: CharacterBody2D) -> StringName:
	var state_machine := player.get_node_or_null("move_state_machine")
	if not is_instance_valid(state_machine):
		return &""
	return StringName(str(state_machine.get("cur_state_name")))


func _trigger_action_burst(direction: Vector2, strength: float) -> void:
	if not _effect_active:
		return
	var burst_direction := direction.normalized() if direction.length_squared() > 0.001 else Vector2.UP
	_action_burst.direction = burst_direction
	_action_burst.initial_velocity_min = 18.0 + 18.0 * strength
	_action_burst.initial_velocity_max = 38.0 + 52.0 * strength
	_action_burst.restart()
	_action_burst.emitting = true
	_light_impulse = maxf(
		_light_impulse,
		ExportSettings.oasis_return_atmosphere_action_light_impulse * strength
	)


func _update_motion_light(delta: float) -> void:
	if not _effect_active or not is_instance_valid(_player):
		_motion_light.energy = 0.0
		return
	var speed_ratio := clampf(
		_motion_speed / maxf(1.0, ExportSettings.player_dash_speed), 0.0, 1.0
	)
	_light_impulse = move_toward(
		_light_impulse,
		0.0,
		ExportSettings.oasis_return_atmosphere_action_light_decay * delta
	)
	var target_energy: float = (
		ExportSettings.oasis_return_atmosphere_motion_light_energy
		+ speed_ratio * ExportSettings.oasis_return_atmosphere_motion_light_speed_boost
		+ _light_impulse
	)
	_motion_light.energy = move_toward(
		_motion_light.energy,
		target_energy,
		ExportSettings.oasis_return_atmosphere_motion_light_response * delta
	)


func _on_player_hurt(_damage_amount: float, knockback_dir: Vector2) -> void:
	if not _effect_active or not is_instance_valid(_player):
		return
	_action_burst.position = _phase.to_local(_player.global_position)
	_motion_light.position = _action_burst.position
	_trigger_action_burst(-knockback_dir, 0.88)


func _on_player_died(player: Node2D) -> void:
	if player != _player:
		return
	_motion_trail.emitting = false
	_motion_light.energy = 0.0
	_motion_speed = 0.0


func _on_player_respawned(_respawn_position: Vector2) -> void:
	_previous_state = &""
	_was_on_floor = true
	_motion_speed = 0.0
