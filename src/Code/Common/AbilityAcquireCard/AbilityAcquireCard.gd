class_name AbilityAcquireCard
extends CanvasLayer

## 本轮展示自然结束且已隐藏时发出；取消和被重播替换的轮次不发出。
signal Finished

## 预设身份与图像仅控制展示，不授予能力。
@export var ability_name: String = "逐日跃"
@export var ability_icon: Texture2D = preload("res://Art/New/component/技能图标/IMG_9889_left.png")
@export var auto_play: bool = true

@onready var _root: Control = $Root
@onready var _background: ColorRect = $Root/Background
@onready var _design: Control = $Root/Design
@onready var _layout: VBoxContainer = $Root/Design/Layout
@onready var _icon: TextureRect = $Root/Design/Layout/Icon
@onready var _obtained: Label = $Root/Design/Layout/Obtained
@onready var _title: Label = $Root/Design/Layout/Title
@onready var _decoration: TextureRect = $Root/Design/Layout/Decoration

var _tween: Tween

func _ready() -> void:
	_icon.material = _icon.material.duplicate()
	_decoration.material = _decoration.material.duplicate()
	get_viewport().size_changed.connect(_fit_layout)
	_layout.resized.connect(_fit_layout)
	_apply_settings()
	if auto_play:
		Play()
	else:
		Cancel()

## 无参播放当前预设；重复调用杀死旧 Tween，并从透明状态重新开始。
func Play() -> void:
	if not is_node_ready():
		await ready
	Cancel()
	_apply_settings()
	_root.show()
	_root.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_root, "modulate:a", 1.0, maxf(ExportSettings.ability_acquire_fade_in, 0.0))
	_tween.tween_interval(maxf(ExportSettings.ability_acquire_hold, 0.0))
	_tween.tween_property(_root, "modulate:a", 0.0, maxf(ExportSettings.ability_acquire_fade_out, 0.0))
	_tween.tween_callback(_finish)

## 无参取消当前展示并隐藏；不发出 Finished，不改变输入或世界状态。
func Cancel() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
	if is_node_ready():
		_root.hide()

func _apply_settings() -> void:
	_icon.texture = ability_icon
	_title.text = ability_name
	_background.color = ExportSettings.ability_acquire_background_color
	_icon.custom_minimum_size = ExportSettings.ability_acquire_icon_size.max(Vector2.ONE)
	_decoration.custom_minimum_size = ExportSettings.ability_acquire_decoration_size.max(Vector2.ONE)
	_layout.add_theme_constant_override("separation", ExportSettings.ability_acquire_spacing)
	_obtained.add_theme_font_size_override("font_size", ExportSettings.ability_acquire_obtained_font_size)
	_title.add_theme_font_size_override("font_size", ExportSettings.ability_acquire_title_font_size)
	_obtained.add_theme_color_override("font_color", ExportSettings.ability_acquire_paper_color)
	_title.add_theme_color_override("font_color", ExportSettings.ability_acquire_title_color)
	_icon.material.set_shader_parameter("paper_color", ExportSettings.ability_acquire_paper_color)
	_decoration.material.set_shader_parameter("paper_color", ExportSettings.ability_acquire_paper_color)
	_fit_layout()

func _fit_layout() -> void:
	var margin: float = maxf(ExportSettings.ability_acquire_margin, 0.0)
	var content_size: Vector2 = _layout.get_combined_minimum_size()
	var design_size: Vector2 = ExportSettings.ability_acquire_design_size.max(content_size + Vector2.ONE * margin * 2.0).max(Vector2.ONE)
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var fit: float = minf(viewport_size.x / design_size.x, viewport_size.y / design_size.y)
	_design.size = design_size
	_design.scale = Vector2.ONE * fit
	_design.position = (viewport_size - design_size * fit) * 0.5
	_layout.size = content_size
	_layout.position = (design_size - content_size) * 0.5

func _finish() -> void:
	_tween = null
	_root.hide()
	Finished.emit()

func _exit_tree() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
