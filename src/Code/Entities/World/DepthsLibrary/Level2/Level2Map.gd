extends Node2D
## 连续地下地图：房间通过实体通道相连，玩家能力与死亡复活由角色系统管理。
var keys: Array[String] = []
var rune_progress: int = 0
var puzzle_solved: bool = false
var completed: bool = false
var _rune_order: PackedStringArray = ["sun", "moon", "weave"]
var submitted_keys: Array[String] = []
var fountain_active: bool = false
# 领取状态死亡后可重置；献湖状态永久保留。
var codex_claimed: bool = false
var codex_offered: bool = false
var _elapsed: float = 0.0
var _player: CharacterBody2D
var _owns_player: bool = false
var _active_room: Node2D
var _toast_left: float = 0.0
var _fountain_return_falling: bool = false
var _fountain_fall_camera_held: bool = false
var _fountain_fall_death_requested: bool = false
var _previous_fountain_point := Vector2.ZERO
var _has_previous_fountain_point: bool = false
var _slow_descent_camera: bool = false
var _has_explicit_codex_offered: bool = false

func _ready() -> void:
	var configured: PackedStringArray = ExportSettings.level2_rune_order
	if configured.size() == 3 and configured.has("sun") and configured.has("moon") and configured.has("weave"):
		_rune_order = configured.duplicate()
	var names := {"sun": "日", "moon": "月", "weave": "交织"}
	$Rooms/WeaveArchive/RoomHint.text = "石碑线索：" + str(names[_rune_order[0]]) + " → " + str(names[_rune_order[1]]) + " → " + str(names[_rune_order[2]]) + "。错误会重置顺序。"
	SignalBus.Level2InteractionRequested.connect(_on_requested)
	SignalBus.PlayerRespawned.connect(_on_respawned)
	SignalBus.PlayerDied.connect(_on_player_died)
	SignalBus.PlayerRelicConsumeRequested.connect(_on_relic_consumed)
	SignalBus.SaveSlotLoaded.connect(_on_save_loaded)
	SignalBus.PlayerBeforeMotion.connect(_on_player_before_motion)
	$Rooms/SurfaceExit/FinishArea.body_entered.connect(_on_exit_reached)
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
		_has_previous_fountain_point = false
		_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not is_instance_valid(_player):
		return
	# 先判定从地表落井，避免水柱反推并让下落镜头优先处理。
	if _update_fountain_return_fall():
		return
	var room: Node2D = GetRoomAt(_player.global_position)
	if room != null and not _owns_player:
		_owns_player = true
	elif room == null and _owns_player and not Rect2(Vector2(-4400, -3450), Vector2(8600, 5800)).has_point(to_local(_player.global_position)):
		_owns_player = false
	$HUD.visible = _owns_player
	if room != null:
		if room != _active_room:
			_active_room = room
			$HUD/Root/Objective.text = room.get_node("RoomHint").text
		$HUD/Root/Status.text = str(room.get_meta("title", room.name)) + "  |  携带 %d · 已提交 %d / 3  |  %02d:%02d" % [keys.size() - submitted_keys.size(), submitted_keys.size(), int(_elapsed) / 60, int(_elapsed) % 60]
	if fountain_active and $Rooms/FountainShaft/Updraft.overlaps_body(_player):
		_player.velocity.y = -ExportSettings.level2_fountain_speed
		_player.ResetDoubleJump()

## 返回左侧竖井是否正在使用慢下落镜头；供预览镜头导演让出控制。
func IsSlowDescentActive() -> bool:
	return _slow_descent_camera

func _on_player_before_motion(player: CharacterBody2D, delta: float) -> void:
	if player != get_tree().get_first_node_in_group("player"):
		return
	var shaft: Node2D = $Rooms/DescentShaft
	var bounds: Rect2 = shaft.get_meta("scenery_bounds")
	var point := shaft.to_local(player.global_position)
	var inside := ExportSettings.level2_descent_enabled and bounds.has_point(point)
	inside = inside and not player.debug_flight_enabled and player.now_HP > 0.0 and not _fountain_return_falling
	if inside != _slow_descent_camera:
		_slow_descent_camera = inside
		if inside:
			SignalBus.CameraShotRequested.emit(player, &"descent", {"intro": false, "level2_slow_descent": true})
		elif not _fountain_return_falling:
			SignalBus.CameraNormalRequested.emit(player)
	var background_speed := 0.0
	# 跳跃、冲刺、钩索等特殊状态不改；只限制自由下落。
	if inside and not player.is_special_state and not player.is_on_floor() and player.velocity.y > 0.0:
		var edge := minf(point.y - bounds.position.y, bounds.end.y - point.y)
		var strength := smoothstep(0.0, maxf(1.0, ExportSettings.level2_descent_edge_fade), edge)
		var slow_speed := maxf(1.0, ExportSettings.level2_descent_fall_speed)
		var cap := lerpf(maxf(slow_speed, ExportSettings.level2_descent_edge_speed), slow_speed, strength)
		player.velocity.y = move_toward(player.velocity.y, minf(player.velocity.y, cap), ExportSettings.level2_descent_braking * delta)
		background_speed = ExportSettings.level2_descent_background_speed * strength * clampf(player.velocity.y / slow_speed, 0.0, 1.0)
	SignalBus.Level2DescentVisualChanged.emit(self, background_speed)

