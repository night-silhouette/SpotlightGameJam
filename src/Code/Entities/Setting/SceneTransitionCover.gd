extends CanvasLayer

func _input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()
