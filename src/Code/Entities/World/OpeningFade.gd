extends CanvasLayer

@onready var _black: ColorRect = $Black

func _ready() -> void:
	for _frame in range(ExportSettings.world_opening_fade_ready_frames):
		await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_black, "color:a", 0.0, ExportSettings.world_opening_fade_duration)
	tween.tween_callback(queue_free)
