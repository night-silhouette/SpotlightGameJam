extends Area2D

## 玩家进入检测区域时显示一次章节标题，不切换场景或剧情状态。
@export var act_text: String = "第一幕"
@export var chapter_text: String = "纺织"

@onready var _card: Control = $ChapterCardLayer/ChapterCard

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_card.call("ShowChapter", act_text, chapter_text)
