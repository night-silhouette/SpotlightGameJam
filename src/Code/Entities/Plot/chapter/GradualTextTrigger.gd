extends Area2D

@export_multiline var content: String = ""
@export_range(0.1, 60.0, 0.1, "or_greater") var display_duration: float = 5.0

@onready var _card: Control = $GradualTextCardLayer/GradualTextCard

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	_card.content = content
	_card.display_duration = display_duration
	_card.Play()
