extends CanvasLayer

const NARRATION: StringName = &"旁白"
const MONOLOGUE: StringName = &"独白"

@onready var _box: PanelContainer = $Root/Box
@onready var _title: Label = $Root/Box/Margin/Content/Title
@onready var _content: Label = $Root/Box/Margin/Content/Text
@onready var _close_button: Button = $Root/Box/Margin/Content/Close


func _ready() -> void:
	_box.hide()
	SignalBus.DialogBox.connect(_on_dialog_box)
	_close_button.pressed.connect(_on_close_pressed)


func _on_dialog_box(dialog_type: StringName, content: String) -> void:
	if dialog_type != NARRATION and dialog_type != MONOLOGUE:
		return
	_title.text = String(dialog_type)
	_title.add_theme_color_override("font_color", Color(0.96, 0.87, 0.65) if dialog_type == NARRATION else Color(0.72, 0.86, 1.0))
	_content.text = content
	_box.show()


func _on_close_pressed() -> void:
	_box.hide()
