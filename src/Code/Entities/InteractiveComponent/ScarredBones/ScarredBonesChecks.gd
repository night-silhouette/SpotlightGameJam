extends Node
## 自动边界检查入口：ScarredBonesChecks.tscn；完成后输出结果并退出测试运行。
## 使用小型物理替身隔离玩家移动、摄像头与剧情导入，与手动集成场景互补。

const BONES_SCENE = preload("res://Code/Entities/InteractiveComponent/ScarredBones/ScarredBones.tscn")
var _failures: Array[String] = []
var _checks: int = 0
var _collected_events: int = 0
var _finished_events: int = 0
var _restore_events: int = 0

class TestPlayer extends CharacterBody2D:
	var now_HP: float = 100.0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	ExportSettings.scarred_bones_lift_duration = 0.03
	ExportSettings.scarred_bones_display_duration = 0.03
	ExportSettings.scarred_bones_fade_duration = 0.03
	SignalBus.ScarredBonesCollected.connect(func(_bones, _player): _collected_events += 1)
	SignalBus.ScarredBonesPresentationFinished.connect(func(_bones): _finished_events += 1)
	SignalBus.ScarredBonesStateRestored.connect(func(_bones, _collected): _restore_events += 1)
	var bones = BONES_SCENE.instantiate()
	add_child(bones)
	var player := TestPlayer.new()
	player.collision_layer = 2
	player.collision_mask = 0
	player.add_to_group("player")
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	collider.shape = shape
	player.add_child(collider)
	player.position = Vector2(400, 0)
	add_child(player)
	await _settle_physics()
	_check(not bones.TryCollect(player) and not bones.get_node("PromptAnchor/Prompt").visible, "outside range rejects input and hides prompt")
	player.position = Vector2.ZERO
	await _settle_physics()
	_check(bones.get_node("PromptAnchor/Prompt").visible, "enter range shows prompt")
	player.position = Vector2(400, 0)
	await _settle_physics()
	_check(not bones.get_node("PromptAnchor/Prompt").visible, "leave range hides prompt")
	player.position = Vector2.ZERO
	await _settle_physics()
	player.remove_from_group("player")
	_check(not bones.TryCollect(player), "other character bodies cannot collect")
	player.add_to_group("player")
	player.now_HP = 0.0
	_check(not bones.TryCollect(player), "dead player cannot collect")
	player.now_HP = 100.0
	player.process_mode = Node.PROCESS_MODE_DISABLED
	await _settle_physics()
	_check(not bones.TryCollect(player) and not bones.get_node("PromptAnchor/Prompt").visible, "CG-disabled player cannot collect")
	player.process_mode = Node.PROCESS_MODE_INHERIT
	await _settle_physics()
	var echo := InputEventKey.new()
	echo.physical_keycode = KEY_F
	echo.pressed = true
	echo.echo = true
	bones._unhandled_input(echo)
	_check(not bones.IsCollected(), "held key echo does not collect")
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	bones._unhandled_input(press)
	_check(bones.IsCollected() and _collected_events == 1, "interact input commits once")
	_check(not bones.TryCollect(player) and _collected_events == 1, "repeated input cannot duplicate pickup")
	var saved: Dictionary = bones.ExportSaveData()
	_check(saved.get("collected") == true, "save during presentation records ownership")
	await get_tree().create_timer(0.18).timeout
	_check(_finished_events == 1 and not bones.get_node("VisualRoot").visible, "presentation finishes once and hides bone")
	bones.LoadSaveData(saved)
	await get_tree().create_timer(0.18).timeout
	_check(_collected_events == 1 and _finished_events == 1 and _restore_events == 1, "load collected does not replay pickup or presentation")
	_check(not bones.TryCollect(player), "loaded collected state blocks pickup")
	bones.LoadSaveData({"collected": false})
	await _settle_physics()
	_check(bones.get_node("VisualRoot").visible and bones.get_node("PromptAnchor/Prompt").visible, "load uncollected restores visual and interaction")
	_check(bones.TryCollect(player) and _collected_events == 2, "reset allows a new pickup")
	bones.LoadSaveData({"collected": false})
	await get_tree().create_timer(0.18).timeout
	_check(_finished_events == 1 and bones.get_node("VisualRoot").visible, "load cancels stale presentation callback")
	bones.LoadSaveData({"collected": "invalid"})
	_check(not bones.IsCollected(), "malformed state is ignored")
	var restored = BONES_SCENE.instantiate()
	restored.LoadSaveData(saved)
	restored.position = Vector2(600, 0)
	add_child(restored)
	_check(restored.IsCollected() and not restored.get_node("VisualRoot").visible, "load before ready safely restores collected")
	_check(bones.get_node("DetectionArea/CollisionShape2D").shape != restored.get_node("DetectionArea/CollisionShape2D").shape, "instances do not share mutable detection shapes")
	_check(_collected_events == 2, "pre-ready restore emits no pickup")
	player.queue_free()
	await _settle_physics()
	_check(not bones.get_node("PromptAnchor/Prompt").visible and not bones.TryCollect(null), "removed player clears prompt and null input is safe")
	print("SCARRED_BONES_CHECKS: %d/%d passed" % [_checks - _failures.size(), _checks])
	for failure in _failures:
		push_error(failure)
	get_tree().quit(0 if _failures.is_empty() else 1)


func _settle_physics() -> void:
	for index in range(3):
		await get_tree().physics_frame
	# process_frame 在节点 _process 之前发出，再等待一帧确保提示已刷新。
	await get_tree().process_frame
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
	print("%s: %s" % ["PASS" if condition else "FAIL", message])
