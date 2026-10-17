extends Node2D
## 沙漠背景视差滚动：各景深层保留独立速度，天空单独纵向镜像衔接。
## 天空素材尺寸 1600x832，由原图和上方纵向镜像图组成 1664 高的循环单元。


@export var enabled_bounds_check: bool = true
@export var local_camera_bounds: Vector2 = Vector2(-2000.0, 4500.0)


func _enter_tree() -> void:
	# top_level 由场景资源负责；不要在运行时覆盖编辑器里拖动后的坐标。
	pass


func _process(_delta: float) -> void:
	if not enabled_bounds_check:
		for layer in get_children():
			if layer is Parallax2D:
				layer.visible = true
		return

	# 视口裁剪保护：保持与沉没宫殿本地边界一致，避免覆盖其他区域
	var camera_world := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
	var phase := get_parent() as Node2D
	if not phase:
		return
	var camera_x: float = phase.to_local(camera_world).x
	var in_level := camera_x >= local_camera_bounds.x and camera_x <= local_camera_bounds.y
	for layer in get_children():
		if layer is Parallax2D:
			layer.visible = in_level
