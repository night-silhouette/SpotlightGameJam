@tool
extends ColorRect


func _ready() -> void:
	_apply_settings()


func _apply_settings() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("glow_color", ExportSettings.level_transition_visual_glow_color)
	shader_material.set_shader_parameter("core_opacity", ExportSettings.level_transition_visual_glow_core_opacity)
	shader_material.set_shader_parameter("halo_opacity", ExportSettings.level_transition_visual_glow_halo_opacity)
	shader_material.set_shader_parameter("edge_softness", ExportSettings.level_transition_visual_glow_edge_softness)
	shader_material.set_shader_parameter("pulse_strength", ExportSettings.level_transition_visual_glow_pulse_strength)
	shader_material.set_shader_parameter("pulse_speed", ExportSettings.level_transition_visual_glow_pulse_speed)
