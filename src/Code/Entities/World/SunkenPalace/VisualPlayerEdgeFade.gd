extends CanvasGroup


func _ready() -> void:
	var fade_material := material as ShaderMaterial
	if fade_material == null:
		return

	var fade_width := maxf(ExportSettings.sunken_scenery_visual_player_fade_width, 0.0)
	var fade_height := maxf(ExportSettings.sunken_scenery_visual_player_fade_height, 0.0)
	fade_material.set_shader_parameter(&"fade_width_pixels", fade_width)
	fade_material.set_shader_parameter(&"fade_height_pixels", fade_height)
	# CanvasGroup 的缓存边距使用节点局部尺寸；visualplayer 本身约缩小到 0.198 倍。
	# 按实际全局缩放反算，否则 240 像素的着色器采样只获得约 49 像素透明缓存，渐变会被截短。
	var global_scale := global_transform.get_scale().abs()
	var minimum_scale := maxf(minf(global_scale.x, global_scale.y), 0.001)
	var required_margin := maxf(fade_width, fade_height) / minimum_scale + 16.0
	fit_margin = maxf(fit_margin, required_margin)
	clear_margin = maxf(clear_margin, required_margin)
