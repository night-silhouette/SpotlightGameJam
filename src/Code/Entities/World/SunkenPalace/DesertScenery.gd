extends Node2D
## 沙漠多景深背景：仅响应相机 X，所有层的屏幕 Y 坐标保持固定，并限制在沉没宫殿范围内显示。


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
	# Parallax2D 必须直接在全局画布中计算视差。若继承 CoverageBounds 及场景实例的
	# 位移/缩放，开场时整套背景会被推到屏幕上方，尽管节点仍处于 visible 状态。
	for layer in _parallax_layers:
		layer.top_level = true
		layer.scroll_offset = _coverage_bounds.position + Vector2(0.0, ExportSettings.sunken_scenery_screen_offset_y)
	_update_layer_visibility()


func _process(_delta: float) -> void:
	_update_layer_visibility()


func _update_layer_visibility() -> void:
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
