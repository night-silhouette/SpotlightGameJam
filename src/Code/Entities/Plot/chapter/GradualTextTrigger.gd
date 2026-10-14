extends Area2D

@export_multiline var content: String = ""
@export_range(0.1, 60.0, 0.1, "or_greater") var display_duration: float = 5.0
@export var trigger_relic: StringName = &""

@onready var _card: Control = $GradualTextCardLayer/GradualTextCard

var _triggered: bool = false

func _ready() -> void:
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
	_card.content = content
	_card.display_duration = display_duration
	_card.Play()
