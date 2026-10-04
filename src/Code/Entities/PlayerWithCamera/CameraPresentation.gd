extends CanvasLayer
## 镜头内部演出层。每次切镜清理上一次 Tween，避免旧字幕或黑幕回调串场。

var _sequence: Tween
@onready var _blur: ColorRect = $Root/Blur
@onready var _curtain: ColorRect = $Root/Curtain
@onready var _mask: ColorRect = $Root/TopMask
@onready var _title: Label = $Root/Title
@onready var _text: Control = $Root/Narration


## 取消当前演出并清空遮罩、标题和字幕。
func Clear() -> void:
	if _sequence and _sequence.is_valid():
		_sequence.kill()
	_blur.hide()
	_curtain.modulate.a = 0.0
	_mask.modulate.a = 0.0
	_title.modulate.a = 0.0
	_text.ShowText("", false)


## 在镜头开始过渡前准备画面；沙漠开场先遮黑，待镜头就位再退幕。
func Prepare(mode: StringName, with_intro: bool) -> void:
	Clear()
	if mode == &"desert" and with_intro:
		_curtain.modulate.a = 1.0
		_blur.show()
		_blur.material.set_shader_parameter("radius", ExportSettings.camera_blur_radius)


## 镜头就位后播放演出。标题和正文由关卡提供，组件不硬编码正式剧情。
func Present(mode: StringName, title: String, narrative: String, with_intro: bool) -> void:
	_sequence = create_tween()
	if mode == &"desert" and with_intro:
		_sequence.tween_property(_curtain, "modulate:a", 0.0, ExportSettings.camera_intro_duration)
		_sequence.parallel().tween_method(_set_blur, ExportSettings.camera_blur_radius, 0.0, ExportSettings.camera_intro_duration)
		_sequence.tween_callback(_blur.hide)
	if mode == &"boat":
		_mask.anchor_bottom = ExportSettings.camera_boat_mask_fraction
		_sequence.tween_property(_mask, "modulate:a", ExportSettings.camera_boat_mask_opacity, ExportSettings.camera_text_fade)
	if not title.is_empty():
		_title.text = title
		_sequence.tween_property(_title, "modulate:a", 1.0, ExportSettings.camera_text_fade)
		_sequence.tween_interval(ExportSettings.camera_title_hold)
		_sequence.tween_property(_title, "modulate:a", 0.0, ExportSettings.camera_text_fade)
	_sequence.tween_callback(_show_narrative.bind(mode, narrative))


func _set_blur(value: float) -> void:
	_blur.material.set_shader_parameter("radius", value)


func _show_narrative(mode: StringName, message: String) -> void:
	var area := Rect2(0.18, 0.18, 0.64, 0.3)
	if mode == &"desert":
		area = Rect2(0.68, 0.13, 0.24, 0.72)
	elif mode == &"boat":
		area = Rect2(0.22, 0.72, 0.56, 0.2)
	_text.anchor_left = area.position.x
	_text.anchor_top = area.position.y
	_text.anchor_right = area.end.x
	_text.anchor_bottom = area.end.y
	_text.ShowText(message, mode == &"desert")
