@tool
extends Node2D
## 沙漠多景深背景：根节点的编辑器位置直接控制整套背景，运行时仅响应相机 X。


@onready var _coverage_bounds: Control = $CoverageBounds
@onready var _parallax_layers: Array[Parallax2D] = [
	$CoverageBounds/BaseSky,
	$CoverageBounds/SunBokeh,
	$CoverageBounds/MesaRocks,
	$CoverageBounds/RockPillars,
	$CoverageBounds/CactusFar,
	$CoverageBounds/DunesMid,
	$CoverageBounds/DesertSilhouette,
]


func _ready() -> void:
	_sync_layer_offsets()
	_update_layer_visibility()


func _process(_delta: float) -> void:
	_sync_layer_offsets()
	_update_layer_visibility()


func _sync_layer_offsets() -> void:
	# Parallax2D 脱离嵌套 Control 的变换，改由根节点 position 直接提供屏幕偏移。
	# @tool 下拖动 DesertScenery 时，本帧即可在编辑器中看到所有层同步移动。
	var screen_offset := position + _coverage_bounds.position
	for layer in _parallax_layers:
		layer.top_level = true
		layer.scroll_offset = screen_offset


func _update_layer_visibility() -> void:
	if Engine.is_editor_hint():
		for layer in _parallax_layers:
			layer.visible = true
		return
	var palace := get_parent() as Node2D
	if palace == null:
		return
	var viewport_center := get_viewport_rect().size * 0.5
	var camera_world := get_viewport().get_canvas_transform().affine_inverse() * viewport_center
	var camera_local_x := palace.to_local(camera_world).x
	var bounds: Vector2 = ExportSettings.sunken_scenery_camera_bounds
	var in_palace := camera_local_x >= bounds.x and camera_local_x <= bounds.y
	for layer in _parallax_layers:
		layer.visible = in_palace
