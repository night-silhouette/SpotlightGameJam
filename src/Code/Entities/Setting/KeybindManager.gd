class_name KeybindManager
extends RefCounted

## =============================================================================
## KeybindManager.gd - 按键绑定与独立持久化管理器
## 负责将用户的按键设置保存至本地 user:// 独立文件，并在启动或设置变更时动态同步 InputMap。
## 严格与游戏存档分离，存档的新建、读取、删除绝不影响按键绑定。
## =============================================================================

const DEFAULT_CONFIG_PATH: String = "user://custom_keybinds.json"
const LEGACY_CONFIG_PATH: String = "res://Code/Entities/Setting/Saves/custom_keybinds.json"

static var _initialized: bool = false

## 受支持的可自定义动作列表
const CONFIGURABLE_ACTIONS: Array[StringName] = [
	&"move_l",
	&"move_r",
	&"up",
	&"down",
	&"jump",
	&"dash",
	&"rope_shoot",
	&"interact",
	&"skip_story"
]

## 获取动作友好中文名称
static func GetActionDisplayName(action: StringName) -> String:
	match action:
		&"move_l": return "向左移动"
		&"move_r": return "向右移动"
		&"up": return "向上/爬梯"
		&"down": return "向下"
		&"jump": return "跳跃"
		&"dash": return "冲刺"
		&"rope_shoot": return "绳索发射/拉取"
		&"interact": return "交互"
		&"skip_story": return "跳过当前剧情文字"
		_: return String(action)


## 获取保存文件路径，仅允许 user:// 内的合法文件路径，否则使用默认路径。
static func GetSavePath() -> String:
	var export_settings = Engine.get_singleton("ExportSettings") if Engine.has_singleton("ExportSettings") else null
	if not export_settings and Engine.get_main_loop() is SceneTree:
		var root = (Engine.get_main_loop() as SceneTree).root
		if root and root.has_node("ExportSettings"):
			export_settings = root.get_node("ExportSettings")
	if export_settings and "setting_keybinds_path" in export_settings:
		var path: String = export_settings.setting_keybinds_path
		if path.begins_with("user://"):
			for part in path.trim_prefix("user://").split("/"):
				if part.is_empty() or part == "." or part == ".." or not part.is_valid_filename():
					return DEFAULT_CONFIG_PATH
			return path
	return DEFAULT_CONFIG_PATH


## 将 InputEvent 转换为可序列化字典
static func EventToDict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"physical_keycode": event.physical_keycode,
			"keycode": event.keycode,
			"key_label": event.key_label,
			"unicode": event.unicode,
			"location": event.location,
			"device": event.device,
			"alt_pressed": event.alt_pressed,
			"shift_pressed": event.shift_pressed,
			"ctrl_pressed": event.ctrl_pressed,
			"meta_pressed": event.meta_pressed
		}
	elif event is InputEventMouseButton:
		return {
			"type": "mouse_button",
			"button_index": event.button_index,
			"device": event.device,
			"alt_pressed": event.alt_pressed,
			"shift_pressed": event.shift_pressed,
			"ctrl_pressed": event.ctrl_pressed,
			"meta_pressed": event.meta_pressed
		}
	return {}

## 将字典还原为 InputEvent
static func DictToEvent(data: Dictionary) -> InputEvent:
	var event_type = data.get("type", "")
	if event_type == "key":
		var ev = InputEventKey.new()
		ev.physical_keycode = data.get("physical_keycode", 0)
		ev.keycode = data.get("keycode", 0)
		ev.key_label = data.get("key_label", 0)
		ev.unicode = data.get("unicode", 0)
		ev.location = data.get("location", 0)
		_apply_event_properties(ev, data)
		return ev
	elif event_type == "mouse_button":
		var ev = InputEventMouseButton.new()
		ev.button_index = data.get("button_index", 1)
		_apply_event_properties(ev, data)
		return ev
	return null

static func _apply_event_properties(event: InputEventWithModifiers, data: Dictionary) -> void:
	event.device = data.get("device", 0)
	event.alt_pressed = data.get("alt_pressed", false)
	event.shift_pressed = data.get("shift_pressed", false)
	event.ctrl_pressed = data.get("ctrl_pressed", false)
	event.meta_pressed = data.get("meta_pressed", false)

## 获取 InputEvent 的简洁显示文本
static func GetEventText(event: InputEvent) -> String:
	if event is InputEventKey:
		if event.physical_keycode != 0:
			return OS.get_keycode_string(event.physical_keycode)
		elif event.keycode != 0:
			return OS.get_keycode_string(event.keycode)
		return "未指定按键"
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "鼠标左键"
			MOUSE_BUTTON_RIGHT: return "鼠标右键"
			MOUSE_BUTTON_MIDDLE: return "鼠标中键"
			MOUSE_BUTTON_WHEEL_UP: return "滚轮向上"
			MOUSE_BUTTON_WHEEL_DOWN: return "滚轮向下"
			_: return "鼠标键 " + str(event.button_index)
	return "无绑定"

