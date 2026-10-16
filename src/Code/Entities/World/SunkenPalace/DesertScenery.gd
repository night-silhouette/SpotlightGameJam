extends Node2D
## 沙漠背景视差滚动（分层拼接）。
## 素材原尺寸 1600x832，采用与 OutwardScenery 一致的正反镜像（flip_h）无缝循环机制：
## 基础单图宽 1600，水平镜像拼合宽 3200，repeat_size = Vector2(3200, 0)。


@export var enabled_bounds_check: bool = true
@export var local_camera_bounds: Vector2 = Vector2(-2000.0, 4500.0)


func _enter_tree() -> void:
	# 覆写 _enter_tree，避免默认 top_level 与 repeat_size 被意外覆盖
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
