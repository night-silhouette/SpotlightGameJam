extends Area2D

@onready var water: ColorRect = $Water
@onready var stream: AnimatedSprite2D = $Stream
@onready var relic_visual: Sprite2D = $OfferingVisual
@onready var offering_target: Marker2D = $OfferingTarget

var _ending_triggered: bool = false
var _fill_stage: int = 0
var _completed_relics: Array[String] = []
var _legacy_light_count: int = 0
var _player_inside: Node2D = null
var _heal_requested_inside: bool = false
var _overlap_arm_generation: int = 0
var _interaction_ready: bool = false
var _blocked_until_exit: bool = false
var _awaiting_relic_state: bool = false
var _relic_submission_pending: bool = false
var _first_fill_ratio: float = 0.5
var _water_tween: Tween
var _offering_tween: Tween
var _generation: int = 0
var _presenting: bool = false
var _presentation_player: Node2D
var _current_relic: StringName
var _prepared: bool = false
var _hand_position: Vector2
var _held_size: Vector2
var _player_visual_height: float
var _stream_finished: bool = false


func _ready() -> void:
	stream.speed_scale = maxf(ExportSettings.lake_stream_animation_fps, 1.0) / stream.sprite_frames.get_animation_speed(&"crown_flow")
	stream.animation_finished.connect(_on_stream_animation_finished)
	_first_fill_ratio = clampf(ExportSettings.lake_first_fill_ratio, 0.0, 1.0)
	relic_visual.material = relic_visual.material.duplicate()
	_reset_stream()
	_update_lights()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	SignalBus.PlayerBeforeMotion.connect(_on_player_before_motion)
	SignalBus.PlayerRelicsChanged.connect(_on_player_relics_changed)
	SignalBus.GradualTextActiveChanged.connect(_on_gradual_text_active_changed)
	SignalBus.SaveSlotLoaded.connect(_on_save_slot_loaded)
	SignalBus.PlayerOfferingPrepared.connect(_on_offering_prepared)
	SignalBus.PlayerOfferingCancelled.connect(_on_offering_cancelled)
	SignalBus.PlayerDied.connect(_on_player_died)
	_update_water(false)
	_arm_after_initial_overlap()


func _arm_after_initial_overlap() -> void:
	_overlap_arm_generation += 1
	var generation := _overlap_arm_generation
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	if not is_inside_tree() or generation != _overlap_arm_generation:
		return
	_blocked_until_exit = false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_player_inside = body
			_request_heal_if_needed(body)
			_blocked_until_exit = true
	_interaction_ready = true


func _request_heal_if_needed(player: Node2D) -> void:
	if _heal_requested_inside:
		return
	_heal_requested_inside = true
	SignalBus.PlayerFullHealRequested.emit(player)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = body
	_request_heal_if_needed(body)
	if not _interaction_ready:
		_blocked_until_exit = true
		return
	if _blocked_until_exit:
		return
	_relic_submission_pending = true
	_try_submit_relics.call_deferred()


func _on_gradual_text_active_changed(active: bool) -> void:
	if not active and _relic_submission_pending:
		_try_submit_relics.call_deferred()


func _on_player_before_motion(player: CharacterBody2D, _delta: float) -> void:
	if player == _player_inside and _relic_submission_pending:
		# 延迟至本次 move_and_slide 后复查地面及真实重叠，空中保留提交资格。
		_try_submit_relics.call_deferred()


func _can_submit_relics() -> bool:
	if not _interaction_ready or _blocked_until_exit:
		return false
	if not is_instance_valid(_player_inside) or _player_inside.is_queued_for_deletion():
		return false
	if not _player_inside.is_inside_tree() or not overlaps_body(_player_inside):
		return false
	if not _player_inside.is_in_group("player") or _player_inside.get("now_HP") == null:
		return false
	if _player_inside.get("now_HP") <= 0.0:
		return false
	var state_machine = _player_inside.get("move_state_machine")
	return not is_instance_valid(state_machine) or state_machine.get("cur_state_name") != "died"


func _try_submit_relics() -> void:
	if not _relic_submission_pending or _presenting:
		return
	if not _can_submit_relics():
		_relic_submission_pending = false
		return
	if SignalBus.IsGradualTextActive() or not (_player_inside is CharacterBody2D) or not _player_inside.is_on_floor():
		return
	_relic_submission_pending = false
	_awaiting_relic_state = true
	SignalBus.PlayerRelicStateRequested.emit()


func _on_save_slot_loaded(_slot_index: int) -> void:
	_cancel_presentation()
	_relic_submission_pending = false
	_awaiting_relic_state = false
	_interaction_ready = false
	_blocked_until_exit = true
	_arm_after_initial_overlap()


