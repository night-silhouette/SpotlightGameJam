extends "res://Code/Entities/ParallaxScenery/ParallaxScenery.gd"
## 与返程共用原尺寸、循环宽度、滚动基准和前后景速度，仅替换 OutPath 原画。


func _enter_tree() -> void:
	# OutPath 背景素材原生宽度均为 5920，通过正反镜像（flip_h）双图拼接构成 11840 完美对称无缝循环。
	# 覆写父类 _enter_tree，防止其将 repeat_size 强制回写为 4831，并避免 top_level=true 破坏阶段层级。
	pass


func _process(_delta: float) -> void:
	# 去程默认开启，限制显示范围以免完整世界中覆盖其他关卡。
	var camera_world := get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
	var phase := get_parent() as Node2D
	var camera_x: float = phase.to_local(camera_world).x
	var bounds: Vector2 = ExportSettings.outward_scenery_camera_bounds
	var in_level := camera_x >= bounds.x and camera_x <= bounds.y
	for layer in get_children():
		if layer is Parallax2D:
			layer.visible = in_level
