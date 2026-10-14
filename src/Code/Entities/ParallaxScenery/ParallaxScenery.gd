extends Node2D
## 素材保持原图位置和 1:1 比例，统一循环周期并局部修正装饰接头。
## 运行参数由 ExportSettings 的 Parallax Scenery 分组统一管理，重新运行后生效。


func _enter_tree() -> void:
	var period := clampf(ExportSettings.parallax_repeat_width, 1.0, $Sky/SkyBase.texture.get_width())
	_configure_layer($Sky, ExportSettings.parallax_far_scroll_x, period)
	_configure_layer($FarBackground, ExportSettings.parallax_far_scroll_x, period)
	_configure_layer($NearBackground, ExportSettings.parallax_near_scroll_x, period)
	_configure_layer($ForegroundLoop, ExportSettings.parallax_foreground_scroll_x, period)
	_configure_sprite_region($ForegroundLoop/Foreground/ForegroundSprite, period)
	_configure_seam($ForegroundLoop/GreenDecoration, period,
		ExportSettings.parallax_green_seam_blend_width, ExportSettings.parallax_green_seam_y_offset)
	_configure_seam($NearBackground/Sprite2D, period,
		ExportSettings.parallax_near_seam_blend_width, ExportSettings.parallax_near_seam_y_offset)


func _configure_seam(sprite: Sprite2D, period: float, transition_width: float, y_offset: float) -> void:
	# 每个场景实例各自持有材质，避免调试时修改其他实例的材质参数。
	sprite.material = sprite.material.duplicate()
	var seam_material: ShaderMaterial = sprite.material
	seam_material.set_shader_parameter("repeat_width", period)
	seam_material.set_shader_parameter("blend_width", clampf(transition_width, 0.0, period))
	seam_material.set_shader_parameter("seam_y_offset", y_offset)


func _configure_layer(layer: Parallax2D, horizontal_speed: float, period: float) -> void:
	# Parallax2D 按世界相机位置计算循环；不要再叠加关卡父节点的位移。
	# 仅脱离变换继承，仍由 ReturnPhase 控制显示与处理状态。
	layer.top_level = true
	layer.scroll_scale = Vector2(horizontal_speed, 1.0)
	layer.repeat_size = Vector2(period, 0.0)
	# 将场景摆放位置纳入滚动基准，保留原画高度及各层在参考镜头处的对齐。
	layer.scroll_offset = Vector2(
		global_position.x * horizontal_speed
			+ (horizontal_speed - 1.0) * ExportSettings.parallax_reference_view_left,
		global_position.y
	)
	for child in layer.get_children():
		if child is Sprite2D:
			_configure_sprite_region(child, period)


func _configure_sprite_region(sprite: Sprite2D, period: float) -> void:
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0.0, 0.0, period, sprite.texture.get_height())
	sprite.region_filter_clip_enabled = true
