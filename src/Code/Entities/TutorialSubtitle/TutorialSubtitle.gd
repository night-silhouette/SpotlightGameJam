extends CanvasLayer

@onready var _root: MarginContainer = $Root
@onready var _subtitle: VBoxContainer = $Root/Subtitle
@onready var _label: Label = $Root/Subtitle/Label
@onready var _line: ColorRect = $Root/Subtitle/Decoration/Line

var _tween: Tween

func _ready() -> void:
	_subtitle.modulate.a = 0.0
	_label.add_theme_color_override("font_color", ExportSettings.tutorial_text_color)
	_label.add_theme_color_override("font_shadow_color", ExportSettings.tutorial_shadow_color)
	_label.add_theme_font_size_override("font_size", ExportSettings.tutorial_font_size)
	_label.add_theme_constant_override("shadow_offset_x", ExportSettings.tutorial_shadow_offset.x)
	_label.add_theme_constant_override("shadow_offset_y", ExportSettings.tutorial_shadow_offset.y)
	_subtitle.add_theme_constant_override("separation", ExportSettings.tutorial_line_spacing)
	_line.color = ExportSettings.tutorial_line_color
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()
	SignalBus.TutorialSubtitleRequested.connect(_on_subtitle_requested)

func _update_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var margin := mini(roundi(ExportSettings.tutorial_screen_margin), floori(viewport_size.x * 0.25))
	var width := minf(ExportSettings.tutorial_max_width, maxf(1.0, viewport_size.x - margin * 2.0))
	_root.add_theme_constant_override("margin_left", margin)
	_root.add_theme_constant_override("margin_right", margin)
	_root.add_theme_constant_override("margin_bottom", roundi(minf(ExportSettings.tutorial_bottom_margin, viewport_size.y * 0.25)))
	_subtitle.custom_minimum_size.x = width
	_line.custom_minimum_size = Vector2(width * ExportSettings.tutorial_line_width_ratio, ExportSettings.tutorial_line_thickness)

func _on_subtitle_requested(text: String) -> void:
	if _tween != null:
		_tween.kill()
	_label.text = text
	_subtitle.modulate.a = 0.0
	if text.is_empty():
		return
	_tween = create_tween()
	_tween.tween_property(_subtitle, "modulate:a", 1.0, ExportSettings.tutorial_fade_in_duration)
	_tween.tween_interval(ExportSettings.tutorial_hold_duration)
	_tween.tween_property(_subtitle, "modulate:a", 0.0, ExportSettings.tutorial_fade_out_duration)

func _exit_tree() -> void:
	if _tween != null:
		_tween.kill()
	if SignalBus.TutorialSubtitleRequested.is_connected(_on_subtitle_requested):
		SignalBus.TutorialSubtitleRequested.disconnect(_on_subtitle_requested)
