@tool
extends Node2D
## SunkenPalace 沙漠景物控制器：同步视差背景偏移，并按宫殿镜头区域统一显隐现存图层。


@onready var _coverage_bounds: Control = $CoverageBounds
const DUNES_MID_PATH: NodePath = ^"CoverageBounds/DunesMid"
const LAYER_PATHS: Array[NodePath] = [
	^"CoverageBounds/BaseSky",
	^"CoverageBounds/SunBokeh",
	^"CoverageBounds/MesaRocks",
	^"CoverageBounds/RockPillars",
	^"CoverageBounds/CactusFar",
	DUNES_MID_PATH,
	^"DesertSilhouette",
]

var _parallax_layers: Array[Parallax2D] = []
var _scenery_layers: Array[CanvasItem] = []
var _authored_visibility: Dictionary[int, bool] = {}
var _dunes_mid: Parallax2D


func _ready() -> void:
	_refresh_layers()
	_sync_layer_offsets()
	_update_layer_visibility()


func _process(_delta: float) -> void:
	_refresh_layers()
	_sync_layer_offsets()
	_update_layer_visibility()


func _refresh_layers() -> void:
	_parallax_layers.clear()
	_scenery_layers.clear()
	_dunes_mid = get_node_or_null(DUNES_MID_PATH) as Parallax2D
	for layer_path in LAYER_PATHS:
		var layer := get_node_or_null(layer_path) as CanvasItem
		if layer == null:
			continue
		_scenery_layers.append(layer)
		if layer is Parallax2D:
			_parallax_layers.append(layer as Parallax2D)
		var instance_id := layer.get_instance_id()
		if Engine.is_editor_hint() or not _authored_visibility.has(instance_id):
			_authored_visibility[instance_id] = layer.visible


func _sync_layer_offsets() -> void:
	# Parallax2D 需要 top_level 计算视差，因此显式把 SunkenPalace 的世界位置
	# 合入偏移。前景是本场景的普通 Node2D 子节点，不在这里改写其编辑器位置或可见性。
	var palace_origin := Vector2.ZERO
	var palace := get_parent() as Node2D
	if palace != null:
		palace_origin = palace.global_position
	var dunes_vertical_release := _get_dunes_vertical_release(palace)
	var authored_offset := position + _coverage_bounds.position
	for layer in _parallax_layers:
		layer.top_level = true
		layer.scroll_offset = authored_offset + palace_origin * layer.scroll_scale
		if layer == _dunes_mid:
			layer.scroll_offset.y += dunes_vertical_release


func _get_dunes_vertical_release(palace: Node2D) -> float:
	if palace == null:
		return 0.0
	var active_camera := get_viewport().get_camera_2d()
	if active_camera == null:
		return 0.0
	var camera_local_y := palace.to_local(active_camera.get_screen_center_position()).y
	var upward_height := maxf(-camera_local_y, 0.0)
	var stop_follow_height := maxf(ExportSettings.sunken_scenery_dunes_stop_follow_height, 0.0)
	var follow_ratio := clampf(ExportSettings.sunken_scenery_dunes_vertical_follow_ratio, 0.0, 1.0)
	var release_before_limit := minf(upward_height, stop_follow_height) * (1.0 - follow_ratio)
	var release_after_limit := maxf(upward_height - stop_follow_height, 0.0)
	return release_before_limit + release_after_limit


func _update_layer_visibility() -> void:
	# 编辑器里不强改可见性，保留策划对根节点或单层 visible 的选择。
	if Engine.is_editor_hint():
		return
	var palace := get_parent() as Node2D
	if palace == null:
		return
	var active_camera := get_viewport().get_camera_2d()
	var camera_world: Vector2
	if active_camera != null:
		camera_world = active_camera.get_screen_center_position()
	else:
		var viewport_center := get_viewport_rect().size * 0.5
		camera_world = get_viewport().get_canvas_transform().affine_inverse() * viewport_center
	var camera_local := palace.to_local(camera_world)
	var bounds: Vector2 = ExportSettings.sunken_scenery_camera_bounds
	var in_x_bounds := camera_local.x >= bounds.x and camera_local.x <= bounds.y
	var in_y_distance := absf(camera_local.y) <= ExportSettings.sunken_scenery_camera_y_distance
	var in_palace := in_x_bounds and in_y_distance
	for layer in _scenery_layers:
		var authored_visible: bool = _authored_visibility.get(layer.get_instance_id(), true)
		layer.visible = authored_visible and in_palace
