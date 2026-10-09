extends Node2D
## 连续地下地图：房间通过实体通道相连。只有失败重生会改变玩家位置。
var keys: Array[String] = []
var rune_progress: int = 0
var puzzle_solved: bool = false
var completed: bool = false
var _rune_order: PackedStringArray = ["sun", "moon", "weave"]
var submitted_keys: Array[String] = []
var fountain_active: bool = false
var _elapsed: float = 0.0
var _player: CharacterBody2D
var _checkpoint: Vector2
var _saved_rope_mode: int = Node.PROCESS_MODE_INHERIT
var _saved_double_jump: bool = true
var _owns_player: bool = false
var _active_room: Node2D
var _toast_left: float = 0.0

func _ready() -> void:
	var configured: PackedStringArray = ExportSettings.level2_rune_order
	if configured.size() == 3 and configured.has("sun") and configured.has("moon") and configured.has("weave"):
		_rune_order = configured.duplicate()
	var names := {"sun": "日", "moon": "月", "weave": "交织"}
	$Rooms/WeaveArchive/RoomHint.text = "石碑线索：" + str(names[_rune_order[0]]) + " → " + str(names[_rune_order[1]]) + " → " + str(names[_rune_order[2]]) + "。错误会重置顺序。"
	_checkpoint = $Rooms/EntryCollapse/Spawn.global_position
	SignalBus.Level2InteractionRequested.connect(_on_requested)
	SignalBus.PlayerRespawned.connect(_on_respawned)
	$Rooms/SurfaceExit/FinishArea.body_entered.connect(_on_exit_reached)
	for area in find_children("*", "Area2D", true, false):
		if area.has_meta("fall_reset"):
			area.body_entered.connect(_on_fall)
	for platform in find_children("*", "AnimatableBody2D", true, false):
		platform.set("movement_speed", ExportSettings.level2_platform_speed)
	for room in $Rooms.get_children():
		room.get_node("RoomTitle").hide()
		room.get_node("RoomHint").hide()
	_refresh()

func _physics_process(delta: float) -> void:
	_elapsed += delta
	_toast_left = maxf(0.0, _toast_left - delta)
	$HUD/Root/Toast.visible = _toast_left > 0.0
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(_player):
		return
	var room: Node2D = GetRoomAt(_player.global_position)
	if room != null and not _owns_player:
		_claim_player()
	elif room == null and _owns_player and not Rect2(Vector2(-4400, -3450), Vector2(8600, 5800)).has_point(to_local(_player.global_position)):
		_release_player()
	$HUD.visible = _owns_player
	if room != null:
		if room != _active_room:
			_active_room = room
			$HUD/Root/Objective.text = room.get_node("RoomHint").text
			_checkpoint = room.get_node("Spawn").global_position
			var other := room.get_node_or_null("ReturnSpawn") as Marker2D
			if other and other.global_position.distance_to(_player.global_position) < _checkpoint.distance_to(_player.global_position):
				_checkpoint = other.global_position
			SignalBus.TentActivated.emit(self, _checkpoint)
		$HUD/Root/Status.text = str(room.get_meta("title", room.name)) + "  |  携带 %d · 已提交 %d / 3  |  %02d:%02d" % [keys.size() - submitted_keys.size(), submitted_keys.size(), int(_elapsed) / 60, int(_elapsed) % 60]
	if _owns_player and _player.global_position.y > global_position.y + 2300.0:
		_reset_player()
	if fountain_active and $Rooms/FountainShaft/Updraft.overlaps_body(_player):
		_player.velocity.y = -ExportSettings.level2_fountain_speed
		_player.ResetDoubleJump()
		# 水柱出口的水平喷流，仍由物理运动通过井口。
		if _player.global_position.y < $Rooms/FountainShaft.global_position.y + 150.0:
			_player.velocity.x = ExportSettings.level2_fountain_exit_speed

	if fountain_active and $Rooms/SurfaceExit/Spout.overlaps_body(_player):
		_player.velocity.x = ExportSettings.level2_fountain_exit_speed

## 返回指定世界坐标所属房间；找不到时返回 null。
func GetRoomAt(point: Vector2) -> Node2D:
	for room in $Rooms.get_children():
		var bounds := Rect2(Vector2(0, -80), Vector2(float(room.get_meta("width", 2200)), float(room.get_meta("height", 900)) + 80.0))
		if bounds.has_point(room.to_local(point)):
			return room
	return null

func _claim_player() -> void:
	_owns_player = true
	_saved_double_jump = _player.enable_double_jump
	_player.enable_double_jump = true
	_player.ResetDoubleJump()
	if _player.rope_controller:
		_saved_rope_mode = _player.rope_controller.process_mode
		_player.rope_controller.process_mode = Node.PROCESS_MODE_DISABLED

func _release_player() -> void:
	if is_instance_valid(_player):
		_player.enable_double_jump = _saved_double_jump
		if _player.rope_controller:
			_player.rope_controller.process_mode = _saved_rope_mode
	_owns_player = false

func _exit_tree() -> void:
	_release_player()

