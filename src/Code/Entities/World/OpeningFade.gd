extends CanvasLayer

@onready var _black: ColorRect = $Black

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _frame in range(ExportSettings.world_opening_fade_ready_frames):
		await get_tree().process_frame
	var cover := get_tree().get_first_node_in_group(&"scene_transition_cover")
	if cover:
		await cover.tree_exited
	var tween := create_tween()
	tween.tween_property(_black, "color:a", 0.0, ExportSettings.world_opening_fade_duration)
	tween.tween_callback(queue_free)
