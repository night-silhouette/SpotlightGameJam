extends Node2D
## 仅用于镜头验收。渡舟和匀速下落是演示轨迹，不实现正式船体/下落玩法。

var demo_mode: int = 1
var _time: float = 0.0
var _resume_demo_mode: int = 0
@onready var _rig: Node2D = $PlayerWithCamera
@onready var _player: CharacterBody2D = $PlayerWithCamera/Player
@onready var _status: Label = $Controls/Panel/Rows/Status


func _ready() -> void:
	# 只在验收场景隐藏玩家调试 UI；原玩家资源不改动。
	_player.get_node("PlayerUI").hide()
	_player.get_node("debug").hide()
	_player.get_node("hp").hide()
	SignalBus.CameraShotReady.connect(_on_ready_shot)
	for index in range(6):
		get_node("Controls/Panel/Rows/Buttons/Shot%d" % index).pressed.connect(_select.bind(index))
	$Controls/Panel/Rows/Buttons/End.pressed.connect(_end)
	call_deferred("_select", 1)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed or event.echo:
		return
	if event.keycode >= KEY_0 and event.keycode <= KEY_5:
		_select(event.keycode - KEY_0)
	elif event.keycode == KEY_R:
		_select(demo_mode)
	elif event.keycode == KEY_ESCAPE:
		_end()


func _physics_process(delta: float) -> void:
	_time += delta
	if not _rig.input_locked:
		if demo_mode == 2:
			_player.position.y += ExportSettings.camera_demo_fall_speed * delta
			_player.position.x += Input.get_axis("move_l", "move_r") * 150.0 * delta
		elif demo_mode == 3:
			$Boat.position.x += ExportSettings.camera_demo_boat_speed * delta
			$Boat.position.y = 1090 + sin(_time * 2.0) * 8.0
			_player.global_position = $Boat.global_position + Vector2(0, -78)
	queue_redraw()


func _select(index: int) -> void:
	if _rig.input_locked:
		_status.text = "CG 中：先点结束 CG / 按 Esc，返回后再选择模式。"
		return
	if index == 4:
		_resume_demo_mode = demo_mode
	demo_mode = index
	if index != 4:
		_player.process_mode = Node.PROCESS_MODE_DISABLED if index in [2, 3] else Node.PROCESS_MODE_INHERIT
		_player.velocity = Vector2.ZERO
		_player.global_position = Vector2(672, 1040)
		$Boat.position = Vector2(672, 1090)
	$Boat.visible = index in [3, 4]
	$ParallaxScenery.visible = index in [0, 1]
	$Ground/CollisionShape2D.disabled = index == 2
	var modes: Array[StringName] = [&"normal", &"desert", &"descent", &"boat", &"ritual", &"fixed"]
	_status.text = "正在切换：%s。0–5 选择 / R 重播 / Esc 结束 CG。" % modes[index]
	match index:
		0:
			SignalBus.CameraNormalRequested.emit(_player)
		1:
			SignalBus.CameraDesertRequested.emit(_player, "", "长风穿过沙海\n独行者仍向远方", true, Rect2())
		2:
			_player.global_position = Vector2(672, 400)
			SignalBus.CameraDescentRequested.emit(_player, "第二幕 · 深渊下落（示例）", "光在身后远去。\n深处，仍有回声。", Rect2())
		3:
			SignalBus.CameraBoatRequested.emit(_player, $Boat, "", "一叶轻舟，渡过未曾说出的往事。", Rect2())
		4:
			$RitualAnchor.global_position = _player.global_position + Vector2(528, -280)
			SignalBus.CameraRitualRequested.emit(_player, $RitualAnchor, "", "遗物归于湖心。\n故事在此继续。（示例文案）", Rect2())
		5:
			SignalBus.CameraFixedRequested.emit(_player, $RoomAnchor, "小室 · 固定镜头（示例）", "", Rect2())


func _end() -> void:
	SignalBus.CameraShotEndRequested.emit(_player)


func _on_ready_shot(player: Node2D, mode: StringName) -> void:
	if player != _player:
		return
	_status.text = "当前：%s | %s | A/D 移动，空格跳跃；0–5 选模式；R 重播。" % [mode, "CG 已就位，Esc 恢复操作" if _rig.input_locked else "镜头已就位"]
	if demo_mode == 4 and mode != &"ritual":
		demo_mode = _resume_demo_mode
		$ParallaxScenery.visible = demo_mode in [0, 1]
		$Boat.visible = demo_mode == 3
		$Ground/CollisionShape2D.disabled = demo_mode == 2


func _draw() -> void:
	if demo_mode in [0, 1]:
		return
	if demo_mode == 2:
		draw_rect(Rect2(-20000, -20000, 40000, 200000), Color("11151f"))
		var start: int = int(_player.position.y / 400) - 5 if is_instance_valid(_player) else -5
		for row in range(start, start + 12):
			draw_rect(Rect2(90, row * 400, 100, 200), Color("2a3041"))
			draw_rect(Rect2(1230, row * 400 + 100, 130, 140), Color("2a3041"))
			draw_line(Vector2(200, row * 400), Vector2(260, row * 400), Color("737d91"), 3)
	else:
		draw_rect(Rect2(-20000, -20000, 40000, 21090), Color("222f41"))
		draw_rect(Rect2(-20000, 1090, 40000, 20000), Color("355d70"))
		for row in range(7):
			var x: float = 300 + row * 250 + sin(_time + row) * 20
			draw_line(Vector2(x, 1110 + row * 25), Vector2(x + 150, 1110 + row * 25), Color("77949d"), 2)
		if demo_mode == 5:
			draw_rect(Rect2(200, 500, 1000, 610), Color("4b4454"))
			draw_rect(Rect2(200, 500, 1000, 610), Color("ae9790"), false, 8)
			draw_rect(Rect2(640, 850, 90, 260), Color("766575"))