func _on_requested(source: Node2D, player: Node2D) -> void:
	if not is_ancestor_of(source) or source.global_position.distance_to(player.global_position) > ExportSettings.level2_interact_radius:
		return
	_player = player as CharacterBody2D
	match str(source.get_meta("kind", "")):
		"key":
			var key_id := str(source.get_meta("key_id", ""))
			if key_id in keys:
				return
			if key_id == "weave" and not puzzle_solved:
				return
			keys.append(key_id)
			_toast("取得钥匙，下层返程栈道已开放！带回喷泉按 F 提交后才会永久保留。")
			_refresh()
		"rune":
			if puzzle_solved:
				return
			var order: PackedStringArray = _rune_order
			if order.is_empty():
				return
			if str(source.get_meta("rune_id", "")) == order[rune_progress]:
				rune_progress += 1
				_toast("符文正确：%d / %d" % [rune_progress, order.size()])
				if rune_progress == order.size():
					puzzle_solved = true
					_toast("三枚符文共鸣，档案库闸门已开启。")
			else:
				rune_progress = 0
				_toast("顺序不符，重新从“日”开始。入口石碑给出了顺序。")
			_refresh()
		"lore":
			_toast("占位叙事：水道曾连接整座图书馆。观星者残卷的正式文本与演出待接入。", 8.0)
		"fountain":
			submitted_keys.assign(keys)
			if submitted_keys.size() < 3:
				_toast("已提交 %d / 3 把钥匙，已提交的不会因死亡丢失。" % submitted_keys.size())
			else:
				fountain_active = true
				_toast("水泵启动！走入喷泉水柱，沿逆流升回地表。", 7.0)
			_refresh()
	SignalBus.Level2StateChanged.emit(self)

func _on_fall(body: Node2D) -> void:
	if body == _player:
		_reset_player.call_deferred()

func _reset_player() -> void:
	if not is_instance_valid(_player):
		return
	_player.Respawn()

func _on_respawned(_position: Vector2) -> void:
	if not _owns_player:
		return
	var lost: int = keys.size() - submitted_keys.size()
	keys.assign(submitted_keys)
	_refresh()
	_toast("回到检查点。未提交钥匙已回到原位，已提交的保留。" if lost > 0 else "回到检查点，已提交钥匙保留。")
	SignalBus.Level2StateChanged.emit(self)

func _on_exit_reached(body: Node2D) -> void:
	if body != _player or not fountain_active or completed:
		return
	completed = true
	_toast("第二关路线完成：从另一个枯井回到地表。此处预留主城接入口。", 12.0)
	SignalBus.Level2Completed.emit(self, _player)
	SignalBus.Level2StateChanged.emit(self)

func _toast(message: String, seconds: float = 4.0) -> void:
	$HUD/Root/Toast.text = message
	_toast_left = seconds

func _refresh() -> void:
	if not is_node_ready():
		return
	for device in find_children("*", "Node2D", true, false):
		if device.is_in_group("level2_device") and str(device.get_meta("kind", "")) == "key":
			var taken: bool = str(device.get_meta("key_id", "")) in keys
			device.set("available", not taken)
			device.visible = not taken
	$Rooms/WeaveArchive/Gate.visible = not puzzle_solved
	$Rooms/WeaveArchive/Gate/CollisionShape2D.set_deferred("disabled", puzzle_solved)
	$Rooms/WeaveArchive/SequenceStatus.text = "闸门开启" if puzzle_solved else "共鸣进度 %d / %d" % [rune_progress, _rune_order.size()]
	$Rooms/Hub/Fountain/Caption.text = "逆流水柱已开启" if fountain_active else "提交钥匙  %d/3" % submitted_keys.size()
	$Rooms/Hub/FountainStream.visible = fountain_active
	$Rooms/FountainShaft/Stream.visible = fountain_active
	for pair in [[$Rooms/SunStacks, "sun"], [$Rooms/MoonAqueduct, "moon"]]:
		var open: bool = pair[1] in keys
		pair[0].get_node("ReturnCatwalk").visible = open
		pair[0].get_node("Flow").visible = open
		pair[0].get_node("ReturnCatwalk/CollisionShape2D").set_deferred("disabled", not open)

## 导出钥匙、谜题和通关状态；由现有存档系统保存，地图本身不写文件。
func ExportSaveData() -> Dictionary:
	return {"keys": keys.duplicate(), "rune_progress": rune_progress, "puzzle_solved": puzzle_solved, "completed": completed, "submitted_keys": submitted_keys.duplicate(), "fountain_active": fountain_active}

## 还原关卡状态；data 为 ExportSaveData 返回的字典，未知钥匙会被忽略。
func LoadSaveData(data: Dictionary) -> void:
	keys.clear()
	for key in data.get("keys", []):
		if str(key) in ["sun", "moon", "weave"] and not str(key) in keys:
			keys.append(str(key))
	submitted_keys.clear()
	for key in data.get("submitted_keys", []):
		if str(key) in keys and not str(key) in submitted_keys:
			submitted_keys.append(str(key))
	fountain_active = bool(data.get("fountain_active", false)) and submitted_keys.size() == 3
	puzzle_solved = bool(data.get("puzzle_solved", false))
	completed = bool(data.get("completed", false)) and fountain_active
	rune_progress = _rune_order.size() if puzzle_solved else clampi(int(data.get("rune_progress", 0)), 0, maxi(0, _rune_order.size() - 1))
	_refresh()