## 返回是否正在从地表落入喷泉井；镜头导演在此期间让出两阶段下落镜头。
func IsFountainReturnFallActive() -> bool:
	return _fountain_return_falling

func _update_fountain_return_fall() -> bool:
	var exit_port: Marker2D = $Rooms/FountainShaft/CityExit
	var point := exit_port.to_local(_player.global_position)
	var previous := _previous_fountain_point
	var had_previous := _has_previous_fountain_point
	_previous_fountain_point = point
	_has_previous_fountain_point = true
	if not ExportSettings.level2_fountain_return_fall_enabled:
		_end_fountain_return_fall()
		return false
	var half_width := float(exit_port.get_meta("opening_width", 128.0)) * 0.5
	var in_opening := absf(point.x) < half_width
	# 只识别向下穿越地表的轨迹；正常上升及地下出生不会触发。
	if not _fountain_return_falling and had_previous and previous.y <= 0.0 and point.y > 0.0 and _player.velocity.y > 0.0:
		var crossing_x := lerpf(previous.x, point.x, -previous.y / (point.y - previous.y))
		if absf(crossing_x) < half_width:
			_fountain_return_falling = true
			_owns_player = true
			# 第一阶段跟随玩家向井内下落，不能在刚进井口时就固定画面。
			SignalBus.CameraDescentRequested.emit(_player, "", "", Rect2())
	if _fountain_return_falling:
		# 仍允许玩家在离屏前跳回井口；死亡已请求时只等待正常复活。
		if not _fountain_fall_death_requested and point.y < 0.0:
			_end_fountain_return_fall()
			return false
		if not _fountain_fall_camera_held and point.y >= ExportSettings.level2_fountain_return_fall_distance:
			# 第二阶段锁住此刻画面，让人物继续下落并离开镜头。
			_fountain_fall_camera_held = true
			var anchor: Marker2D = $FountainFallCameraAnchor
			anchor.global_position = get_viewport().get_canvas_transform().affine_inverse() * (get_viewport_rect().size * 0.5)
			SignalBus.CameraFixedRequested.emit(_player, anchor, "", "", Rect2())
			return true
		var screen_point := _player.get_global_transform_with_canvas().origin
		var below_screen := screen_point.y > get_viewport_rect().size.y + ExportSettings.level2_fountain_return_fall_screen_margin
		if _fountain_fall_camera_held and not _fountain_fall_death_requested and point.y >= ExportSettings.level2_fountain_return_fall_distance and below_screen:
			_fountain_fall_death_requested = true
			SignalBus.PlayerInstantDeathRequested.emit(_player, self)
		return true
	# Updraft 延伸到井口上方；向下靠近井口时先让玩家穿入，不能提前顶回去。
	return in_opening and point.y <= 0.0 and _player.velocity.y > 0.0

func _end_fountain_return_fall() -> void:
	var was_falling := _fountain_return_falling
	_fountain_return_falling = false
	_fountain_fall_camera_held = false
	_fountain_fall_death_requested = false
	if was_falling and is_instance_valid(_player):
		SignalBus.CameraNormalRequested.emit(_player)

## 返回指定世界坐标所属房间；找不到时返回 null。
func GetRoomAt(point: Vector2) -> Node2D:
	for room in $Rooms.get_children():
		var bounds := Rect2(Vector2(0, -80), Vector2(float(room.get_meta("width", 2200)), float(room.get_meta("height", 900)) + 80.0))
		if bounds.has_point(room.to_local(point)):
			return room
	return null

