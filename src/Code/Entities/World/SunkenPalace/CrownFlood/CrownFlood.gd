extends Node2D

@onready var _water: Polygon2D = $Water
@onready var _audio: AudioStreamPlayer = $FloodAudio
@onready var _crown: Node2D = get_parent().get_node("collisionlayer/InterRa/Crown")

var _player: CharacterBody2D
var _active: bool = false
var _elapsed: float = 0.0
var _level: float = 0.0
var _outline: PackedVector2Array
var _material: ShaderMaterial


func _ready() -> void:
	_material = _water.material.duplicate() as ShaderMaterial
	_water.material = _material
	_configure_visual()
	_audio.bus = ExportSettings.audio_sfx_bus
	_audio.finished.connect(_on_audio_finished)
	_clear()
	SignalBus.ComponentInteracted.connect(_on_component_interacted)
	SignalBus.PlayerBeforeMotion.connect(_on_player_before_motion)
	SignalBus.PlayerDied.connect(_on_player_died)
	SignalBus.PlayerRespawned.connect(_on_player_respawned)
	SignalBus.SaveSlotLoaded.connect(_on_save_loaded)
	SignalBus.PlayerRelicConsumeRequested.connect(_on_relic_consumed)


func _configure_visual() -> void:
	var room: Rect2 = ExportSettings.crown_flood_room
	var edge: float = ExportSettings.crown_flood_floor_edge
	var left: float = ExportSettings.crown_flood_drop_left
	var bottom: float = ExportSettings.crown_flood_clear_y
	var exit_top: float = ExportSettings.crown_flood_exit_top
	_outline = PackedVector2Array([
		room.position, Vector2(room.end.x, room.position.y), room.end,
		Vector2(edge, room.end.y), Vector2(edge, bottom),
		Vector2(left, bottom), Vector2(left, exit_top), Vector2(room.position.x, exit_top)
	])
	_water.polygon = _outline
	z_index = ExportSettings.crown_flood_z_index
	_material.set_shader_parameter("opening", ExportSettings.crown_flood_opening)
	_material.set_shader_parameter("ceiling", room.position.y)
	_material.set_shader_parameter("floor_y", room.end.y)
	_material.set_shader_parameter("water_color", ExportSettings.crown_flood_water_color)
	_material.set_shader_parameter("foam_color", ExportSettings.crown_flood_foam_color)
	_material.set_shader_parameter("sand_color", ExportSettings.crown_flood_sand_color)
	_material.set_shader_parameter("wave_height", ExportSettings.crown_flood_wave_height)
	_material.set_shader_parameter("wave_length", ExportSettings.crown_flood_wave_length)
	_material.set_shader_parameter("flow_speed", ExportSettings.crown_flood_visual_flow_speed)
	_material.set_shader_parameter("foam_width", ExportSettings.crown_flood_foam_width)
	_material.set_shader_parameter("detail_density", ExportSettings.crown_flood_detail_density)


func _on_component_interacted(component: Node2D, interactor: Node2D) -> void:
	if component != _crown or _active or not interactor is CharacterBody2D:
		return
	if not interactor.is_in_group(&"player"):
		return
	_start(interactor as CharacterBody2D, 0.0)


func _start(player: CharacterBody2D, elapsed: float) -> void:
	if not ExportSettings.crown_flood_enabled or not _contains(player.global_position):
		return
	if player.get("now_HP") == null or float(player.get("now_HP")) <= 0.0:
		return
	_player = player
	_elapsed = elapsed
	_active = true
	_water.show()
	_update_level()
	_update_audio_volume()
	_audio.play()


func _update_audio_volume() -> void:
	var progress := clampf(_elapsed / maxf(ExportSettings.crown_flood_audio_fade_duration, 0.01), 0.0, 1.0)
	_audio.volume_db = lerpf(ExportSettings.crown_flood_audio_start_db, ExportSettings.crown_flood_audio_peak_db, progress)


func _on_audio_finished() -> void:
	if _active:
		_audio.play()


