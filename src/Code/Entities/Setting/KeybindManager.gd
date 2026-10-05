class_name KeybindManager
extends RefCounted

## =============================================================================
## KeybindManager.gd - 按键绑定与独立持久化管理器
## 负责将用户的按键设置保存至本地 user:// 独立文件，并在启动或设置变更时动态同步 InputMap。
## 严格与游戏存档分离，存档的新建、读取、删除绝不影响按键绑定。
## =============================================================================

const DEFAULT_CONFIG_PATH: String = "res://Code/Entities/Setting/Saves/custom_keybinds.json"

## 受支持的可自定义动作列表
const CONFIGURABLE_ACTIONS: Array[StringName] = [
	&"move_l",
	&"move_r",
	&"up",
	&"down",
	&"jump",
	&"dash",
	&"rope_shoot",
	&"rope_swing",
	&"water_rune",
	&"interact"
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
		&"rope_swing": return "绳索摆动"
		&"water_rune": return "水符文技能"
		&"interact": return "场景交互"
		_: return String(action)

## 获取保存文件路径
static func GetSavePath() -> String:
	var export_settings = Engine.get_singleton("ExportSettings") if Engine.has_singleton("ExportSettings") else null
	if not export_settings and Engine.get_main_loop() is SceneTree:
		var root = (Engine.get_main_loop() as SceneTree).root
		if root and root.has_node("ExportSettings"):
			export_settings = root.get_node("ExportSettings")
	if export_settings and "setting_keybinds_path" in export_settings:
		return export_settings.setting_keybinds_path
	return DEFAULT_CONFIG_PATH


## 将 InputEvent 转换为可序列化字典
static func EventToDict(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {
			"type": "key",
			"physical_keycode": event.physical_keycode,
			"keycode": event.keycode
		}
	elif event is InputEventMouseButton:
		return {
			"type": "mouse_button",
			"button_index": event.button_index
		}
	return {}

## 将字典还原为 InputEvent
static func DictToEvent(data: Dictionary) -> InputEvent:
	var event_type = data.get("type", "")
	if event_type == "key":
		var ev = InputEventKey.new()
		ev.physical_keycode = data.get("physical_keycode", 0)
		ev.keycode = data.get("keycode", 0)
		return ev
	elif event_type == "mouse_button":
		var ev = InputEventMouseButton.new()
		ev.button_index = data.get("button_index", 1)
		return ev
	return null

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

## 保存所有动作的主绑定到独立 json
static func SaveKeybinds() -> Error:
	var path = GetSavePath()
	var base_dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
		
	var binds_data: Dictionary = {}
	for act in CONFIGURABLE_ACTIONS:
		var ev = GetPrimaryEventForAction(act)
		if ev:
			var serialized = EventToDict(ev)
			if not serialized.is_empty():
				binds_data[String(act)] = serialized
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(binds_data, "\t"))
	file.close()
	return OK


## 读取并应用本地按键绑定
static func LoadAndApplyKeybinds() -> bool:
	var path = GetSavePath()
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
		if not InputMap.has_action(act):
			continue
		var ev_dict = data[act_name]
		if ev_dict is Dictionary:
			var ev = DictToEvent(ev_dict)
			if ev:
				RebindAction(act, ev, false)
	return true

## 重新绑定某个动作
## @param action 动作名称
## @param new_event 新的输入事件
## @param auto_save 是否立即写入持久化文件
static func RebindAction(action: StringName, new_event: InputEvent, auto_save: bool = true) -> void:
	if not InputMap.has_action(action):
		return
	
	# 清空现有该动作的所有事件并插入新事件
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	
	if auto_save:
		SaveKeybinds()
		
	var bus = Engine.get_singleton("SignalBus") if Engine.has_singleton("SignalBus") else null
	if not bus and Engine.get_main_loop() is SceneTree:
		var root = (Engine.get_main_loop() as SceneTree).root
		if root and root.has_node("SignalBus"):
			bus = root.get_node("SignalBus")
	if bus and bus.has_signal("KeybindChanged"):
		bus.KeybindChanged.emit(action, GetEventText(new_event))