## 返回主城左侧下行口、右侧上行口的世界中心及净宽；中心 y 表示地表高度。
## 队友平移整张地图对齐入口，再核对出口；不要缩放地图来适配主城间距。
func GetCityConnections() -> Dictionary:
	var entrance: Marker2D = $Rooms/EntryCollapse/CityEntrance
	var exit_port: Marker2D = $Rooms/FountainShaft/CityExit
	return {
		"entrance": {"position": entrance.global_position, "width": entrance.get_meta("opening_width")},
		"exit": {"position": exit_port.global_position, "width": exit_port.get_meta("opening_width")}
	}

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
				if not codex_claimed and not codex_offered:
					codex_claimed = true
					if not bool(player.get("has_starseekers_codex")):
						SignalBus.lock2.emit()
						_toast("获得观星者残卷！水泵启动，沿喷泉升回地表，将残卷带回主城水池。", 7.0)
					else:
						_toast("水泵已启动，沿喷泉升回地表。观星者残卷已领取。", 7.0)
				else:
					_toast("水泵已启动，沿喷泉升回地表。观星者残卷已领取。", 7.0)
			_refresh()
	SignalBus.Level2StateChanged.emit(self)

func _on_player_died(player: Node2D) -> void:
	if player != get_tree().get_first_node_in_group(&"player") or codex_offered:
		return
	codex_claimed = false

func _on_relic_consumed(relic: StringName) -> void:
	if relic == &"codex":
		codex_offered = true
		codex_claimed = true

func _on_save_loaded(_slot: int) -> void:
	var player := get_tree().get_first_node_in_group(&"player")
	if not is_instance_valid(player):
		return
	var carrying := bool(player.get("has_starseekers_codex"))
	if not _has_explicit_codex_offered and bool(player.get("enable_rope")) and not carrying:
		codex_offered = true
	codex_claimed = codex_offered or carrying

func _on_respawned(_position: Vector2) -> void:
	var from_fountain_fall := _fountain_fall_death_requested
	_end_fountain_return_fall()
	_has_previous_fountain_point = false
	if not _owns_player:
		return
	var lost: int = keys.size() - submitted_keys.size()
	keys.assign(submitted_keys)
	_refresh()
	if not from_fountain_fall:
		_toast("未提交钥匙已回到原位，已提交的保留。" if lost > 0 else "已提交钥匙保留。")
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
	$Rooms/SurfaceExit/SprayStream.visible = fountain_active
	for pair in [[$Rooms/SunStacks, "sun"], [$Rooms/MoonAqueduct, "moon"]]:
		var open: bool = pair[1] in keys
		pair[0].get_node("ReturnCatwalk").visible = open
		pair[0].get_node("Flow").visible = open
		pair[0].get_node("ReturnCatwalk/CollisionShape2D").set_deferred("disabled", not open)

## 导出钥匙、谜题、通关和残卷领取状态；由现有存档系统保存，地图本身不写文件。
func ExportSaveData() -> Dictionary:
	return {"keys": keys.duplicate(), "rune_progress": rune_progress, "puzzle_solved": puzzle_solved, "completed": completed, "submitted_keys": submitted_keys.duplicate(), "fountain_active": fountain_active, "codex_claimed": codex_claimed, "codex_offered": codex_offered}

## 还原关卡状态；data 为 ExportSaveData 返回的字典，未知钥匙会被忽略。
func LoadSaveData(data: Dictionary) -> void:
	_end_fountain_return_fall()
	_has_previous_fountain_point = false
	keys.clear()
	for key in data.get("keys", []):
		if str(key) in ["sun", "moon", "weave"] and not str(key) in keys:
			keys.append(str(key))
	submitted_keys.clear()
	for key in data.get("submitted_keys", []):
		if str(key) in keys and not str(key) in submitted_keys:
			submitted_keys.append(str(key))
	fountain_active = bool(data.get("fountain_active", false)) and submitted_keys.size() == 3
	# 玩家数据可能尚未加载；在 SaveSlotLoaded 后统一根据最终持有状态同步。
	_has_explicit_codex_offered = data.has("codex_offered")
	codex_offered = bool(data.get("codex_offered", false))
	codex_claimed = codex_offered or bool(data.get("codex_claimed", false))
	puzzle_solved = bool(data.get("puzzle_solved", false))
	completed = bool(data.get("completed", false)) and fountain_active
	rune_progress = _rune_order.size() if puzzle_solved else clampi(int(data.get("rune_progress", 0)), 0, maxi(0, _rune_order.size() - 1))
	_refresh()
