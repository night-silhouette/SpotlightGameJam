extends Control

const FrameSkin = preload("res://Code/Entities/Setting/SettingsSkin.gd")
const BASE = preload("res://Art/New/ui/设置底图.PNG")
# 去除原文件的透明画布，坐标对应原画可见墨面。
const ART_REGION := Rect2(255, 116, 642, 416)
const CLOSE_RECT := Rect2(0.875, 0.018, 0.105, 0.105)
var _panel: PanelContainer
var _close: Button
var _hovered := false

## 为设置或读档面板安装同一美术框；panel 与 close 须在树内，返回装饰层。
## 只接管外观、留白与缩放，不连接关闭业务，保留传入按钮的已有信号。
static func Mount(panel: PanelContainer, close: Button) -> Control:
	var frame := new()
	frame.name = "IllustratedFrame"
	frame._panel = panel
	frame._close = close
	panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	var margins: Vector4 = ExportSettings.setting_panel_content_margins
	for child in panel.get_children():
		if child is MarginContainer:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			child.add_theme_constant_override("margin_left", roundi(margins.x))
			child.add_theme_constant_override("margin_top", roundi(margins.y))
			child.add_theme_constant_override("margin_right", roundi(margins.z))
			child.add_theme_constant_override("margin_bottom", roundi(margins.w))
	panel.add_child(frame)
	panel.move_child(frame, 0)
	close.reparent(frame)
	close.text = ""
	close.tooltip_text = "关闭 / ESC"
	close.custom_minimum_size = Vector2.ZERO
	close.focus_mode = Control.FOCUS_ALL
	close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	close.anchor_left = CLOSE_RECT.position.x
	close.anchor_top = CLOSE_RECT.position.y
	close.anchor_right = CLOSE_RECT.end.x
	close.anchor_bottom = CLOSE_RECT.end.y
	close.offset_left = 0.0
	close.offset_top = 0.0
	close.offset_right = 0.0
	close.offset_bottom = 0.0
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		close.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	close.mouse_entered.connect(func(): frame._hovered = true; frame.queue_redraw())
	close.mouse_exited.connect(func(): frame._hovered = false; frame.queue_redraw())
	close.focus_entered.connect(frame.queue_redraw)
	close.focus_exited.connect(frame.queue_redraw)
	frame.resized.connect(frame.queue_redraw)
	panel.get_parent().resized.connect(frame._fit_panel)
	panel.minimum_size_changed.connect(frame._fit_panel)
	panel.visibility_changed.connect(frame._on_visibility_changed)
	frame._fit_panel.call_deferred()
	return frame

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_visibility_changed() -> void:
	_hovered = false
	queue_redraw()
	if _panel.is_visible_in_tree():
		_fit_panel.call_deferred()

func _fit_panel() -> void:
	var available: Vector2 = _panel.get_parent().size
	var design: Vector2 = ExportSettings.setting_panel_design_size.max(_panel.get_combined_minimum_size()).max(Vector2.ONE)
	var margin: float = ExportSettings.setting_panel_screen_margin
	var factor := clampf(minf((available.x - margin * 2.0) / design.x, (available.y - margin * 2.0) / design.y), 0.001, 1.0)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_panel.size = design
	_panel.scale = Vector2.ONE * factor
	_panel.position = (available - design * factor) * 0.5

func _draw() -> void:
	# 原图镂空花纹与三角露出纸色底层；内容不受背景透明度影响。
	var opacity: float = ExportSettings.setting_panel_opacity
	draw_rect(Rect2(Vector2.ZERO, size), Color(FrameSkin.PAPER, opacity))
	draw_texture_rect_region(BASE, Rect2(Vector2.ZERO, size), ART_REGION, Color(1, 1, 1, opacity))
	var ink := FrameSkin.PAPER
	var width: float = ExportSettings.setting_panel_edge_width
	# 双道略带抖动的手绘边线，不使用现代圆角卡片替代原画。
	for inset in [5.0, 11.0]:
		var outline := PackedVector2Array()
		var corners := [Vector2(inset, inset), Vector2(size.x - inset, inset), size - Vector2.ONE * inset, Vector2(inset, size.y - inset), Vector2(inset, inset)]
		for edge in range(4):
			var start: Vector2 = corners[edge]
			var finish: Vector2 = corners[edge + 1]
			for step in range(33):
				var t := step / 32.0
				var point := start.lerp(finish, t)
				var normal := (finish - start).normalized().orthogonal()
				point += normal * (sin(t * 39.0 + edge * 2.1 + inset) * 0.8 + sin(t * 83.0) * 0.25)
				outline.append(point)
		outline.append(outline[0])
		draw_polyline(outline, Color(ink, 0.8 if inset == 5.0 else 0.45), width, true)
	# 卷草与渐小的籽点呼应顶部镂空及存档条角花。
	for origin in [Vector2(28, size.y - 28), Vector2(size.x - 28, size.y - 28)]:
		var direction := 1.0 if origin.x < size.x * 0.5 else -1.0
		var curl := PackedVector2Array()
		for i in range(49):
			var t := i / 48.0
			var angle := t * TAU * 1.25
			var radius := 26.0 * (1.0 - t) + 2.0
			curl.append(origin + Vector2(direction * (28.0 + cos(angle) * radius), -18.0 + sin(angle) * radius))
		draw_polyline(curl, ink, width * 1.375, true)
		for i in range(3):
			draw_circle(origin + Vector2(direction * (65 + i * 12), -3), 3.2 - i * 0.6, ink)
	if _hovered or _close.has_focus():
		var triangle := PackedVector2Array([size * Vector2(0.879, 0.072), size * Vector2(0.966, 0.034), size * Vector2(0.966, 0.110)])
		draw_colored_polygon(triangle, FrameSkin.ACCENT)
