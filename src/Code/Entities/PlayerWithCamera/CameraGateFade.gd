extends CanvasLayer

@onready var _player: Node2D = get_node("../Player") as Node2D
@onready var _black: ColorRect = $Black

var _active_gates: Dictionary = {}
var _tween: Tween
var _reset_generation: int = 0


func _ready() -> void:
	SignalBus.CameraGateChanged.connect(_on_gate_changed)
	SignalBus.CameraGateSideChanged.connect(_on_gate_side_changed)
	SignalBus.PlayerRespawned.connect(_on_player_respawned)
	SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)


func _on_gate_changed(player: Node2D, gate: Area2D, active: bool, _side: int, _boundary: float) -> void:
	if player != _player or not is_instance_valid(gate):
		return
	var gate_id: int = gate.get_instance_id()
	if active:
		_active_gates[gate_id] = true
	elif _active_gates.erase(gate_id):
		# 退出树时门仍可能报告在树中；延迟复核，避免移除门触发黑幕。
		_play_if_gate_present.call_deferred(weakref(gate), _reset_generation)


func _play_if_gate_present(gate_ref: WeakRef, generation: int) -> void:
	var gate: Area2D = gate_ref.get_ref() as Area2D
	if generation == _reset_generation and is_instance_valid(gate) and gate.is_inside_tree() and not gate.is_queued_for_deletion():
		_play_fade()


func _on_gate_side_changed(player: Node2D, _gate: Area2D, _side: int, _boundary: float, reset: bool) -> void:
	if player == _player and not reset:
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
	_reset_generation += 1
	if _tween != null:
		_tween.kill()
		_tween = null
	_black.color.a = 0.0


func _on_player_respawned(_respawn_position: Vector2) -> void:
	_clear_fade()


func _on_save_slot_loaded(_slot_index: int) -> void:
	_clear_fade()
