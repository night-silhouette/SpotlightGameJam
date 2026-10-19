extends CanvasGroup


func _ready() -> void:
	var fade_material := material as ShaderMaterial
	if fade_material == null:
		return

	var fade_width := maxf(ExportSettings.sunken_scenery_visual_player_fade_width, 0.0)
	var fade_height := maxf(ExportSettings.sunken_scenery_visual_player_fade_height, 0.0)
	fade_material.set_shader_parameter(&"fade_width_pixels", fade_width)
	fade_material.set_shader_parameter(&"fade_height_pixels", fade_height)
	var required_margin := maxf(fade_width, fade_height) + 8.0
	fit_margin = maxf(fit_margin, required_margin)
	clear_margin = maxf(clear_margin, required_margin)
