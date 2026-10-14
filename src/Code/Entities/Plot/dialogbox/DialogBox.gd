extends CanvasLayer

signal Closed
signal Finished

const NARRATION: StringName = &"旁白"
const MONOLOGUE: StringName = &"独白"

@onready var _box: PanelContainer = $Root/Box
@onready var _title: Label = $Root/Box/Margin/Content/Title
@onready var _content: Label = $Root/Box/Margin/Content/Text
@onready var _close_button: Button = $Root/Box/Margin/Content/Close
@onready var _narration: PanelContainer = $Root/NarrationPanel
@onready var _narration_text: Label = $Root/NarrationPanel/Margin/Content/Text
@onready var _narration_close: Button = $Root/NarrationPanel/Margin/Content/Close

var _pending: Array[Dictionary] = []

func _ready() -> void:
	_box.hide()
	_narration.hide()
	SignalBus.DialogBox.connect(_on_dialog_box)
	_close_button.pressed.connect(_on_close_pressed)
	_narration_close.pressed.connect(_on_close_pressed)

func IsOpen() -> bool:
	return _box.visible or _narration.visible

func Dismiss() -> void:
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

func _on_close_pressed() -> void:
	_box.hide()
	_narration.hide()
	if _pending.is_empty():
		Finished.emit()
	Closed.emit()
	if not IsOpen() and not _pending.is_empty():
		var next: Dictionary = _pending.pop_front()
		_show_dialog(next["type"], next["content"])
