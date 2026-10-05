class_name InteractionPrompt
extends PanelContainer
## 可复用鼠标提示。预置按钮承接点击，文字覆盖层不拦截鼠标。
## 样式参照 MiniChaliceStation；检测范围、最近目标选择由 ProximityInteraction 负责。

## 点击预置按钮时通知所属交互组件，无参数；不直接改变实体状态。
signal Pressed

@onready var _button: Button = $PromptButton
@onready var _key_badge: Label = $Margin/Content/KeyBadge
@onready var _action_label: Label = $Margin/Content/ActionLabel


func _ready() -> void:
	_button.pressed.connect(func(): Pressed.emit())
	resized.connect(_center_prompt)
	_center_prompt()


## 设置显示内容，由交互组件在实体就绪后调用。
## @param key_label 当前交互键名称；text 不含按键的动作文字。
## @param font_size 动作文字字号（界面像素）。按钮高度和按键字号从 ExportSettings 读取。返回 void。
func ConfigurePresentation(key_label: String, text: String, font_size: int) -> void:
	_key_badge.text = key_label
	_action_label.text = text
	_action_label.add_theme_font_size_override("font_size", font_size)
	_key_badge.add_theme_font_size_override("font_size", ExportSettings.interaction_prompt_key_font_size)
	custom_minimum_size.y = ExportSettings.interaction_prompt_min_height
	# 文本变短时也允许缩回；容器结算后保持在 PromptAnchor 水平居中。
	reset_size()
	_center_prompt.call_deferred()


func _center_prompt() -> void:
	position.x = -size.x * 0.5
