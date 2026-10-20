extends Node
## 正式 World 的营地／第二关入口双向视觉衔接；按玩家所在侧局部隐藏另一侧砖块，不改碰撞。

const CLIP_SHADER: Shader = preload("res://Code/Entities/World/DepthsLibrary/Level2/Scenery/EntryOcclusion/EntryOcclusion.gdshader")

@export_node_path("TileMapLayer") var upper_terrain_path: NodePath
@export_node_path("Node2D") var entry_background_path: NodePath
@export_node_path("Node2D") var boundary_path: NodePath
@export var lower_terrain_paths: Array[NodePath] = []

var _terrain: TileMapLayer
var _background: Node2D
var _boundary: Node2D
var _player: Node2D
var _original_material: Material
var _clip: ShaderMaterial
var _lower_targets: Array[Dictionary] = []
var _below := false
var _initialized := false
var _amount := 0.0
var _previous_player_position := Vector2.ZERO

func _ready() -> void:
	_terrain = get_node_or_null(upper_terrain_path) as TileMapLayer
	_background = get_node_or_null(entry_background_path) as Node2D
	_boundary = get_node_or_null(boundary_path) as Node2D
	if _terrain == null or _background == null or _boundary == null:
		push_warning("EntryOcclusion：入口背景、黄砖或镜头边界缺失，保持原画面。")
		set_process(false)
		return
	_original_material = _terrain.material
	# 不覆盖后来添加的自定义效果；当前营地 TileMapLayer3 无自定义材质。
	if _original_material != null or _terrain.use_parent_material:
		push_warning("EntryOcclusion：上层地形已有材质，保持原材质。")
		set_process(false)
		return
	_clip = ShaderMaterial.new()
	_clip.shader = CLIP_SHADER
	for path in lower_terrain_paths:
		var item := get_node_or_null(path) as CanvasItem
		if item == null:
			continue
		if item.material != null or item.use_parent_material:
			push_warning("EntryOcclusion：下层地形已有材质，保持原材质：" + str(path))
			continue
		var material := ShaderMaterial.new()
		material.shader = CLIP_SHADER
		_lower_targets.append({"node": item, "original": item.material, "clip": material})
	_process(0.0)

func _process(delta: float) -> void:
	if not is_instance_valid(_terrain) or _clip == null:
		return
	if not ExportSettings.level2_entry_occlusion_enabled:
		_restore_material()
		_initialized = false
		return
	if not is_instance_valid(_background) or not is_instance_valid(_boundary):
		_restore_material()
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group(&"player") as Node2D
		_initialized = false
	if _player == null:
		_restore_material()
		return
	var coverage: Rect2 = _background.get_meta("coverage", Rect2())
	if not coverage.has_area():
		_restore_material()
		return
	var bounds := _background.global_transform * coverage
	var border := _boundary.global_position.y
	var hysteresis := maxf(ExportSettings.level2_entry_occlusion_hysteresis, 0.0)
	var snap := not _initialized or _player.global_position.distance_to(_previous_player_position) > ExportSettings.level2_entry_occlusion_snap_distance
	if snap:
		_below = _player.global_position.y >= border
	elif _player.global_position.y > border + hysteresis:
		_below = true
	elif _player.global_position.y < border - hysteresis:
		_below = false
	var target := 1.0 if _below else 0.0
	var duration := maxf(ExportSettings.level2_entry_occlusion_fade_duration, 0.0)
	_amount = target if snap or duration <= 0.0 else move_toward(_amount, target, delta / duration)
	_clip.set_shader_parameter("entry_bounds", Vector4(bounds.position.x, bounds.position.y, bounds.end.x, bounds.end.y))
	_clip.set_shader_parameter("conceal_amount", _amount)
	_terrain.material = _clip
	# 蓝砖包括入口背景外侧的厚墙，需留覆盖余量；不隐藏整张第二关地图。
	var lower_bounds := bounds.grow(maxf(ExportSettings.level2_entry_occlusion_lower_margin, 0.0))
	for entry in _lower_targets:
		var item := entry["node"] as CanvasItem
		if not is_instance_valid(item):
			continue
		var material := entry["clip"] as ShaderMaterial
		material.set_shader_parameter("entry_bounds", Vector4(lower_bounds.position.x, lower_bounds.position.y, lower_bounds.end.x, lower_bounds.end.y))
		material.set_shader_parameter("conceal_amount", 1.0 - _amount)
		item.material = material
	_initialized = true
	_previous_player_position = _player.global_position

func _exit_tree() -> void:
	_restore_material()

func _restore_material() -> void:
	if is_instance_valid(_terrain) and _terrain.material == _clip:
		_terrain.material = _original_material
	for entry in _lower_targets:
		var item := entry["node"] as CanvasItem
		if is_instance_valid(item) and item.material == entry["clip"]:
			item.material = entry["original"]
