extends Area2D

@export_enum("jump", "dash", "water_wall") var hint_kind: String = "jump"

var _players_inside: Array[Node2D] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or _players_inside.has(body):
		return
	_players_inside.append(body)
	var text: String = ExportSettings.tutorial_jump_hint_text
	match hint_kind:
		"dash":
			text = ExportSettings.tutorial_dash_hint_text
		"water_wall":
			text = ExportSettings.tutorial_water_wall_hint_text
	SignalBus.TutorialSubtitleRequested.emit(text)

func _on_body_exited(body: Node2D) -> void:
	_players_inside.erase(body)
