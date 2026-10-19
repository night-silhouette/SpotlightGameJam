extends Node

# 主地形每格 665 * 0.14 = 93.1；排除 0.048 倍背景层及远离游玩路线的瓦片。
# 绿洲包含原点左侧悬崖、右下方 y=820.9 的柱顶，右端接 World 中 Camp 的左界。
const OASIS_BOUNDS := Rect2(-578.6, -1154.9, 19634.6, 3116.9)
# Camp/ collision_layer/TileMapLayer3: cells (0,6)..(26,19)，上方预留跳跃高度。
const CAMP_BOUNDS := Rect2(0.0, 258.6, 2420.6, 1610.3)
const EXIT_MARGIN := 32.0

var _mode: StringName = &""
var _oasis: Node2D
var _camp: Node2D


func _ready() -> void:
	var scope: Node = self if name == &"World" else get_parent()
	_oasis = scope as Node2D if scope.name == &"OasisBattlefield" else scope.get_node_or_null("OasisBattlefield") as Node2D
	_camp = scope as Node2D if scope.name == &"Camp" else scope.get_node_or_null("Camp") as Node2D
	_refresh.call_deferred()


func _physics_process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	# 独立测试场景使用附加节点；装入 World 后只由 World 根控制，避免互相抢歌。
	if self != get_tree().current_scene and get_parent() != get_tree().current_scene:
		return
	var player := get_tree().get_first_node_in_group(&"player") as Node2D
	var next_mode: StringName = &"normal"
	if player != null:
		if _contains(_camp, CAMP_BOUNDS, player.global_position, &"camp"):
			next_mode = &"camp"
		elif _contains(_oasis, OASIS_BOUNDS, player.global_position, &"level3"):
			next_mode = &"level3"
	elif _camp == get_parent():
		next_mode = &"camp"
	if next_mode != _mode:
		_mode = next_mode
		get_node("/root/Util").SetBgmMode(_mode)


func _contains(region: Node2D, bounds: Rect2, world_position: Vector2, mode: StringName) -> bool:
	if not is_instance_valid(region):
		return false
	if _mode == mode:
		bounds = bounds.grow(EXIT_MARGIN)
	return bounds.has_point(region.to_local(world_position))
