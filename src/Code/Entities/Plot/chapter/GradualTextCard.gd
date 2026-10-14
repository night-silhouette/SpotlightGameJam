extends Control

signal Finished

@export_multiline var content: String = ""
@export_range(0.1, 60.0, 0.1, "or_greater") var display_duration: float = 5.0
@export var auto_play: bool = true

@onready var _label: Label = $Text

var _tween: Tween

func _ready() -> void:
	if auto_play:
		Play()
	else:
		hide()

func Play() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_label.text = content
	_label.visible_characters = 0
	show()
	var duration := maxf(display_duration, 0.1)
	_tween = create_tween()
	_tween.tween_property(_label, "visible_characters", _label.get_total_character_count(), duration * 0.7)
	_tween.tween_interval(duration * 0.3)
	_tween.tween_callback(_finish)

func _finish() -> void:
	hide()
	Finished.emit()
