extends RefCounted

const CONFIG_PATH = "user://touch_button_layout.cfg"
const ACTIONS = ["jump", "dash", "interact"]
const DEFAULT_RIGHT_OFFSETS = {"jump": 83.0, "dash": 221.0, "interact": 91.0}
const DEFAULT_BOTTOM_OFFSETS = {"jump": 88.0, "dash": 141.0, "interact": 218.0}

## 返回三枚按钮在屏幕右半区内的归一化中心坐标与相对默认半径的大小比例。
## viewport_size 为当前 UI 视口尺寸；无配置时按原右下角像素偏移还原默认布局。
static func GetLayout(viewport_size: Vector2) -> Dictionary:
	var layout: Dictionary = {}
	var config := ConfigFile.new()
	var loaded := config.load(CONFIG_PATH) == OK
	for action in ACTIONS:
		var default_x: float = clampf(1.0 - 2.0 * DEFAULT_RIGHT_OFFSETS[action] / maxf(viewport_size.x, 1.0), 0.0, 1.0)
		var default_y: float = clampf(1.0 - DEFAULT_BOTTOM_OFFSETS[action] / maxf(viewport_size.y, 1.0), 0.0, 1.0)
		var x: Variant = config.get_value(action, "x", default_x) if loaded else default_x
		var y: Variant = config.get_value(action, "y", default_y) if loaded else default_y
		var scale: Variant = config.get_value(action, "scale", 1.0) if loaded else 1.0
		layout[action] = {
			"x": clampf(float(x), 0.0, 1.0) if x is float or x is int else default_x,
			"y": clampf(float(y), 0.0, 1.0) if y is float or y is int else default_y,
			"scale": clampf(float(scale), 0.5, 1.5) if scale is float or scale is int else 1.0,
		}
	return layout

## 将按钮右半屏归一化中心坐标及半径倍率独立保存到 user://；layout 包含 jump/dash/interact 字典。
static func SaveLayout(layout: Dictionary) -> Error:
	var config := ConfigFile.new()
	for action in ACTIONS:
		var entry: Dictionary = layout[action]
		config.set_value(action, "x", clampf(float(entry["x"]), 0.0, 1.0))
		config.set_value(action, "y", clampf(float(entry["y"]), 0.0, 1.0))
		config.set_value(action, "scale", clampf(float(entry["scale"]), 0.5, 1.5))
	return config.save(CONFIG_PATH)

## 清除自定义排版，恢复基于当前视口和 ExportSettings 半径的默认布局。
static func ResetLayout() -> Error:
	if not FileAccess.file_exists(CONFIG_PATH):
		return OK
	return DirAccess.remove_absolute(CONFIG_PATH)