func _contains(world_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(to_local(world_point), _outline)


func _update_level() -> void:
	var room: Rect2 = ExportSettings.crown_flood_room
	var impact: float = room.size.y / maxf(ExportSettings.crown_flood_jet_speed, 1.0)
	var progress := clampf((_elapsed - impact) / maxf(ExportSettings.crown_flood_fill_duration, 0.01), 0.0, 1.0)
	_level = lerpf(room.end.y, room.position.y, progress)
	_material.set_shader_parameter("water_level", _level)
	_material.set_shader_parameter("elapsed", _elapsed)
	_material.set_shader_parameter("jet_tip", minf(room.end.y, room.position.y + _elapsed * ExportSettings.crown_flood_jet_speed))
	_material.set_shader_parameter("pool_ready", _elapsed >= impact)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	if not ExportSettings.crown_flood_enabled or not is_instance_valid(_player) or not _contains(_player.global_position):
		_clear()
		return
	var point := to_local(_player.global_position)
	if point.y >= ExportSettings.crown_flood_clear_y or float(_player.get("now_HP")) <= 0.0:
		_clear()
		return
	_elapsed += delta
	_update_level()
	_update_audio_volume()


func _on_player_before_motion(player: CharacterBody2D, delta: float) -> void:
	if not _active or player != _player or float(player.get("now_HP")) <= 0.0:
		return
	if player.get("offering_locked") == true or player.get("_opening_locked") == true or player.get("debug_flight_enabled") == true:
		return
	var point := to_local(player.global_position)
	if not _contains(player.global_position):
		_clear()
		return
	var half_height: float = ExportSettings.crown_flood_player_half_height
	var immersion := clampf((point.y + half_height - _level) / maxf(half_height * 2.0, 1.0), 0.0, 1.0)
	var room: Rect2 = ExportSettings.crown_flood_room
	if _elapsed < room.size.y / maxf(ExportSettings.crown_flood_jet_speed, 1.0):
		return
	if point.x > ExportSettings.crown_flood_turn_x:
		var surge := clampf(_elapsed / maxf(ExportSettings.crown_flood_surge_duration, 0.01), 0.0, 1.0)
		var speed := lerpf(ExportSettings.crown_flood_min_speed, ExportSettings.crown_flood_max_speed, surge * surge) * immersion
		# 输入加速度已经计算；保持局部水流下限，仍由玩家自己的 move_and_slide 解决全部碰撞。
		if immersion > 0.0:
			player.velocity.x = minf(player.velocity.x, -speed)
	else:
		# 只有身体完整越过实际地板左缘才向下引流，绝不在门口穿墙或向上托起。
		player.velocity.x = clampf((ExportSettings.crown_flood_drop_center - point.x) * ExportSettings.crown_flood_steer_gain, -ExportSettings.crown_flood_steer_speed, ExportSettings.crown_flood_steer_speed)
		player.velocity.y = maxf(player.velocity.y, move_toward(player.velocity.y, ExportSettings.crown_flood_down_speed, ExportSettings.crown_flood_down_acceleration * delta))


func _clear() -> void:
	_active = false
	_player = null
	_elapsed = 0.0
	_water.hide()
	_audio.stop()


func _on_player_died(player: Node2D) -> void:
	if player == _player:
		_clear()


func _on_player_respawned(_position: Vector2) -> void:
	_clear()


func _on_relic_consumed(relic: StringName) -> void:
	if relic == &"crown":
		_clear()


func _on_save_loaded(_slot: int) -> void:
	_clear()
	var player := get_tree().get_first_node_in_group(&"player") as CharacterBody2D
	if is_instance_valid(player) and player.get("has_sunken_crown") == true:
		var elapsed: float = ExportSettings.crown_flood_fill_duration * ExportSettings.crown_flood_resume_progress
		_start(player, elapsed)
		if _active:
			# 旧档可能保存持冠但未保存挡板消失；恢复挑战时一并修复出口，不补播对白。
			SignalBus.lock1.emit()


func _exit_tree() -> void:
	_active = false
	_player = null
