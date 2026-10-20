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
	var authored_offset := position + _coverage_bounds.position
	for layer in _parallax_layers:
		layer.top_level = true
		# Parallax2D 的 Y=0 会把图层贴住屏幕，等同于跟随镜头升降；Y=1 才是固定世界高度。
		layer.scroll_scale.y = ExportSettings.sunken_scenery_vertical_scroll_scale
		layer.scroll_offset = authored_offset + palace_origin * layer.scroll_scale


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
	var y_bounds: Vector2 = ExportSettings.sunken_scenery_camera_y_bounds
	var in_x_bounds := camera_local.x >= bounds.x and camera_local.x <= bounds.y
	var in_y_bounds := camera_local.y >= y_bounds.x and camera_local.y <= y_bounds.y
	var in_palace := in_x_bounds and in_y_bounds
	for layer in _scenery_layers:
		var authored_visible: bool = _authored_visibility.get(layer.get_instance_id(), true)
		layer.visible = authored_visible and in_palace
