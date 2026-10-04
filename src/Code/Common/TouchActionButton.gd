extends Control
class_name TouchActionButton

## =============================================================================
## TouchActionButton.gd - 移动端虚拟触控动作按钮
## 专为移动端触屏设计的半透明圆形动作按钮，支持按下、抬起并向 Godot Input 发送指定 action 事件
## =============================================================================

## 绑定的输入动作名（如 "jump", "dash"）
@export var action_name: String = ""
## 按钮显示的文本提示
@export var button_text: String = ""
## 按钮基础半径（像素）
@export var button_radius: float = 40.0
## 按钮底色
@export var bg_color: Color = Color(0.12, 0.16, 0.22, 0.6)
## 按下时的底色高亮
@export var pressed_color: Color = Color(0.25, 0.7, 1.0, 0.8)
## 边框颜色
@export var border_color: Color = Color(0.8, 0.9, 1.0, 0.8)
## 字体颜色
@export var text_color: Color = Color(1.0, 1.0, 1.0, 0.95)

var is_pressed: bool = false
var touch_index: int = -1

## 设置按钮半径大小并自动更新尺寸与重绘
func SetButtonRadius(radius: float) -> void:
	button_radius = max(10.0, radius)
	custom_minimum_size = Vector2(button_radius * 2, button_radius * 2)
	size = custom_minimum_size
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(button_radius * 2, button_radius * 2)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if touch.pressed:
			if not is_pressed and _is_point_inside(touch.position):
				touch_index = touch.index
				_set_pressed_state(true)
		else:
			if touch.index == touch_index:
				touch_index = -1
				_set_pressed_state(false)
		accept_event()
	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		if drag.index == touch_index:
			# 如果手指滑出了按钮范围过远，可视为松开；如果在内部则保持按下
			var inside = _is_point_inside(drag.position)
			if inside != is_pressed:
				_set_pressed_state(inside)
		accept_event()
	elif event is InputEventMouseButton:
		var mouse = event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				if not is_pressed and _is_point_inside(mouse.position):
					touch_index = -99
					_set_pressed_state(true)
			else:
				if touch_index == -99:
					touch_index = -1
					_set_pressed_state(false)
		accept_event()

func _is_point_inside(pos: Vector2) -> bool:
	var center = size * 0.5
	return pos.distance_to(center) <= button_radius * 1.25

func _set_pressed_state(pressed: bool) -> void:
	if is_pressed == pressed:
		return
	is_pressed = pressed
	queue_redraw()

	if action_name != "":
		if pressed:
			Input.action_press(action_name)
		else:
			Input.action_release(action_name)

func _draw() -> void:
	var center = size * 0.5
	var draw_col = pressed_color if is_pressed else bg_color
	# 绘制圆形背景
	draw_circle(center, button_radius, draw_col)
	# 绘制外边框
	draw_arc(center, button_radius, 0.0, TAU, 32, border_color, 2.0, true)

	# 绘制内部文字
	if button_text != "":
		var font = ThemeDB.fallback_font
		var font_size = int(button_radius * 0.55)
		var text_sz = font.get_string_size(button_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = center + Vector2(-text_sz.x * 0.5, font_size * 0.35)
		draw_string(font, text_pos, button_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_DISABLED:
		if not is_visible_in_tree() and is_pressed:
			_set_pressed_state(false)
			touch_index = -1
