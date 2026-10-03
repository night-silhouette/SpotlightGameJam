extends Control
class_name StartLoseHpButton

## =============================================================================
## StartLoseHpButton.gd - 开始掉血测试按钮
## 点击后向全局 SignalBus 发送 StartPlayerHpDrain 信号，开启玩家随时间流失生命值
## =============================================================================

@export var drain_rate: float = 5.0
@onready var button: Button = $Button

func _ready() -> void:
	if button:
		button.pressed.connect(_on_button_pressed)

## 按钮点击响应
func _on_button_pressed() -> void:
	if SignalBus:
		SignalBus.StartPlayerHpDrain.emit(drain_rate)
