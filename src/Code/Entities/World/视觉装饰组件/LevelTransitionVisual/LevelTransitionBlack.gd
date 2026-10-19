@tool
extends ColorRect


func _ready() -> void:
	_apply_settings()


func _apply_settings() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("mist_color", ExportSettings.level_transition_visual_black_color)
	shader_material.set_shader_parameter("opacity", ExportSettings.level_transition_visual_black_opacity)
	shader_material.set_shader_parameter("edge_softness", ExportSettings.level_transition_visual_black_edge_softness)
	shader_material.set_shader_parameter("fog_amount", ExportSettings.level_transition_visual_black_fog_amount)
	shader_material.set_shader_parameter("fog_scale", ExportSettings.level_transition_visual_black_fog_scale)
	shader_material.set_shader_parameter("fog_speed", ExportSettings.level_transition_visual_black_fog_speed)
