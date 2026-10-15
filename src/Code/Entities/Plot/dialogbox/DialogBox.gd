extends CanvasLayer

signal Closed
signal Finished

const NARRATION: StringName = &"旁白"
const MONOLOGUE: StringName = &"独白"

@onready var _box: AspectRatioContainer = $Root/Box
@onready var _title: Label = $Root/Box/Margin/Content/Title
@onready var _content: Label = $Root/Box/Margin/Content/Text
@onready var _close_button: TextureButton = $Root/Box/Margin/Close
@onready var _narration: AspectRatioContainer = $Root/NarrationPanel
@onready var _narration_text: Label = $Root/NarrationPanel/Margin/Content/Text
@onready var _narration_close: TextureButton = $Root/NarrationPanel/Margin/Close
@onready var _auto_close_timer: Timer = $AutoCloseTimer

var _pending: Array[Dictionary] = []

func _ready() -> void:
	_box.hide()
	_narration.hide()
	SignalBus.DialogBox.connect(_on_dialog_box)
	_close_button.pressed.connect(_on_close_pressed)
	_narration_close.pressed.connect(_on_close_pressed)
	_auto_close_timer.timeout.connect(_on_close_pressed)

func _input(event: InputEvent) -> void:
	if IsOpen() and event.is_action_pressed("skip_story") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_on_close_pressed()

func IsOpen() -> bool:
	return _box.visible or _narration.visible

func Dismiss() -> void:
	_auto_close_timer.stop()
	_pending.clear()
	_box.hide()
	_narration.hide()
	Finished.emit()

func _on_dialog_box(dialog_type: StringName, content: String) -> void:
	if dialog_type != NARRATION and dialog_type != MONOLOGUE:
		return
	if IsOpen():
		_pending.append({"type": dialog_type, "content": content})
		return
	_show_dialog(dialog_type, content)

func _show_dialog(dialog_type: StringName, content: String) -> void:
	if dialog_type == NARRATION:
		_narration_text.text = content
		_narration.show()
	else:
		_title.text = String(dialog_type)
		_title.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0))
		_content.text = content
		_box.show()
	_auto_close_timer.start()

func _on_close_pressed() -> void:
	if not IsOpen():
		return
	_auto_close_timer.stop()
	_box.hide()
	_narration.hide()
	if _pending.is_empty():
		Finished.emit()
	Closed.emit()
	if not IsOpen() and not _pending.is_empty():
		var next: Dictionary = _pending.pop_front()
		_show_dialog(next["type"], next["content"])
