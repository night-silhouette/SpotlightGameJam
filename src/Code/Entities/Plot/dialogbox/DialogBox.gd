extends CanvasLayer

signal Closed
signal Finished

const NARRATION: StringName = &"旁白"
const MONOLOGUE: StringName = &"独白"
const SETTINGS_ART = preload("res://Art/New/ui/设置底图.PNG")
# 设置底图右上角的镂空箭头，保留原画轮廓及抗锯齿。
const ARROW_REGION := Rect2i(816, 127, 62, 38)

@onready var _box: AspectRatioContainer = $Root/Box
@onready var _title: Label = $Root/Box/Margin/Content/Title
@onready var _content: Label = $Root/Box/Margin/Content/Text
@onready var _close_button: TextureButton = $Root/Box/Margin/Close
@onready var _narration: AspectRatioContainer = $Root/NarrationPanel
@onready var _narration_text: Label = $Root/NarrationPanel/Margin/Content/Text
@onready var _narration_close: TextureButton = $Root/NarrationPanel/Margin/Close
@onready var _auto_close_timer: Timer = $AutoCloseTimer

var _pending: Array[Dictionary] = []
var _reveal_elapsed: float = 0.0

func _ready() -> void:
	_box.hide()
	_narration.hide()
	SignalBus.DialogBox.connect(_on_dialog_box)
	_close_button.pressed.connect(_on_close_pressed)
	_narration_close.pressed.connect(_on_close_pressed)
	_auto_close_timer.timeout.connect(_on_close_pressed)
	set_process(false)
	_setup_continue_arrows()

func _process(delta: float) -> void:
	_reveal_elapsed += delta
	_content.visible_characters = mini(int(_reveal_elapsed * ExportSettings.dialog_monologue_chars_per_second), _content.get_total_character_count())
	if _content.visible_characters >= _content.get_total_character_count():
		_content.visible_characters = -1
		set_process(false)
		_auto_close_timer.start(1.0)

func _setup_continue_arrows() -> void:
	var image: Image = SETTINGS_ART.get_image().get_region(ARROW_REGION)
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			image.set_pixel(x, y, Color(1, 1, 1, 1.0 - image.get_pixel(x, y).a))
	image.flip_x()
	var texture := ImageTexture.create_from_image(image)
	for button: TextureButton in [_close_button, _narration_close]:
		var arrow: TextureRect = button.get_node("Hint")
		arrow.texture = texture
		button.mouse_entered.connect(func(): arrow.modulate = ExportSettings.dialog_arrow_hover_color)
		button.mouse_exited.connect(func(): arrow.modulate = Color.WHITE)
		button.visibility_changed.connect(func(): arrow.modulate = Color.WHITE)

func _input(event: InputEvent) -> void:
	if IsOpen() and event.is_action_pressed("skip_story") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if _box.visible and is_processing():
			_content.visible_characters = -1
			set_process(false)
			_auto_close_timer.start(1.0)
		else:
			_on_close_pressed()

func IsOpen() -> bool:
	return _box.visible or _narration.visible

func Dismiss() -> void:
	_auto_close_timer.stop()
	set_process(false)
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
		_auto_close_timer.start()
	else:
		_title.text = String(dialog_type)
		_title.add_theme_color_override("font_color", Color(0.72, 0.86, 1.0))
		_content.text = content
		_content.visible_characters = 0
		_reveal_elapsed = 0.0
		_box.show()
		if _content.get_total_character_count() == 0:
			_auto_close_timer.start(1.0)
		else:
			set_process(true)

func _on_close_pressed() -> void:
	if not IsOpen():
		return
	_auto_close_timer.stop()
	set_process(false)
	_box.hide()
	_narration.hide()
	if _pending.is_empty():
		Finished.emit()
	Closed.emit()
	if not IsOpen() and not _pending.is_empty():
		var next: Dictionary = _pending.pop_front()
		_show_dialog(next["type"], next["content"])
