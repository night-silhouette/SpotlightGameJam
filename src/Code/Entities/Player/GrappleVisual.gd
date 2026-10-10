extends Node2D

@onready var _source_line: Line2D = get_parent().get_node("RopeController/Line2D")
@onready var _rope: Sprite2D = $Rope
@onready var _hook: Sprite2D = $Hook
@onready var _rope_origin: Marker2D = get_parent().get_node("sprite/Action/RopeOrigin")

## 返回人物动作下发射点的世界坐标；无参数，随 ani_move 的人物姿势和朝向变化。
func GetRopeOrigin() -> Vector2:
	return _rope_origin.global_position

func _ready() -> void:
	# 控制器仍负责线段和物理；此节点仅替换绳身、钩头绘制。
	show()
	_source_line.self_modulate.a = 0.0

func _process(_delta: float) -> void:
	_rope.visible = _source_line.visible and _source_line.get_point_count() >= 2
	_hook.visible = _rope.visible
	if not _rope.visible:
		return
	var start := to_local(GetRopeOrigin())
	var end := to_local(_source_line.to_global(_source_line.get_point_position(1)))
	var direction := end - start
	_rope.visible = direction.length_squared() > 0.0
	_hook.visible = _rope.visible
	_rope.modulate = _source_line.modulate
	_hook.modulate = _source_line.modulate
	_rope.position = start
	_rope.rotation = direction.angle()
	_rope.scale = Vector2(direction.length() / _rope.texture.get_width(), ExportSettings.rope_visual_width / _rope.texture.get_height())
	_rope.offset.y = -_rope.texture.get_height() * 0.5
	_hook.position = end
	_hook.rotation = direction.angle()
	_hook.scale = Vector2.ONE * ExportSettings.rope_visual_hook_scale
