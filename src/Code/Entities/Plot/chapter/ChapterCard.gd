extends Control

signal Finished

const DISPLAY_DURATION := 4.0

@export var act_text: String = "第一幕"
@export var chapter_text: String = "纺织"
@export var auto_play: bool = true
@export var fade_duration: float = 0.7

@onready var _act_label: Label = $Act
@onready var _chapter_label: Label = $Title

var _tween: Tween

func _ready() -> void:
	_act_label.text = act_text
	_chapter_label.text = chapter_text
	resized.connect(queue_redraw)
	if auto_play:
		Play()
	else:
		hide()

func Play() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_act_label.text = act_text
	_chapter_label.text = chapter_text
	show()
	modulate.a = 0.0
	var transition_duration: float = minf(maxf(fade_duration, 0.0), DISPLAY_DURATION / 2.0)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, transition_duration)
	_tween.tween_interval(DISPLAY_DURATION - transition_duration * 2.0)
	_tween.tween_property(self, "modulate:a", 0.0, transition_duration)
	_tween.tween_callback(_finish)

func ShowChapter(act: String, heading: String) -> void:
	act_text = act
	chapter_text = heading
	Play()

func _finish() -> void:
	hide()
	Finished.emit()

func _draw() -> void:
	var center := size * 0.5 + Vector2(0, -20)
	var white := Color(0.92, 0.92, 0.92)
	for side in [-1.0, 1.0]:
		for i in range(32):
			var from_x := 18.0 + float(i) * 2.7
			var opacity := 0.95 * (1.0 - float(i) / 32.0)
			var start := center + Vector2(side * from_x, 0)
			var end := center + Vector2(side * (from_x + 2.7), 0)
			draw_line(start, end, Color(white, opacity), 1.0, true)
		draw_line(center + Vector2(side * 15, 0), center + Vector2(side * 24, 2), white, 1.0, true)
	draw_arc(center, 7, 0, TAU, 32, white, 1.5, true)
	draw_line(center + Vector2(0, -5), center + Vector2(0, 5), white, 1.0, true)
	draw_line(center + Vector2(-3, -3), center + Vector2(3, -1), white, 1.0, true)
	draw_line(center + Vector2(-3, 1), center + Vector2(3, 3), white, 1.0, true)
