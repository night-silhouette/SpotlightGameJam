extends CanvasLayer

@onready var _player: Node2D = get_node("../Player") as Node2D
@onready var _black: ColorRect = $Black

var _tween: Tween


func _ready() -> void:
	SignalBus.CameraGateFadeRequested.connect(_on_gate_fade_requested)
	SignalBus.PlayerRespawned.connect(_on_player_respawned)
	SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)


func _on_gate_fade_requested(player: Node2D, _gate: Area2D) -> void:
	if player == _player:
		_play_fade()


func _play_fade() -> void:
	if not ExportSettings.camera_gate_fade_enabled:
		_clear_fade()
		return
	if _tween != null:
		_tween.kill()
	var fade_in: float = maxf(0.0, ExportSettings.camera_gate_fade_in)
	var fade_out: float = maxf(0.0, ExportSettings.camera_gate_fade_out)
	var hold: float = maxf(0.0, ExportSettings.camera_gate_transition_duration - fade_in)
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_black, "color:a", clampf(ExportSettings.camera_gate_fade_opacity, 0.0, 1.0), fade_in)
	if hold > 0.0:
		_tween.tween_interval(hold)
	_tween.tween_property(_black, "color:a", 0.0, fade_out)


func _clear_fade() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	_black.color.a = 0.0


func _on_player_respawned(_respawn_position: Vector2) -> void:
	_clear_fade()


func _on_save_slot_loaded(_slot_index: int) -> void:
	_clear_fade()
