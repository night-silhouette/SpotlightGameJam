extends RefCounted

const PAPER := Color("e4d8b9")
const INK := Color("181914")
const ACCENT := Color("d8b779")
const SLOT = preload("res://Art/New/ui/save_slot_1.png")
const BUTTON = preload("res://Art/New/ui/settings_button_1.png")
const TRACK = preload("res://Art/New/ui/settings_slider_track.png")
const KNOB = preload("res://Art/New/ui/settings_music_knob.png")

static var _theme: Theme
static var _card_theme: Theme
static var _save_style: StyleBoxTexture

static func _paper_texture(source: Texture2D, dimensions: Vector2i) -> Texture2D:
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.resize(dimensions.x, dimensions.y, Image.INTERPOLATE_LANCZOS)
	# 原素材为黑墨加透明镂空；仅反转墨色，保留抗锯齿与原画轮廓。
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(PAPER.r, PAPER.g, PAPER.b, pixel.a))
	return ImageTexture.create_from_image(image)

static func _texture_style(texture: Texture2D, margin: float = 12.0) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, margin)
		style.set_content_margin(side, margin)
	return style

## 返回共用存档条九宫格样式；调用方不得修改返回的共享资源。
static func SaveStyle() -> StyleBoxTexture:
	if _save_style == null:
		_save_style = _texture_style(SLOT, 20.0)
		_save_style.modulate_color = PAPER
		_save_style.content_margin_top = 14.0
		_save_style.content_margin_bottom = 14.0
	return _save_style

## 返回设置及读档面板共用主题；首次调用生成纹理，后续复用缓存。
static func CreateTheme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	_theme.default_font_size = 16
	_theme.set_color("font_color", "Label", PAPER)
	var normal := _texture_style(_paper_texture(BUTTON, Vector2i(184, 44)), 18.0)
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := normal.duplicate() as StyleBoxTexture
		if state == "hover" or state == "pressed":
			style.modulate_color = ACCENT
		elif state == "disabled":
			style.modulate_color = Color(0.55, 0.53, 0.46)
		_theme.set_stylebox(state, "Button", style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		_theme.set_color(state, "Button", INK)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = ACCENT
	focus.set_border_width_all(1)
	focus.set_corner_radius_all(8)
	_theme.set_stylebox("focus", "Button", focus)
	_theme.set_stylebox("focus", "HSlider", focus)
	var track := _texture_style(_paper_texture(TRACK, Vector2i(272, 14)), 6.0)
	track.content_margin_top = 7.0
	track.content_margin_bottom = 7.0
	_theme.set_stylebox("slider", "HSlider", track)
	_theme.set_stylebox("grabber_area", "HSlider", StyleBoxEmpty.new())
	_theme.set_stylebox("grabber_area_highlight", "HSlider", StyleBoxEmpty.new())
	var knob := _paper_texture(KNOB, Vector2i(36, 35))
	for state in ["grabber", "grabber_highlight", "grabber_disabled"]:
		_theme.set_icon(state, "HSlider", knob)
	_theme.set_stylebox("panel", "Panel", StyleBoxEmpty.new())
	var scroll := StyleBoxFlat.new()
	scroll.bg_color = Color(PAPER, 0.12)
	scroll.content_margin_left = 4.0
	scroll.content_margin_right = 4.0
	_theme.set_stylebox("scroll", "VScrollBar", scroll)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var grip := scroll.duplicate() as StyleBoxFlat
		grip.bg_color = ACCENT if state != "grabber" else Color(PAPER, 0.55)
		grip.set_corner_radius_all(3)
		_theme.set_stylebox(state, "VScrollBar", grip)
	return _theme

## 返回浅色存档条内的深色按钮主题；不改变父面板主题。
static func CardTheme() -> Theme:
	if _card_theme != null:
		return _card_theme
	_card_theme = Theme.new()
	_card_theme.default_font_size = 14
	var image := BUTTON.get_image()
	image.resize(184, 44, Image.INTERPOLATE_LANCZOS)
	var button := _texture_style(ImageTexture.create_from_image(image), 30.0)
	button.set_texture_margin(SIDE_TOP, 8.0)
	button.set_texture_margin(SIDE_BOTTOM, 8.0)
	button.content_margin_top = 8.0
	button.content_margin_bottom = 8.0
	for state in ["normal", "hover", "pressed", "disabled"]:
		_card_theme.set_stylebox(state, "Button", button)
	_card_theme.set_stylebox("focus", "Button", CreateTheme().get_stylebox("focus", "Button"))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_card_theme.set_color(state, "Button", PAPER if state == "font_color" else ACCENT)
	_card_theme.set_color("font_disabled_color", "Button", Color("777568"))
	return _card_theme

## 为给定面板子树清除旧配色覆盖并统一控件交互；node 须为已实例化节点。
static func ApplyToTree(node: Node) -> void:
	if node is Label:
		node.remove_theme_color_override("font_color")
		if node.name == "Percent":
			node.custom_minimum_size.x = 64.0
	if node is ScrollContainer:
		node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if node is Button:
		node.remove_theme_stylebox_override("normal")
		node.focus_mode = Control.FOCUS_ALL
	if node is HSlider:
		node.custom_minimum_size.y = 38.0
	for child in node.get_children():
		ApplyToTree(child)
