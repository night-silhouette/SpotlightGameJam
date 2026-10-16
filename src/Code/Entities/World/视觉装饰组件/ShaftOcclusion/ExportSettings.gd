extends Resource
## 井区域双向遮罩的独立配置，不依赖关卡或全局参数。

@export var enabled: bool = true
## 相对组件原点的井内范围；将组件放到井口左上角后调整尺寸。
@export var shaft_region: Rect2 = Rect2(0, 0, 180, 3000)
@export var mask_color: Color = Color(0.025, 0.04, 0.055, 1.0)
## 不指定人物节点时，用此分组查找人物。
@export var player_group: StringName = &"player"
