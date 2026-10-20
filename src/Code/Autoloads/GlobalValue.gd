extends Node

## 全局物理与重力常量
var gravity: float = 1440.0

var _mobile: bool = false
var _application_paused: bool = false
var _application_unfocused: bool = false
var _lifecycle_paused: bool = false
var _previous_tree_paused: bool = false

func _ready() -> void:
	_mobile = OS.has_feature("android") or OS.has_feature("ios")
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _mobile:
		Engine.max_fps = 60

func _notification(what: int) -> void:
	if not _mobile or not is_inside_tree():
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_application_unfocused = true
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_application_unfocused = false
		NOTIFICATION_APPLICATION_PAUSED:
			_application_paused = true
		NOTIFICATION_APPLICATION_RESUMED:
			_application_paused = false
		_:
			return
	_sync_application_pause()

func _sync_application_pause() -> void:
	var should_pause := _application_paused or _application_unfocused
	if should_pause == _lifecycle_paused:
		return
	var tree := get_tree()
	if should_pause:
		_previous_tree_paused = tree.paused
		# 系统栏可能截断触摸释放事件，避免返回游戏后方向键一直按住。
		for action in InputMap.get_actions():
			Input.action_release(action)
		_lifecycle_paused = true
		tree.paused = true
	else:
		_lifecycle_paused = false
		tree.paused = _previous_tree_paused