func _on_body_exited(body: Node2D) -> void:
	if body != _player_inside:
		return
	_cancel_presentation()
	_player_inside = null
	_heal_requested_inside = false
	_blocked_until_exit = false
	_awaiting_relic_state = false
	_relic_submission_pending = false


func _on_player_relics_changed(crown: bool, codex: bool, bones: bool) -> void:
	if not _awaiting_relic_state:
		return
	_awaiting_relic_state = false
	if not _can_submit_relics():
		return
	if SignalBus.IsGradualTextActive() or not (_player_inside is CharacterBody2D) or not _player_inside.is_on_floor():
		_relic_submission_pending = true
		return
	var queue: Array[StringName] = []
	for relic in [{"id": &"crown", "held": crown}, {"id": &"codex", "held": codex}, {"id": &"bones", "held": bones}]:
		if relic.held and not String(relic.id) in _completed_relics:
			queue.append(relic.id)
	if not queue.is_empty():
		_present_relics(queue)


func _present_relics(queue: Array[StringName]) -> void:
	_presenting = true
	_presentation_player = _player_inside
	_generation += 1
	var generation := _generation
	for relic in queue:
		# 上一件消费会同步触发 GradualText；黑幕结束前不开始下一件。
		while SignalBus.IsGradualTextActive():
			if not _presentation_valid(generation):
				return
			await get_tree().process_frame
		if not _presentation_valid(generation):
			return
		_current_relic = relic
		_prepared = false
		SignalBus.PlayerOfferingRequested.emit(_presentation_player, self, relic)
		var elapsed := 0.0
		while not _prepared:
			if not _presentation_valid(generation):
				return
			elapsed += get_process_delta_time()
			if elapsed > ExportSettings.lake_take_timeout:
				_cancel_presentation()
				return
			await get_tree().process_frame
		if not _presentation_valid(generation):
			return
		var duration := maxf(0.01, ExportSettings.lake_relic_flight_duration)
		_offering_tween = create_tween().set_parallel(true)
		_offering_tween.tween_property(relic_visual, "global_position", offering_target.global_position, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		var texture_size := relic_visual.texture.get_size()
		var target_scale: float = _player_visual_height * ExportSettings.lake_relic_height_ratio / maxf(texture_size.y, 1.0)
		_offering_tween.tween_property(relic_visual, "global_scale", Vector2.ONE * target_scale, duration)
		_offering_tween.tween_property(relic_visual, "global_rotation", 0.0, duration)
		if not await _wait_seconds(duration + ExportSettings.lake_relic_hold_duration, generation):
			return
		_offering_tween = create_tween()
		_offering_tween.tween_method(_set_dissolve, 0.0, 1.0, maxf(0.01, ExportSettings.lake_relic_dissolve_duration))
		if not await _wait_seconds(ExportSettings.lake_relic_dissolve_duration, generation):
			return
		relic_visual.hide()
		if relic != &"codex":
			_stream_finished = false
			stream.stop()
			stream.play(&"crown_flow" if relic == &"crown" else &"bones_flow")
			elapsed = 0.0
			while not _stream_finished:
				if not _presentation_valid(generation):
					return
				elapsed += get_process_delta_time()
				if elapsed > ExportSettings.lake_take_timeout:
					_cancel_presentation()
					return
				await get_tree().process_frame
			stream.play(&"Static2")
		if not _presentation_valid(generation):
			return
		# 表现全部完成才原子登记结果并消费；中途存档仍携带尚未完成的遗物。
		_completed_relics.append(String(relic))
		_fill_stage = mini(2, _completed_relics.size() + _legacy_light_count)
		_update_water(true)
		_update_lights()
		if relic == &"crown":
			SignalBus.PlayerAbilityChangeRequested.emit(&"double_jump", true)
		elif relic == &"codex":
			SignalBus.PlayerAbilityChangeRequested.emit(&"rope", true)
		var trigger_ending := relic == &"bones" and not _ending_triggered
		if trigger_ending:
			_ending_triggered = true
		SignalBus.PlayerRelicConsumeRequested.emit(relic)
		if trigger_ending:
			SignalBus.LakeEndingTriggered.emit()
	if generation == _generation:
		_finish_presentation()


func _show_relic(relic: StringName) -> void:
	var textures := {&"crown": ExportSettings.sunken_crown_texture, &"codex": ExportSettings.starseekers_codex_texture, &"bones": ExportSettings.scarred_bones_texture}
	relic_visual.texture = textures[relic]
	relic_visual.global_position = _hand_position
	relic_visual.global_rotation = -PI / 2.0 if relic == &"bones" else 0.0
	relic_visual.global_scale = _held_size / relic_visual.texture.get_size()
	_set_dissolve(0.0)
	relic_visual.show()


func _set_dissolve(value: float) -> void:
	(relic_visual.material as ShaderMaterial).set_shader_parameter("progress", value)


func _on_offering_prepared(player: Node2D, source: Node, relic: StringName, hand_position: Vector2, held_size: Vector2, visual_height: float) -> void:
	if not _presenting or source != self or player != _presentation_player or relic != _current_relic:
		return
	_hand_position = hand_position
	_held_size = held_size
	_player_visual_height = visual_height
	_show_relic(relic)
	_prepared = true


func _presentation_valid(generation: int) -> bool:
	if generation != _generation or not _presenting:
		return false
	if not _can_submit_relics() or not _presentation_player.can_process():
		_cancel_presentation()
		return false
	return true


func _wait_seconds(seconds: float, generation: int) -> bool:
	var elapsed := 0.0
	while elapsed < maxf(seconds, 0.01):
		if not _presentation_valid(generation):
			return false
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return _presentation_valid(generation)


func _finish_presentation() -> void:
	var player := _presentation_player
	_presenting = false
	_presentation_player = null
	relic_visual.hide()
	if is_instance_valid(player):
		SignalBus.PlayerOfferingReleaseRequested.emit(player, self)


func _cancel_presentation() -> void:
	_generation += 1
	if _offering_tween and _offering_tween.is_valid():
		_offering_tween.kill()
	if is_node_ready():
		_finish_presentation()
		_reset_stream()


func _on_offering_cancelled(player: Node2D, source: Node) -> void:
	if source == self and player == _presentation_player:
		_cancel_presentation()


func _on_player_died(player: Node2D) -> void:
	if player == _presentation_player:
		_cancel_presentation()


func _exit_tree() -> void:
	_cancel_presentation()


func _reset_stream() -> void:
	stream.stop()
	if "crown" in _completed_relics or "bones" in _completed_relics or _legacy_light_count > 0:
		stream.play(&"Static2")
	else:
		stream.animation = &"static"
		stream.frame = 0


func _on_stream_animation_finished() -> void:
	if stream.animation in [&"crown_flow", &"bones_flow"]:
		_stream_finished = true


func _update_lights() -> void:
	var lights := [$Stream/OrbLights/LeftOrbLight, $Stream/OrbLights/FrontOrbLight, $Stream/OrbLights/RightOrbLight]
	var count := mini(3, _completed_relics.size() + _legacy_light_count)
	for index in range(lights.size()):
		lights[index].visible = index < count
		lights[index].enabled = index < count
		lights[index].get_node("Glow").visible = index < count


func _update_water(animate: bool) -> void:
	if not is_node_ready():
		return
	var ratio := 0.12
	if _fill_stage == 1:
		ratio = _first_fill_ratio
	elif _fill_stage == 2:
		ratio = 1.0
	var target_y := 13.0 - 26.0 * ratio
	if _water_tween and _water_tween.is_valid():
		_water_tween.kill()
	if animate:
		_water_tween = create_tween().set_parallel(true)
		_water_tween.tween_property(water, "scale:y", ratio, 0.6).set_trans(Tween.TRANS_SINE)
		_water_tween.tween_property(water, "position:y", target_y, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		water.scale.y = ratio
		water.position.y = target_y


## 导出已完整结束的献祭、顺序灯光和结局状态；未完成遗物仍由玩家存档持有。
func ExportSaveData() -> Dictionary:
	return {"position_x": global_position.x, "position_y": global_position.y, "fill_stage": _fill_stage, "completed_relics": _completed_relics.duplicate(), "ending_triggered": _ending_triggered, "legacy_light_count": _legacy_light_count}


## 恢复稳定状态并取消旧演出；旧档仅有 fill_stage 时保留其已完成数量，不补播结局。
func LoadSaveData(data: Dictionary) -> void:
	_cancel_presentation()
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	_fill_stage = clampi(int(data.get("fill_stage", _fill_stage)), 0, 2)
	_completed_relics.clear()
	for relic in data.get("completed_relics", []):
		if relic in ["crown", "codex", "bones"] and not relic in _completed_relics:
			_completed_relics.append(relic)
	_legacy_light_count = clampi(int(data.get("legacy_light_count", 0 if data.has("completed_relics") else _fill_stage)), 0, 3)
	_ending_triggered = bool(data.get("ending_triggered", "bones" in _completed_relics))
	_awaiting_relic_state = false
	_relic_submission_pending = false
	_heal_requested_inside = false
	_interaction_ready = false
	_blocked_until_exit = true
	_update_water(false)
	if is_node_ready():
		_reset_stream()
		_update_lights()
		_arm_after_initial_overlap()
