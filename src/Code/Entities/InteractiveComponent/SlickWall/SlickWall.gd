extends StaticBody2D
class_name SlickWall

## =============================================================================
## SlickWall.gd - 光滑滑石墙交互组件 (禁爬、禁蹬、禁钩锁)
## 表面附着极度光滑的青苔/流沙，垂直墙体。
## - 玩家在此类墙面上无法进入挂壁下滑状态 (ClimbState)
## - 无法进行蹬墙跳 (Wall Jump)
## - 钩索命中时无法吸附抓取，会自动滑脱落空回收
## =============================================================================

@export_category("SlickWall Settings")
## 墙体尺寸 (宽度, 高度)
@export var wall_size: Vector2 = Vector2(32.0, 160.0):
	set(value):
		wall_size = value
		_update_dimensions()

## 标识属性：禁止攀爬和蹬墙跳
@export var disable_climb: bool = true
## 标识属性：禁止钩索吸附
@export var disable_hook: bool = true
## 标识布尔：明确标明为滑石墙
@export var is_slick_wall: bool = true

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var base_rect: ColorRect = $BaseRect
@onready var slick_strip: ColorRect = $SlickStrip

func _ready() -> void:
	_update_dimensions()
	# 确保加入全局特定识别组
	if not is_in_group("slick_wall"):
		add_to_group("slick_wall")
	if not is_in_group("no_climb"):
		add_to_group("no_climb")
	if not is_in_group("no_hook"):
		add_to_group("no_hook")

func _update_dimensions() -> void:
	if not is_inside_tree():
		return
	
	if collision_shape:
		var rect = RectangleShape2D.new()
		rect.size = wall_size
		collision_shape.shape = rect

	if base_rect:
		base_rect.offset_left = -wall_size.x * 0.5
		base_rect.offset_right = wall_size.x * 0.5
		base_rect.offset_top = -wall_size.y * 0.5
		base_rect.offset_bottom = wall_size.y * 0.5

	if slick_strip:
		# 在墙面中间渲染一道青苔/流光光滑带
		slick_strip.offset_left = -wall_size.x * 0.2
		slick_strip.offset_right = wall_size.x * 0.2
		slick_strip.offset_top = -wall_size.y * 0.5
		slick_strip.offset_bottom = wall_size.y * 0.5

## 实体数据导出
func ExportSaveData() -> Dictionary:
	return {
		"position_x": global_position.x,
		"position_y": global_position.y,
		"wall_size_x": wall_size.x,
		"wall_size_y": wall_size.y
	}

## 实体数据加载
## @param data 存档字典
func LoadSaveData(data: Dictionary) -> void:
	if data.has("position_x") and data.has("position_y"):
		global_position = Vector2(data["position_x"], data["position_y"])
	if data.has("wall_size_x") and data.has("wall_size_y"):
		wall_size = Vector2(data["wall_size_x"], data["wall_size_y"])
