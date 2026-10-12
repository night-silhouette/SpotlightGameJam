extends Area2D

@onready var water: ColorRect = $Water

var _fill_stage: int = 0
var _player_inside: Node2D = null
var _interaction_ready: bool = false
var _blocked_until_exit: bool = false
var _awaiting_relic_state: bool = false
var _first_fill_ratio: float = 0.5
var _relic_flight_duration: float = 0.65
var _water_tween: Tween = null


func _ready() -> void:
	if "lake_first_fill_ratio" in ExportSettings:
		_first_fill_ratio = clampf(ExportSettings.lake_first_fill_ratio, 0.0, 1.0)
	if "lake_relic_flight_duration" in ExportSettings:
		_relic_flight_duration = maxf(ExportSettings.lake_relic_flight_duration, 0.01)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if SignalBus.has_signal(&"PlayerRelicsChanged"):
		SignalBus.connect(&"PlayerRelicsChanged", _on_player_relics_changed)
	_update_water(false)
	_arm_after_initial_overlap()


func _arm_after_initial_overlap() -> void:
	# 避免场景实例化/存档还原时，已经在水中的玩家被当作一次新进入。
	await get_tree().physics_frame
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	_blocked_until_exit = false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			_player_inside = body
			_blocked_until_exit = true
	_interaction_ready = true


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_inside = body
	if not _interaction_ready:
		_blocked_until_exit = true
		return
	if _blocked_until_exit:
		return
	if SignalBus.has_signal(&"PlayerRelicStateRequested"):
		_awaiting_relic_state = true
		SignalBus.emit_signal(&"PlayerRelicStateRequested")


func _on_body_exited(body: Node2D) -> void:
	if body != _player_inside:
		return
	_player_inside = null
	_blocked_until_exit = false
	_awaiting_relic_state = false


func _on_player_relics_changed(crown: bool, codex: bool, bones: bool) -> void:
	if not _awaiting_relic_state or not is_instance_valid(_player_inside):
		return
	_awaiting_relic_state = false
	if not crown and not codex and not bones:
		return
	if crown:
		_absorb_relic(&"crown", &"sunken_crown_texture", &"double_jump", Vector2(-18, -18))
	if codex:
		_absorb_relic(&"codex", &"starseekers_codex_texture", &"rope", Vector2(18, -18))
	if bones:
		_absorb_relic(&"bones", &"scarred_bones_texture", &"", Vector2(0, -26))
		create_tween().tween_interval(_relic_flight_duration).finished.connect(_show_ending)
	_fill_stage = mini(2, _fill_stage + int(crown) + int(codex) + int(bones))
	_update_water(true)


func _absorb_relic(relic: StringName, texture_field: StringName, ability: StringName, offset: Vector2) -> void:
	if texture_field in ExportSettings:
		var texture: Texture2D = ExportSettings.get(texture_field) as Texture2D
		if texture != null:
			var icon := Sprite2D.new()
			icon.texture = texture
			icon.scale = Vector2.ONE * (28.0 / maxf(texture.get_size().x, texture.get_size().y))
			add_child(icon)
			icon.position = to_local(_player_inside.global_position) + offset
			var tween := create_tween().set_parallel(true)
			tween.tween_property(icon, "position", Vector2.ZERO, _relic_flight_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			tween.tween_property(icon, "scale", Vector2.ZERO, _relic_flight_duration)
			tween.tween_property(icon, "modulate:a", 0.0, _relic_flight_duration)
			tween.chain().tween_callback(icon.queue_free)
	if SignalBus.has_signal(&"PlayerRelicConsumeRequested"):
		SignalBus.emit_signal(&"PlayerRelicConsumeRequested", relic)
	if ability != &"":
		SignalBus.PlayerAbilityChangeRequested.emit(ability, true)

func _show_ending() -> void:
	SignalBus.LakeEndingTriggered.emit()


func _update_water(animate: bool) -> void:
	if not is_node_ready():
		return
	var ratio := 0.12
	if _fill_stage == 1:
		ratio = _first_fill_ratio
	elif _fill_stage == 2:
		ratio = 1.0
	var target_height := 26.0 * ratio
	var target_y := 13.0 - target_height
	if _water_tween and _water_tween.is_valid():
		_water_tween.kill()
	if animate:
		_water_tween = create_tween().set_parallel(true)
		_water_tween.tween_property(water, "scale:y", ratio, 0.6).set_trans(Tween.TRANS_SINE)
		_water_tween.tween_property(water, "position:y", target_y, 0.6).set_trans(Tween.TRANS_SINE)
	else:
		water.scale.y = ratio
		water.position.y = target_y


## 导出湖泊的世界坐标和充盈阶段；fill_stage 为 0（未充盈）、1（首次进入）或 2（最满）。
## 返回可供存档系统持久化的字典。
func ExportSaveData() -> Dictionary:
	return {"position_x": global_position.x, "position_y": global_position.y, "fill_stage": _fill_stage}


## 从存档恢复湖泊位置和充盈阶段；data 为 ExportSaveData() 返回的字典，允许缺失字段。
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	_fill_stage = clampi(int(data.get("fill_stage", _fill_stage)), 0, 2)
	_awaiting_relic_state = false
	_interaction_ready = false
	_blocked_until_exit = true
	_update_water(false)
	if is_node_ready():
		_arm_after_initial_overlap()
