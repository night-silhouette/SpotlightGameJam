extends Area2D

## 玩家进入检测区域或收到匹配通道请求时显示一次章节标题，不切换场景或剧情状态。
@export var act_text: String = "第一幕"
@export var chapter_text: String = "纺织"
@export var subtitle_text: String = ""
## 留空沿用进入区域触发；非空仅响应总线章节请求，通道由场景装配。
@export var request_channel: StringName = &""

@onready var _card: Control = $ChapterCardLayer/ChapterCard

var _triggered: bool = false

func _ready() -> void:
	_card.Finished.connect(_on_card_finished)
	if request_channel == &"":
		body_entered.connect(_on_body_entered)
	else:
		SignalBus.ChapterCardRequested.connect(_on_chapter_requested)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_show_chapter()

func _on_chapter_requested(channel: StringName) -> void:
	if channel == request_channel:
		_show_chapter()

func _on_card_finished() -> void:
	if _triggered and request_channel != &"":
		SignalBus.ChapterCardFinished.emit(request_channel)

func _show_chapter() -> void:
	if _triggered:
		return
	_triggered = true
	_card.set("subtitle_text", subtitle_text)
	_card.call("ShowChapter", act_text, chapter_text)
