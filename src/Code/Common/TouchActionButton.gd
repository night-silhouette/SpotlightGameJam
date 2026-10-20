extends Control
class_name TouchActionButton

signal pressed_once

## =============================================================================
## TouchActionButton.gd - 移动端虚拟触控动作按钮
## 专为移动端触屏设计的半透明圆形动作按钮，支持按下、抬起并向 Godot Input 发送指定 action 事件
## =============================================================================

## 绑定的输入动作名（如 "jump", "dash"）
@export var action_name: String = ""
## 按钮显示的文本提示
@export var button_text: String = ""
## 可选按钮图标；设置后替代圆形背景、边框和文字
@export var button_icon: Texture2D:
	set(value):
		button_icon = value
		queue_redraw()
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
	button_radius = maxf(0.0, radius)
	custom_minimum_size = Vector2(button_radius * 2, button_radius * 2)
	size = custom_minimum_size
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(button_radius * 2, button_radius * 2)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not can_process():
		return
	if event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if touch.canceled or not touch.pressed:
			if touch.index != touch_index:
				return
			touch_index = -1
			_set_pressed_state(false)
		elif touch_index == -1 and _is_point_inside(_local_position(touch.position)):
			touch_index = touch.index
			_set_pressed_state(true)
			pressed_once.emit()
		else:
			return
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag = event as InputEventScreenDrag
		if drag.index != touch_index:
			return
		# 滑出时释放动作，但保留触点归属，避免其他手指抢占按钮。
		_set_pressed_state(_is_point_inside(_local_position(drag.position)))
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse = event as InputEventMouseButton
		# 触摸产生的模拟鼠标事件不能改变真实触点的按住状态。
		if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed:
			if touch_index != -1 or not _is_point_inside(_local_position(mouse.position)):
				return
			touch_index = -99
			_set_pressed_state(true)
			pressed_once.emit()
		else:
			if touch_index != -99:
				return
			touch_index = -1
			_set_pressed_state(false)
		get_viewport().set_input_as_handled()

func _local_position(viewport_position: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * viewport_position

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
	if button_icon:
		var icon_size: Vector2 = button_icon.get_size()
		var icon_scale: float = button_radius * 2.0 / maxf(icon_size.x, icon_size.y)
		var draw_size: Vector2 = icon_size * icon_scale
		var icon_modulate := Color(0.75, 0.75, 0.75, 1.0) if is_pressed else Color.WHITE
		draw_texture_rect(button_icon, Rect2(center - draw_size * 0.5, draw_size), false, icon_modulate)
		return
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
		if not is_visible_in_tree() or not can_process():
			_set_pressed_state(false)
			touch_index = -1
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		_set_pressed_state(false)
		touch_index = -1