## 获取当前动作的主按键
static func GetPrimaryEventForAction(action: StringName) -> InputEvent:
	if not InputMap.has_action(action):
		return null
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0]
	return null

## 获取指定动作绑定的快捷按键友好显示短文本 (例如 "F", "E", "Space", "左键" 等)
## @param action 动作名称
## @param fallback_text 未找到时的保底文本
static func GetActionKeyBadgeText(action: StringName, fallback_text: String = "") -> String:
	var ev = GetPrimaryEventForAction(action)
	if not ev:
		return fallback_text
	if ev is InputEventKey:
		var code = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
		if code != 0:
			var s = OS.get_keycode_string(code)
			return s.to_upper()
	elif ev is InputEventMouseButton:
		match ev.button_index:
			MOUSE_BUTTON_LEFT: return "左键"
			MOUSE_BUTTON_RIGHT: return "右键"
			MOUSE_BUTTON_MIDDLE: return "中键"
			_: return "M" + str(ev.button_index)
	return fallback_text


## 保存可自定义动作的完整事件列表到独立 json，返回目录创建或写盘结果。
static func SaveKeybinds() -> Error:
	var path = GetSavePath()
	var base_dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		var dir_error = DirAccess.make_dir_recursive_absolute(base_dir)
		if dir_error != OK:
			return dir_error
		
	var binds_data: Dictionary = {}
	for act in CONFIGURABLE_ACTIONS:
		if not InputMap.has_action(act):
			continue
		var events_data: Array = []
		for event in InputMap.action_get_events(act):
			var serialized = EventToDict(event)
			if not serialized.is_empty():
				events_data.append(serialized)
		binds_data[String(act)] = events_data
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(binds_data, "\t"))
	file.flush()
	var write_error = file.get_error()
	file.close()
	return write_error


## 每进程仅首次读取并应用本地按键绑定；返回本次是否成功加载。
static func LoadAndApplyKeybinds() -> bool:
	if _initialized:
		return false
	_initialized = true
	var path = GetSavePath()
	var migrating = not FileAccess.file_exists(path)
	if migrating:
		path = LEGACY_CONFIG_PATH
	if not FileAccess.file_exists(path):
		return false
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return false
	var json_str = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return false
	
	var data = json.get_data()
	if not (data is Dictionary):
		return false
		
	for act_name in data.keys():
		var act = StringName(act_name)
		if act not in CONFIGURABLE_ACTIONS or not InputMap.has_action(act):
			continue
		var saved_events = data[act_name]
		if saved_events is Dictionary:
			saved_events = [saved_events]
		if not saved_events is Array:
			continue
		var events: Array[InputEvent] = []
		for event_data in saved_events:
			if event_data is Dictionary:
				var event = DictToEvent(event_data)
				if event:
					events.append(event)
		if not saved_events.is_empty() and events.is_empty():
			continue
		InputMap.action_erase_events(act)
		for event in events:
			InputMap.action_add_event(act, event)
		_emit_keybind_changed(act)
	if migrating:
		var save_error = SaveKeybinds()
		if save_error != OK:
			push_warning("旧按键绑定已生效，但迁移保存失败：%s" % error_string(save_error))
	return true

## 重新绑定某个动作，返回保存结果；动作不存在时返回 ERR_DOES_NOT_EXIST。
## @param action 动作名称
## @param new_event 新的输入事件
## @param auto_save 是否立即写入持久化文件
static func RebindAction(action: StringName, new_event: InputEvent, auto_save: bool = true) -> Error:
	if not InputMap.has_action(action):
		return ERR_DOES_NOT_EXIST
	
	# 清空现有该动作的所有事件并插入新事件
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	
	var save_error: Error = OK
	if auto_save:
		save_error = SaveKeybinds()
		
	_emit_keybind_changed(action)
	return save_error

## 从项目 input/<action> 配置复制完整默认事件，仅重置可自定义动作并广播变更。
## 返回独立配置的保存结果；保存失败时本次恢复仍在内存中生效。
static func ResetToDefaults() -> Error:
	for action in CONFIGURABLE_ACTIONS:
		if not InputMap.has_action(action):
			continue
		var defaults: Dictionary = ProjectSettings.get_setting("input/" + String(action), {})
		InputMap.action_erase_events(action)
		for event in defaults.get("events", []):
			if event is InputEvent:
				InputMap.action_add_event(action, event.duplicate())
		_emit_keybind_changed(action)
	return SaveKeybinds()

static func _emit_keybind_changed(action: StringName) -> void:
	var bus = Engine.get_singleton("SignalBus") if Engine.has_singleton("SignalBus") else null
	if not bus and Engine.get_main_loop() is SceneTree:
		var root = (Engine.get_main_loop() as SceneTree).root
		if root and root.has_node("SignalBus"):
			bus = root.get_node("SignalBus")
	if bus and bus.has_signal("KeybindChanged"):
		bus.KeybindChanged.emit(action, GetEventText(GetPrimaryEventForAction(action)))
