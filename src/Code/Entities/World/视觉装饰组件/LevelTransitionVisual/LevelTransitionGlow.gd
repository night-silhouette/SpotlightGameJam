@tool
extends ColorRect

@export_category("Reveal Trigger")
## 需要等待其消失完成后才显示本光照的挡板；留空时保持常显。
@export_node_path("Node2D") var reveal_after_blocker_path: NodePath

var _reveal_blocker: Node2D


func _ready() -> void:
	_apply_settings()
	if Engine.is_editor_hint() or reveal_after_blocker_path.is_empty():
		return
	_reveal_blocker = get_node_or_null(reveal_after_blocker_path) as Node2D
	if not is_instance_valid(_reveal_blocker):
		push_warning("LevelTransitionGlow could not find reveal blocker: %s" % reveal_after_blocker_path)
		hide()
		return
	hide()
	if not SignalBus.BlockerVanished.is_connected(_on_blocker_vanished):
		SignalBus.BlockerVanished.connect(_on_blocker_vanished)
	if not SignalBus.SaveSlotLoaded.is_connected(_on_save_slot_loaded):
		SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)
	_sync_reveal_state()


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


func _on_blocker_vanished(blocker: Node2D) -> void:
	if blocker == _reveal_blocker:
		show()


func _on_save_slot_loaded(_slot_index: int) -> void:
	call_deferred(&"_sync_reveal_state")


func _sync_reveal_state() -> void:
	if not is_instance_valid(_reveal_blocker):
		hide()
		return
	visible = _reveal_blocker.has_method("IsVanished") and bool(_reveal_blocker.call("IsVanished"))
