extends Area2D

@export_multiline var content: String = ""
@export_range(0.1, 60.0, 0.1, "or_greater") var display_duration: float = 5.0
@export var trigger_relic: StringName = &""
## 本卡真实结束后请求的章节通道；留空不请求，通道由场景装配。
@export var finished_chapter_channel: StringName = &""

@onready var _card: Control = $GradualTextCardLayer/GradualTextCard

var _triggered: bool = false
var _chapter_pending: bool = false

func _ready() -> void:
	_card.Finished.connect(_on_card_finished)
	SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)
	if trigger_relic == &"":
		body_entered.connect(_on_body_entered)
	else:
		SignalBus.PlayerRelicConsumeRequested.connect(_on_relic_consumed)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_play()

func _on_relic_consumed(relic: StringName) -> void:
	if relic == trigger_relic:
		_play()

func _play() -> void:
	if _triggered:
		return
	_triggered = true
	_chapter_pending = finished_chapter_channel != &""
	_card.content = content
	_card.display_duration = display_duration
	_card.Play()

func _on_card_finished() -> void:
	if not _chapter_pending:
		return
	_chapter_pending = false
	SignalBus.ChapterCardRequested.emit(finished_chapter_channel)

func _on_save_slot_loaded(_slot_index: int) -> void:
	_chapter_pending = false
