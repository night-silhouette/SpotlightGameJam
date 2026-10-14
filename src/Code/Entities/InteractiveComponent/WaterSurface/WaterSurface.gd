@tool
extends Node2D
class_name WaterSurface

## 水面无限滚动组件
## 利用 UV 贴图重复流动（TextureRect / Shader 模式），在编辑器和运行时都能看到流动效果

@export var scroll_speed: float = 60.0: ## 水流滚动速度（像素/秒，正数向右，负数向左）
	set(val):
		scroll_speed = val
@export var width: float = 665.0: ## 水面总长度（像素）
	set(val):
		width = val
		_update_size()
@export var height: float = 665.0: ## 水面高度（像素）
	set(val):
		height = val
		_update_size()

@onready var texture_rect: TextureRect = $TextureRect

var _uv_offset_x: float = 0.0

func _ready() -> void:
	_update_size()

func _update_size() -> void:
	var tr = get_node_or_null("TextureRect") as TextureRect
	if tr:
		tr.size = Vector2(width, height)

func _process(delta: float) -> void:
	var tr = get_node_or_null("TextureRect") as TextureRect
	if not tr or not tr.texture:
		return
	
	var tex_w = tr.texture.get_width()
	if tex_w > 0:
		_uv_offset_x += (scroll_speed * delta) / tex_w
		_uv_offset_x = fposmod(_uv_offset_x, 1.0)
		if tr.material is ShaderMaterial:
			(tr.material as ShaderMaterial).set_shader_parameter("offset_x", _uv_offset_x)

## 动态调节流速接口
func set_speed(speed: float) -> void:
	scroll_speed = speed

