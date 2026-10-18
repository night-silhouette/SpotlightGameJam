@tool
extends Node2D
## SunkenPalace 沙漠背景控制器：背景保留视差，直接放在宫殿场景中的前景按世界坐标显示。


@onready var _coverage_bounds: Control = $CoverageBounds
@onready var _parallax_layers: Array[Parallax2D] = [
	$CoverageBounds/BaseSky,
	$CoverageBounds/SunBokeh,
	$CoverageBounds/MesaRocks,
	$CoverageBounds/RockPillars,
	$CoverageBounds/CactusFar,
]

var _foreground_layers: Array[CanvasItem] = []


func _ready() -> void:
	_refresh_foreground_layers()
	_sync_layer_offsets()
	_update_layer_visibility()


func _process(_delta: float) -> void:
	_refresh_foreground_layers()
	_sync_layer_offsets()
	_update_layer_visibility()


func _sync_layer_offsets() -> void:
	# Parallax2D 需要 top_level 计算视差，因此显式把 SunkenPalace 的世界位置
	# 合入偏移。前景是宫殿的普通 Node2D 子节点，不在这里改写其编辑器位置。
	var palace_origin := Vector2.ZERO
	if get_parent() is Node2D:
		palace_origin = (get_parent() as Node2D).global_position
	var authored_offset := position + _coverage_bounds.position
	for layer in _parallax_layers:
		layer.top_level = true
		layer.scroll_offset = authored_offset + palace_origin * layer.scroll_scale


func _refresh_foreground_layers() -> void:
	_foreground_layers.clear()
	var palace := get_parent()
	if palace == null:
		return
	for node_name in [&"DunesMid", &"DesertSilhouette"]:
		var layer := palace.get_node_or_null(NodePath(node_name)) as CanvasItem
		if layer != null:
			_foreground_layers.append(layer)


func _update_layer_visibility() -> void:
	if Engine.is_editor_hint():
		for layer in _all_scenery_layers():
			layer.visible = true
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
	var camera_local_x := palace.to_local(camera_world).x
	var bounds: Vector2 = ExportSettings.sunken_scenery_camera_bounds
	var in_palace := camera_local_x >= bounds.x and camera_local_x <= bounds.y
	for layer in _all_scenery_layers():
		layer.visible = in_palace


func _all_scenery_layers() -> Array[CanvasItem]:
	var result: Array[CanvasItem] = []
	result.assign(_parallax_layers)
	result.append_array(_foreground_layers)
	return result
