extends "res://Code/Entities/ParallaxScenery/ParallaxScenery.gd"
## 返程视差层只在第三关横向范围内显示，避免 top_level 图层泄漏到其他关卡。


func _process(_delta: float) -> void:
	var camera_world := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
	var phase := get_parent() as Node2D
	if phase == null:
		return
	var camera_x: float = phase.to_local(camera_world).x
	var bounds: Vector2 = ExportSettings.return_scenery_camera_bounds
	var in_level := camera_x >= bounds.x and camera_x <= bounds.y
	for layer in get_children():
		if layer is Parallax2D:
			layer.visible = in_level
