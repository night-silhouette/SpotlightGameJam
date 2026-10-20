extends Sprite2D
## Camp 的 Sprite2D2 远景控制器：低速跟随镜头，并把移动与绘制限制在 Camp 内。

const CLIP_SHADER: Shader = preload("res://Code/Entities/World/Camp/CampBackgroundClip.gdshader")

var _authored_position: Vector2
var _reference_camera_local: Vector2
var _has_reference: bool = false
var _clip_material: ShaderMaterial


func _ready() -> void:
	_authored_position = position
	_clip_material = ShaderMaterial.new()
	_clip_material.shader = CLIP_SHADER
	material = _clip_material
	_update_clip_bounds()
	SignalBus.PlayerRespawned.connect(_on_player_respawned)
	SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)


func _process(delta: float) -> void:
	var camp := get_parent() as Node2D
	if camp == null:
		return
	var camera_world := _get_camera_world_position()
	var camera_local := camp.to_local(camera_world)
	var bounds: Rect2 = ExportSettings.camp_background_local_bounds.abs()
	var bounded_camera := Vector2(
		clampf(camera_local.x, bounds.position.x, bounds.end.x),
		clampf(camera_local.y, bounds.position.y, bounds.end.y)
	)
	if not _has_reference:
		_reference_camera_local = bounded_camera
		_has_reference = true

	var camera_travel := bounded_camera - _reference_camera_local
	var max_offset: Vector2 = ExportSettings.camp_background_max_offset.abs()
	var target_offset := Vector2(
		clampf(camera_travel.x * ExportSettings.camp_background_follow_x, -max_offset.x, max_offset.x),
		clampf(camera_travel.y * ExportSettings.camp_background_follow_y, -max_offset.y, max_offset.y)
	)
	var target_position := _authored_position + target_offset
	var smoothing_speed: float = maxf(ExportSettings.camp_background_smoothing_speed, 0.0)
	if smoothing_speed <= 0.0:
		position = target_position
	else:
		position = position.lerp(target_position, 1.0 - exp(-smoothing_speed * delta))
	_update_clip_bounds()


func _get_camera_world_position() -> Vector2:
	var active_camera := get_viewport().get_camera_2d()
	if active_camera != null:
		return active_camera.get_screen_center_position()
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	if player != null:
		return player.global_position
	return global_position


func _update_clip_bounds() -> void:
	if _clip_material == null:
		return
	var camp := get_parent() as Node2D
	if camp == null:
		return
	var bounds: Rect2 = ExportSettings.camp_background_local_bounds.abs()
	var first := camp.to_global(bounds.position)
	var second := camp.to_global(Vector2(bounds.end.x, bounds.position.y))
	var third := camp.to_global(bounds.end)
	var fourth := camp.to_global(Vector2(bounds.position.x, bounds.end.y))
	var clip_min := Vector2(
		minf(minf(first.x, second.x), minf(third.x, fourth.x)),
		minf(minf(first.y, second.y), minf(third.y, fourth.y))
	)
	var clip_max := Vector2(
		maxf(maxf(first.x, second.x), maxf(third.x, fourth.x)),
		maxf(maxf(first.y, second.y), maxf(third.y, fourth.y))
	)
	_clip_material.set_shader_parameter(&"clip_min", clip_min)
	_clip_material.set_shader_parameter(&"clip_max", clip_max)


func _reset_reference() -> void:
	position = _authored_position
	_has_reference = false


func _on_player_respawned(_respawn_position: Vector2) -> void:
	_reset_reference()


func _on_save_slot_loaded(_slot_index: int) -> void:
	_reset_reference()
