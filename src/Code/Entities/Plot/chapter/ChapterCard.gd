extends Control

signal Finished

const DISPLAY_DURATION := 4.0
const SETTINGS_SKIN = preload("res://Code/Entities/Setting/SettingsSkin.gd")

@export var act_text: String = "第一幕"
@export var chapter_text: String = "纺织"
@export var subtitle_text: String = ""
@export var auto_play: bool = true
@export var fade_duration: float = 0.7

@onready var _act_label: Label = $Layout/Act
@onready var _chapter_label: Label = $Layout/Title
@onready var _subtitle_label: Label = $Layout/Subtitle
@onready var _decoration: TextureRect = $Layout/Decoration

var _tween: Tween

func _ready() -> void:
	_act_label.text = act_text
	_chapter_label.text = chapter_text
	_subtitle_label.text = subtitle_text
	_subtitle_label.visible = not subtitle_text.is_empty()
	_act_label.add_theme_color_override("font_color", SETTINGS_SKIN.PAPER)
	_chapter_label.add_theme_color_override("font_color", SETTINGS_SKIN.ACCENT)
	_subtitle_label.add_theme_color_override("font_color", SETTINGS_SKIN.PAPER)
	_decoration.material.set_shader_parameter("paper_color", SETTINGS_SKIN.PAPER)
	if auto_play:
		Play()
	else:
		hide()

## 播放当前章节标题，无需参数；重复调用会重新开始淡入淡出。
func Play() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_act_label.text = act_text
	_chapter_label.text = chapter_text
	_subtitle_label.text = subtitle_text
	_subtitle_label.visible = not subtitle_text.is_empty()
	show()
	modulate.a = 0.0
	var transition_duration: float = minf(maxf(fade_duration, 0.0), DISPLAY_DURATION / 2.0)
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, transition_duration)
	_tween.tween_interval(DISPLAY_DURATION - transition_duration * 2.0)
	_tween.tween_property(self, "modulate:a", 0.0, transition_duration)
	_tween.tween_callback(_finish)

## 设置并播放章节标题；act 为幕名，heading 为章节名，均传入展示文本。
func ShowChapter(act: String, heading: String) -> void:
	act_text = act
	chapter_text = heading
	Play()

func _finish() -> void:
	hide()
	Finished.emit()
